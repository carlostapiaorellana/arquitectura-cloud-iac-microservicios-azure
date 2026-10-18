# Módulo Terraform: `vnet` (Azure Virtual Network)

## Propósito
Aprovisiona una red virtual aislada (`azurerm_virtual_network`) en Microsoft Azure bajo las convenciones de nombres Cloud Adoption Framework (CAF) y el etiquetado obligatorio de `cloud-standards`. Constituye el perímetro de red privado para el Laboratorio 03 (`10.0.0.0/16`).

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `vnet_name` | `string` | Sí (o `name`) | `null` | Nombre de la VNet (ej. `vnet-univ-dev-ncus`). |
| `name` | `string` | No | `null` | Alias opcional para el nombre de la VNet. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group contenedor. |
| `location` | `string` | No | `"northcentralus"` | Región de Azure para el despliegue. |
| `address_space` | `list(string)` | Sí | — | Bloques CIDR de la VNet (ej. `["10.0.0.0/16"]`). |
| `dns_servers` | `list(string)` | No | `[]` | Servidores DNS personalizados opcionales. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `vnet_id` | ID de recurso de la Virtual Network en Azure. |
| `name` / `vnet_name` | Nombre de la Virtual Network creada. |
| `address_space` | Lista de bloques CIDR configurados en la VNet. |
| `location` | Región de Azure de la VNet. |
