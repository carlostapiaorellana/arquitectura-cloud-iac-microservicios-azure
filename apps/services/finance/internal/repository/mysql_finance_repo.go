package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/universidad/platform/apps/services/finance/internal/models"
)

var (
	ErrOrderNotFound  = errors.New("orden de pago no encontrada")
	ErrMethodNotFound = errors.New("método de pago no encontrado")
)

type MySQLFinanceRepo struct {
	db *sql.DB
}

func NewMySQLFinanceRepo(db *sql.DB) *MySQLFinanceRepo {
	return &MySQLFinanceRepo{db: db}
}

func (r *MySQLFinanceRepo) GetOrdersByStudentID(ctx context.Context, studentID string) ([]models.PaymentOrder, error) {
	query := `
		SELECT 
			o.id, o.student_id, o.enrollment_id, o.concept_id, 
			c.code, c.name,
			o.status_id, s.code, s.name,
			o.amount, o.due_date, o.created_at
		FROM payment_orders o
		INNER JOIN payment_concepts c ON o.concept_id = c.id
		INNER JOIN payment_statuses s ON o.status_id = s.id
		WHERE o.student_id = ?
		ORDER BY o.id ASC`

	rows, err := r.db.QueryContext(ctx, query, studentID)
	if err != nil {
		return nil, fmt.Errorf("error al consultar órdenes de pago: %w", err)
	}
	defer rows.Close()

	var orders []models.PaymentOrder
	for rows.Next() {
		var o models.PaymentOrder
		var enrollmentID sql.NullInt64
		var dueDate sql.NullString

		err := rows.Scan(
			&o.ID, &o.StudentID, &enrollmentID, &o.ConceptID,
			&o.ConceptCode, &o.ConceptName,
			&o.StatusID, &o.StatusCode, &o.StatusName,
			&o.Amount, &dueDate, &o.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("error al escanear orden de pago: %w", err)
		}

		if enrollmentID.Valid {
			val := int(enrollmentID.Int64)
			o.EnrollmentID = &val
		}
		if dueDate.Valid {
			o.DueDate = &dueDate.String
		}

		orders = append(orders, o)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterando órdenes de pago: %w", err)
	}

	return orders, nil
}

func (r *MySQLFinanceRepo) GetOrderByID(ctx context.Context, orderID int) (*models.PaymentOrder, error) {
	query := `
		SELECT 
			o.id, o.student_id, o.enrollment_id, o.concept_id, 
			c.code, c.name,
			o.status_id, s.code, s.name,
			o.amount, o.due_date, o.created_at
		FROM payment_orders o
		INNER JOIN payment_concepts c ON o.concept_id = c.id
		INNER JOIN payment_statuses s ON o.status_id = s.id
		WHERE o.id = ?`

	row := r.db.QueryRowContext(ctx, query, orderID)

	var o models.PaymentOrder
	var enrollmentID sql.NullInt64
	var dueDate sql.NullString

	err := row.Scan(
		&o.ID, &o.StudentID, &enrollmentID, &o.ConceptID,
		&o.ConceptCode, &o.ConceptName,
		&o.StatusID, &o.StatusCode, &o.StatusName,
		&o.Amount, &dueDate, &o.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrOrderNotFound
		}
		return nil, fmt.Errorf("error al consultar orden por ID: %w", err)
	}

	if enrollmentID.Valid {
		val := int(enrollmentID.Int64)
		o.EnrollmentID = &val
	}
	if dueDate.Valid {
		o.DueDate = &dueDate.String
	}

	return &o, nil
}

func (r *MySQLFinanceRepo) GetMethodByCode(ctx context.Context, code string) (*models.PaymentMethod, error) {
	query := `SELECT id, code, name, created_at FROM payment_methods WHERE code = ?`
	row := r.db.QueryRowContext(ctx, query, code)

	var m models.PaymentMethod
	err := row.Scan(&m.ID, &m.Code, &m.Name, &m.CreatedAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrMethodNotFound
		}
		return nil, fmt.Errorf("error al consultar método de pago: %w", err)
	}
	return &m, nil
}

func (r *MySQLFinanceRepo) CreatePaymentTx(ctx context.Context, payment *models.Payment, newStatusID int) error {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return fmt.Errorf("error al iniciar transacción de pago: %w", err)
	}
	defer func() {
		_ = tx.Rollback()
	}()

	// 1. Insertar pago
	insertQuery := `
		INSERT INTO payments (payment_order_id, method_id, amount, transaction_ref, idempotency_key)
		VALUES (?, ?, ?, ?, ?)`
	res, err := tx.ExecContext(ctx, insertQuery,
		payment.PaymentOrderID,
		payment.MethodID,
		payment.Amount,
		payment.TransactionRef,
		payment.IdempotencyKey,
	)
	if err != nil {
		return fmt.Errorf("error al registrar pago: %w", err)
	}

	lastID, err := res.LastInsertId()
	if err != nil {
		return fmt.Errorf("error obteniendo ID de pago: %w", err)
	}
	payment.ID = int(lastID)

	// 2. Actualizar estado de orden
	updateQuery := `UPDATE payment_orders SET status_id = ? WHERE id = ?`
	_, err = tx.ExecContext(ctx, updateQuery, newStatusID, payment.PaymentOrderID)
	if err != nil {
		return fmt.Errorf("error al actualizar estado de orden de pago: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("error al confirmar transacción de pago: %w", err)
	}

	return nil
}
