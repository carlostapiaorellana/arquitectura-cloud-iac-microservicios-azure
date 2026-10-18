# Módulo Terraform: apim_service (Módulo 34)

Aprovisiona la instancia de **Azure API Management** perimetral para la plataforma universitaria.

## Características Técnicas
- **SKU Efímero FinOps**: Opera en `Consumption_0` ($0.00 hasta 1M llamadas/mes gratis, ideal para `Azure for Students`).
- **Identidad Administrada**: Configura System-Assigned Identity para autorización con Key Vault y App Insights.
- **Seguridad**: TLS 1.2+ obligatorio, control de versión mínima de API y cero exposición de credenciales estáticas.

## Entradas Principales
- `service_name` / `name`: Nombre del recurso APIM (`apim-univ-dev-ncus`).
- `resource_group_name`: Nombre del grupo de recursos (`rg-univ-dev-ncus`).
- `location`: `"northcentralus"`.
- `publisher_name` / `publisher_email`: Metadatos de contacto.
- `sku_name`: `"Consumption_0"` (default).
- `tags`: Mapa con las 6 etiquetas obligatorias de `cloud-standards`.

## Salidas
- `id`: Resource ID del servicio.
- `name`: Nombre del servicio.
- `gateway_url`: Endpoint HTTPS público del Gateway.
- `identity_principal_id`: Principal ID de la identidad administrada.
