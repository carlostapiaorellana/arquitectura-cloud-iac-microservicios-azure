# Módulo Terraform: `private_dns_zone` (Azure Private DNS Zone)

## Propósito
Aprovisiona una Zona DNS Privada (`azurerm_private_dns_zone`) para la resolución interna de servicios PaaS expuestos vía Private Link / VNet Injection (`privatelink.mysql.database.azure.com`, `privatelink.vaultcore.azure.net`, `privatelink.documents.azure.com`, `privatelink.servicebus.windows.net`).

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `dns_zone_name` | `string` | Sí (o `name`) | `null` | Nombre FQDN de la zona DNS privada. |
| `name` | `string` | No | `null` | Alias opcional del nombre FQDN de la zona DNS privada. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `dns_zone_id` | ID de recurso de la Zona DNS Privada. |
| `name` / `dns_zone_name` | Nombre FQDN de la Zona DNS Privada. |
