package mysql

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// Config define los parámetros de conexión y pooling hacia una base de datos MySQL
type Config struct {
	Host            string
	Port            int
	User            string
	Password        string
	Database        string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
	ConnMaxIdleTime time.Duration
	ConnectTimeout  time.Duration
}

// NewClient inicializa un pool de conexiones optimizado hacia MySQL aplicando los límites especificados
func NewClient(cfg Config) (*sql.DB, error) {
	connectTimeout := 5 * time.Second
	if cfg.ConnectTimeout > 0 {
		connectTimeout = cfg.ConnectTimeout
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true&charset=utf8mb4&loc=Local&timeout=%s&tls=preferred",
		cfg.User,
		cfg.Password,
		cfg.Host,
		cfg.Port,
		cfg.Database,
		connectTimeout.String(),
	)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("error al abrir conector mysql: %w", err)
	}

	maxOpen := 25
	if cfg.MaxOpenConns > 0 {
		maxOpen = cfg.MaxOpenConns
	}

	maxIdle := 10
	if cfg.MaxIdleConns > 0 {
		maxIdle = cfg.MaxIdleConns
	}

	lifetime := 5 * time.Minute
	if cfg.ConnMaxLifetime > 0 {
		lifetime = cfg.ConnMaxLifetime
	}

	idleTime := 2 * time.Minute
	if cfg.ConnMaxIdleTime > 0 {
		idleTime = cfg.ConnMaxIdleTime
	}

	db.SetMaxOpenConns(maxOpen)
	db.SetMaxIdleConns(maxIdle)
	db.SetConnMaxLifetime(lifetime)
	db.SetConnMaxIdleTime(idleTime)

	return db, nil
}
