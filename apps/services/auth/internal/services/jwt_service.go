package services

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"math/big"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/universidad/platform/apps/services/auth/internal/models"
)

const (
	KeyIDDefault = "auth-rsa-key-1"
	Issuer       = "auth-service"
	Audience     = "university-platform"
)

type JWTService struct {
	mu         sync.RWMutex
	privateKey *rsa.PrivateKey
	publicKey  *rsa.PublicKey
	keyID      string
	tokenTTL   time.Duration
}

type JWK struct {
	Kty string `json:"kty"`
	Use string `json:"use"`
	Alg string `json:"alg"`
	Kid string `json:"kid"`
	N   string `json:"n"`
	E   string `json:"e"`
}

type JWKSResponse struct {
	Keys []JWK `json:"keys"`
}

func NewJWTService(certsDir string, tokenTTL time.Duration) (*JWTService, error) {
	svc := &JWTService{
		keyID:    KeyIDDefault,
		tokenTTL: tokenTTL,
	}

	privPath := filepath.Join(certsDir, "jwt-private.pem")
	pubPath := filepath.Join(certsDir, "jwt-public.pem")

	// 1. Intentar cargar claves de disco
	if privData, err := os.ReadFile(privPath); err == nil {
		block, _ := pem.Decode(privData)
		if block != nil {
			if privKey, err := x509.ParsePKCS1PrivateKey(block.Bytes); err == nil {
				svc.privateKey = privKey
				svc.publicKey = &privKey.PublicKey
				return svc, nil
			} else if key, err := x509.ParsePKCS8PrivateKey(block.Bytes); err == nil {
				if rsaKey, ok := key.(*rsa.PrivateKey); ok {
					svc.privateKey = rsaKey
					svc.publicKey = &rsaKey.PublicKey
					return svc, nil
				}
			}
		}
	}

	// 2. Generar un nuevo par de claves RSA 2048-bit en memoria
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, fmt.Errorf("error al generar par de claves RSA 2048: %w", err)
	}

	svc.privateKey = privKey
	svc.publicKey = &privKey.PublicKey

	// 3. Opcional: persistir en disco si el directorio existe o se puede crear
	if err := os.MkdirAll(certsDir, 0700); err == nil {
		privPEM := pem.EncodeToMemory(&pem.Block{
			Type:  "RSA PRIVATE KEY",
			Bytes: x509.MarshalPKCS1PrivateKey(privKey),
		})
		_ = os.WriteFile(privPath, privPEM, 0600)

		pubASN1, err := x509.MarshalPKIXPublicKey(&privKey.PublicKey)
		if err == nil {
			pubPEM := pem.EncodeToMemory(&pem.Block{
				Type:  "PUBLIC KEY",
				Bytes: pubASN1,
			})
			_ = os.WriteFile(pubPath, pubPEM, 0644)
		}
	}

	return svc, nil
}

// GenerateAccessToken genera un JWT RS256 con claims estándar
func (s *JWTService) GenerateAccessToken(user *models.User) (string, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if s.privateKey == nil {
		return "", errors.New("clave privada RSA no disponible")
	}

	now := time.Now().UTC()
	exp := now.Add(s.tokenTTL)

	header := map[string]string{
		"alg": "RS256",
		"typ": "JWT",
		"kid": s.keyID,
	}

	headerJSON, err := json.Marshal(header)
	if err != nil {
		return "", err
	}

	claims := models.TokenClaims{
		Sub:      user.ID,
		Username: user.Username,
		Role:     user.RoleName,
		Roles:    []string{user.RoleName},
		Scopes:   []string{},
		Iss:      Issuer,
		Aud:      Audience,
		Exp:      exp.Unix(),
		Iat:      now.Unix(),
	}

	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}

	encodedHeader := base64.RawURLEncoding.EncodeToString(headerJSON)
	encodedClaims := base64.RawURLEncoding.EncodeToString(claimsJSON)
	signingInput := encodedHeader + "." + encodedClaims

	hashed := sha256.Sum256([]byte(signingInput))
	signature, err := rsa.SignPKCS1v15(rand.Reader, s.privateKey, crypto.SHA256, hashed[:])
	if err != nil {
		return "", fmt.Errorf("error al firmar token: %w", err)
	}

	encodedSignature := base64.RawURLEncoding.EncodeToString(signature)
	return signingInput + "." + encodedSignature, nil
}

// GenerateRefreshToken genera una cadena pseudoaleatoria segura y su hash SHA-256
func (s *JWTService) GenerateRefreshToken() (tokenRaw string, tokenHash string, err error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", "", fmt.Errorf("error al generar bytes aleatorios: %w", err)
	}

	tokenRaw = hex.EncodeToString(bytes)
	tokenHash = s.HashToken(tokenRaw)
	return tokenRaw, tokenHash, nil
}

func (s *JWTService) HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

// GetJWKS exporta el JSON Web Key Set público
func (s *JWTService) GetJWKS() JWKSResponse {
	s.mu.RLock()
	defer s.mu.RUnlock()

	nBytes := s.publicKey.N.Bytes()
	eBytes := big.NewInt(int64(s.publicKey.E)).Bytes()

	return JWKSResponse{
		Keys: []JWK{
			{
				Kty: "RSA",
				Use: "sig",
				Alg: "RS256",
				Kid: s.keyID,
				N:   base64.RawURLEncoding.EncodeToString(nBytes),
				E:   base64.RawURLEncoding.EncodeToString(eBytes),
			},
		},
	}
}

func (s *JWTService) TokenTTL() time.Duration {
	return s.tokenTTL
}
