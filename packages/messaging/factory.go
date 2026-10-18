package messaging

import (
	"os"
	"strings"
)

// NewMessageBus fabrica e inicializa el adaptador de mensajería adecuado
// según el valor configurado o la variable de entorno EVENT_BUS_TYPE
func NewMessageBus(cfg Config) (MessageBus, error) {
	busType := cfg.Type
	if busType == "" {
		busType = os.Getenv("EVENT_BUS_TYPE")
	}

	switch strings.ToLower(strings.TrimSpace(busType)) {
	case "azure_servicebus", "servicebus", "azure":
		if cfg.ServiceBusFQDN == "" {
			cfg.ServiceBusFQDN = os.Getenv("SERVICEBUS_FQDN")
		}
		if cfg.ServiceBusConnString == "" {
			cfg.ServiceBusConnString = os.Getenv("SERVICEBUS_CONNECTION_STRING")
		}
		return NewServiceBusAdapter(cfg)

	case "local_redis", "redis", "local":
		if cfg.RedisAddr == "" {
			cfg.RedisAddr = os.Getenv("REDIS_ADDR")
		}
		return NewRedisStreamsAdapter(cfg)

	default:
		// Fallback local por defecto ($0.00 / 12-factor)
		if cfg.RedisAddr == "" {
			cfg.RedisAddr = os.Getenv("REDIS_ADDR")
		}
		if cfg.RedisAddr == "" {
			cfg.RedisAddr = "redis:6379"
		}
		return NewRedisStreamsAdapter(cfg)
	}
}

// DefaultConfigFromEnv construye una configuración a partir de las variables de entorno del sistema
func DefaultConfigFromEnv() Config {
	return Config{
		Type:                 os.Getenv("EVENT_BUS_TYPE"),
		RedisAddr:            os.Getenv("REDIS_ADDR"),
		RedisPassword:        os.Getenv("REDIS_PASSWORD"),
		ServiceBusFQDN:       os.Getenv("SERVICEBUS_FQDN"),
		ServiceBusConnString: os.Getenv("SERVICEBUS_CONNECTION_STRING"),
		UseManagedIdentity:   os.Getenv("ENV") == "dev" || os.Getenv("ENV") == "prod",
	}
}
