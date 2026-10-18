package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/universidad/platform/packages/nosql"
	"github.com/universidad/platform/apps/services/lms/internal/models"
)

const (
	CollectionCourses     = "lms_courses"
	CollectionEnrollments = "lms_enrollments"
	PartitionCatalog      = "catalog"
)

var (
	ErrCourseNotFound = errors.New("curso LMS no encontrado")
)

type NoSQLLmsRepo struct {
	store nosql.DocumentStore
}

func NewNoSQLLmsRepo(store nosql.DocumentStore) *NoSQLLmsRepo {
	return &NoSQLLmsRepo{store: store}
}

func (r *NoSQLLmsRepo) PutCourse(ctx context.Context, course models.LmsCourse) error {
	if course.PartitionKey == "" {
		course.PartitionKey = PartitionCatalog
	}
	return r.store.PutItem(ctx, CollectionCourses, course.PartitionKey, course)
}

func (r *NoSQLLmsRepo) GetCourse(ctx context.Context, courseID string) (*models.LmsCourse, error) {
	// Primero intentar por GetItem con clave canónica
	var course models.LmsCourse
	err := r.store.GetItem(ctx, CollectionCourses, PartitionCatalog, courseID, &course)
	if err == nil {
		return &course, nil
	}

	// Si no, buscar en la partición catalog
	all, err := r.GetAllCourses(ctx)
	if err != nil {
		return nil, fmt.Errorf("error al buscar curso: %w", err)
	}
	for _, c := range all {
		if c.ID == courseID || c.CourseCode == courseID {
			return &c, nil
		}
	}

	return nil, ErrCourseNotFound
}

func (r *NoSQLLmsRepo) GetAllCourses(ctx context.Context) ([]models.LmsCourse, error) {
	var courses []models.LmsCourse
	err := r.store.QueryByPartition(ctx, CollectionCourses, PartitionCatalog, &courses)
	if err != nil {
		return nil, fmt.Errorf("error al consultar catálogo de cursos LMS: %w", err)
	}
	if courses == nil {
		courses = []models.LmsCourse{}
	}
	return courses, nil
}

func (r *NoSQLLmsRepo) PutEnrollment(ctx context.Context, enrollment models.LmsEnrollment) error {
	if enrollment.PartitionKey == "" {
		enrollment.PartitionKey = enrollment.StudentID
	}
	return r.store.PutItem(ctx, CollectionEnrollments, enrollment.PartitionKey, enrollment)
}

func (r *NoSQLLmsRepo) GetEnrollmentsByStudentID(ctx context.Context, studentID string) ([]models.LmsEnrollment, error) {
	var enrollments []models.LmsEnrollment
	err := r.store.QueryByPartition(ctx, CollectionEnrollments, studentID, &enrollments)
	if err != nil {
		return nil, fmt.Errorf("error al consultar inscripciones LMS del alumno: %w", err)
	}
	if enrollments == nil {
		enrollments = []models.LmsEnrollment{}
	}
	return enrollments, nil
}

func (r *NoSQLLmsRepo) Ping(ctx context.Context) error {
	return r.store.Ping(ctx)
}
