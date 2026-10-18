# Módulo Terraform: service_bus_subscription

Módulo atómico para aprovisionar suscripciones independientes en un tópico de **Azure Service Bus**, con Dead-Letter Queue (DLQ) y modo Peek-Lock para microservicios consumidores de eventos.

## Características
- Vinculación directa mediante `topic_id` conforme al estándar `azurerm ~> 4.0`.
- Control de reintentos mediante `max_delivery_count = 5`.
- Bloqueo de mensaje en modo Peek-Lock de 1 minuto (`lock_duration = "PT1M"`).
- Redirección automática a la sub-cola DLQ (`$DeadLetterQueue`) ante expiración de mensajes o errores de filtro.

## Entradas
- `subscription_name` / `name`: Nombre de la suscripción (ej. `sub-enrollment-student`).
- `topic_id`: ID del Service Bus Topic emisor.
- `max_delivery_count`: Intentos máximos de entrega antes de DLQ (default 5).
- `lock_duration`: Duración de bloqueo Peek-Lock (default `PT1M`).
- `dead_lettering_on_message_expiration`: Envío a DLQ por expiración (default `true`).

## Salidas
- `id` / `subscription_id`: ID de la suscripción en Azure.
- `name` / `subscription_name`: Nombre de la suscripción.
