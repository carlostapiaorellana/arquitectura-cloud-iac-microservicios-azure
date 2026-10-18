# Módulo Terraform: `nsg` (Azure Network Security Group)

## Propósito
Aprovisiona un contenedor base de Network Security Group (`azurerm_network_security_group`) por subred (`nsg-aca`, `nsg-data`, `nsg-pe`) desacoplado de las reglas individuales (`nsg_rule`) para evitar recreaciones accidentales y ciclos de dependencia.

## Variables de Entrada
| Nombre | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `nsg_name` | `string` | Sí (o `name`) | `null` | Nombre del Network Security Group. |
| `name` | `string` | No | `null` | Alias opcional para el nombre del NSG. |
| `location` | `string` | No | `"northcentralus"` | Región de Azure. |
| `resource_group_name` | `string` | Sí | — | Nombre del Resource Group. |
| `tags` | `map(string)` | Sí | — | Mapa con las 6 etiquetas obligatorias de `cloud-standards`. |

## Salidas (Outputs)
| Nombre | Descripción |
|---|---|
| `id` / `nsg_id` | ID de recurso del Network Security Group. |
| `name` / `nsg_name` | Nombre del Network Security Group creado. |
