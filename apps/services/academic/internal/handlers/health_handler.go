package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/universidad/platform/packages/mysql"
)

type HealthHandler struct {
	db *sql.DB
}

func NewHealthHandler(db *sql.DB) *HealthHandler {
	return &HealthHandler{db: db}
}

func (h *HealthHandler) Live(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":    "UP",
		"service":   "academic-service",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

func (h *HealthHandler) Ready(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	ctx := r.Context()
	dbStatus := "UP"
	if err := mysql.Ping(ctx, h.db); err != nil {
		dbStatus = "DOWN"
	}

	overall := "READY"
	statusCode := http.StatusOK
	if dbStatus == "DOWN" {
		overall = "DOWN"
		statusCode = http.StatusServiceUnavailable
	}

	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":    overall,
		"service":   "academic-service",
		"database":  dbStatus,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
