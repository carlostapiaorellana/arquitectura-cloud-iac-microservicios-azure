package observability

import (
	"context"
	"log/slog"
	"os"
	"strings"
)

// InitLogger inicializa y configura slog por defecto en formato JSON estructurado
// inyectando de manera fija service y env a nivel de handler.
func InitLogger(serviceName, env string) *slog.Logger {
	level := slog.LevelInfo
	if strings.EqualFold(os.Getenv("LOG_LEVEL"), "DEBUG") || strings.EqualFold(env, "local") {
		level = slog.LevelDebug
	}

	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: level,
	}).WithAttrs([]slog.Attr{
		slog.String("service", serviceName),
		slog.String("env", env),
	})

	logger := slog.New(handler)
	slog.SetDefault(logger)
	return logger
}

// LogWithContext devuelve un logger que incluye el Correlation ID extraído del contexto
func LogWithContext(ctx context.Context, logger *slog.Logger) *slog.Logger {
	if logger == nil {
		logger = slog.Default()
	}
	corrID := GetCorrelationID(ctx)
	return logger.With("correlation_id", corrID)
}
