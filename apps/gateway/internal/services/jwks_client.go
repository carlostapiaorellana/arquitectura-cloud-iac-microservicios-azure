package services

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/universidad/platform/apps/gateway/internal/models"
)

type JWKSClient struct {
	jwksURL    string
	httpClient *http.Client
	mu         sync.RWMutex
	publicKey  *rsa.PublicKey
	lastFetch  time.Time
}

func NewJWKSClient(jwksURL string) *JWKSClient {
	return &JWKSClient{
		jwksURL: jwksURL,
		httpClient: &http.Client{
			Timeout: 4 * time.Second,
		},
	}
}

func (c *JWKSClient) FetchPublicKey() (*rsa.PublicKey, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Reutilizar si fue obtenido recientemente (últimos 60 segundos)
	if c.publicKey != nil && time.Since(c.lastFetch) < 60*time.Second {
		return c.publicKey, nil
	}

	resp, err := c.httpClient.Get(c.jwksURL)
	if err != nil {
		if c.publicKey != nil {
			return c.publicKey, nil // Retornar clave en caché si el upstream falla
		}
		return nil, fmt.Errorf("fallo al consultar jwks de auth-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		if c.publicKey != nil {
			return c.publicKey, nil
		}
		return nil, fmt.Errorf("código HTTP no exitoso al consultar jwks: %d", resp.StatusCode)
	}

	var jwks struct {
		Keys []struct {
			Kid string `json:"kid"`
			N   string `json:"n"`
			E   string `json:"e"`
		} `json:"keys"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("fallo al decodificar jwks: %w", err)
	}

	if len(jwks.Keys) == 0 {
		return nil, errors.New("jwks no contiene claves públicas")
	}

	nBytes, err := base64.RawURLEncoding.DecodeString(jwks.Keys[0].N)
	if err != nil {
		return nil, fmt.Errorf("módulo N base64 inválido: %w", err)
	}

	eBytes, err := base64.RawURLEncoding.DecodeString(jwks.Keys[0].E)
	if err != nil {
		return nil, fmt.Errorf("exponente E base64 inválido: %w", err)
	}

	var n big.Int
	n.SetBytes(nBytes)

	var eInt int
	for _, b := range eBytes {
		eInt = (eInt << 8) | int(b)
	}

	pubKey := &rsa.PublicKey{
		N: &n,
		E: eInt,
	}

	c.publicKey = pubKey
	c.lastFetch = time.Now()

	return pubKey, nil
}

func (c *JWKSClient) VerifyToken(tokenStr string) (*models.TokenClaims, error) {
	parts := strings.Split(tokenStr, ".")
	if len(parts) != 3 {
		return nil, errors.New("formato JWT inválido: debe contener 3 partes separadas por punto")
	}

	pubKey, err := c.FetchPublicKey()
	if err != nil {
		return nil, fmt.Errorf("clave pública no disponible: %w", err)
	}

	signingInput := parts[0] + "." + parts[1]
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return nil, errors.New("firma Base64URL inválida")
	}

	hashed := sha256.Sum256([]byte(signingInput))
	if err := rsa.VerifyPKCS1v15(pubKey, crypto.SHA256, hashed[:], signature); err != nil {
		// Reintentar refrescando la clave una vez (por si rotó la clave en auth-service)
		c.mu.Lock()
		c.publicKey = nil
		c.mu.Unlock()

		freshPubKey, refErr := c.FetchPublicKey()
		if refErr != nil {
			return nil, fmt.Errorf("firma criptográfica inválida: %w", err)
		}

		if retryErr := rsa.VerifyPKCS1v15(freshPubKey, crypto.SHA256, hashed[:], signature); retryErr != nil {
			return nil, fmt.Errorf("firma criptográfica inválida tras refresco de clave: %w", retryErr)
		}
	}

	claimsBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, errors.New("claims Base64URL inválidos")
	}

	var claims models.TokenClaims
	if err := json.Unmarshal(claimsBytes, &claims); err != nil {
		return nil, errors.New("error al deserializar payload de claims")
	}

	if time.Now().UTC().Unix() > claims.Exp {
		return nil, errors.New("token expirado")
	}

	return &claims, nil
}
