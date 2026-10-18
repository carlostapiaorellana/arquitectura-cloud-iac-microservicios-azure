package apicontracts

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNewPageResponse(t *testing.T) {
	items := []string{"item1", "item2", "item3"}
	resp := NewPageResponse(items, 1, 10, 25)

	if resp.TotalPages != 3 {
		t.Fatalf("se esperaba 3 totalPages para 25 items con pageSize 10, se obtuvo %d", resp.TotalPages)
	}
	if len(resp.Items) != 3 {
		t.Fatalf("se esperaba 3 items en respuesta")
	}
}

func TestExtractPageRequest_Defaults(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/courses", nil)
	pageReq := ExtractPageRequest(req)

	if pageReq.Page != DefaultPage {
		t.Errorf("se esperaba página por defecto %d, se obtuvo %d", DefaultPage, pageReq.Page)
	}
	if pageReq.PageSize != DefaultPageSize {
		t.Errorf("se esperaba pageSize por defecto %d, se obtuvo %d", DefaultPageSize, pageReq.PageSize)
	}
}

func TestExtractPageRequest_Limits(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/courses?page=2&pageSize=500&sort=name:asc", nil)
	pageReq := ExtractPageRequest(req)

	if pageReq.Page != 2 {
		t.Errorf("se esperaba página 2, se obtuvo %d", pageReq.Page)
	}
	if pageReq.PageSize != MaxPageSize {
		t.Errorf("pageSize debería haberse truncado al máximo %d, se obtuvo %d", MaxPageSize, pageReq.PageSize)
	}
	if pageReq.Sort != "name:asc" {
		t.Errorf("se esperaba sort name:asc, se obtuvo %s", pageReq.Sort)
	}
	if pageReq.Offset() != 100 {
		t.Errorf("se esperaba offset 100, se obtuvo %d", pageReq.Offset())
	}
}
