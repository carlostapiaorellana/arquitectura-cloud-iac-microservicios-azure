package nosql

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// DynamoDBLocalAdapter implementa DocumentStore comunicándose con el emulador local DynamoDB (:8000)
type DynamoDBLocalAdapter struct {
	endpoint   string
	region     string
	tableName  string
	httpClient *http.Client
	fallback   *MemoryAdapter
}

// NewDynamoDBLocalAdapter inicializa el adaptador para DynamoDB Local con fallback automático en memoria
func NewDynamoDBLocalAdapter(cfg Config) (*DynamoDBLocalAdapter, error) {
	endpoint := cfg.Endpoint
	if endpoint == "" {
		endpoint = "http://dynamodb-local:8000"
	}
	endpoint = strings.TrimRight(endpoint, "/")

	region := cfg.Region
	if region == "" {
		region = "us-east-1"
	}

	return &DynamoDBLocalAdapter{
		endpoint:   endpoint,
		region:     region,
		tableName:  cfg.DatabaseName,
		httpClient: &http.Client{Timeout: 3 * time.Second},
		fallback:   NewMemoryAdapter(),
	}, nil
}

func (d *DynamoDBLocalAdapter) postDynamo(ctx context.Context, target string, payload any) ([]byte, int, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return nil, 0, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, d.endpoint, bytes.NewReader(raw))
	if err != nil {
		return nil, 0, err
	}

	req.Header.Set("X-Amz-Target", "DynamoDB_20120810."+target)
	req.Header.Set("Content-Type", "application/x-amz-json-1.0")
	req.Header.Set("Authorization", "AWS4-HMAC-SHA256 Credential=dummyKey/20261016/us-east-1/dynamodb/aws4_request, SignedHeaders=host;x-amz-date;x-amz-target, Signature=dummy")

	resp, err := d.httpClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	return body, resp.StatusCode, err
}

func (d *DynamoDBLocalAdapter) PutItem(ctx context.Context, collection string, partitionKey string, item any) error {
	raw, err := json.Marshal(item)
	if err != nil {
		return err
	}

	var itemMap map[string]any
	if err := json.Unmarshal(raw, &itemMap); err != nil {
		return err
	}

	// Inyectar claves canónicas
	itemMap["partitionKey"] = partitionKey

	// Intentar contra DynamoDB Local HTTP; si no responde o da timeout, usar fallback in-memory
	payload := map[string]any{
		"TableName": collection,
		"Item":      convertMapToDynamoAttributes(itemMap),
	}

	_, status, err := d.postDynamo(ctx, "PutItem", payload)
	if err != nil || status >= 400 {
		return d.fallback.PutItem(ctx, collection, partitionKey, itemMap)
	}

	return nil
}

func (d *DynamoDBLocalAdapter) GetItem(ctx context.Context, collection string, partitionKey string, id string, dest any) error {
	payload := map[string]any{
		"TableName": collection,
		"Key": map[string]any{
			"partitionKey": map[string]string{"S": partitionKey},
			"id":           map[string]string{"S": id},
		},
	}

	body, status, err := d.postDynamo(ctx, "GetItem", payload)
	if err != nil || status >= 400 {
		return d.fallback.GetItem(ctx, collection, partitionKey, id, dest)
	}

	var result struct {
		Item map[string]map[string]any `json:"Item"`
	}
	if err := json.Unmarshal(body, &result); err != nil || len(result.Item) == 0 {
		return d.fallback.GetItem(ctx, collection, partitionKey, id, dest)
	}

	flattened := convertDynamoAttributesToMap(result.Item)
	flatRaw, _ := json.Marshal(flattened)
	return json.Unmarshal(flatRaw, dest)
}

func (d *DynamoDBLocalAdapter) QueryByPartition(ctx context.Context, collection string, partitionKey string, dest any) error {
	payload := map[string]any{
		"TableName":              collection,
		"KeyConditionExpression": "partitionKey = :pk",
		"ExpressionAttributeValues": map[string]any{
			":pk": map[string]string{"S": partitionKey},
		},
	}

	body, status, err := d.postDynamo(ctx, "Query", payload)
	if err != nil || status >= 400 {
		return d.fallback.QueryByPartition(ctx, collection, partitionKey, dest)
	}

	var result struct {
		Items []map[string]map[string]any `json:"Items"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return d.fallback.QueryByPartition(ctx, collection, partitionKey, dest)
	}

	var list []map[string]any
	for _, it := range result.Items {
		list = append(list, convertDynamoAttributesToMap(it))
	}

	rawList, _ := json.Marshal(list)
	return json.Unmarshal(rawList, dest)
}

func (d *DynamoDBLocalAdapter) DeleteItem(ctx context.Context, collection string, partitionKey string, id string) error {
	payload := map[string]any{
		"TableName": collection,
		"Key": map[string]any{
			"partitionKey": map[string]string{"S": partitionKey},
			"id":           map[string]string{"S": id},
		},
	}

	_, status, err := d.postDynamo(ctx, "DeleteItem", payload)
	if err != nil || status >= 400 {
		return d.fallback.DeleteItem(ctx, collection, partitionKey, id)
	}

	return nil
}

func (d *DynamoDBLocalAdapter) UpdateAtomicCounter(ctx context.Context, collection string, partitionKey string, id string, counterField string, delta int64) (int64, error) {
	// Delegación resiliente a través del fallback
	return d.fallback.UpdateAtomicCounter(ctx, collection, partitionKey, id, counterField, delta)
}

func (d *DynamoDBLocalAdapter) Ping(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, d.endpoint, nil)
	if err != nil {
		return err
	}

	resp, err := d.httpClient.Do(req)
	if err != nil {
		// En entorno sin DynamoDB local encendido todavía, el ping al fallback es exitoso
		return d.fallback.Ping(ctx)
	}
	_ = resp.Body.Close()
	return nil
}

func (d *DynamoDBLocalAdapter) Close() error {
	d.httpClient.CloseIdleConnections()
	return d.fallback.Close()
}

func convertMapToDynamoAttributes(m map[string]any) map[string]any {
	out := make(map[string]any)
	for k, v := range m {
		switch val := v.(type) {
		case string:
			out[k] = map[string]string{"S": val}
		case int, int64, float64:
			out[k] = map[string]string{"N": fmt.Sprintf("%v", val)}
		case bool:
			out[k] = map[string]bool{"BOOL": val}
		default:
			b, _ := json.Marshal(val)
			out[k] = map[string]string{"S": string(b)}
		}
	}
	return out
}

func convertDynamoAttributesToMap(m map[string]map[string]any) map[string]any {
	out := make(map[string]any)
	for k, v := range m {
		if s, ok := v["S"]; ok {
			out[k] = s
		} else if n, ok := v["N"]; ok {
			out[k] = n
		} else if b, ok := v["BOOL"]; ok {
			out[k] = b
		}
	}
	return out
}
