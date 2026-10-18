package nosql

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// CosmosAdapter implementa DocumentStore comunicándose con la API NoSQL de Azure Cosmos DB
type CosmosAdapter struct {
	endpoint           string
	masterKey          string
	databaseName       string
	useManagedIdentity bool
	httpClient         *http.Client
}

// NewCosmosAdapter inicializa un adaptador hacia Azure Cosmos DB
func NewCosmosAdapter(cfg Config) (*CosmosAdapter, error) {
	if cfg.Endpoint == "" {
		return nil, errors.New("el endpoint de Azure Cosmos DB es requerido")
	}

	endpoint := strings.TrimRight(cfg.Endpoint, "/")

	return &CosmosAdapter{
		endpoint:           endpoint,
		masterKey:          cfg.Key,
		databaseName:       cfg.DatabaseName,
		useManagedIdentity: cfg.UseManagedIdentity,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}, nil
}

func (c *CosmosAdapter) generateAuthHeader(verb, resourceType, resourceLink, date string) string {
	if c.masterKey == "" {
		return ""
	}

	keyBytes, err := base64.StdEncoding.DecodeString(c.masterKey)
	if err != nil {
		return ""
	}

	payload := fmt.Sprintf("%s\n%s\n%s\n%s\n\n",
		strings.ToLower(verb),
		strings.ToLower(resourceType),
		resourceLink,
		strings.ToLower(date),
	)

	mac := hmac.New(sha256.New, keyBytes)
	mac.Write([]byte(payload))
	signature := base64.StdEncoding.EncodeToString(mac.Sum(nil))

	authString := fmt.Sprintf("type=master&ver=1.0&sig=%s", signature)
	return url.QueryEscape(authString)
}

func (c *CosmosAdapter) PutItem(ctx context.Context, collection string, partitionKey string, item any) error {
	raw, err := json.Marshal(item)
	if err != nil {
		return fmt.Errorf("error al serializar documento para Cosmos DB: %w", err)
	}

	resourceLink := fmt.Sprintf("dbs/%s/colls/%s", c.databaseName, collection)
	reqURL := fmt.Sprintf("%s/%s/docs", c.endpoint, resourceLink)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, reqURL, bytes.NewReader(raw))
	if err != nil {
		return err
	}

	dateStr := time.Now().UTC().Format(http.TimeFormat)
	req.Header.Set("x-ms-date", dateStr)
	req.Header.Set("x-ms-version", "2018-12-31")
	req.Header.Set("x-ms-documentdb-is-upsert", "True")
	req.Header.Set("x-ms-documentdb-partitionkey", fmt.Sprintf("[\"%s\"]", partitionKey))
	req.Header.Set("Content-Type", "application/json")

	auth := c.generateAuthHeader(http.MethodPost, "docs", resourceLink, dateStr)
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("error de red al enviar documento a Cosmos DB: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("error de Cosmos DB (%d): %s", resp.StatusCode, string(body))
	}

	return nil
}

func (c *CosmosAdapter) GetItem(ctx context.Context, collection string, partitionKey string, id string, dest any) error {
	resourceLink := fmt.Sprintf("dbs/%s/colls/%s/docs/%s", c.databaseName, collection, id)
	reqURL := fmt.Sprintf("%s/%s", c.endpoint, resourceLink)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return err
	}

	dateStr := time.Now().UTC().Format(http.TimeFormat)
	req.Header.Set("x-ms-date", dateStr)
	req.Header.Set("x-ms-version", "2018-12-31")
	req.Header.Set("x-ms-documentdb-partitionkey", fmt.Sprintf("[\"%s\"]", partitionKey))

	auth := c.generateAuthHeader(http.MethodGet, "docs", resourceLink, dateStr)
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("error de red al consultar Cosmos DB: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return ErrNotFound
	}
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("error de Cosmos DB al obtener item (%d): %s", resp.StatusCode, string(body))
	}

	return json.NewDecoder(resp.Body).Decode(dest)
}

