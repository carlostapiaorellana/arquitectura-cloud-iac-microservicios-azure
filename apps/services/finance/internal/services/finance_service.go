package services

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/packages/messaging"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/finance/internal/models"
	"github.com/universidad/platform/apps/services/finance/internal/repository"
)

type FinanceService struct {
	mysqlRepo       *repository.MySQLFinanceRepo
	idempotencyRepo repository.IdempotencyRepository
	eventBus        messaging.MessageBus
	logger          *slog.Logger
}

func NewFinanceService(
	mysqlRepo *repository.MySQLFinanceRepo,
	idempotencyRepo repository.IdempotencyRepository,
	eventBus messaging.MessageBus,
	logger *slog.Logger,
) *FinanceService {
	return &FinanceService{
		mysqlRepo:       mysqlRepo,
		idempotencyRepo: idempotencyRepo,
		eventBus:        eventBus,
		logger:          logger,
	}
}

func (s *FinanceService) GetMyOrders(ctx context.Context, studentID string) ([]models.PaymentOrder, error) {
	if studentID == "" {
		return nil, errorhandling.NewBadRequestError("studentID es requerido", nil)
	}

	// 1. Intentar recuperar desde caché de Redis (particionado por studentID)
	if cachedOrders, err := s.idempotencyRepo.GetOrders(ctx, studentID); err == nil && cachedOrders != nil {
		s.logger.Debug("Órdenes recuperadas de caché Redis", "studentID", studentID, "count", len(cachedOrders))
		return cachedOrders, nil
	}

	// 2. Consulta autoritativa a MySQL
	orders, err := s.mysqlRepo.GetOrdersByStudentID(ctx, studentID)
	if err != nil {
		s.logger.Error("Error al consultar órdenes del estudiante", "studentID", studentID, "error", err)
		return nil, errorhandling.NewInternalError("error interno al consultar órdenes", err)
	}

	if orders == nil {
		orders = []models.PaymentOrder{}
	}

	// 3. Guardar en caché Redis con TTL de 5 minutos
	_ = s.idempotencyRepo.SetOrders(ctx, studentID, orders, 5*time.Minute)

	return orders, nil
}

