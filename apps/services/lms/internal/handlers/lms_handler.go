package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/lms/internal/services"
)

type LmsHandler struct {
	svc *services.LmsService
}

func NewLmsHandler(svc *services.LmsService) *LmsHandler {
	return &LmsHandler{svc: svc}
}

func (h *LmsHandler) Live(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"UP","service":"lms-service"}`))
}

func (h *LmsHandler) Ready(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"READY","service":"lms-service"}`))
}

func (h *LmsHandler) GetMyCourses(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	courses, err := h.svc.GetMyCourses(r.Context(), userID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(courses)
}

func (h *LmsHandler) HandleCoursesRoutes(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	// Ruta esperada: /api/v1/lms/courses/{courseId}/evaluations
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/lms/courses/")
	parts := strings.Split(path, "/")
	if len(parts) >= 2 && parts[1] == "evaluations" {
		courseID := parts[0]
		evals, err := h.svc.GetCourseEvaluations(r.Context(), courseID)
		if err != nil {
			errorhandling.WriteError(w, r, err)
			return
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(evals)
		return
	}

	errorhandling.WriteError(w, r, errorhandling.NewNotFoundError("ruta de curso LMS no encontrada", nil))
}
