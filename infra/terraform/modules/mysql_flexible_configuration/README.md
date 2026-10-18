# Módulo Terraform: mysql_flexible_configuration

Módulo atómico para aplicar parámetros de configuración y endurecimiento en **Azure Database for MySQL - Flexible Server**.

## Características
- Permite definir parámetros individuales o un mapa completo de configuraciones mediante `configurations`.
- Optimizado para parámetros de seguridad Zero-Trust:
  - `require_secure_transport = "ON"`
  - `tls_version = "TLSv1.2,TLSv1.3"`
  - `max_connections = "150"`

## Entradas
- `resource_group_name`: Nombre del Resource Group.
- `server_name`: Nombre del servidor MySQL Flexible Server.
- `configurations`: Mapa de pares clave-valor de configuración.
- `configuration_name`: (Opcional) Nombre de configuración individual.
- `value`: (Opcional) Valor de configuración individual.

## Salidas
- `configurations`: Mapa de configuraciones aplicadas.
- `ids`: Mapa de IDs de recurso generados.
