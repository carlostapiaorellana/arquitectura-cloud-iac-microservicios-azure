package apicontracts

import (
	"net/http"
	"strings"
)

// Constantes contractuales de cabeceras HTTP internas y perimetrales
const (
	HeaderUserID         = "X-User-Id"
	HeaderUserRole       = "X-User-Role"
	HeaderUserScopes     = "X-User-Scopes"
	HeaderUserEmail      = "X-User-Email"
	HeaderCorrelationID  = "X-Correlation-Id"
	HeaderIdempotencyKey = "Idempotency-Key"
	HeaderAuthorization  = "Authorization"
)

// InternalIdentity representa la identidad autenticada propagada por el API Gateway
type InternalIdentity struct {
	UserID   string   `json:"userId"`
	Email    string   `json:"email"`
	Role     string   `json:"role"`
	Scopes   []string `json:"scopes"`
}

// ExtractIdentity extrae la identidad del usuario a partir de las cabeceras sanitizadas por el Gateway
func ExtractIdentity(r *http.Request) InternalIdentity {
	if r == nil {
		return InternalIdentity{}
	}

	rawScopes := r.Header.Get(HeaderUserScopes)
	var scopes []string
	if rawScopes != "" {
		for _, s := range strings.Split(rawScopes, ",") {
			trimmed := strings.TrimSpace(s)
			if trimmed != "" {
				scopes = append(scopes, trimmed)
			}
		}
	}

	return InternalIdentity{
		UserID: r.Header.Get(HeaderUserID),
		Email:  r.Header.Get(HeaderUserEmail),
		Role:   r.Header.Get(HeaderUserRole),
		Scopes: scopes,
	}
}

// GetIdempotencyKey obtiene la clave de idempotencia de la petición
func GetIdempotencyKey(r *http.Request) string {
	if r == nil {
		return ""
	}
	return strings.TrimSpace(r.Header.Get(HeaderIdempotencyKey))
}
