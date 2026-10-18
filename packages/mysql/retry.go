package mysql

import (
	"context"
	"crypto/rand"
	"database/sql"
	"fmt"
	"math/big"
	"time"
)

// NewClientWithRetry inicializa el pool de conexiones e intenta establecer conectividad
// activa aplicando retroceso exponencial (exponential backoff) con jitter.
func NewClientWithRetry(ctx context.Context, cfg Config, maxRetries int, initialBackoff time.Duration) (*sql.DB, error) {
	if maxRetries <= 0 {
		maxRetries = 5
	}
	if initialBackoff <= 0 {
		initialBackoff = 500 * time.Millisecond
	}

	db, err := NewClient(cfg)
	if err != nil {
		return nil, err
	}

	currentBackoff := initialBackoff
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		pingCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
		err = db.PingContext(pingCtx)
		cancel()

		if err == nil {
			return db, nil
		}

		lastErr = err

		if attempt == maxRetries {
			break
		}

		// Cálculo de jitter aleatorio entre 0 y 250ms
		n, _ := rand.Int(rand.Reader, big.NewInt(250))
		jitter := time.Duration(n.Int64()) * time.Millisecond
		sleepDuration := currentBackoff + jitter

		select {
		case <-ctx.Done():
			_ = db.Close()
			return nil, fmt.Errorf("contexto cancelado durante reintentos hacia mysql: %w", ctx.Err())
		case <-time.After(sleepDuration):
		}

		currentBackoff *= 2
		if currentBackoff > 10*time.Second {
			currentBackoff = 10 * time.Second
		}
	}

	_ = db.Close()
	return nil, fmt.Errorf("fallaron todos los reintentos (%d) de conexión a mysql en %s:%d/%s: %w",
		maxRetries, cfg.Host, cfg.Port, cfg.Database, lastErr)
}
