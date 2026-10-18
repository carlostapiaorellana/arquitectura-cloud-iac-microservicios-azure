package errorhandling

import (
	"errors"
	"fmt"
	"net/http"
)

// Códigos institucionales y canónicos de error
const (
	CodeValidationError    = "VALIDATION_ERROR"
	CodeUnauthenticated    = "UNAUTHENTICATED"
	CodeForbidden          = "FORBIDDEN"
	CodeResourceNotFound   = "RESOURCE_NOT_FOUND"
	CodeConflict           = "CONFLICT"
	CodeInternalError      = "INTERNAL_ERROR"
	CodeBadRequest         = "BAD_REQUEST"
	CodeRateLimitExceeded  = "RATE_LIMIT_EXCEEDED"
	CodeServiceUnavailable = "SERVICE_UNAVAILABLE"
	CodeUpstreamTimeout    = "UPSTREAM_TIMEOUT"
)

// DomainError representa un error estructurado de dominio con metadatos HTTP y de trazabilidad
type DomainError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Status  int    `json:"status"`
	Err     error  `json:"-"`
}

func (e *DomainError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("[%s] %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *DomainError) Unwrap() error {
	return e.Err
}

// NewDomainError constructor general para errores de dominio
func NewDomainError(status int, code, message string, err error) *DomainError {
	return &DomainError{
		Status:  status,
		Code:    code,
		Message: message,
		Err:     err,
	}
}

// Constructores especializados para errores canónicos
func NewBadRequestError(message string, err error) *DomainError {
	return NewDomainError(http.StatusBadRequest, CodeBadRequest, message, err)
}

func NewValidationError(message string, err error) *DomainError {
	return NewDomainError(http.StatusUnprocessableEntity, CodeValidationError, message, err)
}

func NewUnauthenticatedError(message string, err error) *DomainError {
	if message == "" {
		message = "autenticación requerida para acceder al recurso"
	}
	return NewDomainError(http.StatusUnauthorized, CodeUnauthenticated, message, err)
}

func NewForbiddenError(message string, err error) *DomainError {
	if message == "" {
		message = "permisos insuficientes para ejecutar esta operación"
	}
	return NewDomainError(http.StatusForbidden, CodeForbidden, message, err)
}

func NewNotFoundError(message string, err error) *DomainError {
	return NewDomainError(http.StatusNotFound, CodeResourceNotFound, message, err)
}

func NewConflictError(message string, err error) *DomainError {
	return NewDomainError(http.StatusConflict, CodeConflict, message, err)
}

func NewInternalError(message string, err error) *DomainError {
	if message == "" {
		message = "ha ocurrido un error interno en el servicio"
	}
	return NewDomainError(http.StatusInternalServerError, CodeInternalError, message, err)
}

// AsDomainError intenta desenvolver un error genérico hacia DomainError
func AsDomainError(err error) (*DomainError, bool) {
	var target *DomainError
	if errors.As(err, &target) {
		return target, true
	}
	return nil, false
}
