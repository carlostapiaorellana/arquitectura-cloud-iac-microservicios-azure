package proxy

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"io"
	"log/slog"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	"github.com/universidad/platform/apps/gateway/internal/models"
	gatewayservices "github.com/universidad/platform/apps/gateway/internal/services"
)

func createTestJWTRSA(privKey *rsa.PrivateKey, claims models.TokenClaims) (string, error) {
	header := `{"alg":"RS256","typ":"JWT","kid":"test-key-1"}`
	headerEnc := base64.RawURLEncoding.EncodeToString([]byte(header))

	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	claimsEnc := base64.RawURLEncoding.EncodeToString(claimsJSON)

	signingInput := headerEnc + "." + claimsEnc
	hashed := sha256.Sum256([]byte(signingInput))

	sig, err := rsa.SignPKCS1v15(rand.Reader, privKey, crypto.SHA256, hashed[:])
	if err != nil {
		return "", err
	}
	sigEnc := base64.RawURLEncoding.EncodeToString(sig)

	return signingInput + "." + sigEnc, nil
}

func TestGatewayProxy_HeaderStrippingAndAuth(t *testing.T) {
	// 1. Generar clave RSA para el mock de autenticación
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("error al generar clave RSA: %v", err)
	}

	authServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/.well-known/jwks.json" {
			w.Header().Set("Content-Type", "application/json")
			jwks := map[string]any{
				"keys": []map[string]any{
					{
						"kty": "RSA",
						"use": "sig",
						"alg": "RS256",
						"kid": "test-key-1",
						"n":   base64.RawURLEncoding.EncodeToString(privKey.N.Bytes()),
						"e":   base64.RawURLEncoding.EncodeToString(big.NewInt(int64(privKey.E)).Bytes()),
					},
				},
			}
			_ = json.NewEncoder(w).Encode(jwks)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"service":"auth-mock"}`))
	}))
	defer authServer.Close()

	// 2. Iniciar mock de person-service para verificar inyección de headers
	var receivedUserID string
	var receivedUserRole string
	var spoofedHeaderPresent bool

	personServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedUserID = r.Header.Get(apicontracts.HeaderUserID)
		receivedUserRole = r.Header.Get(apicontracts.HeaderUserRole)
		spoofedHeaderPresent = r.Header.Get("X-User-Custom") != ""
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status": "OK",
		})
	}))
	defer personServer.Close()

	// 3. Iniciar Gateway
	jwksClient := gatewayservices.NewJWKSClient(authServer.URL + "/.well-known/jwks.json")
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))

	gw, err := NewGatewayProxy(
		authServer.URL,
		personServer.URL,
		personServer.URL,
		personServer.URL,
		personServer.URL,
		personServer.URL,
		personServer.URL,
		jwksClient,
		[]string{"*"},
		logger,
	)
	if err != nil {
		t.Fatalf("error al crear Gateway: %v", err)
	}

	// 4. Test Healthcheck
	healthReq := httptest.NewRequest(http.MethodGet, "/health/live", nil)
	healthRec := httptest.NewRecorder()
	gw.ServeHTTP(healthRec, healthReq)
	if healthRec.Code != http.StatusOK {
		t.Fatalf("healthcheck status code esperado 200, obtenido %d", healthRec.Code)
	}

	// 5. Test intento de spoofing sin Bearer token hacia ruta protegida
	spoofReq := httptest.NewRequest(http.MethodGet, "/api/v1/person/profile/me", nil)
	spoofReq.Header.Set(apicontracts.HeaderUserID, "hacked-user-id")
	spoofRec := httptest.NewRecorder()
	gw.ServeHTTP(spoofRec, spoofReq)
	if spoofRec.Code != http.StatusUnauthorized {
		t.Fatalf("se esperaba 401 Unauthorized sin Bearer token, obtenido %d", spoofRec.Code)
	}

	// 6. Test con token legítimo y verificación de stripping
	validClaims := models.TokenClaims{
		Sub:      "018f0001-0000-7000-8000-000000000002",
		Username: "estudiante1",
		Role:     "STUDENT",
		Roles:    []string{"STUDENT"},
		Exp:      time.Now().Add(10 * time.Minute).Unix(),
		Iat:      time.Now().Unix(),
	}
	validToken, err := createTestJWTRSA(privKey, validClaims)
	if err != nil {
		t.Fatalf("error al crear token de prueba: %v", err)
	}

	legitReq := httptest.NewRequest(http.MethodGet, "/api/v1/person/profile/me", nil)
	legitReq.Header.Set("Authorization", "Bearer "+validToken)
	legitReq.Header.Set(apicontracts.HeaderUserID, "spoofed-attacker-id") // Header malicioso previo que debe ser sobreescrito

	legitRec := httptest.NewRecorder()
	gw.ServeHTTP(legitRec, legitReq)

	if legitRec.Code != http.StatusOK {
		t.Fatalf("se esperaba 200 OK con token válido, obtenido %d: %s", legitRec.Code, legitRec.Body.String())
	}

	if receivedUserID != validClaims.Sub {
		t.Fatalf("person-service debió recibir el ID del token (%s), pero recibió: %s", validClaims.Sub, receivedUserID)
	}
	if receivedUserRole != "STUDENT" {
		t.Fatalf("person-service debió recibir el rol STUDENT, pero recibió: %s", receivedUserRole)
	}

	// 7. Test ruta académica (acceso público permitido)
	academicReq := httptest.NewRequest(http.MethodGet, "/api/v1/academic/courses", nil)
	academicRec := httptest.NewRecorder()
	gw.ServeHTTP(academicRec, academicReq)
	if academicRec.Code != http.StatusOK {
		t.Fatalf("se esperaba 200 OK en ruta académica pública, obtenido %d", academicRec.Code)
	}

	// 8. Test ruta de matrícula sin token (401 Unauthorized)
	unauthEnrollReq := httptest.NewRequest(http.MethodGet, "/api/v1/enrollment/my-enrollments", nil)
	unauthEnrollRec := httptest.NewRecorder()
	gw.ServeHTTP(unauthEnrollRec, unauthEnrollReq)
	if unauthEnrollRec.Code != http.StatusUnauthorized {
		t.Fatalf("se esperaba 401 Unauthorized en enrollment sin token, obtenido %d", unauthEnrollRec.Code)
	}

	// 9. Test ruta de matrícula con token válido (200 OK)
	authEnrollReq := httptest.NewRequest(http.MethodGet, "/api/v1/enrollment/my-enrollments", nil)
	authEnrollReq.Header.Set("Authorization", "Bearer "+validToken)
	authEnrollRec := httptest.NewRecorder()
	gw.ServeHTTP(authEnrollRec, authEnrollReq)
	if authEnrollRec.Code != http.StatusOK {
		t.Fatalf("se esperaba 200 OK en enrollment con token, obtenido %d", authEnrollRec.Code)
	}
	_ = spoofedHeaderPresent
}

func TestGatewayProxy_UpstreamUnavailableErrorHandler(t *testing.T) {
	// Crear un servidor cerrado para simular un upstream completamente caído
	closedServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	closedURL := closedServer.URL
	closedServer.Close() // Cerrar inmediatamente para forzar connection refused

	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	jwksClient := gatewayservices.NewJWKSClient(closedURL + "/.well-known/jwks.json")

	gw, err := NewGatewayProxy(
		closedURL,
		closedURL,
		closedURL,
		closedURL,
		closedURL,
		closedURL,
		closedURL,
		jwksClient,
		[]string{"*"},
		logger,
	)
	if err != nil {
		t.Fatalf("error al inicializar Gateway: %v", err)
	}

	// Petición hacia ruta pública académica (apunta al closedServer)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/academic/courses", nil)
	req.Header.Set("X-Correlation-Id", "test-corr-503")
	rec := httptest.NewRecorder()

	gw.ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("se esperaba status HTTP 503 Service Unavailable, pero se obtuvo %d", rec.Code)
	}

	contentType := rec.Header().Get("Content-Type")
	if !strings.HasPrefix(contentType, "application/json") {
		t.Fatalf("Content-Type esperado application/json, obtenido: %s", contentType)
	}

	corrHeader := rec.Header().Get("X-Correlation-Id")
	if corrHeader != "test-corr-503" {
		t.Fatalf("cabecera X-Correlation-Id esperada test-corr-503, obtenida: %s", corrHeader)
	}

	var env struct {
		Error struct {
			Code          string `json:"code"`
			Message       string `json:"message"`
			Status        int    `json:"status"`
			CorrelationID string `json:"correlationId"`
		} `json:"error"`
	}

	if err := json.NewDecoder(rec.Body).Decode(&env); err != nil {
		t.Fatalf("error al decodificar sobre canónico de error JSON: %v", err)
	}

	if env.Error.Code != "SERVICE_UNAVAILABLE" {
		t.Fatalf("código de error esperado SERVICE_UNAVAILABLE, obtenido: %s", env.Error.Code)
	}
	if env.Error.Status != 503 {
		t.Fatalf("status en sobre esperado 503, obtenido: %d", env.Error.Status)
	}
	if env.Error.CorrelationID != "test-corr-503" {
		t.Fatalf("correlationId en sobre esperado test-corr-503, obtenido: %s", env.Error.CorrelationID)
	}
}

