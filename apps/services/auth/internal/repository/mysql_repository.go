package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/universidad/platform/apps/services/auth/internal/models"
)

var (
	ErrUserNotFound  = errors.New("usuario no encontrado")
	ErrTokenNotFound = errors.New("refresh token no encontrado")
)

type UserRepository interface {
	FindByUsernameOrEmail(ctx context.Context, identifier string) (*models.User, error)
	FindByID(ctx context.Context, id string) (*models.User, error)
	Create(ctx context.Context, user *models.User) error
}

type TokenRepository interface {
	SaveRefreshToken(ctx context.Context, token *models.RefreshToken) error
	FindByTokenHash(ctx context.Context, tokenHash string) (*models.RefreshToken, error)
	RevokeToken(ctx context.Context, id string) error
}

type MySQLRepository struct {
	db *sql.DB
}

func NewMySQLRepository(db *sql.DB) *MySQLRepository {
	return &MySQLRepository{db: db}
}

func (r *MySQLRepository) FindByUsernameOrEmail(ctx context.Context, identifier string) (*models.User, error) {
	query := `
		SELECT u.id, u.username, u.email, u.password_hash, u.role_id, COALESCE(r.name, 'UNKNOWN') AS role_name, u.status, u.created_at, u.updated_at
		FROM users u
		LEFT JOIN roles r ON u.role_id = r.id
		WHERE u.username = ? OR u.email = ?
		LIMIT 1`

	var u models.User
	err := r.db.QueryRowContext(ctx, query, identifier, identifier).Scan(
		&u.ID,
		&u.Username,
		&u.Email,
		&u.PasswordHash,
		&u.RoleID,
		&u.RoleName,
		&u.Status,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("error al consultar usuario: %w", err)
	}

	return &u, nil
}

func (r *MySQLRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	query := `
		SELECT u.id, u.username, u.email, u.password_hash, u.role_id, COALESCE(r.name, 'UNKNOWN') AS role_name, u.status, u.created_at, u.updated_at
		FROM users u
		LEFT JOIN roles r ON u.role_id = r.id
		WHERE u.id = ?
		LIMIT 1`

	var u models.User
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&u.ID,
		&u.Username,
		&u.Email,
		&u.PasswordHash,
		&u.RoleID,
		&u.RoleName,
		&u.Status,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("error al consultar usuario por id: %w", err)
	}

	return &u, nil
}

func (r *MySQLRepository) Create(ctx context.Context, u *models.User) error {
	query := `
		INSERT INTO users (id, username, email, password_hash, role_id, status)
		VALUES (?, ?, ?, ?, ?, ?)`

	_, err := r.db.ExecContext(ctx, query, u.ID, u.Username, u.Email, u.PasswordHash, u.RoleID, u.Status)
	if err != nil {
		return fmt.Errorf("error al insertar usuario: %w", err)
	}
	return nil
}

func (r *MySQLRepository) SaveRefreshToken(ctx context.Context, token *models.RefreshToken) error {
	query := `
		INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, created_at)
		VALUES (?, ?, ?, ?, ?)`

	createdAt := token.CreatedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}

	_, err := r.db.ExecContext(ctx, query, token.ID, token.UserID, token.TokenHash, token.ExpiresAt, createdAt)
	if err != nil {
		return fmt.Errorf("error al guardar refresh token: %w", err)
	}
	return nil
}

func (r *MySQLRepository) FindByTokenHash(ctx context.Context, tokenHash string) (*models.RefreshToken, error) {
	query := `
		SELECT id, user_id, token_hash, expires_at, revoked_at, created_at
		FROM refresh_tokens
		WHERE token_hash = ?
		LIMIT 1`

	var t models.RefreshToken
	var revokedAt sql.NullTime

	err := r.db.QueryRowContext(ctx, query, tokenHash).Scan(
		&t.ID,
		&t.UserID,
		&t.TokenHash,
		&t.ExpiresAt,
		&revokedAt,
		&t.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrTokenNotFound
		}
		return nil, fmt.Errorf("error al buscar refresh token: %w", err)
	}

	if revokedAt.Valid {
		t.RevokedAt = &revokedAt.Time
	}

	return &t, nil
}

func (r *MySQLRepository) RevokeToken(ctx context.Context, id string) error {
	query := `UPDATE refresh_tokens SET revoked_at = ? WHERE id = ? AND revoked_at IS NULL`
	now := time.Now().UTC()
	_, err := r.db.ExecContext(ctx, query, now, id)
	if err != nil {
		return fmt.Errorf("error al revocar refresh token: %w", err)
	}
	return nil
}
