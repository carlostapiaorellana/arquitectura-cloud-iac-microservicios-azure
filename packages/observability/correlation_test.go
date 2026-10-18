package observability

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGenerateULID(t *testing.T) {
	ulid1 := GenerateULID()
	ulid2 := GenerateULID()

	if len(ulid1) != 26 {
		t.Fatalf("se esperaba longitud 26 para ULID, se obtuvo %d (%s)", len(ulid1), ulid1)
	}
	if ulid1 == ulid2 {
		t.Fatalf("dos ULID generados sucesivamente no deberían ser idénticos: %s vs %s", ulid1, ulid2)
	}
}

func TestCorrelationMiddleware(t *testing.T) {
	var capturedCorrID string

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedCorrID = GetCorrelationID(r.Context())
		w.WriteHeader(http.StatusOK)
	})

	middleware := CorrelationMiddleware(handler)

	// Caso 1: Generación automática si no viene cabecera
	req1 := httptest.NewRequest(http.MethodGet, "/health", nil)
	w1 := httptest.NewRecorder()
	middleware.ServeHTTP(w1, req1)

	if capturedCorrID == "" || len(capturedCorrID) != 26 {
		t.Fatalf("se esperaba ULID de 26 caracteres en contexto, se obtuvo: %s", capturedCorrID)
	}
	if w1.Header().Get(HeaderCorrelationID) != capturedCorrID {
		t.Fatalf("se esperaba que la cabecera HTTP de respuesta coincidiera con el contexto")
	}

	// Caso 2: Propagación si ya viene en la petición
	req2 := httptest.NewRequest(http.MethodGet, "/health", nil)
	req2.Header.Set(HeaderCorrelationID, "EXISTING-CORRELATION-ID-12345")
	w2 := httptest.NewRecorder()
	middleware.ServeHTTP(w2, req2)

	if capturedCorrID != "EXISTING-CORRELATION-ID-12345" {
		t.Fatalf("se esperaba propagación del correlation ID recibido, se obtuvo: %s", capturedCorrID)
	}
	if w2.Header().Get(HeaderCorrelationID) != "EXISTING-CORRELATION-ID-12345" {
		t.Fatalf("la cabecera de respuesta no propagó el correlation ID original")
	}
}

func TestWithCorrelationID(t *testing.T) {
	ctx := context.Background()
	ctx = WithCorrelationID(ctx, "CUSTOM-ID-999")

	if id := GetCorrelationID(ctx); id != "CUSTOM-ID-999" {
		t.Fatalf("se esperaba CUSTOM-ID-999, se obtuvo %s", id)
	}
}
