package errorhandling

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWriteError_DomainError(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set(HeaderCorrelationID, "01ARZ3NDEKTSV4RRFFQ69G5FAV")
	w := httptest.NewRecorder()

	domErr := NewNotFoundError("estudiante no encontrado", nil)
	WriteError(w, req, domErr)

	if w.Code != http.StatusNotFound {
		t.Fatalf("se esperaba status 404, se obtuvo %d", w.Code)
	}

	var env ErrorEnvelope
	if err := json.Unmarshal(w.Body.Bytes(), &env); err != nil {
		t.Fatalf("error al deserializar json: %v", err)
	}

	if env.Error.Code != CodeResourceNotFound {
		t.Errorf("se esperaba código %s, se obtuvo %s", CodeResourceNotFound, env.Error.Code)
	}
	if env.Error.CorrelationID != "01ARZ3NDEKTSV4RRFFQ69G5FAV" {
		t.Errorf("se esperaba correlationId propagado, se obtuvo %s", env.Error.CorrelationID)
	}
}

func TestWriteError_GenericError_DoesNotLeakStackTrace(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	w := httptest.NewRecorder()

	secretErr := errors.New("sql: syntax error at or near 'SELECT * FROM secret_passwords'")
	WriteError(w, req, secretErr)

	if w.Code != http.StatusInternalServerError {
		t.Fatalf("se esperaba status 500, se obtuvo %d", w.Code)
	}

	var env ErrorEnvelope
	if err := json.Unmarshal(w.Body.Bytes(), &env); err != nil {
		t.Fatalf("error al deserializar json: %v", err)
	}

	if env.Error.Code != CodeInternalError {
		t.Errorf("se esperaba código %s, se obtuvo %s", CodeInternalError, env.Error.Code)
	}
	if env.Error.Message != "ha ocurrido un error interno en el servicio" {
		t.Errorf("el mensaje interno no fue sanitizado: %s", env.Error.Message)
	}
}
