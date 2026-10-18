package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/library/internal/models"
	"github.com/universidad/platform/apps/services/library/internal/services"
)

type LibraryHandler struct {
	svc *services.LibraryService
}

func NewLibraryHandler(svc *services.LibraryService) *LibraryHandler {
	return &LibraryHandler{svc: svc}
}

func (h *LibraryHandler) Live(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"UP","service":"library-service"}`))
}

func (h *LibraryHandler) Ready(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"READY","service":"library-service"}`))
}

func (h *LibraryHandler) GetBooks(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	category := r.URL.Query().Get("category")
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("pageSize"))

	books, err := h.svc.GetBooks(r.Context(), category, page, pageSize)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(books)
}

func (h *LibraryHandler) CreateLoan(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	var req models.CreateLoanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errorhandling.WriteError(w, r, errorhandling.NewBadRequestError("payload JSON de préstamo inválido", err))
		return
	}

	loan, err := h.svc.CreateLoan(r.Context(), userID, req.BookID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(loan)
}

func (h *LibraryHandler) GetMyLoans(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		errorhandling.WriteError(w, r, errorhandling.NewDomainError(http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "método no permitido", nil))
		return
	}

	userID := r.Header.Get(apicontracts.HeaderUserID)
	if userID == "" {
		errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("identidad perimetral ausente: X-User-Id requerido", nil))
		return
	}

	loans, err := h.svc.GetMyLoans(r.Context(), userID)
	if err != nil {
		errorhandling.WriteError(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(loans)
}
