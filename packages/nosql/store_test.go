package nosql

import (
	"context"
	"testing"
)

type sampleDoc struct {
	ID           string `json:"id"`
	PartitionKey string `json:"partitionKey"`
	Title        string `json:"title"`
	Views        int64  `json:"views"`
}

func TestMemoryAdapter_CRUD_And_Counter(t *testing.T) {
	ctx := context.Background()
	store := NewMemoryAdapter()
	defer store.Close()

	doc := sampleDoc{
		ID:           "doc-001",
		PartitionKey: "course-101",
		Title:        "Arquitectura Cloud Native",
		Views:        10,
	}

	// 1. PutItem
	if err := store.PutItem(ctx, "courses", doc.PartitionKey, doc); err != nil {
		t.Fatalf("error al guardar documento: %v", err)
	}

	// 2. GetItem
	var fetched sampleDoc
	if err := store.GetItem(ctx, "courses", doc.PartitionKey, doc.ID, &fetched); err != nil {
		t.Fatalf("error al obtener documento: %v", err)
	}
	if fetched.Title != doc.Title {
		t.Errorf("se esperaba título %s, se obtuvo %s", doc.Title, fetched.Title)
	}

	// 3. UpdateAtomicCounter
	newCount, err := store.UpdateAtomicCounter(ctx, "courses", doc.PartitionKey, doc.ID, "views", 5)
	if err != nil {
		t.Fatalf("error en incremento atómico: %v", err)
	}
	if newCount != 15 {
		t.Errorf("se esperaba contador 15, se obtuvo %d", newCount)
	}

	// 4. QueryByPartition
	var list []sampleDoc
	if err := store.QueryByPartition(ctx, "courses", doc.PartitionKey, &list); err != nil {
		t.Fatalf("error al consultar partición: %v", err)
	}
	if len(list) != 1 {
		t.Fatalf("se esperaba 1 documento en la partición, se obtuvieron %d", len(list))
	}

	// 5. DeleteItem
	if err := store.DeleteItem(ctx, "courses", doc.PartitionKey, doc.ID); err != nil {
		t.Fatalf("error al borrar documento: %v", err)
	}

	// 6. Verificar eliminación
	if err := store.GetItem(ctx, "courses", doc.PartitionKey, doc.ID, &fetched); err != ErrNotFound {
		t.Fatalf("se esperaba ErrNotFound, se obtuvo: %v", err)
	}
}