func (s *FinanceService) ProcessPayment(
	ctx context.Context,
	studentID string,
	idempotencyKey string,
	req models.ProcessPaymentRequest,
) (*models.PaymentResponse, error) {
	if studentID == "" {
		return nil, errorhandling.NewBadRequestError("studentID es requerido", nil)
	}
	if idempotencyKey == "" {
		return nil, errorhandling.NewBadRequestError("cabecera Idempotency-Key es obligatoria", nil)
	}
	if req.PaymentOrderID <= 0 {
		return nil, errorhandling.NewBadRequestError("paymentOrderId inválido", nil)
	}

	// 1. Verificar idempotencia en Redis
	cachedResp, err := s.idempotencyRepo.GetIdempotency(ctx, idempotencyKey)
	if err == nil && cachedResp != nil {
		s.logger.Info("Respuesta idempotente recuperada de Redis sin tocar BD",
			"idempotencyKey", idempotencyKey,
			"paymentId", cachedResp.PaymentID,
		)
		return cachedResp, nil
	}

	// 2. Consultar orden de pago en MySQL
	order, err := s.mysqlRepo.GetOrderByID(ctx, req.PaymentOrderID)
	if err != nil {
		if errors.Is(err, repository.ErrOrderNotFound) {
			return nil, errorhandling.NewNotFoundError("orden de pago no encontrada", err)
		}
		s.logger.Error("Error al buscar orden de pago", "orderID", req.PaymentOrderID, "error", err)
		return nil, errorhandling.NewInternalError("error al validar orden de pago", err)
	}

	// 3. Validar pertenencia del estudiante
	if order.StudentID != studentID {
		return nil, errorhandling.NewForbiddenError("la orden de pago no pertenece al usuario autenticado", nil)
	}

	// 4. Validar estado de la orden (1 = PENDING, 2 = PAID)
	if order.StatusID == 2 {
		return nil, errorhandling.NewConflictError("la orden de pago ya se encuentra pagada", nil)
	}

	// 5. Determinar método de pago
	methodCode := req.MethodCode
	if methodCode == "" {
		methodCode = "CARD"
	}
	method, err := s.mysqlRepo.GetMethodByCode(ctx, methodCode)
	if err != nil {
		// Fallback por defecto a CARD (id: 1)
		method = &models.PaymentMethod{ID: 1, Code: "CARD", Name: "Tarjeta de Credito/Debito"}
	}

	// 6. Validar monto
	paymentAmount := req.Amount
	if paymentAmount <= 0 {
		paymentAmount = order.Amount
	}

	// 7. Generar referencia y entidad de pago
	txRef := fmt.Sprintf("TX-%s-%s", time.Now().Format("20060102150405"), uuid.New().String()[:8])
	now := time.Now().UTC()

	payment := models.Payment{
		PaymentOrderID: order.ID,
		MethodID:       method.ID,
		Amount:         paymentAmount,
		TransactionRef: txRef,
		IdempotencyKey: idempotencyKey,
		PaidAt:         now,
	}

	// 8. Ejecutar Transacción ACID: Insertar pago + Actualizar orden a status 2 (PAID)
	if err := s.mysqlRepo.CreatePaymentTx(ctx, &payment, 2); err != nil {
		if strings.Contains(err.Error(), "Duplicate entry") || strings.Contains(err.Error(), "1062") {
			time.Sleep(100 * time.Millisecond)
			if cachedResp, cErr := s.idempotencyRepo.GetIdempotency(ctx, idempotencyKey); cErr == nil && cachedResp != nil {
				s.logger.Info("Respuesta idempotente recuperada de Redis tras colisión concurrente",
					"idempotencyKey", idempotencyKey,
					"paymentId", cachedResp.PaymentID,
				)
				return cachedResp, nil
			}
			return nil, errorhandling.NewConflictError("transacción concurrente detectada para esta clave de idempotencia", err)
		}
		s.logger.Error("Error al ejecutar transacción de pago", "error", err)
		return nil, errorhandling.NewInternalError("fallo en la transacción de pago", err)
	}

	paymentResp := &models.PaymentResponse{
		PaymentID:      payment.ID,
		PaymentOrderID: payment.PaymentOrderID,
		Amount:         payment.Amount,
		TransactionRef: payment.TransactionRef,
		IdempotencyKey: payment.IdempotencyKey,
		Status:         "PAID",
		PaidAt:         payment.PaidAt,
	}

	// 9. Guardar en Redis para idempotencia estricta (TTL 24 horas)
	if err := s.idempotencyRepo.SetIdempotency(ctx, idempotencyKey, paymentResp, 24*time.Hour); err != nil {
		s.logger.Warn("No se pudo cachear la respuesta idempotente en Redis", "error", err)
	}

	// 9b. Invalidar caché de órdenes del estudiante en Redis
	_ = s.idempotencyRepo.DeleteOrders(ctx, studentID)

	// 10. Publicar evento asíncrono PaymentCompletedEvent
	corrID := observability.GetCorrelationID(ctx)
	if corrID == "" {
		corrID = uuid.New().String()
	}

	enrollmentIDStr := ""
	if order.EnrollmentID != nil {
		enrollmentIDStr = fmt.Sprintf("%d", *order.EnrollmentID)
	}

	completedEvent := apicontracts.PaymentCompletedEvent{
		BaseEvent: apicontracts.NewBaseEvent(uuid.New().String(), apicontracts.EventTypePaymentCompleted, corrID),
		Payload: apicontracts.PaymentCompletedPayload{
			PaymentID:      fmt.Sprintf("%d", payment.ID),
			PaymentOrderID: fmt.Sprintf("%d", payment.PaymentOrderID),
			EnrollmentID:   enrollmentIDStr,
			StudentID:      studentID,
			Amount:         payment.Amount,
			Currency:       "PEN",
			PaymentMethod:  method.Code,
			TransactionRef: payment.TransactionRef,
			PaidAt:         payment.PaidAt.Format(time.RFC3339),
		},
	}

	if s.eventBus != nil {
		if err := s.eventBus.Publish(ctx, apicontracts.QueuePaymentsProcessing, completedEvent); err != nil {
			s.logger.Warn("Error al publicar PaymentCompletedEvent en message bus", "error", err)
		} else {
			s.logger.Info("PaymentCompletedEvent publicado exitosamente",
				"paymentId", payment.ID,
				"topic", apicontracts.QueuePaymentsProcessing,
			)
		}
	}

	return paymentResp, nil
}
