# Módulo Terraform: `nat_gateway` (Azure NAT Gateway + Public IP)

## Propósito
Aprovisiona un Azure NAT Gateway (`azurerm_nat_gateway`) en SKU `Standard` junto con su dirección IP pública estática dedicada (`azurerm_public_ip`) y asociaciones opcionales a subredes privadas (`azurerm_subnet_nat_gateway_association`) para proporcionar salida SNAT determinista y evitar el agotamiento de puertos efímeros.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `nat_gateway_name` | `string` | Sí (o `name`) | `null` | Nombre del NAT Gateway. |
| `name` | `string` | No | `null` | Alias opcional para el nombre del NAT Gateway. |
| `public_ip_name` | `string` | No | `null` | Nombre de la Public IP (por defecto `pip-<name>`). |
| `location` | `string` | No | `"northcentralus"` | Región de Azure. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `sku_name` | `string` | No | `"Standard"` | SKU del NAT Gateway (`Standard`). |
| `idle_timeout_in_minutes` | `number` | No | `10` | Timeout de inactividad TCP (`4` a `120` min). |
| `zones` | `list(string)` | No | `[]` | Zonas de disponibilidad opcionales. |
| `subnet_ids` | `set(string)` | No | `[]` | Conjunto de IDs de subredes a asociar con el NAT Gateway. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `nat_gateway_id` | ID de recurso del NAT Gateway. |
| `name` | Nombre del NAT Gateway. |
| `public_ip_id` | ID de recurso de la IP pública asociada. |
| `public_ip_address` | Dirección IP pública estática asignada. |
