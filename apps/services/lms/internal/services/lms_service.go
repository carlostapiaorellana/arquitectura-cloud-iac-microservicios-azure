package services

import (
	"context"
	"errors"
	"log/slog"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/lms/internal/models"
	"github.com/universidad/platform/apps/services/lms/internal/repository"
)

type LmsService struct {
	repo   *repository.NoSQLLmsRepo
	logger *slog.Logger
}

func NewLmsService(repo *repository.NoSQLLmsRepo, logger *slog.Logger) *LmsService {
	return &LmsService{
		repo:   repo,
		logger: logger,
	}
}

func (s *LmsService) GetMyCourses(ctx context.Context, studentID string) ([]models.StudentCourseView, error) {
	if studentID == "" {
		return nil, errorhandling.NewBadRequestError("studentID es requerido", nil)
	}

	enrollments, err := s.repo.GetEnrollmentsByStudentID(ctx, studentID)
	if err != nil {
		s.logger.Error("Error al consultar inscripciones LMS", "studentID", studentID, "error", err)
		return nil, errorhandling.NewInternalError("error al consultar cursos del estudiante", err)
	}

	var results []models.StudentCourseView
	for _, enr := range enrollments {
		view := models.StudentCourseView{
			EnrollmentID:       enr.ID,
			CourseID:           enr.CourseID,
			SectionID:          enr.SectionID,
			CourseCode:         enr.CourseCode,
			Title:              enr.Title,
			Role:               enr.Role,
			ProgressPercentage: enr.ProgressPercentage,
		}

		// Enriquecer con evaluaciones del curso si existe
		course, err := s.repo.GetCourse(ctx, enr.CourseID)
		if err == nil && course != nil {
			view.SyllabusURL = course.SyllabusURL
			view.Evaluations = course.Evaluations
		}

		results = append(results, view)
	}

	if results == nil {
		results = []models.StudentCourseView{}
	}

	return results, nil
}

func (s *LmsService) GetCourseEvaluations(ctx context.Context, courseID string) ([]models.LmsEvaluation, error) {
	if courseID == "" {
		return nil, errorhandling.NewBadRequestError("courseId es requerido", nil)
	}

	course, err := s.repo.GetCourse(ctx, courseID)
	if err != nil {
		if errors.Is(err, repository.ErrCourseNotFound) {
			return nil, errorhandling.NewNotFoundError("curso LMS no encontrado", err)
		}
		s.logger.Error("Error al consultar curso LMS", "courseId", courseID, "error", err)
		return nil, errorhandling.NewInternalError("error al obtener curso LMS", err)
	}

	evals := course.Evaluations
	if evals == nil {
		evals = []models.LmsEvaluation{}
	}

	return evals, nil
}

func (s *LmsService) SeedIfEmpty(ctx context.Context) error {
	courses, err := s.repo.GetAllCourses(ctx)
	if err == nil && len(courses) > 0 {
		s.logger.Info("Colección lms_courses ya inicializada", "count", len(courses))
		return nil
	}

	s.logger.Info("Inicializando catálogo NoSQL semilla para LMS...")

	initialCourses := []models.LmsCourse{
		{
			ID:           "c-001",
			PartitionKey: repository.PartitionCatalog,
			SectionID:   "1",
			CourseCode:  "SIS-101",
			Title:       "Algoritmos y Estructura de Datos",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/sis-101.pdf",
			Evaluations: []models.LmsEvaluation{
				{
					EvaluationID: "eval-1",
					Title:        "Practica Calificada 1",
					Type:         "PRAC",
					Weight:       20,
					DueDate:      "2026-04-15",
				},
				{
					EvaluationID: "eval-2",
					Title:        "Examen Parcial",
					Type:         "EXAM",
					Weight:       40,
					DueDate:      "2026-05-20",
				},
			},
		},
	}

	for _, c := range initialCourses {
		if err := s.repo.PutCourse(ctx, c); err != nil {
			s.logger.Warn("Error sembrando curso LMS", "courseId", c.ID, "error", err)
		}
	}

	// Inscripción semilla para el estudiante demo alu01
	demoStudentID := "018f0001-0000-7000-8000-000000000002"
	initialEnrollment := models.LmsEnrollment{
		ID:                 "lms-enr-001",
		PartitionKey:       demoStudentID,
		StudentID:          demoStudentID,
		CourseID:           "c-001",
		SectionID:          "1",
		CourseCode:         "SIS-101",
		Title:              "Algoritmos y Estructura de Datos",
		Role:               "STUDENT",
		ProgressPercentage: 65.0,
	}

	if err := s.repo.PutEnrollment(ctx, initialEnrollment); err != nil {
		s.logger.Warn("Error sembrando inscripción LMS demo", "enrollmentId", initialEnrollment.ID, "error", err)
	}

	s.logger.Info("Sembrado inicial de LMS completado con éxito")
	return nil
}
