package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/universidad/platform/apps/services/person/internal/models"
)

var ErrCacheMiss = errors.New("cache miss")

type CacheRepository interface {
	GetProfile(ctx context.Context, userID string) (*models.UserProfile, error)
	SetProfile(ctx context.Context, userID string, profile *models.UserProfile, ttl time.Duration) error
	DeleteProfile(ctx context.Context, userID string) error
	Ping(ctx context.Context) error
}

type RedisCacheRepo struct {
	client *redis.Client
}

func NewRedisCacheRepo(addr, password string, db int) *RedisCacheRepo {
	rdb := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		DB:           db,
		DialTimeout:  3 * time.Second,
		ReadTimeout:  2 * time.Second,
		WriteTimeout: 2 * time.Second,
	})

	return &RedisCacheRepo{client: rdb}
}

func (c *RedisCacheRepo) key(userID string) string {
	return "profile:" + userID
}

func (c *RedisCacheRepo) GetProfile(ctx context.Context, userID string) (*models.UserProfile, error) {
	val, err := c.client.Get(ctx, c.key(userID)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, ErrCacheMiss
		}
		return nil, fmt.Errorf("error al leer de redis: %w", err)
	}

	var profile models.UserProfile
	if err := json.Unmarshal([]byte(val), &profile); err != nil {
		return nil, fmt.Errorf("error al deserializar perfil de redis: %w", err)
	}

	return &profile, nil
}

func (c *RedisCacheRepo) SetProfile(ctx context.Context, userID string, profile *models.UserProfile, ttl time.Duration) error {
	data, err := json.Marshal(profile)
	if err != nil {
		return fmt.Errorf("error al serializar perfil para redis: %w", err)
	}

	err = c.client.Set(ctx, c.key(userID), data, ttl).Err()
	if err != nil {
		return fmt.Errorf("error al escribir en redis: %w", err)
	}

	return nil
}

func (c *RedisCacheRepo) DeleteProfile(ctx context.Context, userID string) error {
	err := c.client.Del(ctx, c.key(userID)).Err()
	if err != nil && !errors.Is(err, redis.Nil) {
		return fmt.Errorf("error al evictar de redis: %w", err)
	}
	return nil
}

func (c *RedisCacheRepo) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}
