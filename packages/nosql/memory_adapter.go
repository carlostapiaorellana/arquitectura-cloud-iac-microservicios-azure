package nosql

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
)

// MemoryAdapter implementa DocumentStore de forma segura y concurrente en memoria
type MemoryAdapter struct {
	mu   sync.RWMutex
	data map[string]map[string][]byte // collection -> compositeKey -> serialized JSON
}

// NewMemoryAdapter crea una nueva instancia de almacenamiento documental en memoria
func NewMemoryAdapter() *MemoryAdapter {
	return &MemoryAdapter{
		data: make(map[string]map[string][]byte),
	}
}

func makeCompositeKey(partitionKey, id string) string {
	return fmt.Sprintf("%s#%s", partitionKey, id)
}

func (m *MemoryAdapter) PutItem(ctx context.Context, collection string, partitionKey string, item any) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	raw, err := json.Marshal(item)
	if err != nil {
		return err
	}

	var mObj map[string]any
	if err := json.Unmarshal(raw, &mObj); err != nil {
		return err
	}

	id := ""
	if idVal, ok := mObj["id"]; ok {
		id = fmt.Sprintf("%v", idVal)
	} else if idVal, ok := mObj["_id"]; ok {
		id = fmt.Sprintf("%v", idVal)
	} else {
		id = partitionKey
	}

	if _, exists := m.data[collection]; !exists {
		m.data[collection] = make(map[string][]byte)
	}

	compKey := makeCompositeKey(partitionKey, id)
	m.data[collection][compKey] = raw
	return nil
}

func (m *MemoryAdapter) GetItem(ctx context.Context, collection string, partitionKey string, id string, dest any) error {
	m.mu.RLock()
	defer m.mu.RUnlock()

	coll, exists := m.data[collection]
	if !exists {
		return ErrNotFound
	}

	compKey := makeCompositeKey(partitionKey, id)
	raw, exists := coll[compKey]
	if !exists {
		return ErrNotFound
	}

	return json.Unmarshal(raw, dest)
}

func (m *MemoryAdapter) QueryByPartition(ctx context.Context, collection string, partitionKey string, dest any) error {
	m.mu.RLock()
	defer m.mu.RUnlock()

	coll, exists := m.data[collection]
	if !exists {
		emptyList, _ := json.Marshal([]any{})
		return json.Unmarshal(emptyList, dest)
	}

	prefix := partitionKey + "#"
	var matchedDocs []json.RawMessage

	for compKey, raw := range coll {
		if len(compKey) >= len(prefix) && compKey[:len(prefix)] == prefix {
			matchedDocs = append(matchedDocs, json.RawMessage(raw))
		}
	}

	combined, err := json.Marshal(matchedDocs)
	if err != nil {
		return err
	}

	return json.Unmarshal(combined, dest)
}

func (m *MemoryAdapter) DeleteItem(ctx context.Context, collection string, partitionKey string, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	coll, exists := m.data[collection]
	if !exists {
		return nil
	}

	compKey := makeCompositeKey(partitionKey, id)
	delete(coll, compKey)
	return nil
}

func (m *MemoryAdapter) UpdateAtomicCounter(ctx context.Context, collection string, partitionKey string, id string, counterField string, delta int64) (int64, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	coll, exists := m.data[collection]
	if !exists {
		coll = make(map[string][]byte)
		m.data[collection] = coll
	}

	compKey := makeCompositeKey(partitionKey, id)
	raw, exists := coll[compKey]

	var doc map[string]any
	if exists {
		_ = json.Unmarshal(raw, &doc)
	} else {
		doc = map[string]any{
			"id":           id,
			"partitionKey": partitionKey,
		}
	}

	currentVal := int64(0)
	if val, ok := doc[counterField]; ok {
		if fVal, ok := val.(float64); ok {
			currentVal = int64(fVal)
		}
	}

	newVal := currentVal + delta
	doc[counterField] = newVal

	updatedRaw, err := json.Marshal(doc)
	if err != nil {
		return 0, err
	}

	coll[compKey] = updatedRaw
	return newVal, nil
}

func (m *MemoryAdapter) Ping(ctx context.Context) error {
	return nil
}

func (m *MemoryAdapter) Close() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.data = make(map[string]map[string][]byte)
	return nil
}
