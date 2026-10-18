package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisStreamsAdapter implementa MessageBus sobre Redis Streams para emulación local ($0.00)
type RedisStreamsAdapter struct {
	client   *redis.Client
	stopChan chan struct{}
}

// NewRedisStreamsAdapter inicializa el adaptador de Redis Streams
func NewRedisStreamsAdapter(cfg Config) (*RedisStreamsAdapter, error) {
	addr := cfg.RedisAddr
	if addr == "" {
		addr = "localhost:6379"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: cfg.RedisPassword,
		DB:       cfg.RedisDB,
	})

	return &RedisStreamsAdapter{
		client:   rdb,
		stopChan: make(chan struct{}),
	}, nil
}

// Publish publica un evento en el Stream de Redis correspondiente al tópico
func (r *RedisStreamsAdapter) Publish(ctx context.Context, topic string, event any) error {
	var payloadBytes []byte
	switch v := event.(type) {
	case []byte:
		payloadBytes = v
	case string:
		payloadBytes = []byte(v)
	default:
		var err error
		payloadBytes, err = json.Marshal(event)
		if err != nil {
			return fmt.Errorf("error al serializar evento para redis stream %s: %w", topic, err)
		}
	}

	return r.client.XAdd(ctx, &redis.XAddArgs{
		Stream: topic,
		Values: map[string]any{
			"payload": string(payloadBytes),
		},
	}).Err()
}

// Subscribe escucha un Stream de Redis utilizando un Consumer Group (emula suscripciones Pub/Sub independientes)
func (r *RedisStreamsAdapter) Subscribe(ctx context.Context, topic string, subscription string, handler EventHandler) error {
	if handler == nil {
		return ErrNilHandler
	}

	// Crear el grupo de consumidores si aún no existe
	err := r.client.XGroupCreateMkStream(ctx, topic, subscription, "$").Err()
	if err != nil && !strings.Contains(err.Error(), "BUSYGROUP") {
		// Log o verificación de existencia
	}

	consumerName := fmt.Sprintf("consumer-%d", time.Now().UnixNano())

	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-r.stopChan:
				return
			default:
				entries, err := r.client.XReadGroup(ctx, &redis.XReadGroupArgs{
					Group:    subscription,
					Consumer: consumerName,
					Streams:  []string{topic, ">"},
					Count:    10,
					Block:    2 * time.Second,
				}).Result()

				if err != nil {
					if errors.Is(err, context.Canceled) {
						return
					}
					time.Sleep(500 * time.Millisecond)
					continue
				}

				for _, stream := range entries {
					for _, message := range stream.Messages {
						payloadStr, ok := message.Values["payload"].(string)
						if !ok {
							continue
						}

						if handleErr := handler(ctx, []byte(payloadStr)); handleErr == nil {
							_ = r.client.XAck(ctx, topic, subscription, message.ID).Err()
						}
					}
				}
			}
		}
	}()

	return nil
}

// Send envía un mensaje punto a punto a un Stream que actúa como cola
func (r *RedisStreamsAdapter) Send(ctx context.Context, queue string, message any) error {
	return r.Publish(ctx, queue, message)
}

// Consume procesa mensajes de una cola en Redis Streams con acuse de recibo explícito (XACK)
func (r *RedisStreamsAdapter) Consume(ctx context.Context, queue string, handler MessageHandler) error {
	groupName := fmt.Sprintf("%s-group", queue)
	return r.Subscribe(ctx, queue, groupName, func(ctx context.Context, eventData []byte) error {
		return handler(ctx, eventData)
	})
}

// Ping comprueba la conectividad contra Redis
func (r *RedisStreamsAdapter) Ping(ctx context.Context) error {
	return r.client.Ping(ctx).Err()
}

// Close cierra la conexión del cliente Redis y finaliza los workers
func (r *RedisStreamsAdapter) Close() error {
	close(r.stopChan)
	return r.client.Close()
}
