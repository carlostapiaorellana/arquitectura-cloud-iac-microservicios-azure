# Módulo Terraform: `key_vault` (Azure Key Vault Zero-Trust)

## Propósito
Aprovisiona un almacén criptográfico `azurerm_key_vault` endurecido bajo el modelo Zero-Trust: autorización delegada a Microsoft Entra ID RBAC (`rbac_authorization_enabled = true`), protección contra purga activada (`purge_protection_enabled = true`), retención de eliminación suave (`7..90` días) y firewall de red con denegación por defecto (`network_acls.default_action = "Deny"`).

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `key_vault_name` | `string` | Sí (o `name`) | `null` | Nombre del Key Vault (`3..24` caracteres). |
| `name` | `string` | No | `null` | Alias opcional para el nombre del Key Vault. |
| `location` | `string` | No | `"northcentralus"` | Región de Azure. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `tenant_id` | `string` | Sí | — | UUID del Tenant de Entra ID. |
| `sku_name` | `string` | No | `"standard"` | SKU (`standard` o `premium`). |
| `enable_rbac_authorization` | `bool` | No | `true` | Autorización data-plane mediante Azure RBAC. |
| `purge_protection_enabled` | `bool` | No | `true` | Protección contra purga permanente. |
| `soft_delete_retention_days` | `number` | No | `7` | Días de retención soft-delete (`7..90`). |
| `public_network_access_enabled` | `bool` | No | `false` | Habilita/deshabilita acceso de red pública. |
| `network_acls` | `object` | No | `{ default_action = "Deny", bypass = "AzureServices", ... }` | Reglas de firewall de red del Key Vault. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `key_vault_id` | ID de recurso del Key Vault. |
| `name` / `key_vault_name` | Nombre del Key Vault. |
| `vault_uri` / `key_vault_uri` | URI HTTPS del Key Vault. |
