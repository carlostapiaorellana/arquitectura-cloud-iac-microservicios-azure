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
			ID: "c-001", PartitionKey: repository.PartitionCatalog, SectionID: "1", CourseCode: "IS101", Title: "Fundamentos de Programación",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/is-101.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-1", Title: "Evaluación 1", Type: "PRAC", Weight: 20, DueDate: "2026-06-06"}},
		},
		{
			ID: "c-002", PartitionKey: repository.PartitionCatalog, SectionID: "2", CourseCode: "IS102", Title: "Base de Datos I",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/is-102.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-2", Title: "Evaluación 2", Type: "PRAC", Weight: 20, DueDate: "2026-06-07"}},
		},
		{
			ID: "c-003", PartitionKey: repository.PartitionCatalog, SectionID: "3", CourseCode: "IS103", Title: "Arquitectura de Computadoras",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/is-103.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-3", Title: "Evaluación 3", Type: "PRAC", Weight: 20, DueDate: "2026-06-08"}},
		},
		{
			ID: "c-004", PartitionKey: repository.PartitionCatalog, SectionID: "4", CourseCode: "IS104", Title: "Redes de Computadoras",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/is-104.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-4", Title: "Evaluación 4", Type: "PRAC", Weight: 20, DueDate: "2026-06-09"}},
		},
		{
			ID: "c-005", PartitionKey: repository.PartitionCatalog, SectionID: "5", CourseCode: "SW101", Title: "Ingeniería de Software I",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/sw-101.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-5", Title: "Evaluación 5", Type: "PRAC", Weight: 20, DueDate: "2026-06-10"}},
		},
		{
			ID: "c-006", PartitionKey: repository.PartitionCatalog, SectionID: "6", CourseCode: "SW102", Title: "Desarrollo Web",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/sw-102.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-6", Title: "Evaluación 6", Type: "PRAC", Weight: 20, DueDate: "2026-06-11"}},
		},
		{
			ID: "c-007", PartitionKey: repository.PartitionCatalog, SectionID: "7", CourseCode: "AD101", Title: "Fundamentos de Administración",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/ad-101.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-7", Title: "Evaluación 7", Type: "PRAC", Weight: 20, DueDate: "2026-06-12"}},
		},
		{
			ID: "c-008", PartitionKey: repository.PartitionCatalog, SectionID: "8", CourseCode: "AD102", Title: "Contabilidad General",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/ad-102.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-8", Title: "Evaluación 8", Type: "PRAC", Weight: 20, DueDate: "2026-06-13"}},
		},
		{
			ID: "c-009", PartitionKey: repository.PartitionCatalog, SectionID: "9", CourseCode: "ED101", Title: "Fundamentos de Educación",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/ed-101.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-9", Title: "Evaluación 9", Type: "PRAC", Weight: 20, DueDate: "2026-06-14"}},
		},
		{
			ID: "c-010", PartitionKey: repository.PartitionCatalog, SectionID: "10", CourseCode: "ED102", Title: "Tecnología Educativa",
			SyllabusURL: "https://unfpg.edu.pe/syllabus/ed-102.pdf",
			Evaluations: []models.LmsEvaluation{{EvaluationID: "eval-10", Title: "Evaluación 10", Type: "PRAC", Weight: 20, DueDate: "2026-06-15"}},
		},
	}

	for _, c := range initialCourses {
		if err := s.repo.PutCourse(ctx, c); err != nil {
			s.logger.Warn("Error sembrando curso LMS", "courseId", c.ID, "error", err)
		}
	}

	// 10 Inscripciones semilla Dataset v2
	initialEnrollments := []models.LmsEnrollment{
		{ID: "lms-enr-001", PartitionKey: "018f0001-0000-7000-8000-000000000002", StudentID: "018f0001-0000-7000-8000-000000000002", CourseID: "c-001", SectionID: "1", CourseCode: "IS101", Title: "Fundamentos de Programación", Role: "STUDENT", ProgressPercentage: 65.0},
		{ID: "lms-enr-002", PartitionKey: "018f0001-0000-7000-8000-000000000012", StudentID: "018f0001-0000-7000-8000-000000000012", CourseID: "c-002", SectionID: "2", CourseCode: "IS102", Title: "Base de Datos I", Role: "STUDENT", ProgressPercentage: 60.0},
		{ID: "lms-enr-003", PartitionKey: "018f0001-0000-7000-8000-000000000013", StudentID: "018f0001-0000-7000-8000-000000000013", CourseID: "c-003", SectionID: "3", CourseCode: "IS103", Title: "Arquitectura de Computadoras", Role: "STUDENT", ProgressPercentage: 55.0},
		{ID: "lms-enr-004", PartitionKey: "018f0001-0000-7000-8000-000000000014", StudentID: "018f0001-0000-7000-8000-000000000014", CourseID: "c-004", SectionID: "4", CourseCode: "IS104", Title: "Redes de Computadoras", Role: "STUDENT", ProgressPercentage: 70.0},
		{ID: "lms-enr-005", PartitionKey: "018f0001-0000-7000-8000-000000000015", StudentID: "018f0001-0000-7000-8000-000000000015", CourseID: "c-005", SectionID: "5", CourseCode: "SW101", Title: "Ingeniería de Software I", Role: "STUDENT", ProgressPercentage: 80.0},
		{ID: "lms-enr-006", PartitionKey: "018f0001-0000-7000-8000-000000000016", StudentID: "018f0001-0000-7000-8000-000000000016", CourseID: "c-006", SectionID: "6", CourseCode: "SW102", Title: "Desarrollo Web", Role: "STUDENT", ProgressPercentage: 75.0},
		{ID: "lms-enr-007", PartitionKey: "018f0001-0000-7000-8000-000000000017", StudentID: "018f0001-0000-7000-8000-000000000017", CourseID: "c-007", SectionID: "7", CourseCode: "AD101", Title: "Fundamentos de Administración", Role: "STUDENT", ProgressPercentage: 50.0},
		{ID: "lms-enr-008", PartitionKey: "018f0001-0000-7000-8000-000000000018", StudentID: "018f0001-0000-7000-8000-000000000018", CourseID: "c-008", SectionID: "8", CourseCode: "AD102", Title: "Contabilidad General", Role: "STUDENT", ProgressPercentage: 60.0},
		{ID: "lms-enr-009", PartitionKey: "018f0001-0000-7000-8000-000000000019", StudentID: "018f0001-0000-7000-8000-000000000019", CourseID: "c-009", SectionID: "9", CourseCode: "ED101", Title: "Fundamentos de Educación", Role: "STUDENT", ProgressPercentage: 85.0},
		{ID: "lms-enr-010", PartitionKey: "018f0001-0000-7000-8000-000000000020", StudentID: "018f0001-0000-7000-8000-000000000020", CourseID: "c-010", SectionID: "10", CourseCode: "ED102", Title: "Tecnología Educativa", Role: "STUDENT", ProgressPercentage: 90.0},
	}

	for _, e := range initialEnrollments {
		if err := s.repo.PutEnrollment(ctx, e); err != nil {
			s.logger.Warn("Error sembrando inscripción LMS demo", "enrollmentId", e.ID, "error", err)
		}
	}

	s.logger.Info("Sembrado inicial de LMS v2 completado con éxito")
	return nil
}
