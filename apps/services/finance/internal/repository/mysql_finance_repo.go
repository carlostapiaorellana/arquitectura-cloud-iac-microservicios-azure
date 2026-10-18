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

// EnsureSchema inicializa tablas y datos semilla de finance_db de forma idempotente
func (r *MySQLFinanceRepo) EnsureSchema(ctx context.Context) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS payment_concepts (
			id INT AUTO_INCREMENT PRIMARY KEY,
			code VARCHAR(20) NOT NULL UNIQUE,
			name VARCHAR(100) NOT NULL,
			amount DECIMAL(10,2) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS payment_methods (
			id INT AUTO_INCREMENT PRIMARY KEY,
			code VARCHAR(20) NOT NULL UNIQUE,
			name VARCHAR(50) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS payment_statuses (
			id INT AUTO_INCREMENT PRIMARY KEY,
			code VARCHAR(20) NOT NULL UNIQUE,
			name VARCHAR(50) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS payment_orders (
			id INT AUTO_INCREMENT PRIMARY KEY,
			student_id VARCHAR(36) NOT NULL,
			enrollment_id INT NULL,
			concept_id INT NOT NULL,
			status_id INT NOT NULL,
			amount DECIMAL(10,2) NOT NULL,
			due_date DATE NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_orders_student (student_id),
			CONSTRAINT fk_orders_concept FOREIGN KEY (concept_id) REFERENCES payment_concepts(id),
			CONSTRAINT fk_orders_status FOREIGN KEY (status_id) REFERENCES payment_statuses(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS payments (
			id INT AUTO_INCREMENT PRIMARY KEY,
			payment_order_id INT NOT NULL,
			method_id INT NOT NULL,
			amount DECIMAL(10,2) NOT NULL,
			transaction_ref VARCHAR(100) NOT NULL UNIQUE,
			idempotency_key VARCHAR(100) NOT NULL UNIQUE,
			paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT fk_payments_order FOREIGN KEY (payment_order_id) REFERENCES payment_orders(id),
			CONSTRAINT fk_payments_method FOREIGN KEY (method_id) REFERENCES payment_methods(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`INSERT INTO payment_concepts (id, code, name, amount) VALUES
		(1, 'MAT-ORD', 'Matricula Ordinaria', 350.00),
		(2, 'PEN-01', 'Cuota Pension 1', 850.00),
		(3, 'CAR-EST', 'Carne Universitario', 30.00),
		(4, 'CON-EST', 'Constancia de Estudios', 25.00)
		ON DUPLICATE KEY UPDATE name = VALUES(name), amount = VALUES(amount);`,

		`INSERT INTO payment_methods (id, code, name) VALUES
		(1, 'CARD', 'Tarjeta de Credito/Debito'),
		(2, 'TRANSFER', 'Transferencia Bancaria'),
		(3, 'COUNTER', 'Pago en Ventanilla'),
		(4, 'WALLET', 'Billetera Digital')
		ON DUPLICATE KEY UPDATE name = VALUES(name);`,

		`INSERT INTO payment_statuses (id, code, name) VALUES
		(1, 'PENDING', 'Pendiente de Pago'),
		(2, 'PAID', 'Pagado'),
		(3, 'OVERDUE', 'Vencido'),
		(4, 'ANNULLED', 'Anulado')
		ON DUPLICATE KEY UPDATE name = VALUES(name);`,

		`INSERT INTO payment_orders (id, student_id, enrollment_id, concept_id, status_id, amount, due_date) VALUES
		(1, '018f0001-0000-7000-8000-000000000002', 1, 1, 1, 350.00, '2026-04-30'),
		(2, '018f0001-0000-7000-8000-000000000002', 1, 2, 1, 850.00, '2026-05-31')
		ON DUPLICATE KEY UPDATE
			concept_id = VALUES(concept_id),
			status_id = VALUES(status_id),
			amount = VALUES(amount),
			due_date = VALUES(due_date);`,
	}

	for _, q := range queries {
		if _, err := r.db.ExecContext(ctx, q); err != nil {
			return fmt.Errorf("error al ejecutar bootstrap finance schema: %w", err)
		}
	}
	return nil
}
