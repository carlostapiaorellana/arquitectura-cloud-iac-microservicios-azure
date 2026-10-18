# Módulo Terraform: apim_api (Módulo 35)

Registra y publica definiciones de API versionadas en **Azure API Management**.

## Características Técnicas
- **Enrutamiento Perimetral**: Enruta prefijos HTTP (`/api/v1/auth`, `/api/v1/person`, `/api/v1/academic`, `/api/v1/enrollment`, `/api/v1/finance`, `/api/v1/library`, `/api/v1/lms`).
- **Seguridad**: Soporte parametrizado para exigir claves de suscripción (`subscription_required`), con nombres de cabecera y query string personalizables.
- **Protocolos**: TLS / HTTPS estricto.

## Entradas Principales
- `api_name` / `name`: Identificador único de la API.
- `api_management_name`: Instancia de APIM padre.
- `resource_group_name`: Resource Group contenedor.
- `display_name`: Título visual de la API.
- `path`: Ruta relativa del endpoint perimetral.
- `service_url`: URL del backend destino (opcional).

## Salidas
- `id`: Resource ID de la API.
- `name`: Nombre identificador.
- `path`: Ruta perimetral de acceso.
- `service_url`: URL del backend asignado.
