package middleware

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	errorhandling "github.com/universidad/platform/packages/error-handling"
)

func TestRateLimiter_Allow(t *testing.T) {
	limiter := NewRateLimiter(5, 1*time.Minute)
	ip := "192.168.1.50"

	for i := 1; i <= 5; i++ {
		if !limiter.Allow(ip) {
			t.Fatalf("se esperaba que la petición %d fuera permitida", i)
		}
	}

	// La 6ta petición debe ser denegada
	if limiter.Allow(ip) {
		t.Fatalf("se esperaba que la petición 6 fuera bloqueada por superar el límite de 5")
	}

	// Otra IP debe tener su cuota independiente
	otherIP := "192.168.1.51"
	if !limiter.Allow(otherIP) {
		t.Fatalf("otra IP debió ser permitida independientemente")
	}
}

func TestRateLimitMiddleware(t *testing.T) {
	limiter := NewRateLimiter(5, 1*time.Minute)
	mw := RateLimitMiddleware(limiter)

	dummyHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	handler := mw(dummyHandler)

	// Peticiones distintas a /api/v1/auth/login no deben afectarse
	for i := 0; i < 10; i++ {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/person/profile/me", nil)
		req.RemoteAddr = "10.0.0.1:12345"
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("petición GET no debe ser rate-limited, obtenido %d", rec.Code)
		}
	}

	// 5 peticiones POST a /api/v1/auth/login deben pasar
	for i := 1; i <= 5; i++ {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", nil)
		req.RemoteAddr = "10.0.0.2:12345"
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("petición %d de login debió responder 200, obtenido %d", i, rec.Code)
		}
	}

	// La 6ta petición debe recibir 429 Too Many Requests
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", nil)
	req.RemoteAddr = "10.0.0.2:12345"
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("petición 6 de login debió responder 429, obtenido %d", rec.Code)
	}

	if retryAfter := rec.Header().Get("Retry-After"); retryAfter != "60" {
		t.Fatalf("cabecera Retry-After esperada 60, obtenida: %s", retryAfter)
	}

	var env errorhandling.ErrorEnvelope
	if err := json.NewDecoder(rec.Body).Decode(&env); err != nil {
		t.Fatalf("error al decodificar sobre canónico de error: %v", err)
	}

	if env.Error.Code != errorhandling.CodeRateLimitExceeded {
		t.Fatalf("código de error esperado %s, obtenido %s", errorhandling.CodeRateLimitExceeded, env.Error.Code)
	}
}
