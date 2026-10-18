package apicontracts

import (
	"math"
	"net/http"
	"strconv"
	"strings"
)

const (
	DefaultPage     = 1
	DefaultPageSize = 20
	MaxPageSize     = 100
)

// PageRequest encapsula los parámetros de paginación y ordenamiento
type PageRequest struct {
	Page     int    `json:"page"`
	PageSize int    `json:"pageSize"`
	Sort     string `json:"sort,omitempty"`
}

// Offset calcula el desplazamiento para consultas SQL (LIMIT pageSize OFFSET offset)
func (p PageRequest) Offset() int {
	if p.Page <= 1 {
		return 0
	}
	return (p.Page - 1) * p.PageSize
}

// Limit devuelve el límite seguro para consultas SQL
func (p PageRequest) Limit() int {
	return p.PageSize
}

// PageResponse representa el sobre unificado para colecciones paginadas genéricas
type PageResponse[T any] struct {
	Items      []T   `json:"items"`
	Page       int   `json:"page"`
	PageSize   int   `json:"pageSize"`
	TotalItems int64 `json:"totalItems"`
	TotalPages int   `json:"totalPages"`
}

// NewPageResponse crea un PageResponse calculando automáticamente TotalPages
func NewPageResponse[T any](items []T, page, pageSize int, totalItems int64) PageResponse[T] {
	if items == nil {
		items = make([]T, 0)
	}

	totalPages := 0
	if pageSize > 0 && totalItems > 0 {
		totalPages = int(math.Ceil(float64(totalItems) / float64(pageSize)))
	}

	return PageResponse[T]{
		Items:      items,
		Page:       page,
		PageSize:   pageSize,
		TotalItems: totalItems,
		TotalPages: totalPages,
	}
}

// ExtractPageRequest extrae y sanitiza los parámetros ?page=, ?pageSize= y ?sort= desde un http.Request
func ExtractPageRequest(r *http.Request) PageRequest {
	req := PageRequest{
		Page:     DefaultPage,
		PageSize: DefaultPageSize,
	}

	if r == nil {
		return req
	}

	query := r.URL.Query()

	if pStr := strings.TrimSpace(query.Get("page")); pStr != "" {
		if p, err := strconv.Atoi(pStr); err == nil && p > 0 {
			req.Page = p
		}
	}

	if psStr := strings.TrimSpace(query.Get("pageSize")); psStr != "" {
		if ps, err := strconv.Atoi(psStr); err == nil && ps > 0 {
			if ps > MaxPageSize {
				ps = MaxPageSize
			}
			req.PageSize = ps
		}
	}

	req.Sort = strings.TrimSpace(query.Get("sort"))

	return req
}
