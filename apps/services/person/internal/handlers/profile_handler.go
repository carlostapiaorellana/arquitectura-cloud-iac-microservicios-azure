package handlers

import (
	"encoding/json"
	"net/http"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/person/internal/models"
	"github.com/universidad/platform/apps/services/person/internal/services"
)

type ProfileHandler struct {
	personSvc *services.PersonService
}

func NewProfileHandler(personSvc *services.PersonService) *ProfileHandler {
	return &ProfileHandler{personSvc: personSvc}
}

func (h *ProfileHandler) HandleProfileMe(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		h.GetMyProfile(w, r)
	case http.MethodPut:
		h.UpdateMyContact(w, r)
	default:
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
	}
}

func (h *ProfileHandler) GetMyProfile(w http.ResponseWriter, r *http.Request) {
	// 1. Extraer X-User-Id inyectado de forma segura por el Gateway
	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	profile, fromCache, err := h.personSvc.GetMyProfile(r.Context(), userID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	if fromCache {
		w.Header().Set("X-Cache", "HIT")
	} else {
		w.Header().Set("X-Cache", "MISS")
	}

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(profile)
}

func (h *ProfileHandler) UpdateMyContact(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	var req models.UpdateContactRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON inválido", err))
		return
	}

	updated, err := h.personSvc.UpdateMyContact(r.Context(), userID, req)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(updated)
}
