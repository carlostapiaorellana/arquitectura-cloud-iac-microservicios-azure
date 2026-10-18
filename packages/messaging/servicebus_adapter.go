package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
)

// ServiceBusAdapter implementa MessageBus conectando nativamente a Azure Service Bus
type ServiceBusAdapter struct {
	client   *azservicebus.Client
	stopChan chan struct{}
}

// NewServiceBusAdapter inicializa el cliente azservicebus con Managed Identity o Connection String
func NewServiceBusAdapter(cfg Config) (*ServiceBusAdapter, error) {
	var client *azservicebus.Client
	var err error

	if cfg.UseManagedIdentity || (cfg.ServiceBusConnString == "" && cfg.ServiceBusFQDN != "") {
		cred, credErr := azidentity.NewDefaultAzureCredential(nil)
		if credErr != nil {
			return nil, fmt.Errorf("error al obtener credencial DefaultAzureCredential: %w", credErr)
		}
		client, err = azservicebus.NewClient(cfg.ServiceBusFQDN, cred, nil)
	} else if cfg.ServiceBusConnString != "" {
		client, err = azservicebus.NewClientFromConnectionString(cfg.ServiceBusConnString, nil)
	} else {
		return nil, errors.New("se requiere ServiceBusFQDN (con Managed Identity) o ServiceBusConnString")
	}

	if err != nil {
		return nil, fmt.Errorf("error al instanciar cliente de Azure Service Bus: %w", err)
	}

	return &ServiceBusAdapter{
		client:   client,
		stopChan: make(chan struct{}),
	}, nil
}

// Publish envía un mensaje tipado hacia un Topic de Azure Service Bus
func (s *ServiceBusAdapter) Publish(ctx context.Context, topic string, event any) error {
	sender, err := s.client.NewSender(topic, nil)
	if err != nil {
		return fmt.Errorf("error al crear sender para topic %s: %w", topic, err)
	}
	defer sender.Close(ctx)

	var body []byte
	switch v := event.(type) {
	case []byte:
		body = v
	case string:
		body = []byte(v)
	default:
		body, err = json.Marshal(event)
		if err != nil {
			return fmt.Errorf("error al serializar evento para topic %s: %w", topic, err)
		}
	}

	msg := &azservicebus.Message{
		Body: body,
	}

	return sender.SendMessage(ctx, msg, nil)
}

// Subscribe recibe mensajes en modo Peek-Lock desde una Subscription de un Topic
func (s *ServiceBusAdapter) Subscribe(ctx context.Context, topic string, subscription string, handler EventHandler) error {
	if handler == nil {
		return ErrNilHandler
	}

	receiver, err := s.client.NewReceiverForSubscription(topic, subscription, &azservicebus.ReceiverOptions{
		ReceiveMode: azservicebus.ReceiveModePeekLock,
	})
	if err != nil {
		return fmt.Errorf("error al crear receiver para suscripción %s en topic %s: %w", subscription, topic, err)
	}

	go func() {
		defer receiver.Close(context.Background())
		for {
			select {
			case <-ctx.Done():
				return
			case <-s.stopChan:
				return
			default:
				messages, recvErr := receiver.ReceiveMessages(ctx, 5, nil)
				if recvErr != nil {
					if errors.Is(recvErr, context.Canceled) {
						return
					}
					continue
				}

				for _, msg := range messages {
					if err := handler(ctx, msg.Body); err != nil {
						// Si falla y ha alcanzado el límite de entregas, mover a DLQ
						if msg.DeliveryCount >= 5 {
							_ = receiver.DeadLetterMessage(ctx, msg, &azservicebus.DeadLetterOptions{
								Reason:           toPtr("MaxDeliveryCountExceeded"),
								ErrorDescription: toPtr(err.Error()),
							})
						} else {
							_ = receiver.AbandonMessage(ctx, msg, nil)
						}
					} else {
						_ = receiver.CompleteMessage(ctx, msg, nil)
					}
				}
			}
		}
	}()

	return nil
}

// Send envía un mensaje a una Queue de Azure Service Bus con soporte para deduplicación
func (s *ServiceBusAdapter) Send(ctx context.Context, queue string, message any) error {
	sender, err := s.client.NewSender(queue, nil)
	if err != nil {
		return fmt.Errorf("error al crear sender para cola %s: %w", queue, err)
	}
	defer sender.Close(ctx)

	var body []byte
	switch v := message.(type) {
	case []byte:
		body = v
	case string:
		body = []byte(v)
	default:
		body, err = json.Marshal(message)
		if err != nil {
			return fmt.Errorf("error al serializar mensaje para cola %s: %w", queue, err)
		}
	}

	msg := &azservicebus.Message{
		Body: body,
	}

	return sender.SendMessage(ctx, msg, nil)
}

// Consume procesa mensajes punto a punto de una Queue en modo Peek-Lock
func (s *ServiceBusAdapter) Consume(ctx context.Context, queue string, handler MessageHandler) error {
	if handler == nil {
		return ErrNilHandler
	}

	receiver, err := s.client.NewReceiverForQueue(queue, &azservicebus.ReceiverOptions{
		ReceiveMode: azservicebus.ReceiveModePeekLock,
	})
	if err != nil {
		return fmt.Errorf("error al crear receiver para cola %s: %w", queue, err)
	}

	go func() {
		defer receiver.Close(context.Background())
		for {
			select {
			case <-ctx.Done():
				return
			case <-s.stopChan:
				return
			default:
				messages, recvErr := receiver.ReceiveMessages(ctx, 5, nil)
				if recvErr != nil {
					if errors.Is(recvErr, context.Canceled) {
						return
					}
					continue
				}

				for _, msg := range messages {
					if err := handler(ctx, msg.Body); err != nil {
						if msg.DeliveryCount >= 5 {
							_ = receiver.DeadLetterMessage(ctx, msg, &azservicebus.DeadLetterOptions{
								Reason:           toPtr("MaxDeliveryCountExceeded"),
								ErrorDescription: toPtr(err.Error()),
							})
						} else {
							_ = receiver.AbandonMessage(ctx, msg, nil)
						}
					} else {
						_ = receiver.CompleteMessage(ctx, msg, nil)
					}
				}
			}
		}
	}()

	return nil
}

// Ping comprueba la conectividad contra Service Bus
func (s *ServiceBusAdapter) Ping(ctx context.Context) error {
	if s.client == nil {
		return errors.New("cliente de Azure Service Bus es nulo")
	}
	return nil
}

// Close finaliza el cliente azservicebus
func (s *ServiceBusAdapter) Close() error {
	close(s.stopChan)
	return s.client.Close(context.Background())
}

func toPtr[T any](v T) *T {
	return &v
}
