# Módulo Terraform: service_bus_namespace

Módulo atómico para aprovisionar el broker empresarial de mensajería asíncrona **Azure Service Bus Namespace** bajo el modelo de seguridad Zero-Trust (100% Microsoft Entra ID RBAC).

## Características
- SKU por defecto `Standard` (soporte completo de Topics y Subscriptions con 12.5M de operaciones mensuales incluidas).
- Autenticación SAS desactivada por defecto (`local_auth_enabled = false`) forzando el acceso mediante Managed Identities y roles Azure RBAC (`Azure Service Bus Data Sender` / `Data Receiver`).
- Restricción estricta de TLS: `minimum_tls_version = "1.2"`.
- Exportación del FQDN para la variable `SERVICEBUS_FQDN` consumida por los microservicios en Go.

## Entradas
- `namespace_name` / `name`: Nombre del namespace (ej. `sb-univ-dev-ncus`).
- `resource_group_name`: Grupo de recursos contenedor.
- `location`: Región de Azure (default `northcentralus`).
- `sku`: SKU del servicio (`Standard` o `Premium`).
- `local_auth_enabled`: Habilitación de SAS (default `false`).
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `namespace_id`: ID del namespace en Azure.
- `name` / `namespace_name`: Nombre del namespace.
- `endpoint`: URL del endpoint de conexión.
- `fqdn`: Fully Qualified Domain Name del broker.
