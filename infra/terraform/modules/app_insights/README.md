# Módulo Terraform: app_insights

Módulo atómico para aprovisionar **Azure Application Insights** en modo **Workspace-based** vinculado a Azure Log Analytics para telemetría, APM y trazabilidad distribuida (`X-Correlation-Id`).

## Características
- Integración obligatoria con `workspace_id` de Log Analytics Workspace conforme a las mejores prácticas de AzureRM v4.
- Tipo de aplicación `web` por defecto.
- Retención optimizada a 30 días.
- Exportación segura y sensible de `instrumentation_key` y `connection_string`.

## Entradas
- `app_insights_name` / `name`: Nombre del componente.
- `resource_group_name`: Grupo de recursos.
- `location`: Región de Azure (default `northcentralus`).
- `workspace_id`: ID del Log Analytics Workspace.
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `app_insights_id`: ID del recurso.
- `app_id`: Application ID.
- `instrumentation_key`: Clave de instrumentación sensible.
- `connection_string`: Cadena de conexión sensible para OpenTelemetry y SDKs.
