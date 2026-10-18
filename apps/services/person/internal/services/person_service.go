package services

import (
	"context"
	"errors"
	"time"

	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/apps/services/person/internal/models"
	"github.com/universidad/platform/apps/services/person/internal/repository"
)

type PersonService struct {
	personRepo repository.PersonRepository
	cacheRepo  repository.CacheRepository
	cacheTTL   time.Duration
}

func NewPersonService(
	personRepo repository.PersonRepository,
	cacheRepo repository.CacheRepository,
	cacheTTL time.Duration,
) *PersonService {
	return &PersonService{
		personRepo: personRepo,
		cacheRepo:  cacheRepo,
		cacheTTL:   cacheTTL,
	}
}

// GetMyProfile implementa Cache-Aside: intenta Redis -> fallback a MySQL -> guarda en Redis
func (s *PersonService) GetMyProfile(ctx context.Context, authUserID string) (*models.UserProfile, bool, error) {
	if authUserID == "" {
		return nil, false, errorhandling.NewUnauthenticatedError("identidad de usuario no proporcionada", nil)
	}

	// 1. Intentar leer desde Redis
	if s.cacheRepo != nil {
		cached, err := s.cacheRepo.GetProfile(ctx, authUserID)
		if err == nil && cached != nil {
			return cached, true, nil
		}
	}

	// 2. Consulta autoritativa en MySQL
	profile, err := s.personRepo.FindProfileByAuthUserID(ctx, authUserID)
	if err != nil {
		if errors.Is(err, repository.ErrProfileNotFound) {
			return nil, false, errorhandling.NewNotFoundError("perfil no registrado en person_db", nil)
		}
		return nil, false, errorhandling.NewInternalError("error al obtener perfil", err)
	}

	// 3. Escribir asíncronamente en caché Redis
	if s.cacheRepo != nil {
		_ = s.cacheRepo.SetProfile(ctx, authUserID, profile, s.cacheTTL)
	}

	return profile, false, nil
}

// UpdateMyContact actualiza datos de contacto y evicta inmediatamente la caché
func (s *PersonService) UpdateMyContact(ctx context.Context, authUserID string, req models.UpdateContactRequest) (*models.UserProfile, error) {
	if authUserID == "" {
		return nil, errorhandling.NewUnauthenticatedError("identidad de usuario no proporcionada", nil)
	}

	if req.Address == "" && req.Phone == "" && req.Mobile == "" {
		return nil, errorhandling.NewBadRequestError("debe proporcionar al menos un campo de contacto a actualizar", nil)
	}

	// 1. Actualizar en MySQL
	if err := s.personRepo.UpdateContact(ctx, authUserID, req); err != nil {
		if errors.Is(err, repository.ErrProfileNotFound) {
			return nil, errorhandling.NewNotFoundError("perfil no encontrado para actualizar", nil)
		}
		return nil, errorhandling.NewInternalError("error al actualizar datos de contacto", err)
	}

	// 2. Evicción inmediata de la caché (Cache Invalidation)
	if s.cacheRepo != nil {
		_ = s.cacheRepo.DeleteProfile(ctx, authUserID)
	}

	// 3. Retornar perfil actualizado
	freshProfile, err := s.personRepo.FindProfileByAuthUserID(ctx, authUserID)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al recuperar perfil actualizado", err)
	}

	// Repoblar caché con el nuevo dato
	if s.cacheRepo != nil {
		_ = s.cacheRepo.SetProfile(ctx, authUserID, freshProfile, s.cacheTTL)
	}

	return freshProfile, nil
}
