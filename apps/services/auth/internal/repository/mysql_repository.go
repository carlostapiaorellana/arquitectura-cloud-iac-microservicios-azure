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

// EnsureSchema inicializa tablas y usuarios semilla en auth_db de forma idempotente
func (r *MySQLRepository) EnsureSchema(ctx context.Context) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS roles (
			id INT AUTO_INCREMENT PRIMARY KEY,
			name VARCHAR(50) NOT NULL UNIQUE,
			description VARCHAR(255),
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS users (
			id VARCHAR(36) PRIMARY KEY,
			username VARCHAR(50) NOT NULL UNIQUE,
			email VARCHAR(100) NOT NULL UNIQUE,
			password_hash VARCHAR(255) NOT NULL,
			role_id INT NOT NULL,
			status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			FOREIGN KEY (role_id) REFERENCES roles(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`CREATE TABLE IF NOT EXISTS refresh_tokens (
			id VARCHAR(36) PRIMARY KEY,
			user_id VARCHAR(36) NOT NULL,
			token_hash VARCHAR(255) NOT NULL UNIQUE,
			expires_at DATETIME NOT NULL,
			revoked_at DATETIME NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES users(id)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`,

		`INSERT INTO roles (id, name, description) VALUES
		(1, 'ADMIN', 'Administrador con control total de la plataforma'),
		(2, 'STUDENT', 'Estudiante universitario con acceso a portal y matriculas'),
		(3, 'TEACHER', 'Docente titular o contratado con gestion de notas y asistencias'),
		(4, 'EMPLOYEE', 'Personal administrativo y operativo')
		ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);`,

		`INSERT INTO users (id, username, email, password_hash, role_id, status) VALUES
		('018f0001-0000-7000-8000-000000000001', 'admin', 'admin@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 1, 'ACTIVE'),
		('018f0001-0000-7000-8000-000000000002', 'alu01', 'estudiante1@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
		('018f0001-0000-7000-8000-000000000003', 'docente1', 'docente1@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE')
		ON DUPLICATE KEY UPDATE username = VALUES(username), email = VALUES(email), password_hash = VALUES(password_hash), role_id = VALUES(role_id), status = VALUES(status);`,
	}

	for _, q := range queries {
		if _, err := r.db.ExecContext(ctx, q); err != nil {
			return fmt.Errorf("error al ejecutar bootstrap schema: %w", err)
		}
	}
	return nil
}
