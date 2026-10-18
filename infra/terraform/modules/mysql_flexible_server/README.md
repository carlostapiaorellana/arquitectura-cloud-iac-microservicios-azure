# Módulo Terraform: mysql_flexible_server

Módulo atómico para aprovisionar un servidor **Azure Database for MySQL - Flexible Server** bajo el estándar Enterprise Tier-1 y las cuotas de la suscripción `Azure for Students` en `northcentralus`.

## Características
- SKU por defecto `B_Standard_B1ms` (1 vCore, 2 GiB RAM, 20 GB almacenamiento).
- Integración nativa con red privada mediante `delegated_subnet_id` (`snet-data`) y zona DNS privada `privatelink.mysql.database.azure.com`.
- Desactivación de acceso público por defecto (`public_network_access_enabled = false`).
- Retención de copias de seguridad de 7 días y copias geo-redundantes desactivadas para optimización FinOps ($0.00 extra).
- Soporte para etiquetas obligatorias de gobernanza (`cloud-standards`).

## Entradas Principales
- `server_name` / `name`: Nombre único del servidor (ej. `mysql-univ-dev-ncus`).
- `resource_group_name`: Grupo de recursos.
- `location`: Región de Azure (default `northcentralus`).
- `administrator_login`: Usuario administrador (default `mysqladmin`).
- `administrator_password`: Contraseña sensible del administrador.
- `delegated_subnet_id`: ID de la subred delegada (`snet-data`).
- `private_dns_zone_id`: ID de la zona DNS privada.
- `tags`: Mapa con las 6 etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `server_id`: ID del servidor.
- `name` / `server_name`: Nombre del servidor.
- `fqdn`: Fully Qualified Domain Name para cadenas de conexión.
