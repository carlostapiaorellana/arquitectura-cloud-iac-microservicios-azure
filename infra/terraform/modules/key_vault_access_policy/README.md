# Módulo Terraform: `key_vault_access_policy` (Azure Key Vault Access Policy)

## Propósito
Aprovisiona una política de acceso granular (`azurerm_key_vault_access_policy`) para escenarios de compatibilidad donde un Key Vault opere con Access Policies (`enable_rbac_authorization = false`), restringiendo permisos de lectura por defecto (`["Get", "List"]`) y bloqueando el permiso `Purge`.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `key_vault_id` | `string` | Sí | — | ID de recurso del Key Vault. |
| `tenant_id` | `string` | Sí | — | UUID del Tenant de Entra ID. |
| `object_id` | `string` | Sí | — | Object ID (Principal ID) del sujeto. |
| `key_permissions` | `list(string)` | No | `[]` | Permisos sobre claves. |
| `secret_permissions` | `list(string)` | No | `["Get", "List"]` | Permisos sobre secretos. |
| `certificate_permissions` | `list(string)` | No | `[]` | Permisos sobre certificados. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` | ID de recurso de la política de acceso en Key Vault. |
