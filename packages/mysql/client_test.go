package mysql

import (
	"context"
	"testing"
	"time"
)

func TestPing_NilDatabase(t *testing.T) {
	err := Ping(context.Background(), nil)
	if err != ErrNilDatabase {
		t.Fatalf("se esperaba ErrNilDatabase, se obtuvo: %v", err)
	}
}

func TestHealthCheck_NilDatabase(t *testing.T) {
	err := HealthCheck(nil, 1*time.Second)
	if err != ErrNilDatabase {
		t.Fatalf("se esperaba ErrNilDatabase, se obtuvo: %v", err)
	}
}

func TestNewClient_Config(t *testing.T) {
	cfg := Config{
		Host:         "127.0.0.1",
		Port:         3306,
		User:         "test_user",
		Password:     "test_pwd",
		Database:     "test_db",
		MaxOpenConns: 15,
		MaxIdleConns: 5,
	}

	db, err := NewClient(cfg)
	if err != nil {
		t.Fatalf("error al instanciar cliente mysql: %v", err)
	}
	defer db.Close()

	if db.Stats().MaxOpenConnections != 15 {
		t.Errorf("se esperaba MaxOpenConnections 15, se obtuvo %d", db.Stats().MaxOpenConnections)
	}
}
