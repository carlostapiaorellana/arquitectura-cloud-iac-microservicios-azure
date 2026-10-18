# Módulo Terraform: `user_assigned_identity` (Azure User-Assigned Managed Identity)

## Propósito
Aprovisiona una identidad administrada independiente (`azurerm_user_assigned_identity`) por microservicio (`id-gateway`, `id-auth`, `id-person`, `id-academic`, `id-enrollment`, `id-finance`, `id-library`, `id-lms`), eliminando por completo el uso de credenciales estáticas o cadenas de conexión con claves SAS hacia Azure Service Bus, Key Vault, Cosmos DB y ACR.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `identity_name` | `string` | Sí (o `name`) | `null` | Nombre de la User-Assigned Managed Identity. |
| `name` | `string` | No | `null` | Alias opcional del nombre de la identidad. |
| `location` | `string` | No | `"northcentralus"` | Región de Azure. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `identity_id` | ID de recurso de la identidad administrada. |
| `name` | Nombre de la identidad administrada. |
| `principal_id` | Object ID del Service Principal para asignaciones RBAC. |
| `client_id` | Client ID para autenticar con `DefaultAzureCredential` (`AZURE_CLIENT_ID`). |
| `tenant_id` | Tenant ID en Microsoft Entra ID. |
