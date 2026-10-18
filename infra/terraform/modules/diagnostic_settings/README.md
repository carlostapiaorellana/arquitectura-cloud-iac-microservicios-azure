# Módulo Terraform: diagnostic_settings

Módulo atómico para configurar el envío declarativo de registros de auditoría y métricas desde recursos de Azure hacia **Azure Log Analytics Workspace**, cuentas de almacenamiento o Event Hubs.

## Características
- Soporte para categorías específicas de logs o grupos de categorías (`allLogs`, `audit`).
- Soporte para categorías de métricas (`AllMetrics`).
- Verificación de precondición para garantizar que al menos un destino esté configurado.

## Entradas
- `name`: Nombre de la configuración diagnóstica.
- `target_resource_id`: ID del recurso de Azure a monitorear.
- `log_analytics_workspace_id`: ID del Log Analytics Workspace destino.
- `log_categories`: Lista de categorías individuales de logs.
- `log_category_groups`: Lista de grupos de categorías de logs.
- `metric_categories`: Lista de categorías de métricas (default `["AllMetrics"]`).

## Salidas
- `id` / `diagnostic_setting_id`: ID de la configuración creada.
- `name`: Nombre de la configuración.
- `target_resource_id`: ID del recurso monitoreado.
