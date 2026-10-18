package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/universidad/platform/packages/messaging"
	"github.com/universidad/platform/packages/mysql"
)

type HealthHandler struct {
	db      *sql.DB
	message messaging.MessageBus
}

func NewHealthHandler(db *sql.DB, message messaging.MessageBus) *HealthHandler {
	return &HealthHandler{db: db, message: message}
}

func (h *HealthHandler) Live(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":    "UP",
		"service":   "enrollment-service",
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

	busStatus := "UP"
	if h.message != nil {
		if err := h.message.Ping(ctx); err != nil {
			busStatus = "DEGRADED"
		}
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
		"service":   "enrollment-service",
		"database":  dbStatus,
		"eventBus":  busStatus,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
