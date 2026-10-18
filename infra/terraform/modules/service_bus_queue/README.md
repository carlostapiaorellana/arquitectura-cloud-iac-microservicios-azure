# Módulo Terraform: service_bus_queue

Módulo atómico para aprovisionar una cola transaccional **Azure Service Bus Queue** (`payments.processing`) con modo Peek-Lock, deduplicación y enrutamiento a Dead-Letter Queue (DLQ).

## Características
- Vinculación obligatoria mediante `namespace_id` conforme a `azurerm ~> 4.0`.
- Procesamiento transaccional en modo Peek-Lock (`lock_duration = "PT1M"`).
- Protección anti-doble procesamiento con `requires_duplicate_detection = true` y ventana `PT10M`.
- Aislamiento de mensajes envenenados tras 5 reintentos en `$DeadLetterQueue`.

## Entradas
- `queue_name` / `name`: Nombre de la cola (ej. `payments.processing`).
- `namespace_id`: ID del Service Bus Namespace.
- `lock_duration`: Duración de bloqueo Peek-Lock (default `PT1M`).
- `max_delivery_count`: Intentos máximos de entrega antes de DLQ (default 5).
- `requires_duplicate_detection`: Habilita deduplicación (default `true`).

## Salidas
- `id` / `queue_id`: ID de la cola en Azure.
- `name` / `queue_name`: Nombre de la cola.
