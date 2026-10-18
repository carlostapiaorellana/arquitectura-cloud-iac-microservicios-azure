# Módulo Terraform: apim_logger

Módulo atómico para vincular **Azure API Management** con **Azure Application Insights**, habilitando trazabilidad distribuida extremo a extremo con correlación unificada (`X-Correlation-Id`).

## Características
- Integración con Application Insights mediante `instrumentation_key` y `connection_string` sensibles.
- Modo de eventos en buffer (`buffered = true`) para optimizar el rendimiento y reducir latencia.

## Entradas
- `logger_name` / `name`: Nombre del logger (ej. `apim-logger-appinsights`).
- `api_management_name`: Nombre de la instancia de APIM.
- `resource_group_name`: Grupo de recursos.
- `instrumentation_key`: Clave de instrumentación sensible de Application Insights.

## Salidas
- `id` / `logger_id`: ID del logger en Azure.
- `name` / `logger_name`: Nombre del logger.
