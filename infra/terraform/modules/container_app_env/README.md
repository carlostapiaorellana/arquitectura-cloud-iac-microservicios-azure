# Módulo Terraform: container_app_env

Módulo atómico para aprovisionar el entorno serverless **Azure Container App Environment (ACA Env)** inyectado en red virtual (`snet-aca`) con perfil `Consumption`.

## Características
- Inyección directa en red virtual mediante `infrastructure_subnet_id` (`snet-aca` /23 delegada a `Microsoft.App/environments`).
- Integración con Azure Log Analytics Workspace para trazabilidad y logs centralizados.
- Perfil serverless `Consumption` que aprovecha el nivel gratuito mensual de 180,000 vCPU-segundos y 360,000 GiB-segundos ($0.00 en reposo).

## Entradas
- `environment_name` / `name`: Nombre del entorno (ej. `cae-univ-dev-ncus`).
- `resource_group_name`: Grupo de recursos contenedor.
- `location`: Región de Azure (default `northcentralus`).
- `log_analytics_workspace_id`: ID del espacio de Log Analytics.
- `infrastructure_subnet_id`: ID de la subred delegada (`snet-aca`).
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `aca_env_id`: ID del entorno en Azure.
- `name` / `aca_env_name`: Nombre del entorno.
- `default_domain`: Dominio DNS base para microservicios.
- `static_ip_address`: Dirección IP estática de salida.
