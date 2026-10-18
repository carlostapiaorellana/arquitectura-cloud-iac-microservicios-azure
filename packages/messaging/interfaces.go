package messaging

import (
	"context"
	"errors"
)

var (
	ErrSubscriptionFailed = errors.New("fallo en la suscripción de eventos")
	ErrConsumerFailed     = errors.New("fallo en el consumidor de cola")
	ErrNilHandler         = errors.New("el handler no puede ser nulo")
)

// EventHandler es la función callback para procesar eventos emitidos a un tópico
type EventHandler func(ctx context.Context, eventData []byte) error

// MessageHandler es la función callback para procesar mensajes punto a punto recibidos de una cola
type MessageHandler func(ctx context.Context, messageData []byte) error

// EventPublisher define el contrato para publicar eventos hacia un tópico (Fan-out Pub/Sub)
type EventPublisher interface {
	Publish(ctx context.Context, topic string, event any) error
}

// EventSubscriber define el contrato para suscribirse a un tópico y recibir eventos
type EventSubscriber interface {
	Subscribe(ctx context.Context, topic string, subscription string, handler EventHandler) error
}

// QueueProducer define el contrato para enviar mensajes a una cola punto a punto
type QueueProducer interface {
	Send(ctx context.Context, queue string, message any) error
}

// QueueConsumer define el contrato para procesar mensajes de una cola en modo Peek-Lock
type QueueConsumer interface {
	Consume(ctx context.Context, queue string, handler MessageHandler) error
}

// MessageBus combina todas las capacidades de mensajería (Pub/Sub y Colas)
type MessageBus interface {
	EventPublisher
	EventSubscriber
	QueueProducer
	QueueConsumer
	Ping(ctx context.Context) error
	Close() error
}

// Config estructura de parámetros para inicializar el bus de mensajería
type Config struct {
	Type                   string // "local_redis" o "azure_servicebus"
	RedisAddr              string // Host:puerto de Redis (ej. "redis:6379")
	RedisPassword          string
	RedisDB                int
	ServiceBusFQDN         string // ej. "sb-univ-dev-ncus.servicebus.windows.net"
	ServiceBusConnString   string
	UseManagedIdentity     bool
	MaxConcurrentReceivers int
}
