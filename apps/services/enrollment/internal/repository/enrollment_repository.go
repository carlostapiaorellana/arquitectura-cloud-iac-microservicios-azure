package repository

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/universidad/platform/apps/services/enrollment/internal/models"
)

type EnrollmentRepository interface {
	GetEnrollmentsByStudentID(ctx context.Context, studentID string) ([]models.Enrollment, error)
	GetGradesByStudentID(ctx context.Context, studentID string) ([]models.Grade, error)
	CreateEnrollment(ctx context.Context, studentID string, req models.RegisterEnrollmentRequest) (*models.Enrollment, error)
}

type MySQLEnrollmentRepo struct {
	db *sql.DB
}

func NewMySQLEnrollmentRepo(db *sql.DB) *MySQLEnrollmentRepo {
	return &MySQLEnrollmentRepo{db: db}
}

func (r *MySQLEnrollmentRepo) GetEnrollmentsByStudentID(ctx context.Context, studentID string) ([]models.Enrollment, error) {
	query := `
		SELECT id, student_id, academic_period_id, enrollment_status_id, enrollment_type_id, observations, created_at
		FROM enrollments
		WHERE student_id = ?
		ORDER BY id DESC`

	rows, err := r.db.QueryContext(ctx, query, studentID)
	if err != nil {
		return nil, fmt.Errorf("error al consultar matriculas por student_id: %w", err)
	}
	defer rows.Close()

	var enrollments []models.Enrollment
	for rows.Next() {
		var e models.Enrollment
		var statusID, typeID sql.NullInt64
		var obs sql.NullString
		if err := rows.Scan(&e.ID, &e.StudentID, &e.AcademicPeriodID, &statusID, &typeID, &obs, &e.CreatedAt); err != nil {
			return nil, fmt.Errorf("error al escanear matricula: %w", err)
		}
		if statusID.Valid {
			sID := int(statusID.Int64)
			e.EnrollmentStatusID = &sID
		}
		if typeID.Valid {
			tID := int(typeID.Int64)
			e.EnrollmentTypeID = &tID
		}
		if obs.Valid {
			e.Observations = &obs.String
		}
		enrollments = append(enrollments, e)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterando matriculas: %w", err)
	}

	if enrollments == nil {
		return []models.Enrollment{}, nil
	}

	// Cargar detalles de cada matrícula
	for i := range enrollments {
		detailQuery := `SELECT id, enrollment_id, section_id, status, created_at FROM enrollment_details WHERE enrollment_id = ? ORDER BY id ASC`
		dRows, err := r.db.QueryContext(ctx, detailQuery, enrollments[i].ID)
		if err != nil {
			return nil, fmt.Errorf("error al consultar detalles de matricula %d: %w", enrollments[i].ID, err)
		}
		var details []models.EnrollmentDetail
		for dRows.Next() {
			var d models.EnrollmentDetail
			if err := dRows.Scan(&d.ID, &d.EnrollmentID, &d.SectionID, &d.Status, &d.CreatedAt); err != nil {
				dRows.Close()
				return nil, fmt.Errorf("error al escanear detalle de matricula: %w", err)
			}
			details = append(details, d)
		}
		dRows.Close()
		if details == nil {
			details = []models.EnrollmentDetail{}
		}
		enrollments[i].Details = details
	}

	return enrollments, nil
}

func (r *MySQLEnrollmentRepo) GetGradesByStudentID(ctx context.Context, studentID string) ([]models.Grade, error) {
	query := `
		SELECT g.id, g.enrollment_detail_id, ed.section_id, g.grade_type_id, gt.name, g.score, g.graded_at
		FROM grades g
		INNER JOIN enrollment_details ed ON g.enrollment_detail_id = ed.id
		INNER JOIN enrollments e ON ed.enrollment_id = e.id
		INNER JOIN grade_types gt ON g.grade_type_id = gt.id
		WHERE e.student_id = ?
		ORDER BY g.id ASC`

	rows, err := r.db.QueryContext(ctx, query, studentID)
	if err != nil {
		return nil, fmt.Errorf("error al consultar calificaciones: %w", err)
	}
	defer rows.Close()

	var grades []models.Grade
	for rows.Next() {
		var g models.Grade
		if err := rows.Scan(&g.ID, &g.EnrollmentDetailID, &g.SectionID, &g.GradeTypeID, &g.GradeTypeName, &g.Score, &g.GradedAt); err != nil {
			return nil, fmt.Errorf("error al escanear calificacion: %w", err)
		}
		grades = append(grades, g)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterando calificaciones: %w", err)
	}
	if grades == nil {
		grades = []models.Grade{}
	}
	return grades, nil
}

