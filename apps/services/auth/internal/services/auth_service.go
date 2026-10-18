package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/packages/messaging"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/auth/internal/models"
	"github.com/universidad/platform/apps/services/auth/internal/repository"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo        repository.UserRepository
	tokenRepo       repository.TokenRepository
	jwtSvc          *JWTService
	messageBus      messaging.MessageBus
	refreshTokenTTL time.Duration
}

func NewAuthService(
	userRepo repository.UserRepository,
	tokenRepo repository.TokenRepository,
	jwtSvc *JWTService,
	messageBus messaging.MessageBus,
	refreshTokenTTL time.Duration,
) *AuthService {
	return &AuthService{
		userRepo:        userRepo,
		tokenRepo:       tokenRepo,
		jwtSvc:          jwtSvc,
		messageBus:      messageBus,
		refreshTokenTTL: refreshTokenTTL,
	}
}

func (s *AuthService) Login(ctx context.Context, req models.LoginRequest) (*models.LoginResponse, error) {
	if req.Username == "" || req.Password == "" {
		return nil, errorhandling.NewBadRequestError("usuario y contraseña son obligatorios", nil)
	}

	user, err := s.userRepo.FindByUsernameOrEmail(ctx, req.Username)
	if err != nil {
		if errors.Is(err, repository.ErrUserNotFound) {
			return nil, errorhandling.NewUnauthenticatedError("credenciales inválidas", nil)
		}
		return nil, errorhandling.NewInternalError("error al validar credenciales", err)
	}

	if user.Status != "ACTIVE" {
		return nil, errorhandling.NewForbiddenError("la cuenta de usuario no está activa", nil)
	}

	// Comparación segura con Bcrypt
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errorhandling.NewUnauthenticatedError("credenciales inválidas", nil)
	}

	// Generar Access Token RS256
	accessToken, err := s.jwtSvc.GenerateAccessToken(user)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al emitir token de acceso", err)
	}

	// Generar Refresh Token
	tokenRaw, tokenHash, err := s.jwtSvc.GenerateRefreshToken()
	if err != nil {
		return nil, errorhandling.NewInternalError("error al generar refresh token", err)
	}

	refreshRecord := &models.RefreshToken{
		ID:        observability.GenerateULID(),
		UserID:    user.ID,
		TokenHash: tokenHash,
		ExpiresAt: time.Now().UTC().Add(s.refreshTokenTTL),
		CreatedAt: time.Now().UTC(),
	}

	if err := s.tokenRepo.SaveRefreshToken(ctx, refreshRecord); err != nil {
		return nil, errorhandling.NewInternalError("error al persistir refresh token", err)
	}

	return &models.LoginResponse{
		AccessToken:  accessToken,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.jwtSvc.TokenTTL().Seconds()),
		RefreshToken: tokenRaw,
		UserID:       user.ID,
		Role:         user.RoleName,
		Roles:        []string{user.RoleName},
		Username:     user.Username,
	}, nil
}

func (s *AuthService) Refresh(ctx context.Context, req models.RefreshTokenRequest) (*models.LoginResponse, error) {
	if req.RefreshToken == "" {
		return nil, errorhandling.NewBadRequestError("el refresh token es requerido", nil)
	}

	tokenHash := s.jwtSvc.HashToken(req.RefreshToken)
	tokenRecord, err := s.tokenRepo.FindByTokenHash(ctx, tokenHash)
	if err != nil {
		if errors.Is(err, repository.ErrTokenNotFound) {
			return nil, errorhandling.NewUnauthenticatedError("refresh token inválido o revocado", nil)
		}
		return nil, errorhandling.NewInternalError("error al verificar refresh token", err)
	}

	if tokenRecord.RevokedAt != nil {
		return nil, errorhandling.NewUnauthenticatedError("refresh token ya ha sido revocado", nil)
	}

	if time.Now().UTC().After(tokenRecord.ExpiresAt) {
		return nil, errorhandling.NewUnauthenticatedError("refresh token expirado", nil)
	}

	user, err := s.userRepo.FindByID(ctx, tokenRecord.UserID)
	if err != nil {
		return nil, errorhandling.NewUnauthenticatedError("usuario asociado al token no existe", nil)
	}

	if user.Status != "ACTIVE" {
		return nil, errorhandling.NewForbiddenError("la cuenta de usuario no está activa", nil)
	}

	// Revocar el token utilizado (rotación de refresh tokens)
	_ = s.tokenRepo.RevokeToken(ctx, tokenRecord.ID)

	// Emitir nuevo Access Token
	newAccessToken, err := s.jwtSvc.GenerateAccessToken(user)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al generar nuevo token de acceso", err)
	}

	// Emitir nuevo Refresh Token
	newRaw, newHash, err := s.jwtSvc.GenerateRefreshToken()
	if err != nil {
		return nil, errorhandling.NewInternalError("error al generar nuevo refresh token", err)
	}

	newRecord := &models.RefreshToken{
		ID:        observability.GenerateULID(),
		UserID:    user.ID,
		TokenHash: newHash,
		ExpiresAt: time.Now().UTC().Add(s.refreshTokenTTL),
		CreatedAt: time.Now().UTC(),
	}

	if err := s.tokenRepo.SaveRefreshToken(ctx, newRecord); err != nil {
		return nil, errorhandling.NewInternalError("error al persistir nuevo refresh token", err)
	}

	return &models.LoginResponse{
		AccessToken:  newAccessToken,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.jwtSvc.TokenTTL().Seconds()),
		RefreshToken: newRaw,
		UserID:       user.ID,
		Role:         user.RoleName,
		Roles:        []string{user.RoleName},
		Username:     user.Username,
	}, nil
}

func (s *AuthService) RegisterUser(ctx context.Context, req models.CreateUserRequest, correlationID string) (*models.User, error) {
	if req.Username == "" || req.Email == "" || req.Password == "" {
		return nil, errorhandling.NewBadRequestError("usuario, correo y contraseña son obligatorios", nil)
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errorhandling.NewInternalError("error al procesar contraseña", err)
	}

	roleID := req.RoleID
	if roleID <= 0 {
		roleID = 2 // STUDENT por defecto
	}

	user := &models.User{
		ID:           observability.GenerateULID(),
		Username:     req.Username,
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		RoleID:       roleID,
		Status:       "ACTIVE",
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, errorhandling.NewInternalError("error al registrar usuario", err)
	}

	// Publicar evento UserCreatedEvent de forma asíncrona desacoplada
	if s.messageBus != nil {
		event := apicontracts.UserCreatedEvent{
			BaseEvent: apicontracts.NewBaseEvent(observability.GenerateULID(), apicontracts.EventTypeUserCreated, correlationID),
			Payload: apicontracts.UserCreatedPayload{
				UserID:   user.ID,
				Username: user.Username,
				Email:    user.Email,
				Role:     fmt.Sprintf("%d", user.RoleID),
			},
		}
		_ = s.messageBus.Publish(ctx, apicontracts.TopicAuthEvents, event)
	}

	return user, nil
}
