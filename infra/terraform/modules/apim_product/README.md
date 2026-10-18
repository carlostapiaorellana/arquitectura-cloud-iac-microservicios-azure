# Módulo Terraform: apim_product (Módulo 37)

Crea y administra productos lógicos en **Azure API Management** para agrupar APIs bajo un esquema de gobierno unificado.

## Características Técnicas
- **Gobierno de Consumo**: Agrupa APIs (`university-core-apis`, `university-financial-apis`).
- **Control de Suscripción**: Controla si se requiere suscripción (`subscription_required`), aprobación administrativa y límite de suscripciones.
- **Asociación Declarativa**: Vincula automáticamente las APIs indicadas mediante recursos `azurerm_api_management_product_api`.

## Entradas Principales
- `product_id` / `name`: Identificador único del producto.
- `api_management_name`: Instancia de APIM padre.
- `resource_group_name`: Resource Group contenedor.
- `display_name`: Título visual del producto.
- `subscription_required`: Requiere claves de acceso (default `true`).
- `api_names`: Lista de nombres de APIs a asociar.

## Salidas
- `id`: Resource ID del producto.
- `product_id`: Identificador del producto.
- `display_name`: Nombre visible.
- `api_names`: Lista de APIs asociadas.
