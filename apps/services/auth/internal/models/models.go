package models

import "time"

// Role representa un rol institucional en auth_db
type Role struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
}

// User representa un usuario del sistema en auth_db
type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	RoleID       int       `json:"roleId"`
	RoleName     string    `json:"roleName"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// RefreshToken representa un token de refresco criptográfico persistido
type RefreshToken struct {
	ID        string     `json:"id"`
	UserID    string     `json:"userId"`
	TokenHash string     `json:"tokenHash"`
	ExpiresAt time.Time  `json:"expiresAt"`
	RevokedAt *time.Time `json:"revokedAt,omitempty"`
	CreatedAt time.Time  `json:"createdAt"`
}

// LoginRequest DTO de entrada para autenticación
type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// LoginResponse DTO de salida con tokens JWT y metadatos de sesión
type LoginResponse struct {
	AccessToken  string   `json:"accessToken"`
	TokenType    string   `json:"tokenType"`
	ExpiresIn    int64    `json:"expiresIn"`
	RefreshToken string   `json:"refreshToken,omitempty"`
	UserID       string   `json:"userId"`
	Role         string   `json:"role"`
	Roles        []string `json:"roles"`
	Username     string   `json:"username"`
}

// RefreshTokenRequest DTO para solicitar rotación de token
type RefreshTokenRequest struct {
	RefreshToken string `json:"refreshToken"`
}

// CreateUserRequest DTO para creación de nuevo usuario
type CreateUserRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
	RoleID   int    `json:"roleId"`
}

// TokenClaims representa la carga útil del JWT firmado con RS256
type TokenClaims struct {
	Sub      string   `json:"sub"`
	Username string   `json:"username"`
	Role     string   `json:"role"`
	Roles    []string `json:"roles"`
	Scopes   []string `json:"scopes"`
	Iss      string   `json:"iss"`
	Aud      string   `json:"aud"`
	Exp      int64    `json:"exp"`
	Iat      int64    `json:"iat"`
}
