package handlers

import (
	"encoding/json"
	"net/http"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/academic/internal/services"
)

type AcademicHandler struct {
	svc *services.AcademicService
}

func NewAcademicHandler(svc *services.AcademicService) *AcademicHandler {
	return &AcademicHandler{svc: svc}
}

func (h *AcademicHandler) ListPrograms(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	programs, err := h.svc.ListPrograms(r.Context())
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(programs)
}

func (h *AcademicHandler) ListCourses(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	courses, err := h.svc.ListCourses(r.Context())
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(courses)
}

func (h *AcademicHandler) ListSections(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	sections, err := h.svc.ListSections(r.Context())
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(sections)
}
