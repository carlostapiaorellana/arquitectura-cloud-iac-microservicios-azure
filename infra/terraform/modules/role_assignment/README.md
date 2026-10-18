# Módulo Terraform: `role_assignment` (Azure RBAC Least-Privilege Role Assignment)

## Propósito
Aprovisiona una asignación de rol de mínimo privilegio (`azurerm_role_assignment`) acotada al recurso específico (Topic/Subscription/Queue de Service Bus, Key Vault, ACR), validando que se especifique exactamente uno de `role_definition_name` o `role_definition_id` y bloqueando la asignación de roles administrativos amplios (`Owner`, `Contributor`, `User Access Administrator`).

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `scope` | `string` | Sí | — | ID del recurso específico donde aplica el rol. |
| `principal_id` | `string` | Sí | — | Object ID (Principal ID) de la identidad. |
| `role_definition_name` | `string` | Condicional | `null` | Nombre del rol RBAC integrado (excluyente con `role_definition_id`). |
| `role_definition_id` | `string` | Condicional | `null` | ID de definición del rol RBAC (excluyente con `role_definition_name`). |
| `principal_type` | `string` | No | `null` | Tipo de principal (`ServicePrincipal`, `User`, etc.). |
| `skip_service_principal_aad_check` | `bool` | No | `false` | Omite comprobación previa en Entra ID para SPs nuevos. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` | ID de la asignación de rol en Azure. |
| `role_definition_name` | Nombre del rol asignado. |
| `principal_id` | Object ID del sujeto. |
| `scope` | Alcance del permiso otorgado. |