func (r *MySQLEnrollmentRepo) CreateEnrollment(ctx context.Context, studentID string, req models.RegisterEnrollmentRequest) (*models.Enrollment, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("error iniciando transaccion de matricula: %w", err)
	}
	defer tx.Rollback()

	statusID := 2 // ENROLLED
	typeID := req.EnrollmentTypeID
	if typeID == 0 {
		typeID = 1 // REGULAR
	}

	insertEnrollmentSQL := `
		INSERT INTO enrollments (student_id, academic_period_id, enrollment_status_id, enrollment_type_id, observations)
		VALUES (?, ?, ?, ?, ?)`
	res, err := tx.ExecContext(ctx, insertEnrollmentSQL, studentID, req.AcademicPeriodID, statusID, typeID, req.Observations)
	if err != nil {
		return nil, fmt.Errorf("error insertando matricula: %w", err)
	}

	enrollmentID, err := res.LastInsertId()
	if err != nil {
		return nil, fmt.Errorf("error obteniendo id de matricula generada: %w", err)
	}

	var details []models.EnrollmentDetail
	insertDetailSQL := `INSERT INTO enrollment_details (enrollment_id, section_id, status) VALUES (?, ?, 'ENROLLED')`
	for _, secID := range req.SectionIDs {
		dRes, err := tx.ExecContext(ctx, insertDetailSQL, enrollmentID, secID)
		if err != nil {
			return nil, fmt.Errorf("error insertando detalle de seccion %d: %w", secID, err)
		}
		dID, _ := dRes.LastInsertId()
		details = append(details, models.EnrollmentDetail{
			ID:           int(dID),
			EnrollmentID: int(enrollmentID),
			SectionID:    secID,
			Status:       "ENROLLED",
		})
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("error confirmando transaccion de matricula: %w", err)
	}

	return &models.Enrollment{
		ID:                 int(enrollmentID),
		StudentID:          studentID,
		AcademicPeriodID:   req.AcademicPeriodID,
		EnrollmentStatusID: &statusID,
		EnrollmentTypeID:   &typeID,
		Observations:       &req.Observations,
		Details:            details,
	}, nil
}

// EnsureSchema inicializa tablas y datos semilla de enrollment_db de forma idempotente
func (r *MySQLEnrollmentRepo) EnsureSchema(ctx context.Context) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS enrollment_statuses (
			id INT PRIMARY KEY AUTO_INCREMENT,
			name VARCHAR(30) NOT NULL UNIQUE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS enrollment_types (
			id INT PRIMARY KEY AUTO_INCREMENT,
			name VARCHAR(30) NOT NULL UNIQUE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS grade_types (
			id INT PRIMARY KEY AUTO_INCREMENT,
			name VARCHAR(30) NOT NULL UNIQUE,
			weight DECIMAL(3,2) NOT NULL DEFAULT 1.00
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS enrollments (
			id INT AUTO_INCREMENT PRIMARY KEY,
			student_id VARCHAR(36) NOT NULL,
			academic_period_id INT NOT NULL,
			enrollment_status_id INT,
			enrollment_type_id INT,
			observations TEXT,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_enrollments_student (student_id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS enrollment_details (
			id INT AUTO_INCREMENT PRIMARY KEY,
			enrollment_id INT NOT NULL,
			section_id INT NOT NULL,
			status VARCHAR(20) DEFAULT 'ENROLLED',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_enrollment_details_section (section_id),
			CONSTRAINT fk_enrollment_details_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS grades (
			id INT AUTO_INCREMENT PRIMARY KEY,
			enrollment_detail_id INT NOT NULL,
			grade_type_id INT NOT NULL,
			score DECIMAL(5,2) NOT NULL,
			graded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_grades_detail (enrollment_detail_id),
			CONSTRAINT fk_grades_detail FOREIGN KEY (enrollment_detail_id) REFERENCES enrollment_details(id) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`INSERT IGNORE INTO enrollment_statuses (id, name) VALUES
		(1, 'RESERVED'), (2, 'ENROLLED'), (3, 'CANCELLED'), (4, 'COMPLETED');`,

		`INSERT IGNORE INTO enrollment_types (id, name) VALUES
		(1, 'REGULAR'), (2, 'EXTEMPORANEA'), (3, 'DIRIGIDA');`,

		`INSERT IGNORE INTO grade_types (id, name, weight) VALUES
		(1, 'Examen Parcial', 0.30),
		(2, 'Examen Final', 0.40),
		(3, 'Práctica Calificada 1', 0.15),
		(4, 'Práctica Calificada 2', 0.15);`,

		`INSERT IGNORE INTO enrollments (
			id, student_id, academic_period_id, enrollment_status_id, enrollment_type_id, observations, created_at
		) VALUES (
			1, '018f0001-0000-7000-8000-000000000002', 1, 2, 1, 'Matrícula regular periodo 2026-I', '2026-03-01 09:00:00'
		);`,

		`INSERT IGNORE INTO enrollment_details (id, enrollment_id, section_id, status, created_at) VALUES
		(1, 1, 1, 'ENROLLED', '2026-03-01 09:05:00'),
		(2, 1, 2, 'ENROLLED', '2026-03-01 09:05:00');`,

		`INSERT IGNORE INTO grades (id, enrollment_detail_id, grade_type_id, score, graded_at) VALUES
		(1, 1, 1, 16.50, '2026-05-15 10:00:00'),
		(2, 1, 3, 18.00, '2026-04-10 10:00:00'),
		(3, 2, 1, 17.00, '2026-05-16 11:00:00');`,
	}

	for _, q := range queries {
		if _, err := r.db.ExecContext(ctx, q); err != nil {
			return fmt.Errorf("error al ejecutar bootstrap enrollment schema: %w", err)
		}
	}
	return nil
}
