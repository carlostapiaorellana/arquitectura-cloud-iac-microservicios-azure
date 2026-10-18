# Módulo Terraform: service_bus_topic

Módulo atómico para aprovisionar un tópico Pub/Sub de **Azure Service Bus Topic** (`student.events`, `enrollment.events`) con soporte para ordenamiento y detección de duplicados para Event-Driven Architecture (EDA).

## Características
- Vinculación obligatoria mediante `namespace_id` conforme a `azurerm ~> 4.0`.
- Soporte para ordenamiento estricto de mensajes (`support_ordering = true`).
- Deduplicación nativa de mensajes mediante ventana configurable (`duplicate_detection_history_time_window = "PT10M"`).
- Tiempo de vida de mensajes predeterminado de 14 días (`default_message_ttl = "P14D"`).

## Entradas
- `topic_name` / `name`: Nombre del tópico de dominio.
- `namespace_id`: ID del Service Bus Namespace.
- `support_ordering`: Habilita ordenamiento de mensajes (default `true`).
- `requires_duplicate_detection`: Habilita detección de duplicados (default `true`).
- `duplicate_detection_history_time_window`: Ventana de deduplicación (default `PT10M`).
- `max_size_in_megabytes`: Tamaño máximo del tópico en MB (default `1024`).

## Salidas
- `id` / `topic_id`: ID del tópico en Azure.
- `name` / `topic_name`: Nombre del tópico.
