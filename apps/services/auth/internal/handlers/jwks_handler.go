package handlers

import (
	"encoding/json"
	"net/http"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/auth/internal/services"
)

type JWKSHandler struct {
	jwtSvc *services.JWTService
}

func NewJWKSHandler(jwtSvc *services.JWTService) *JWKSHandler {
	return &JWKSHandler{jwtSvc: jwtSvc}
}

func (h *JWKSHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	jwks := h.jwtSvc.GetJWKS()
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(jwks)
}
