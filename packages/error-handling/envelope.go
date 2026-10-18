package errorhandling

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

// HeaderCorrelationID constante estándar de cabecera de correlación
const HeaderCorrelationID = "X-Correlation-Id"

// ErrorDetail estructura interna del error canónico unificado
type ErrorDetail struct {
	Code          string `json:"code"`
	Message       string `json:"message"`
	Status        int    `json:"status"`
	CorrelationID string `json:"correlationId"`
	Timestamp     string `json:"timestamp"`
}

// ErrorEnvelope sobre canónico institucional para respuestas de error JSON
type ErrorEnvelope struct {
	Error ErrorDetail `json:"error"`
}

// WriteError inspecciona el error recibido, lo mapea al status code adecuado y
// escribe el sobre JSON unificado en la respuesta HTTP sin exponer trazas internas ni stack traces.
func WriteError(w http.ResponseWriter, r *http.Request, err error) {
	if err == nil {
		return
	}

	correlationID := extractCorrelationID(r)

	domainErr, ok := AsDomainError(err)
	if !ok {
		// Error genérico no tipado: no exponer detalles de base de datos ni stack traces
		WriteEnvelope(w, http.StatusInternalServerError, CodeInternalError, "ha ocurrido un error interno en el servicio", correlationID)
		return
	}

	// Si es un error de servidor interno, omitir mensaje interno sensible si no está sanitizado
	message := domainErr.Message
	if domainErr.Status >= 500 && message == "" {
		message = "ha ocurrido un error interno en el servicio"
	}

	WriteEnvelope(w, domainErr.Status, domainErr.Code, message, correlationID)
}

// WriteEnvelope escribe directamente el sobre JSON estandarizado en la respuesta HTTP
func WriteEnvelope(w http.ResponseWriter, status int, code, message, correlationID string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set(HeaderCorrelationID, correlationID)
	w.WriteHeader(status)

	envelope := ErrorEnvelope{
		Error: ErrorDetail{
			Code:          code,
			Message:       message,
			Status:        status,
			CorrelationID: correlationID,
			Timestamp:     time.Now().UTC().Format(time.RFC3339),
		},
	}

	_ = json.NewEncoder(w).Encode(envelope)
}

// extractCorrelationID extrae el Correlation-ID de las cabeceras HTTP del request
func extractCorrelationID(r *http.Request) string {
	if r == nil {
		return ""
	}

	corrID := strings.TrimSpace(r.Header.Get(HeaderCorrelationID))
	if corrID != "" {
		return corrID
	}

	// Comprobar si se almacenó en el contexto
	if val := r.Context().Value(HeaderCorrelationID); val != nil {
		if s, ok := val.(string); ok && s != "" {
			return s
		}
	}

	return ""
}
