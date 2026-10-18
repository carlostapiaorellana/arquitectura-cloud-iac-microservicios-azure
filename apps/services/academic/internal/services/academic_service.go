package services

import (
	"context"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/academic/internal/models"
	"github.com/universidad/platform/apps/services/academic/internal/repository"
)

type AcademicService struct {
	repo repository.AcademicRepository
}

func NewAcademicService(repo repository.AcademicRepository) *AcademicService {
	return &AcademicService{repo: repo}
}

func (s *AcademicService) ListPrograms(ctx context.Context) ([]models.Program, error) {
	programs, err := s.repo.ListPrograms(ctx)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al obtener programas académicos", err)
	}
	return programs, nil
}

func (s *AcademicService) ListCourses(ctx context.Context) ([]models.Course, error) {
	courses, err := s.repo.ListCourses(ctx)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al obtener cursos", err)
	}
	return courses, nil
}

func (s *AcademicService) ListSections(ctx context.Context) ([]models.Section, error) {
	sections, err := s.repo.ListSections(ctx)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al obtener secciones", err)
	}
	return sections, nil
}
