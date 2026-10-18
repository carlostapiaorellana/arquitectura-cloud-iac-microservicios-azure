package services

import (
	"context"
	"fmt"
	"log/slog"
	"strconv"

	"github.com/google/uuid"
	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/packages/messaging"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/enrollment/internal/models"
	"github.com/universidad/platform/apps/services/enrollment/internal/repository"
)

type EnrollmentService struct {
	repo       repository.EnrollmentRepository
	messageBus messaging.MessageBus
	logger     *slog.Logger
}

func NewEnrollmentService(
	repo repository.EnrollmentRepository,
	messageBus messaging.MessageBus,
	logger *slog.Logger,
) *EnrollmentService {
	return &EnrollmentService{
		repo:       repo,
		messageBus: messageBus,
		logger:     logger,
	}
}

func (s *EnrollmentService) GetMyEnrollments(ctx context.Context, studentID string) ([]models.Enrollment, error) {
	if studentID == "" {
		return nil, errorhandling.NewUnauthenticatedError("identidad de estudiante no proporcionada", nil)
	}

	enrollments, err := s.repo.GetEnrollmentsByStudentID(ctx, studentID)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al obtener matrículas", err)
	}
	return enrollments, nil
}

func (s *EnrollmentService) GetMyGrades(ctx context.Context, studentID string) ([]models.Grade, error) {
	if studentID == "" {
		return nil, errorhandling.NewUnauthenticatedError("identidad de estudiante no proporcionada", nil)
	}

	grades, err := s.repo.GetGradesByStudentID(ctx, studentID)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al obtener calificaciones", err)
	}
	return grades, nil
}

func (s *EnrollmentService) RegisterEnrollment(ctx context.Context, studentID string, req models.RegisterEnrollmentRequest) (*models.RegisterEnrollmentResponse, error) {
	if studentID == "" {
		return nil, errorhandling.NewUnauthenticatedError("identidad de estudiante no proporcionada", nil)
	}
	if req.AcademicPeriodID <= 0 {
		return nil, errorhandling.NewBadRequestError("academicPeriodId debe ser un identificador válido mayor a 0", nil)
	}
	if len(req.SectionIDs) == 0 {
		return nil, errorhandling.NewBadRequestError("debe seleccionar al menos una sección académica", nil)
	}

	// 1. Persistencia transaccional en enrollment_db
	enrollment, err := s.repo.CreateEnrollment(ctx, studentID, req)
	if err != nil {
		return nil, errorhandling.NewInternalError("error registrando matrícula", err)
	}

	// 2. Publicación asíncrona de evento de dominio EnrollmentConfirmedEvent
	eventPublished := false
	if s.messageBus != nil {
		corrID := observability.GetCorrelationID(ctx)
		eventID := uuid.New().String()

		event := apicontracts.EnrollmentConfirmedEvent{
			BaseEvent: apicontracts.NewBaseEvent(eventID, apicontracts.EventTypeEnrollmentConfirmed, corrID),
			Payload: apicontracts.EnrollmentConfirmedPayload{
				EnrollmentID:   strconv.Itoa(enrollment.ID),
				StudentID:      studentID,
				AcademicTermID: req.AcademicPeriodID,
				StudyPlanID:    1,
				SectionIDs:     req.SectionIDs,
				TotalCredits:   len(req.SectionIDs) * 4,
				TuitionAmount:  350.00,
				Currency:       "PEN",
			},
		}

		if pubErr := s.messageBus.Publish(ctx, apicontracts.TopicEnrollmentEvents, event); pubErr != nil {
			s.logger.Warn("No se pudo publicar EnrollmentConfirmedEvent en el bus de eventos", "error", pubErr, "enrollmentId", enrollment.ID)
		} else {
			s.logger.Info("Evento EnrollmentConfirmedEvent publicado exitosamente", "topic", apicontracts.TopicEnrollmentEvents, "enrollmentId", enrollment.ID, "correlationId", corrID)
			eventPublished = true
		}
	}

	return &models.RegisterEnrollmentResponse{
		EnrollmentID:   enrollment.ID,
		StudentID:      studentID,
		Status:         "CONFIRMED",
		Message:        fmt.Sprintf("Matrícula %d registrada exitosamente para el periodo académico %d", enrollment.ID, req.AcademicPeriodID),
		EventPublished: eventPublished,
	}, nil
}
