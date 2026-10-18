# Módulo Terraform: apim_subscription (Módulo 38)

Genera y gestiona suscripciones de clientes consumidores autorizados en **Azure API Management**.

## Características Técnicas
- **Credenciales Seguras**: Emite claves de acceso primaria y secundaria (`primary_key`, `secondary_key`) marcadas estrictamente como `sensitive = true`.
- **Asociación Flexible**: Soporta vinculación tanto a un `product_id` (acceso a suite de APIs) como a un `api_id` específico.
- **Control de Estado**: Permite suspender o activar credenciales sin destruir el recurso.

## Entradas Principales
- `api_management_name`: Instancia de APIM padre.
- `resource_group_name`: Resource Group contenedor.
- `display_name`: Nombre de la suscripción (ej. "Portal Web Estudiantil").
- `product_id`: ID del producto vinculado (opcional si se usa `api_id`).
- `api_id`: ID de la API individual vinculada (opcional si se usa `product_id`).
- `state`: `"active"` (default).

## Salidas
- `id`: Resource ID de la suscripción.
- `subscription_id`: Identificador de la suscripción.
- `primary_key`: Clave primaria de suscripción (sensible).
- `secondary_key`: Clave secundaria de suscripción (sensible).
