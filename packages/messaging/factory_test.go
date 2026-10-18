package messaging

import (
	"os"
	"testing"
)

func TestNewMessageBus_DefaultRedis(t *testing.T) {
	cfg := Config{
		Type:      "local_redis",
		RedisAddr: "localhost:6379",
	}

	bus, err := NewMessageBus(cfg)
	if err != nil {
		t.Fatalf("error al instanciar bus local: %v", err)
	}
	defer bus.Close()

	if _, ok := bus.(*RedisStreamsAdapter); !ok {
		t.Errorf("se esperaba instancia de *RedisStreamsAdapter")
	}
}

func TestDefaultConfigFromEnv(t *testing.T) {
	os.Setenv("EVENT_BUS_TYPE", "local_redis")
	os.Setenv("REDIS_ADDR", "custom-redis:6379")
	defer func() {
		os.Unsetenv("EVENT_BUS_TYPE")
		os.Unsetenv("REDIS_ADDR")
	}()

	cfg := DefaultConfigFromEnv()
	if cfg.Type != "local_redis" {
		t.Errorf("se esperaba Type local_redis, se obtuvo %s", cfg.Type)
	}
	if cfg.RedisAddr != "custom-redis:6379" {
		t.Errorf("se esperaba REDIS_ADDR custom-redis:6379, se obtuvo %s", cfg.RedisAddr)
	}
}
