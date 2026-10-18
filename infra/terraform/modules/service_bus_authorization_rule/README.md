# Módulo Terraform: service_bus_authorization_rule

Módulo atómico condicional para aprovisionar reglas de autorización SAS (**Shared Access Signature**) en un namespace de **Azure Service Bus**, reservado exclusivamente para clientes legacy que no soporten autenticación moderna con Microsoft Entra ID RBAC.

## Características
- Creación condicional mediante `enable_rule` (default `true` al instanciar el módulo).
- Precondiciones de seguridad: Prohíbe conceder `manage = true` si `listen` o `send` son falsos.
- Exportación segura y sensible de claves primarias y cadenas de conexión.

## Entradas
- `rule_name` / `name`: Nombre de la regla de autorización (ej. `auth-rule-external-sender`).
- `namespace_id`: ID del Service Bus Namespace.
- `listen`: Permiso de escucha (default `false`).
- `send`: Permiso de envío (default `false`).
- `manage`: Permiso de gestión (default `false`).
- `enable_rule`: Flag booleano para habilitar/deshabilitar la regla (default `true`).

## Salidas
- `id` / `auth_rule_id`: ID del recurso de la regla.
- `name`: Nombre de la regla.
- `primary_connection_string`: Cadena de conexión primaria sensible.
- `primary_key`: Clave primaria sensible.
