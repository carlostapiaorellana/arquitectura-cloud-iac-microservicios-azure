package handlers

import (
	"encoding/json"
	"net/http"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/enrollment/internal/models"
	"github.com/universidad/platform/apps/services/enrollment/internal/services"
)

type EnrollmentHandler struct {
	svc *services.EnrollmentService
}

func NewEnrollmentHandler(svc *services.EnrollmentService) *EnrollmentHandler {
	return &EnrollmentHandler{svc: svc}
}

func (h *EnrollmentHandler) GetMyEnrollments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	enrollments, err := h.svc.GetMyEnrollments(r.Context(), userID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(enrollments)
}

func (h *EnrollmentHandler) GetMyGrades(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	grades, err := h.svc.GetMyGrades(r.Context(), userID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(grades)
}

func (h *EnrollmentHandler) RegisterEnrollment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	var req models.RegisterEnrollmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON de matrícula inválido", err))
		return
	}

	resp, err := h.svc.RegisterEnrollment(r.Context(), userID, req)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(resp)
}
