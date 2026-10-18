package handlers

import (
	"context"
	"database/sql"
	"net/http"
	"time"

	"github.com/universidad/platform/apps/services/finance/internal/repository"
)

type HealthHandler struct {
	db    *sql.DB
	cache repository.IdempotencyRepository
}

func NewHealthHandler(db *sql.DB, cache repository.IdempotencyRepository) *HealthHandler {
	return &HealthHandler{db: db, cache: cache}
}

func (h *HealthHandler) Live(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"UP","service":"finance-service"}`))
}

func (h *HealthHandler) Ready(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if h.db != nil {
		if err := h.db.PingContext(ctx); err != nil {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte(`{"status":"DOWN","reason":"mysql unreachable"}`))
			return
		}
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"READY","service":"finance-service"}`))
}
