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
