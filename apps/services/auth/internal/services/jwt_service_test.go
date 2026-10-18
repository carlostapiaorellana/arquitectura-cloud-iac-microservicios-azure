package services

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"strings"
	"testing"
	"time"

	"github.com/universidad/platform/apps/services/auth/internal/models"
)

func TestJWTService_GenerateAndVerify(t *testing.T) {
	jwtSvc, err := NewJWTService(t.TempDir(), 15*time.Minute)
	if err != nil {
		t.Fatalf("error al crear JWTService: %v", err)
	}

	user := &models.User{
		ID:       "018f0001-0000-7000-8000-000000000001",
		Username: "admin",
		Email:    "admin@universidad.edu.pe",
		RoleName: "ADMIN",
	}

	token, err := jwtSvc.GenerateAccessToken(user)
	if err != nil {
		t.Fatalf("error al generar access token: %v", err)
	}

	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		t.Fatalf("token debe tener 3 partes, obtenido: %d", len(parts))
	}

	// Verificar firma directamente con la clave pública
	jwks := jwtSvc.GetJWKS()
	if len(jwks.Keys) == 0 {
		t.Fatal("JWKS debe contener al menos 1 clave pública")
	}

	signingInput := parts[0] + "." + parts[1]
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		t.Fatalf("error al decodificar firma: %v", err)
	}

	hashed := sha256.Sum256([]byte(signingInput))
	if err := rsa.VerifyPKCS1v15(jwtSvc.publicKey, crypto.SHA256, hashed[:], sig); err != nil {
		t.Fatalf("firma RS256 inválida: %v", err)
	}
}

func TestJWTService_RefreshTokenGeneration(t *testing.T) {
	jwtSvc, err := NewJWTService(t.TempDir(), 15*time.Minute)
	if err != nil {
		t.Fatalf("error al crear JWTService: %v", err)
	}

	tokenRaw, tokenHash, err := jwtSvc.GenerateRefreshToken()
	if err != nil {
		t.Fatalf("error al generar refresh token: %v", err)
	}

	if tokenRaw == "" || tokenHash == "" {
		t.Fatal("tokenRaw y tokenHash no pueden estar vacíos")
	}

	expectedHash := jwtSvc.HashToken(tokenRaw)
	if tokenHash != expectedHash {
		t.Fatalf("hash no coincide: obtenido %s, esperado %s", tokenHash, expectedHash)
	}
}
