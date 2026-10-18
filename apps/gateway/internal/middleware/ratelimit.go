package middleware

import (
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/packages/observability"
)

type ipHistory struct {
	timestamps []time.Time
}

// RateLimiter gestiona la limitación de peticiones por ventana deslizante en memoria
type RateLimiter struct {
	mu       sync.Mutex
	requests map[string]*ipHistory
	limit    int
	window   time.Duration
}

// NewRateLimiter inicializa un limitador de tasa con capacidad y ventana configurables
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		requests: make(map[string]*ipHistory),
		limit:    limit,
		window:   window,
	}

	// Rutina en segundo plano para purgar IPs inactivas y evitar fugas de memoria
	go func() {
		ticker := time.NewTicker(2 * time.Minute)
		for range ticker.C {
			rl.cleanup()
		}
	}()

	return rl
}

func (rl *RateLimiter) cleanup() {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	for ip, entry := range rl.requests {
		validIdx := 0
		for _, t := range entry.timestamps {
			if now.Sub(t) <= rl.window {
				break
			}
			validIdx++
		}
		if validIdx >= len(entry.timestamps) {
			delete(rl.requests, ip)
		} else {
			entry.timestamps = entry.timestamps[validIdx:]
		}
	}
}

// Allow evalúa si una IP cliente tiene cuota disponible en la ventana actual
func (rl *RateLimiter) Allow(ip string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	entry, exists := rl.requests[ip]
	if !exists {
		entry = &ipHistory{timestamps: make([]time.Time, 0, rl.limit)}
		rl.requests[ip] = entry
	}

	// Descartar marcas de tiempo expiradas fuera de la ventana
	valid := entry.timestamps[:0]
	for _, t := range entry.timestamps {
		if now.Sub(t) <= rl.window {
			valid = append(valid, t)
		}
	}
	entry.timestamps = valid

	if len(entry.timestamps) >= rl.limit {
		return false
	}

	entry.timestamps = append(entry.timestamps, now)
	return true
}

// RateLimitMiddleware intercepta peticiones hacia POST /api/v1/auth/login y aplica cuota por IP
func RateLimitMiddleware(limiter *RateLimiter) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Aplicar exclusivamente a la ruta de inicio de sesión institucional
			if r.Method == http.MethodPost && (r.URL.Path == "/api/v1/auth/login" || r.URL.Path == "/api/v1/auth/login/") {
				clientIP := getClientIP(r)
				if !limiter.Allow(clientIP) {
					corrID := observability.GetCorrelationID(r.Context())
					if corrID == "" {
						corrID = r.Header.Get(observability.HeaderCorrelationID)
					}

					w.Header().Set("Retry-After", "60")
					errorhandling.WriteEnvelope(
						w,
						http.StatusTooManyRequests,
						errorhandling.CodeRateLimitExceeded,
						"demasiadas peticiones hacia el servicio de autenticacion",
						corrID,
					)
					return
				}
			}

			next.ServeHTTP(w, r)
		})
	}
}

func getClientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		first := strings.TrimSpace(parts[0])
		if first != "" {
			return first
		}
	}

	if xrip := r.Header.Get("X-Real-IP"); xrip != "" {
		trimmed := strings.TrimSpace(xrip)
		if trimmed != "" {
			return trimmed
		}
	}

	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err == nil {
		return host
	}
	return r.RemoteAddr
}
