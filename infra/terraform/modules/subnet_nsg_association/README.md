# Módulo Terraform: `subnet_nsg_association` (Azure Subnet NSG Association)

## Propósito
Vincula declarativamente una subred (`azurerm_subnet`) con su correspondiente Network Security Group (`azurerm_network_security_group`) mediante `azurerm_subnet_network_security_group_association`.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `subnet_id` | `string` | Sí | — | ID de recurso de la subred en Azure. |
| `network_security_group_id` | `string` | Sí | — | ID de recurso del Network Security Group. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` | ID de la asociación Subred-NSG. |
| `subnet_id` | ID de la subred vinculada. |
| `network_security_group_id` | ID del NSG vinculado. |
