package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/universidad/platform/apps/services/person/internal/models"
)

var ErrProfileNotFound = errors.New("perfil de persona no encontrado")

type PersonRepository interface {
	FindProfileByAuthUserID(ctx context.Context, authUserID string) (*models.UserProfile, error)
	UpdateContact(ctx context.Context, authUserID string, req models.UpdateContactRequest) error
}

type MySQLPersonRepo struct {
	db *sql.DB
}

func NewMySQLPersonRepo(db *sql.DB) *MySQLPersonRepo {
	return &MySQLPersonRepo{db: db}
}

func (r *MySQLPersonRepo) FindProfileByAuthUserID(ctx context.Context, authUserID string) (*models.UserProfile, error) {
	// 1. Intentar buscar como Estudiante
	studentQuery := `
		SELECT s.id, s.student_code, s.auth_user_id, s.first_name, s.last_name_father, s.last_name_mother,
		       s.birth_date, s.document_number, COALESCE(td.nombre, 'DNI') as doc_type, s.nationality,
		       s.address, COALESCE(s.phone, ''), COALESCE(s.mobile, ''), s.email,
		       COALESCE(d.nombre, '') as district, COALESCE(sx.nombre, '') as gender,
		       COALESCE(ec.nombre, '') as civil_status, s.status, s.updated_at
		FROM students s
		LEFT JOIN tipodocumento td ON s.document_type_id = td.id
		LEFT JOIN distrito d ON s.district_id = d.id
		LEFT JOIN sexo sx ON s.gender_id = sx.id
		LEFT JOIN estadocivil ec ON s.civil_status_id = ec.id
		WHERE s.auth_user_id = ?
		LIMIT 1`

	var p models.UserProfile
	var birthDate sql.NullTime
	err := r.db.QueryRowContext(ctx, studentQuery, authUserID).Scan(
		&p.ID,
		&p.InstitutionalCode,
		&p.AuthUserID,
		&p.FirstName,
		&p.LastNameFather,
		&p.LastNameMother,
		&birthDate,
		&p.DocumentNumber,
		&p.DocumentTypeName,
		&p.Nationality,
		&p.Address,
		&p.Phone,
		&p.Mobile,
		&p.Email,
		&p.DistrictName,
		&p.GenderName,
		&p.CivilStatusName,
		&p.Status,
		&p.UpdatedAt,
	)
	if err == nil {
		p.UserType = "STUDENT"
		p.FullName = fmt.Sprintf("%s %s %s", p.FirstName, p.LastNameFather, p.LastNameMother)
		if birthDate.Valid {
			p.BirthDate = birthDate.Time.Format("2006-01-02")
		}
		return &p, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("error al consultar estudiante: %w", err)
	}

	// 2. Intentar buscar como Docente
	teacherQuery := `
		SELECT t.id, t.teacher_code, t.auth_user_id, t.first_name, t.last_name_father, t.last_name_mother,
		       t.birth_date, t.document_number, COALESCE(td.nombre, 'DNI') as doc_type, t.nationality,
		       t.address, COALESCE(t.phone, ''), COALESCE(t.mobile, ''), t.email, t.salary,
		       COALESCE(d.nombre, '') as district, COALESCE(sx.nombre, '') as gender,
		       COALESCE(ec.nombre, '') as civil_status, t.status, t.updated_at
		FROM teachers t
		LEFT JOIN tipodocumento td ON t.document_type_id = td.id
		LEFT JOIN distrito d ON t.district_id = d.id
		LEFT JOIN sexo sx ON t.gender_id = sx.id
		LEFT JOIN estadocivil ec ON t.civil_status_id = ec.id
		WHERE t.auth_user_id = ?
		LIMIT 1`

	var salary float64
	err = r.db.QueryRowContext(ctx, teacherQuery, authUserID).Scan(
		&p.ID,
		&p.InstitutionalCode,
		&p.AuthUserID,
		&p.FirstName,
		&p.LastNameFather,
		&p.LastNameMother,
		&birthDate,
		&p.DocumentNumber,
		&p.DocumentTypeName,
		&p.Nationality,
		&p.Address,
		&p.Phone,
		&p.Mobile,
		&p.Email,
		&salary,
		&p.DistrictName,
		&p.GenderName,
		&p.CivilStatusName,
		&p.Status,
		&p.UpdatedAt,
	)
	if err == nil {
		p.UserType = "TEACHER"
		p.Salary = &salary
		p.FullName = fmt.Sprintf("%s %s %s", p.FirstName, p.LastNameFather, p.LastNameMother)
		if birthDate.Valid {
			p.BirthDate = birthDate.Time.Format("2006-01-02")
		}
		return &p, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("error al consultar docente: %w", err)
	}

	// 3. Intentar buscar como Empleado Administrativo
	employeeQuery := `
		SELECT e.id, e.employee_code, e.auth_user_id, e.first_name, e.last_name_father, e.last_name_mother,
		       e.birth_date, e.document_number, COALESCE(td.nombre, 'DNI') as doc_type, e.nationality,
		       e.address, COALESCE(e.phone, ''), COALESCE(e.mobile, ''), e.email, e.salary,
		       COALESCE(d.nombre, '') as district, COALESCE(sx.nombre, '') as gender,
		       COALESCE(ec.nombre, '') as civil_status, e.status, e.updated_at
		FROM employees e
		LEFT JOIN tipodocumento td ON e.document_type_id = td.id
		LEFT JOIN distrito d ON e.district_id = d.id
		LEFT JOIN sexo sx ON e.gender_id = sx.id
		LEFT JOIN estadocivil ec ON e.civil_status_id = ec.id
		WHERE e.auth_user_id = ?
		LIMIT 1`

	err = r.db.QueryRowContext(ctx, employeeQuery, authUserID).Scan(
		&p.ID,
		&p.InstitutionalCode,
		&p.AuthUserID,
		&p.FirstName,
		&p.LastNameFather,
		&p.LastNameMother,
		&birthDate,
		&p.DocumentNumber,
		&p.DocumentTypeName,
		&p.Nationality,
		&p.Address,
		&p.Phone,
		&p.Mobile,
		&p.Email,
		&salary,
		&p.DistrictName,
		&p.GenderName,
		&p.CivilStatusName,
		&p.Status,
		&p.UpdatedAt,
	)
	if err == nil {
		p.UserType = "EMPLOYEE"
		p.Salary = &salary
		p.FullName = fmt.Sprintf("%s %s %s", p.FirstName, p.LastNameFather, p.LastNameMother)
		if birthDate.Valid {
			p.BirthDate = birthDate.Time.Format("2006-01-02")
		}
		return &p, nil
	}
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrProfileNotFound
	}

	return nil, fmt.Errorf("error al consultar empleado: %w", err)
}

