package observability

import (
	"log/slog"
	"net/http"
	"time"
)

// statusTrackingResponseWriter envuelve http.ResponseWriter para interceptar el código de estado HTTP
type statusTrackingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func newStatusTrackingResponseWriter(w http.ResponseWriter) *statusTrackingResponseWriter {
	return &statusTrackingResponseWriter{ResponseWriter: w, statusCode: http.StatusOK}
}

func (w *statusTrackingResponseWriter) WriteHeader(code int) {
	w.statusCode = code
	w.ResponseWriter.WriteHeader(code)
}

// CorrelationMiddleware intercepta la petición HTTP, extrae o genera el Correlation-ID,
// lo propaga en las cabeceras de respuesta y en el contexto de Go.
func CorrelationMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		corrID := ExtractOrGenerateCorrelationID(r)

		// Cabecera en la respuesta para el cliente o servicio consumidor
		w.Header().Set(HeaderCorrelationID, corrID)

		// Inyección en el contexto de la petición
		ctx := WithCorrelationID(r.Context(), corrID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequestLoggerMiddleware registra en formato JSON estructurado cada petición HTTP
// incluyendo método, path, código de respuesta, latencia y Correlation-ID.
func RequestLoggerMiddleware(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			wrapped := newStatusTrackingResponseWriter(w)

			// Asegurar que exista correlation ID en contexto
			corrID := ExtractOrGenerateCorrelationID(r)
			ctx := WithCorrelationID(r.Context(), corrID)
			wrapped.Header().Set(HeaderCorrelationID, corrID)

			next.ServeHTTP(wrapped, r.WithContext(ctx))

			duration := time.Since(start)

			logEntry := LogWithContext(ctx, logger)
			logEntry.Info("http request",
				slog.String("method", r.Method),
				slog.String("path", r.URL.Path),
				slog.Int("status", wrapped.statusCode),
				slog.Float64("duration_ms", float64(duration.Microseconds())/1000.0),
				slog.String("remote_addr", r.RemoteAddr),
				slog.String("user_agent", r.UserAgent()),
			)
		})
	}
}
