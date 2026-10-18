package handlers

import (
	"encoding/json"
	"net/http"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/auth/internal/models"
	"github.com/universidad/platform/apps/services/auth/internal/services"
)

type AuthHandler struct {
	authSvc *services.AuthService
}

func NewAuthHandler(authSvc *services.AuthService) *AuthHandler {
	return &AuthHandler{authSvc: authSvc}
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON inválido", err))
		return
	}

	resp, err := h.authSvc.Login(r.Context(), req)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	var req models.RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON inválido", err))
		return
	}

	resp, err := h.authSvc.Refresh(r.Context(), req)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	var req models.CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON inválido", err))
		return
	}

	corrID := observability.GetCorrelationID(r.Context())
	user, err := h.authSvc.RegisterUser(r.Context(), req, corrID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"userId":   user.ID,
		"username": user.Username,
		"email":    user.Email,
		"status":   user.Status,
	})
}
