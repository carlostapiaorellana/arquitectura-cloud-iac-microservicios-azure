package services

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/universidad/platform/apps/services/person/internal/models"
	"github.com/universidad/platform/apps/services/person/internal/repository"
)

type mockPersonRepo struct {
	profile *models.UserProfile
	updated bool
}

func (m *mockPersonRepo) FindProfileByAuthUserID(ctx context.Context, authUserID string) (*models.UserProfile, error) {
	if m.profile == nil || m.profile.AuthUserID != authUserID {
		return nil, repository.ErrProfileNotFound
	}
	return m.profile, nil
}

func (m *mockPersonRepo) UpdateContact(ctx context.Context, authUserID string, req models.UpdateContactRequest) error {
	if m.profile == nil || m.profile.AuthUserID != authUserID {
		return repository.ErrProfileNotFound
	}
	m.profile.Address = req.Address
	m.profile.Phone = req.Phone
	m.profile.Mobile = req.Mobile
	m.updated = true
	return nil
}

type mockCacheRepo struct {
	mu     sync.Mutex
	store  map[string]*models.UserProfile
	evicts int
}

func newMockCacheRepo() *mockCacheRepo {
	return &mockCacheRepo{store: make(map[string]*models.UserProfile)}
}

func (c *mockCacheRepo) GetProfile(ctx context.Context, userID string) (*models.UserProfile, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	p, ok := c.store[userID]
	if !ok {
		return nil, repository.ErrCacheMiss
	}
	return p, nil
}

func (c *mockCacheRepo) SetProfile(ctx context.Context, userID string, profile *models.UserProfile, ttl time.Duration) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.store[userID] = profile
	return nil
}

func (c *mockCacheRepo) DeleteProfile(ctx context.Context, userID string) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.store, userID)
	c.evicts++
	return nil
}

func (c *mockCacheRepo) Ping(ctx context.Context) error {
	return nil
}

func TestPersonService_CacheAside(t *testing.T) {
	authID := "018f0001-0000-7000-8000-000000000002"
	initialProfile := &models.UserProfile{
		ID:         "p1",
		AuthUserID: authID,
		FirstName:  "Juan",
		Address:    "Av. Original",
	}

	repo := &mockPersonRepo{profile: initialProfile}
	cache := newMockCacheRepo()

	svc := NewPersonService(repo, cache, 10*time.Minute)

	// 1ra llamada: debe consultar BD y guardar en caché (fromCache = false)
	p1, fromCache, err := svc.GetMyProfile(context.Background(), authID)
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if fromCache {
		t.Fatal("esperaba cache miss en la 1ra llamada")
	}
	if p1.Address != "Av. Original" {
		t.Fatalf("dirección incorrecta: %s", p1.Address)
	}

	// 2da llamada: debe venir de caché (fromCache = true)
	p2, fromCache, err := svc.GetMyProfile(context.Background(), authID)
	if err != nil {
		t.Fatalf("error inesperado en 2da llamada: %v", err)
	}
	if !fromCache {
		t.Fatal("esperaba cache hit en la 2da llamada")
	}
	if p2.Address != "Av. Original" {
		t.Fatalf("dirección incorrecta: %s", p2.Address)
	}

	// Actualización: debe evictar la caché
	updated, err := svc.UpdateMyContact(context.Background(), authID, models.UpdateContactRequest{
		Address: "Av. Modificada 456",
		Phone:   "014567890",
	})
	if err != nil {
		t.Fatalf("error al actualizar: %v", err)
	}
	if updated.Address != "Av. Modificada 456" {
		t.Fatalf("dirección no actualizada: %s", updated.Address)
	}
	if cache.evicts != 1 {
		t.Fatalf("esperaba 1 evicción en caché, obtenido: %d", cache.evicts)
	}
}
