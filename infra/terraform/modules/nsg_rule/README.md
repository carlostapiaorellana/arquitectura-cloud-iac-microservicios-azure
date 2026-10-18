# Módulo Terraform: `nsg_rule` (Azure Network Security Rule)

## Propósito
Aprovisiona una regla atómica de filtrado de capa 4 (`azurerm_network_security_rule`) dentro de un Network Security Group existente, incorporando una precondición de seguridad Zero-Trust que impide la apertura accidental de puertos de administración o bases de datos (`22`, `3389`, `3306`, `5432`, `6379`, `*`) desde `0.0.0.0/0` o `Internet`.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `name` | `string` | Sí | — | Nombre de la regla NSG. |
| `priority` | `number` | Sí | — | Prioridad de evaluación (`100` a `4096`). |
| `direction` | `string` | Sí | — | Dirección (`Inbound` o `Outbound`). |
| `access` | `string` | Sí | — | Acción (`Allow` o `Deny`). |
| `protocol` | `string` | Sí | — | Protocolo (`Tcp`, `Udp`, `Icmp`, `*`). |
| `source_port_range` | `string` | No | `"*"` | Puerto o rango de puertos de origen. |
| `destination_port_range` | `string` | Sí | — | Puerto o rango de puertos de destino. |
| `source_address_prefix` | `string` | Sí | — | CIDR o Service Tag de origen. |
| `destination_address_prefix` | `string` | Sí | — | CIDR o Service Tag de destino. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `network_security_group_name` | `string` | Sí | — | Nombre del NSG destino. |
| `description` | `string` | No | `null` | Descripción opcional de la regla. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` | ID de recurso de la regla NSG. |
| `name` | Nombre de la regla NSG. |
| `priority` | Prioridad configurada de la regla. |
