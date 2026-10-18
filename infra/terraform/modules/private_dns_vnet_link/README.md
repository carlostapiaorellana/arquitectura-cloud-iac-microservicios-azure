# Módulo Terraform: `private_dns_vnet_link` (Azure Private DNS Zone VNet Link)

## Propósito
Enlaza una Zona DNS Privada (`azurerm_private_dns_zone`) con una Virtual Network (`azurerm_virtual_network`) mediante `azurerm_private_dns_zone_virtual_network_link`, manteniendo `registration_enabled = false` por defecto para zonas `privatelink.*`.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `link_name` | `string` | Sí (o `name`) | `null` | Nombre del enlace VNet-DNS. |
| `name` | `string` | No | `null` | Alias opcional del nombre del enlace. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `private_dns_zone_name` | `string` | Sí | — | Nombre FQDN de la Zona DNS Privada. |
| `virtual_network_id` | `string` | Sí | — | ID de la Virtual Network a vincular. |
| `registration_enabled` | `bool` | No | `false` | Autorregistro DNS de VMs en la zona. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` | ID de recurso del enlace VNet-DNS. |
| `name` | Nombre del enlace VNet-DNS. |
