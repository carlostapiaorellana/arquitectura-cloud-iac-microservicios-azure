# Módulo Terraform: `subnet` (Azure Subnet)

## Propósito
Aprovisiona una subred segmentada (`azurerm_subnet`) dentro de una Virtual Network de Azure con salida por defecto deshabilitada (`default_outbound_access_enabled = false`) por seguridad Zero-Trust, políticas de red habilitadas para Private Endpoints (`private_endpoint_network_policies = "Enabled"`) y soporte dinámico de delegación de servicios (`Microsoft.App/environments`, `Microsoft.DBforMySQL/flexibleServers`).

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `subnet_name` | `string` | Sí (o `name`) | `null` | Nombre de la subred (`snet-apim`, `snet-aca`, `snet-data`, `snet-pe`). |
| `name` | `string` | No | `null` | Alias opcional para el nombre de la subred. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `virtual_network_name` | `string` | Sí | — | Nombre de la VNet padre. |
| `address_prefixes` | `list(string)` | Sí | — | Prefijos CIDR de la subred. |
| `service_endpoints` | `list(string)` | No | `[]` | Lista de Service Endpoints opcionales. |
| `private_endpoint_network_policies` | `string` | No | `"Enabled"` | Políticas de red sobre Private Endpoints. |
| `default_outbound_access_enabled` | `bool` | No | `false` | Bloquea salida implícita no controlada a Internet. |
| `delegation` | `object` | No | `null` | Objeto opcional para delegar la subred a un servicio PaaS/Serverless. |
| `delegations` | `list(object)` | No | `[]` | Lista opcional de delegaciones de subred. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `subnet_id` | ID de recurso de la subred. |
| `name` / `subnet_name` | Nombre de la subred creada. |
| `address_prefixes` | Prefijos CIDR configurados en la subred. |
