package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/universidad/platform/packages/nosql"
	"github.com/universidad/platform/apps/services/library/internal/models"
)

const (
	CollectionBooks = "library_books"
	CollectionLoans = "library_loans"
	PartitionBooks  = "catalog"
)

var (
	ErrBookNotFound = errors.New("libro no encontrado")
)

type NoSQLLibraryRepo struct {
	store nosql.DocumentStore
}

func NewNoSQLLibraryRepo(store nosql.DocumentStore) *NoSQLLibraryRepo {
	return &NoSQLLibraryRepo{store: store}
}

func (r *NoSQLLibraryRepo) PutBook(ctx context.Context, book models.Book) error {
	if book.PartitionKey == "" {
		book.PartitionKey = PartitionBooks
	}
	return r.store.PutItem(ctx, CollectionBooks, book.PartitionKey, book)
}

func (r *NoSQLLibraryRepo) GetBook(ctx context.Context, id string) (*models.Book, error) {
	var book models.Book
	err := r.store.GetItem(ctx, CollectionBooks, PartitionBooks, id, &book)
	if err != nil {
		if errors.Is(err, nosql.ErrNotFound) {
			return nil, ErrBookNotFound
		}
		return nil, fmt.Errorf("error al obtener libro: %w", err)
	}
	return &book, nil
}

func (r *NoSQLLibraryRepo) GetAllBooks(ctx context.Context) ([]models.Book, error) {
	var books []models.Book
	err := r.store.QueryByPartition(ctx, CollectionBooks, PartitionBooks, &books)
	if err != nil {
		return nil, fmt.Errorf("error al consultar libros: %w", err)
	}
	if books == nil {
		books = []models.Book{}
	}
	return books, nil
}

func (r *NoSQLLibraryRepo) PutLoan(ctx context.Context, loan models.Loan) error {
	if loan.PartitionKey == "" {
		loan.PartitionKey = loan.StudentID
	}
	return r.store.PutItem(ctx, CollectionLoans, loan.PartitionKey, loan)
}

func (r *NoSQLLibraryRepo) GetLoansByStudentID(ctx context.Context, studentID string) ([]models.Loan, error) {
	var loans []models.Loan
	err := r.store.QueryByPartition(ctx, CollectionLoans, studentID, &loans)
	if err != nil {
		return nil, fmt.Errorf("error al consultar préstamos del alumno: %w", err)
	}
	if loans == nil {
		loans = []models.Loan{}
	}
	return loans, nil
}

func (r *NoSQLLibraryRepo) Ping(ctx context.Context) error {
	return r.store.Ping(ctx)
}