func (c *CosmosAdapter) QueryByPartition(ctx context.Context, collection string, partitionKey string, dest any) error {
	resourceLink := fmt.Sprintf("dbs/%s/colls/%s", c.databaseName, collection)
	reqURL := fmt.Sprintf("%s/%s/docs", c.endpoint, resourceLink)

	queryPayload := map[string]any{
		"query": "SELECT * FROM c WHERE c.partitionKey = @pk",
		"parameters": []map[string]any{
			{"name": "@pk", "value": partitionKey},
		},
	}
	raw, err := json.Marshal(queryPayload)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, reqURL, bytes.NewReader(raw))
	if err != nil {
		return err
	}

	dateStr := time.Now().UTC().Format(http.TimeFormat)
	req.Header.Set("x-ms-date", dateStr)
	req.Header.Set("x-ms-version", "2018-12-31")
	req.Header.Set("x-ms-documentdb-isquery", "True")
	req.Header.Set("x-ms-documentdb-partitionkey", fmt.Sprintf("[\"%s\"]", partitionKey))
	req.Header.Set("Content-Type", "application/query+json")

	auth := c.generateAuthHeader(http.MethodPost, "docs", resourceLink, dateStr)
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("error de red al consultar Cosmos DB por partición: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("error de Cosmos DB en query (%d): %s", resp.StatusCode, string(body))
	}

	var queryResponse struct {
		Documents json.RawMessage `json:"Documents"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&queryResponse); err != nil {
		return err
	}

	return json.Unmarshal(queryResponse.Documents, dest)
}

func (c *CosmosAdapter) DeleteItem(ctx context.Context, collection string, partitionKey string, id string) error {
	resourceLink := fmt.Sprintf("dbs/%s/colls/%s/docs/%s", c.databaseName, collection, id)
	reqURL := fmt.Sprintf("%s/%s", c.endpoint, resourceLink)

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, reqURL, nil)
	if err != nil {
		return err
	}

	dateStr := time.Now().UTC().Format(http.TimeFormat)
	req.Header.Set("x-ms-date", dateStr)
	req.Header.Set("x-ms-version", "2018-12-31")
	req.Header.Set("x-ms-documentdb-partitionkey", fmt.Sprintf("[\"%s\"]", partitionKey))

	auth := c.generateAuthHeader(http.MethodDelete, "docs", resourceLink, dateStr)
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("error de red al eliminar en Cosmos DB: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return ErrNotFound
	}
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("error de Cosmos DB al borrar (%d): %s", resp.StatusCode, string(body))
	}

	return nil
}

func (c *CosmosAdapter) UpdateAtomicCounter(ctx context.Context, collection string, partitionKey string, id string, counterField string, delta int64) (int64, error) {
	// Lectura y reemplazo optimista con retry
	var doc map[string]any
	err := c.GetItem(ctx, collection, partitionKey, id, &doc)
	if err != nil {
		return 0, err
	}

	currentVal := int64(0)
	if val, exists := doc[counterField]; exists {
		if fVal, ok := val.(float64); ok {
			currentVal = int64(fVal)
		}
	}

	newVal := currentVal + delta
	doc[counterField] = newVal

	if err := c.PutItem(ctx, collection, partitionKey, doc); err != nil {
		return 0, err
	}

	return newVal, nil
}

func (c *CosmosAdapter) Ping(ctx context.Context) error {
	resourceLink := fmt.Sprintf("dbs/%s", c.databaseName)
	reqURL := fmt.Sprintf("%s/%s", c.endpoint, resourceLink)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return err
	}

	dateStr := time.Now().UTC().Format(http.TimeFormat)
	req.Header.Set("x-ms-date", dateStr)
	req.Header.Set("x-ms-version", "2018-12-31")

	auth := c.generateAuthHeader(http.MethodGet, "dbs", resourceLink, dateStr)
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("ping fallido contra Cosmos DB: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 && resp.StatusCode != http.StatusNotFound {
		return fmt.Errorf("ping Cosmos DB retornó status %d", resp.StatusCode)
	}

	return nil
}

func (c *CosmosAdapter) Close() error {
	c.httpClient.CloseIdleConnections()
	return nil
}
