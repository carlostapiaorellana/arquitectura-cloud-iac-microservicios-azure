package mysql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

var (
	ErrNilDatabase = errors.New("la instancia de base de datos *sql.DB es nula")
)

// Ping verifica la conectividad activa contra el motor MySQL utilizando un timeout estricto
func Ping(ctx context.Context, db *sql.DB) error {
	if db == nil {
		return ErrNilDatabase
	}

	// Si el contexto no tiene límite de tiempo predefinido, aplicar 2 segundos
	if _, hasDeadline := ctx.Deadline(); !hasDeadline {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, 2*time.Second)
		defer cancel()
	}

	if err := db.PingContext(ctx); err != nil {
		return fmt.Errorf("fallo de comprobación activa (healthcheck) de mysql: %w", err)
	}

	return nil
}

// HealthCheck ejecuta un ping con timeout explícito
func HealthCheck(db *sql.DB, timeout time.Duration) error {
	if timeout <= 0 {
		timeout = 2 * time.Second
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	return Ping(ctx, db)
}
