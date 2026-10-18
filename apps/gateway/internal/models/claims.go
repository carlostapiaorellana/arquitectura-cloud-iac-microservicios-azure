package models

// TokenClaims representa la carga útil del JWT verificado en el Gateway
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
