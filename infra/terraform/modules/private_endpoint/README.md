# Módulo Terraform: `private_endpoint` (Azure Private Endpoint)

## Propósito
Aprovisiona un Azure Private Endpoint (`azurerm_private_endpoint`) en la subred dedicada `snet-pe` para exponer servicios PaaS (Key Vault, Cosmos DB, Service Bus Premium, ACR Premium) mediante direcciones IP privadas dentro de la VNet, con soporte de integración automática en Private DNS Zones (`private_dns_zone_group`) y asignación opcional de IP estática (`ip_configuration`).

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `endpoint_name` | `string` | Sí (o `name`) | `null` | Nombre del Private Endpoint. |
| `name` | `string` | No | `null` | Alias opcional para el nombre del Private Endpoint. |
| `location` | `string` | No | `"northcentralus"` | Región de Azure. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `subnet_id` | `string` | Sí | — | ID de la subred `snet-pe`. |
| `private_connection_resource_id` | `string` | Sí | — | ID del recurso PaaS de destino. |
| `subresource_names` | `list(string)` | Sí | — | Subrecursos a conectar (`["vault"]`, `["Sql"]`, etc.). |
| `is_manual_connection` | `bool` | No | `false` | Requiere aprobación manual de conexión. |
| `private_dns_zone_ids` | `list(string)` | No | `[]` | IDs de Zonas DNS Privadas a vincular. |
| `ip_configuration` | `object` | No | `null` | Objeto opcional de IP privada estática. |
| `ip_configurations` | `list(object)` | No | `[]` | Lista opcional de IPs privadas estáticas. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `private_endpoint_id` | ID de recurso del Private Endpoint. |
| `name` | Nombre del Private Endpoint. |
| `private_ip_address` | Dirección IP privada asignada al Private Endpoint. |
