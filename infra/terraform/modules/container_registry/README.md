# Módulo Terraform: container_registry

Módulo atómico para aprovisionar un registro de contenedores privado **Azure Container Registry (ACR)** bajo el modelo Zero-Trust (sin credenciales de administración estáticas).

## Características
- SKU estándar `Basic` para desarrollo (10 GB incluidos en Azure for Students).
- Prohibición de usuario administrador por defecto (`admin_enabled = false`), forzando autenticación de los microservicios mediante Managed Identity con rol `AcrPull`.
- Validación estricta de nombres alfanuméricos entre 5 y 50 caracteres.

## Entradas
- `registry_name` / `name`: Nombre del registro (ej. `crunivdevncus`).
- `resource_group_name`: Grupo de recursos contenedor.
- `location`: Región de Azure (default `northcentralus`).
- `sku`: SKU del registro (`Basic`, `Standard` o `Premium`).
- `admin_enabled`: Habilita usuario admin (default `false`).
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `acr_id`: ID del registro en Azure.
- `name` / `acr_name`: Nombre del registro.
- `login_server` / `acr_login_server`: FQDN del servidor de login para Docker.
