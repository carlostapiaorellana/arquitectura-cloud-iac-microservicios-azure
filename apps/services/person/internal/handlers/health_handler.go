package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/universidad/platform/packages/mysql"
	"github.com/universidad/platform/apps/services/person/internal/repository"
)

type HealthHandler struct {
	db        *sql.DB
	cacheRepo repository.CacheRepository
}

func NewHealthHandler(db *sql.DB, cacheRepo repository.CacheRepository) *HealthHandler {
	return &HealthHandler{db: db, cacheRepo: cacheRepo}
}

func (h *HealthHandler) Live(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":    "UP",
		"service":   "person-service",
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

	redisStatus := "UP"
	if h.cacheRepo != nil {
		if err := h.cacheRepo.Ping(ctx); err != nil {
			redisStatus = "DEGRADED"
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
		"service":   "person-service",
		"database":  dbStatus,
		"redis":     redisStatus,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
