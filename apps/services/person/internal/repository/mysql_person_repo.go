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

// EnsureSchema inicializa tablas y datos semilla de person_db de forma idempotente
func (r *MySQLPersonRepo) EnsureSchema(ctx context.Context) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS tipodocumento (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(30) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS sexo (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(30) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS distrito (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(50) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS estadocivil (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(50) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS gradoinstruccion (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(50) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS areaempleo (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(50) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS cargo (
			id INT PRIMARY KEY AUTO_INCREMENT,
			nombre VARCHAR(50) NOT NULL UNIQUE,
			estado BIT NOT NULL DEFAULT 1
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS students (
			id VARCHAR(36) PRIMARY KEY,
			student_code VARCHAR(20) NOT NULL UNIQUE,
			auth_user_id VARCHAR(36) NOT NULL UNIQUE,
			first_name VARCHAR(50) NOT NULL,
			last_name_father VARCHAR(40) NOT NULL,
			last_name_mother VARCHAR(40) NOT NULL,
			birth_date DATE NOT NULL,
			document_number VARCHAR(20) NOT NULL UNIQUE,
			nationality VARCHAR(20) NOT NULL DEFAULT 'Peruana',
			address TEXT NOT NULL,
			phone VARCHAR(15) NULL,
			mobile VARCHAR(15) NULL,
			email VARCHAR(100) NOT NULL UNIQUE,
			status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
			district_id INT NOT NULL,
			gender_id INT NOT NULL,
			document_type_id INT NOT NULL,
			civil_status_id INT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_students_auth_user (auth_user_id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS teachers (
			id VARCHAR(36) PRIMARY KEY,
			teacher_code VARCHAR(20) NOT NULL UNIQUE,
			auth_user_id VARCHAR(36) NOT NULL UNIQUE,
			first_name VARCHAR(50) NOT NULL,
			last_name_father VARCHAR(40) NOT NULL,
			last_name_mother VARCHAR(40) NOT NULL,
			birth_date DATE NOT NULL,
			document_number VARCHAR(20) NOT NULL UNIQUE,
			nationality VARCHAR(20) NOT NULL DEFAULT 'Peruana',
			address TEXT NOT NULL,
			phone VARCHAR(15) NULL,
			mobile VARCHAR(15) NOT NULL,
			email VARCHAR(100) NOT NULL UNIQUE,
			salary DECIMAL(10,2) NOT NULL DEFAULT 0.00,
			status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
			district_id INT NOT NULL,
			gender_id INT NOT NULL,
			document_type_id INT NOT NULL,
			civil_status_id INT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_teachers_auth_user (auth_user_id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS employees (
			id VARCHAR(36) PRIMARY KEY,
			employee_code VARCHAR(20) NOT NULL UNIQUE,
			auth_user_id VARCHAR(36) NOT NULL UNIQUE,
			first_name VARCHAR(50) NOT NULL,
			last_name_father VARCHAR(40) NOT NULL,
			last_name_mother VARCHAR(40) NOT NULL,
			birth_date DATE NOT NULL,
			document_number VARCHAR(20) NOT NULL UNIQUE,
			nationality VARCHAR(20) NOT NULL DEFAULT 'Peruana',
			address TEXT NOT NULL,
			phone VARCHAR(15) NULL,
			mobile VARCHAR(15) NOT NULL,
			email VARCHAR(100) NOT NULL UNIQUE,
			salary DECIMAL(10,2) NOT NULL DEFAULT 0.00,
			status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
			area_id INT NOT NULL,
			position_id INT NOT NULL,
			district_id INT NOT NULL,
			gender_id INT NOT NULL,
			document_type_id INT NOT NULL,
			civil_status_id INT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_employees_auth_user (auth_user_id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`INSERT IGNORE INTO tipodocumento (id, nombre, estado) VALUES
		(1, 'DNI', 1), (2, 'Pasaporte', 1), (3, 'Carnet Extranjería', 1);`,

		`INSERT IGNORE INTO sexo (id, nombre, estado) VALUES
		(1, 'Masculino', 1), (2, 'Femenino', 1);`,

		`INSERT IGNORE INTO estadocivil (id, nombre, estado) VALUES
		(1, 'Soltero(a)', 1), (2, 'Casado(a)', 1);`,

		`INSERT IGNORE INTO distrito (id, nombre, estado) VALUES
		(1, 'Lima', 1), (12, 'Jesús María', 1), (15, 'Lima Cercado', 1), (17, 'Los Olivos', 1),
		(21, 'Miraflores', 1), (31, 'San Isidro', 1), (32, 'San Juan de Lurigancho', 1);`,

		`INSERT INTO students (
			id, student_code, auth_user_id, first_name, last_name_father, last_name_mother,
			birth_date, document_number, nationality, address, phone, mobile,
			email, status, district_id, gender_id, document_type_id, civil_status_id
		) VALUES (
			'018f0001-0000-7000-9000-000000000002', 'ALU-2026-0001', '018f0001-0000-7000-8000-000000000002',
			'Juan Carlos', 'Ramirez', 'Lopez', '2005-03-15', '78000001', 'Peruana',
			'Av. Los Próceres 123 - San Juan de Lurigancho', '014500001', '900100001',
			'estudiante1@universidad.edu.pe', 'ACTIVE', 32, 1, 1, 1
		) ON DUPLICATE KEY UPDATE
			first_name = VALUES(first_name), last_name_father = VALUES(last_name_father),
			last_name_mother = VALUES(last_name_mother), status = VALUES(status);`,
	}

	for _, q := range queries {
		if _, err := r.db.ExecContext(ctx, q); err != nil {
			return fmt.Errorf("error al ejecutar bootstrap person schema: %w", err)
		}
	}
	return nil
}
