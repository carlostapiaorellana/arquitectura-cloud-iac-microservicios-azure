package repository

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/universidad/platform/apps/services/academic/internal/models"
)

type AcademicRepository interface {
	ListPrograms(ctx context.Context) ([]models.Program, error)
	ListCourses(ctx context.Context) ([]models.Course, error)
	ListSections(ctx context.Context) ([]models.Section, error)
}

type MySQLAcademicRepo struct {
	db *sql.DB
}

func NewMySQLAcademicRepo(db *sql.DB) *MySQLAcademicRepo {
	return &MySQLAcademicRepo{db: db}
}

func (r *MySQLAcademicRepo) ListPrograms(ctx context.Context) ([]models.Program, error) {
	query := `SELECT id, faculty_id, code, name, degree, created_at FROM programs ORDER BY id ASC`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("error al consultar programas: %w", err)
	}
	defer rows.Close()

	var programs []models.Program
	for rows.Next() {
		var p models.Program
		if err := rows.Scan(&p.ID, &p.FacultyID, &p.Code, &p.Name, &p.Degree, &p.CreatedAt); err != nil {
			return nil, fmt.Errorf("error al escanear programa: %w", err)
		}
		programs = append(programs, p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterando programas: %w", err)
	}
	if programs == nil {
		programs = []models.Program{}
	}
	return programs, nil
}

func (r *MySQLAcademicRepo) ListCourses(ctx context.Context) ([]models.Course, error) {
	query := `SELECT id, program_id, sercur, nomcur, crecur, COALESCE(blocur, ''), created_at FROM courses ORDER BY id ASC`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("error al consultar cursos: %w", err)
	}
	defer rows.Close()

	var courses []models.Course
	for rows.Next() {
		var c models.Course
		if err := rows.Scan(&c.ID, &c.ProgramID, &c.Sercur, &c.Nomcur, &c.Crecur, &c.Blocur, &c.CreatedAt); err != nil {
			return nil, fmt.Errorf("error al escanear curso: %w", err)
		}
		courses = append(courses, c)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterando cursos: %w", err)
	}
	if courses == nil {
		courses = []models.Course{}
	}
	return courses, nil
}

func (r *MySQLAcademicRepo) ListSections(ctx context.Context) ([]models.Section, error) {
	query := `SELECT id, course_id, academic_period_id, code, teacher_id, capacity, enrolled, created_at FROM sections ORDER BY id ASC`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("error al consultar secciones: %w", err)
	}
	defer rows.Close()

	var sections []models.Section
	for rows.Next() {
		var s models.Section
		var teacherID sql.NullString
		if err := rows.Scan(&s.ID, &s.CourseID, &s.AcademicPeriodID, &s.Code, &teacherID, &s.Capacity, &s.Enrolled, &s.CreatedAt); err != nil {
			return nil, fmt.Errorf("error al escanear seccion: %w", err)
		}
		if teacherID.Valid {
			s.TeacherID = &teacherID.String
		}
		sections = append(sections, s)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterando secciones: %w", err)
	}
	if sections == nil {
		sections = []models.Section{}
	}
	return sections, nil
}

// EnsureSchema inicializa tablas y datos semilla de academic_db de forma idempotente
func (r *MySQLAcademicRepo) EnsureSchema(ctx context.Context) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS faculties (
			id INT PRIMARY KEY AUTO_INCREMENT,
			code VARCHAR(20) NOT NULL UNIQUE,
			name VARCHAR(100) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS academic_periods (
			id INT PRIMARY KEY AUTO_INCREMENT,
			name VARCHAR(20) NOT NULL UNIQUE,
			start_date DATE NOT NULL,
			end_date DATE NOT NULL,
			is_active BOOLEAN NOT NULL DEFAULT TRUE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS programs (
			id INT PRIMARY KEY AUTO_INCREMENT,
			faculty_id INT NOT NULL,
			code VARCHAR(20) NOT NULL UNIQUE,
			name VARCHAR(100) NOT NULL,
			degree VARCHAR(100) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT fk_programs_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS courses (
			id INT PRIMARY KEY AUTO_INCREMENT,
			program_id INT NOT NULL,
			sercur VARCHAR(20) NOT NULL UNIQUE,
			nomcur VARCHAR(100) NOT NULL,
			crecur INT NOT NULL,
			blocur VARCHAR(20) NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT fk_courses_program FOREIGN KEY (program_id) REFERENCES programs(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS sections (
			id INT PRIMARY KEY AUTO_INCREMENT,
			course_id INT NOT NULL,
			academic_period_id INT NOT NULL,
			code VARCHAR(20) NOT NULL,
			teacher_id VARCHAR(36) NULL,
			capacity INT NOT NULL DEFAULT 40,
			enrolled INT NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_sections_teacher (teacher_id),
			CONSTRAINT uq_section_course_period UNIQUE (course_id, academic_period_id, code),
			CONSTRAINT fk_sections_course FOREIGN KEY (course_id) REFERENCES courses(id),
			CONSTRAINT fk_sections_period FOREIGN KEY (academic_period_id) REFERENCES academic_periods(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`INSERT IGNORE INTO faculties (id, code, name) VALUES
		(1, 'FIA', 'Facultad de Ingeniería y Arquitectura'),
		(2, 'FCE', 'Facultad de Ciencias Económicas y Empresariales');`,

		`INSERT IGNORE INTO academic_periods (id, name, start_date, end_date, is_active) VALUES
		(1, '2026-I', '2026-03-01', '2026-07-31', 1),
		(2, '2026-II', '2026-08-15', '2026-12-20', 0);`,

		`INSERT IGNORE INTO programs (id, faculty_id, code, name, degree) VALUES
		(1, 1, 'ING-SIS', 'Ingeniería de Sistemas', 'Bachiller en Ingeniería de Sistemas'),
		(2, 1, 'ING-IND', 'Ingeniería Industrial', 'Bachiller en Ingeniería Industrial');`,

		`INSERT IGNORE INTO courses (id, program_id, sercur, nomcur, crecur, blocur) VALUES
		(1, 1, 'SIS-101', 'Algoritmos y Estructura de Datos', 4, 'B1'),
		(2, 1, 'SIS-102', 'Bases de Datos Relacionales y NoSQL', 4, 'B1'),
		(3, 1, 'SIS-103', 'Arquitectura de Computadoras y Sistemas Operativos', 3, 'B2'),
		(4, 1, 'SIS-104', 'Ingeniería de Software y DevOps', 4, 'B2'),
		(5, 1, 'MAT-101', 'Cálculo Multivariable', 4, 'B1');`,

		`INSERT IGNORE INTO sections (id, course_id, academic_period_id, code, teacher_id, capacity, enrolled) VALUES
		(1, 1, 1, 'SEC-01', '018f0001-0000-7000-8000-000000000003', 35, 1),
		(2, 2, 1, 'SEC-01', '018f0001-0000-7000-8000-000000000003', 35, 1),
		(3, 3, 1, 'SEC-01', '018f0001-0000-7000-8000-000000000003', 30, 0);`,
	}

	for _, q := range queries {
		if _, err := r.db.ExecContext(ctx, q); err != nil {
			return fmt.Errorf("error al ejecutar bootstrap academic schema: %w", err)
		}
	}
	return nil
}
