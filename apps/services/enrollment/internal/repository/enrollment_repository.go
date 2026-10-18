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
