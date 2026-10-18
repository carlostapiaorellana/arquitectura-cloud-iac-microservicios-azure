package handlers

import (
	"encoding/json"
	"net/http"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/finance/internal/models"
	"github.com/universidad/platform/apps/services/finance/internal/services"
)

type FinanceHandler struct {
	svc *services.FinanceService
}

func NewFinanceHandler(svc *services.FinanceService) *FinanceHandler {
	return &FinanceHandler{svc: svc}
}

func (h *FinanceHandler) GetMyOrders(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	orders, err := h.svc.GetMyOrders(r.Context(), userID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(orders)
}

func (h *FinanceHandler) ProcessPayment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	idempotencyKey := r.Header.Get("Idempotency-Key")
	if idempotencyKey == "" {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("cabecera Idempotency-Key es obligatoria", nil))
		return
	}

	var req models.ProcessPaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON de pago inválido", err))
		return
	}

	resp, err := h.svc.ProcessPayment(r.Context(), userID, idempotencyKey, req)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(resp)
}
