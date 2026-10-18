package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/universidad/platform/apps/services/finance/internal/models"
)

var ErrIdempotencyNotFound = errors.New("idempotency record not found")

type IdempotencyRepository interface {
	GetIdempotency(ctx context.Context, key string) (*models.PaymentResponse, error)
	SetIdempotency(ctx context.Context, key string, resp *models.PaymentResponse, ttl time.Duration) error
	Ping(ctx context.Context) error
}

type RedisIdempotencyRepo struct {
	client       *redis.Client
	mu           sync.RWMutex
	fallbackData map[string][]byte
}

func NewRedisIdempotencyRepo(addr, password string, db int) *RedisIdempotencyRepo {
	rdb := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		DB:           db,
		DialTimeout:  3 * time.Second,
		ReadTimeout:  2 * time.Second,
		WriteTimeout: 2 * time.Second,
	})

	return &RedisIdempotencyRepo{
		client:       rdb,
		fallbackData: make(map[string][]byte),
	}
}

func (r *RedisIdempotencyRepo) formatKey(key string) string {
	return "idempotency:" + key
}

func (r *RedisIdempotencyRepo) GetIdempotency(ctx context.Context, key string) (*models.PaymentResponse, error) {
	redisKey := r.formatKey(key)

	val, err := r.client.Get(ctx, redisKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, ErrIdempotencyNotFound
		}

		// Fallback local en memoria
		r.mu.RLock()
		fbVal, ok := r.fallbackData[redisKey]
		r.mu.RUnlock()
		if ok {
			var resp models.PaymentResponse
			if err := json.Unmarshal(fbVal, &resp); err == nil {
				return &resp, nil
			}
		}

		return nil, ErrIdempotencyNotFound
	}

	var resp models.PaymentResponse
	if err := json.Unmarshal([]byte(val), &resp); err != nil {
		return nil, fmt.Errorf("error deserializando respuesta idempotente: %w", err)
	}

	return &resp, nil
}

func (r *RedisIdempotencyRepo) SetIdempotency(ctx context.Context, key string, resp *models.PaymentResponse, ttl time.Duration) error {
	redisKey := r.formatKey(key)
	data, err := json.Marshal(resp)
	if err != nil {
		return fmt.Errorf("error serializando respuesta para idempotencia: %w", err)
	}

	// Guardar en fallback en memoria
	r.mu.Lock()
	r.fallbackData[redisKey] = data
	r.mu.Unlock()

	err = r.client.Set(ctx, redisKey, data, ttl).Err()
	if err != nil {
		// Log or degrade gracefully
		return nil
	}

	return nil
}

func (r *RedisIdempotencyRepo) Ping(ctx context.Context) error {
	return r.client.Ping(ctx).Err()
}
