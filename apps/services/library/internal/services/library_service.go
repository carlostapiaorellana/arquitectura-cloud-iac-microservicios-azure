package services

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/library/internal/models"
	"github.com/universidad/platform/apps/services/library/internal/repository"
)

type LibraryService struct {
	repo   *repository.NoSQLLibraryRepo
	logger *slog.Logger
}

func NewLibraryService(repo *repository.NoSQLLibraryRepo, logger *slog.Logger) *LibraryService {
	return &LibraryService{
		repo:   repo,
		logger: logger,
	}
}

func (s *LibraryService) GetBooks(ctx context.Context, category string, page, pageSize int) ([]models.Book, error) {
	books, err := s.repo.GetAllBooks(ctx)
	if err != nil {
		s.logger.Error("Error al consultar libros NoSQL", "error", err)
		return nil, errorhandling.NewInternalError("error al consultar catálogo de libros", err)
	}

	// Filtrado por categoría si se especifica
	var filtered []models.Book
	for _, b := range books {
		if category != "" && !strings.EqualFold(b.Category, category) {
			continue
		}
		filtered = append(filtered, b)
	}

	if filtered == nil {
		filtered = []models.Book{}
	}

	// Paginación en memoria si aplica
	if pageSize <= 0 {
		pageSize = 20
	}
	if page <= 0 {
		page = 1
	}

	start := (page - 1) * pageSize
	if start >= len(filtered) {
		return []models.Book{}, nil
	}
	end := start + pageSize
	if end > len(filtered) {
		end = len(filtered)
	}

	return filtered[start:end], nil
}

func (s *LibraryService) CreateLoan(ctx context.Context, studentID, bookID string) (*models.Loan, error) {
	if studentID == "" {
		return nil, errorhandling.NewBadRequestError("studentID es requerido", nil)
	}
	if bookID == "" {
		return nil, errorhandling.NewBadRequestError("bookId es requerido", nil)
	}

	book, err := s.repo.GetBook(ctx, bookID)
	if err != nil {
		return nil, errorhandling.NewNotFoundError("libro no encontrado", err)
	}

	if book.AvailableCopies <= 0 {
		return nil, errorhandling.NewConflictError("no hay copias disponibles para este libro", nil)
	}

	// Decrementar copias
	book.AvailableCopies--
	_ = s.repo.PutBook(ctx, *book)

	now := time.Now().UTC()
	dueDate := now.Add(14 * 24 * time.Hour)

	loan := models.Loan{
		ID:           fmt.Sprintf("loan-%s", uuid.New().String()[:8]),
		PartitionKey: studentID,
		StudentID:    studentID,
		BookID:       book.ID,
		BookTitle:    book.Title,
		LoanDate:     now.Format("2006-01-02"),
		DueDate:      dueDate.Format("2006-01-02"),
		Status:       "ACTIVE",
	}

	if err := s.repo.PutLoan(ctx, loan); err != nil {
		s.logger.Error("Error al registrar préstamo", "error", err)
		return nil, errorhandling.NewInternalError("error al guardar préstamo", err)
	}

	return &loan, nil
}

func (s *LibraryService) GetMyLoans(ctx context.Context, studentID string) ([]models.Loan, error) {
	if studentID == "" {
		return nil, errorhandling.NewBadRequestError("studentID es requerido", nil)
	}

	loans, err := s.repo.GetLoansByStudentID(ctx, studentID)
	if err != nil {
		s.logger.Error("Error al consultar préstamos del estudiante", "studentID", studentID, "error", err)
		return nil, errorhandling.NewInternalError("error al consultar préstamos", err)
	}

	if loans == nil {
		loans = []models.Loan{}
	}

	return loans, nil
}

func (s *LibraryService) SeedBooksIfEmpty(ctx context.Context) error {
	books, err := s.repo.GetAllBooks(ctx)
	if err == nil && len(books) > 0 {
		s.logger.Info("Colección library_books ya inicializada", "count", len(books))
		return nil
	}

	s.logger.Info("Inicializando catálogo NoSQL semilla para library...")

	initialBooks := []models.Book{
		{
			ID:              "b-001",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "978-0134190440",
			Title:           "The Go Programming Language",
			Author:          "Alan Donovan & Brian Kernighan",
			Category:        "Informatica",
			AvailableCopies: 5,
			TotalCopies:     5,
		},
		{
			ID:              "b-002",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "978-0132350884",
			Title:           "Clean Code",
			Author:          "Robert C. Martin",
			Category:        "Informatica",
			AvailableCopies: 3,
			TotalCopies:     3,
		},
		{
			ID:              "b-003",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "978-0596007126",
			Title:           "Head First Design Patterns",
			Author:          "Eric Freeman",
			Category:        "Informatica",
			AvailableCopies: 4,
			TotalCopies:     4,
		},
	}

	for _, b := range initialBooks {
		if err := s.repo.PutBook(ctx, b); err != nil {
			s.logger.Warn("Error sembrando libro", "bookId", b.ID, "error", err)
		}
	}

	// Préstamo semilla para alu01
	demoStudentID := "018f0001-0000-7000-8000-000000000002"
	initialLoan := models.Loan{
		ID:           "loan-001",
		PartitionKey: demoStudentID,
		StudentID:    demoStudentID,
		BookID:       "b-001",
		BookTitle:    "The Go Programming Language",
		LoanDate:     "2026-10-10",
		DueDate:      "2026-10-24",
		Status:       "ACTIVE",
	}

	if err := s.repo.PutLoan(ctx, initialLoan); err != nil {
		s.logger.Warn("Error sembrando préstamo demo", "loanId", initialLoan.ID, "error", err)
	}

	s.logger.Info("Sembrado inicial de library completado con éxito")
	return nil
}
