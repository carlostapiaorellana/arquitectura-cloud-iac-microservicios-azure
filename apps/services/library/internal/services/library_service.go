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
			ISBN:            "9780134685991",
			Title:           "Effective Java",
			Author:          "Joshua Bloch",
			Category:        "Informatica",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-002",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9780132350884",
			Title:           "Clean Code",
			Author:          "Robert C. Martin",
			Category:        "Informatica",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-003",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9786071503145",
			Title:           "Fundamentos de Bases de Datos",
			Author:          "Silberschatz, Korth y Sudarshan",
			Category:        "Informatica",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-004",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9788426728210",
			Title:           "SQL",
			Author:          "Varios autores",
			Category:        "Informatica",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-005",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9780133594140",
			Title:           "Computer Networks",
			Author:          "Andrew S. Tanenbaum",
			Category:        "Informatica",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-006",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9786071513830",
			Title:           "Administración",
			Author:          "Stephen Robbins",
			Category:        "Ciencias Empresariales",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-007",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9788499647351",
			Title:           "Ingeniería del Software",
			Author:          "Ian Sommerville",
			Category:        "Informatica",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
		{
			ID:              "b-008",
			PartitionKey:    repository.PartitionBooks,
			ISBN:            "9786075224565",
			Title:           "Tecnología Educativa",
			Author:          "Varios autores",
			Category:        "Educación",
			AvailableCopies: 2,
			TotalCopies:     2,
		},
	}

	for _, b := range initialBooks {
		if err := s.repo.PutBook(ctx, b); err != nil {
			s.logger.Warn("Error sembrando libro", "bookId", b.ID, "error", err)
		}
	}

	// 6 Préstamos semilla Dataset v2
	initialLoans := []models.Loan{
		{
			ID:           "loan-001",
			PartitionKey: "018f0001-0000-7000-8000-000000000002",
			StudentID:    "018f0001-0000-7000-8000-000000000002",
			BookID:       "b-001",
			BookTitle:    "Effective Java",
			LoanDate:     "2026-04-01",
			DueDate:      "2026-04-08",
			Status:       "RETURNED",
		},
		{
			ID:           "loan-002",
			PartitionKey: "018f0001-0000-7000-8000-000000000012",
			StudentID:    "018f0001-0000-7000-8000-000000000012",
			BookID:       "b-002",
			BookTitle:    "Clean Code",
			LoanDate:     "2026-04-03",
			DueDate:      "2026-04-10",
			Status:       "RETURNED",
		},
		{
			ID:           "loan-003",
			PartitionKey: "018f0001-0000-7000-8000-000000000013",
			StudentID:    "018f0001-0000-7000-8000-000000000013",
			BookID:       "b-003",
			BookTitle:    "Fundamentos de Bases de Datos",
			LoanDate:     "2026-05-01",
			DueDate:      "2026-05-15",
			Status:       "ACTIVE",
		},
		{
			ID:           "loan-004",
			PartitionKey: "018f0001-0000-7000-8000-000000000014",
			StudentID:    "018f0001-0000-7000-8000-000000000014",
			BookID:       "b-004",
			BookTitle:    "SQL",
			LoanDate:     "2026-05-02",
			DueDate:      "2026-05-16",
			Status:       "ACTIVE",
		},
		{
			ID:           "loan-005",
			PartitionKey: "018f0001-0000-7000-8000-000000000015",
			StudentID:    "018f0001-0000-7000-8000-000000000015",
			BookID:       "b-005",
			BookTitle:    "Computer Networks",
			LoanDate:     "2026-05-03",
			DueDate:      "2026-05-12",
			Status:       "RETURNED",
		},
		{
			ID:           "loan-006",
			PartitionKey: "018f0001-0000-7000-8000-000000000016",
			StudentID:    "018f0001-0000-7000-8000-000000000016",
			BookID:       "b-006",
			BookTitle:    "Administración",
			LoanDate:     "2026-05-05",
			DueDate:      "2026-05-19",
			Status:       "OVERDUE",
		},
	}

	for _, l := range initialLoans {
		if err := s.repo.PutLoan(ctx, l); err != nil {
			s.logger.Warn("Error sembrando préstamo demo", "loanId", l.ID, "error", err)
		}
	}

	s.logger.Info("Sembrado inicial de library v2 completado con éxito")
	return nil
}
