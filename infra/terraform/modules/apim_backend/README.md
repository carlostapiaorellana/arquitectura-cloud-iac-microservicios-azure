# Módulo Terraform: apim_backend

Módulo atómico para registrar el **Backend HTTP/HTTPS** en **Azure API Management (APIM)** apuntando al FQDN de `ca-api-gateway` en Azure Container Apps con validación estricta de TLS.

## Características
- Configuración del endpoint de backend único para enrutar el tráfico norte-sur desde APIM hacia el gateway de la plataforma.
- Validación de seguridad TLS completa (`validate_certificate_chain = true`, `validate_certificate_name = true`).

## Entradas
- `backend_name` / `name`: Nombre del backend (ej. `backend-api-gateway`).
- `api_management_name`: Nombre de la instancia de APIM.
- `resource_group_name`: Grupo de recursos.
- `url`: URL HTTPS del API Gateway en ACA.
- `protocol`: Protocolo (`http` o `soap`).

## Salidas
- `id` / `backend_id`: ID del backend en Azure.
- `name` / `backend_name`: Nombre del backend.
- `url`: URL configurada.
