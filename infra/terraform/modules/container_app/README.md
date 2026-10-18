# Módulo Terraform: container_app

Módulo atómico para desplegar microservicios en **Azure Container Apps** con soporte para escalado a cero (`min_replicas = 0`), pull seguro desde ACR vía Managed Identity e Ingress Zero-Trust.

## Características
- Escalado serverless a cero en reposo (`min_replicas = 0`, `max_replicas = 3`) con tamaño mínimo `0.25 vCPU` y `0.5Gi` RAM para optimización FinOps ($0.00 en reposo).
- Regla dura de seguridad Zero-Trust: Ingress público (`external_enabled = true`) exclusivo para el API Gateway (`service_role = "gateway"`). Microservicios internos forzados a `external_enabled = false`.
- Probes integrados de `liveness` y `readiness` para resiliencia operativa.
- Soporte para secretos montados desde Azure Key Vault mediante identidades administradas.

## Entradas
- `app_name` / `name`: Nombre de la aplicación (ej. `ca-api-gateway`).
- `container_app_environment_id`: ID del entorno ACA.
- `resource_group_name`: Grupo de recursos.
- `image`: URL completa de la imagen de contenedor.
- `service_role`: Rol arquitectónico (`gateway`, `microservice`, `cache`).
- `external_enabled`: Exposición pública (default `false`).
- `min_replicas` / `max_replicas`: Límites de autoescalado.
- `environment_variables`: Variables de entorno.
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `container_app_id`: ID del recurso en Azure.
- `name` / `container_app_name`: Nombre de la aplicación.
- `ingress_fqdn` / `fqdn`: FQDN del servicio (público o interno).
