# Módulo Terraform: log_analytics_workspace

Módulo atómico para aprovisionar el repositorio centralizado de telemetría y logs **Azure Log Analytics Workspace** bajo el modelo FinOps de protección presupuestaria (`Azure for Students`).

## Características
- SKU estándar `PerGB2018`.
- Retención optimizada a 30 días para cumplimiento mínimo y control de costos.
- Cuota diaria de ingesta estricta (`daily_quota_gb = 0.1` GB/día) para evitar agotamiento inadvertido del crédito de $100 USD.
- Exportación segura del Customer ID y claves de ingesta compartidas.

## Entradas
- `workspace_name` / `name`: Nombre del espacio de trabajo.
- `resource_group_name`: Grupo de recursos contenedor.
- `location`: Región de Azure (default `northcentralus`).
- `retention_in_days`: Días de retención (default 30).
- `daily_quota_gb`: Límite máximo de ingesta diario (default 0.1 GB).
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `workspace_id`: ID del recurso en Azure.
- `workspace_customer_id`: GUID de cliente para configuración de diagnósticos y agentes.
- `primary_shared_key`: Clave compartida primaria sensible.