func (r *MySQLPersonRepo) UpdateContact(ctx context.Context, authUserID string, req models.UpdateContactRequest) error {
	// Intentar actualizar en students
	res, err := r.db.ExecContext(ctx, "UPDATE students SET address = ?, phone = ?, mobile = ? WHERE auth_user_id = ?",
		req.Address, req.Phone, req.Mobile, authUserID)
	if err != nil {
		return fmt.Errorf("error al actualizar estudiante: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows > 0 {
		return nil
	}

	// Intentar actualizar en teachers
	res, err = r.db.ExecContext(ctx, "UPDATE teachers SET address = ?, phone = ?, mobile = ? WHERE auth_user_id = ?",
		req.Address, req.Phone, req.Mobile, authUserID)
	if err != nil {
		return fmt.Errorf("error al actualizar docente: %w", err)
	}
	rows, _ = res.RowsAffected()
	if rows > 0 {
		return nil
	}

	// Intentar actualizar en employees
	res, err = r.db.ExecContext(ctx, "UPDATE employees SET address = ?, phone = ?, mobile = ? WHERE auth_user_id = ?",
		req.Address, req.Phone, req.Mobile, authUserID)
	if err != nil {
		return fmt.Errorf("error al actualizar empleado: %w", err)
	}
	rows, _ = res.RowsAffected()
	if rows > 0 {
		return nil
	}

	return ErrProfileNotFound
}
