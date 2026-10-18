# Módulo Terraform: redis_cache

Módulo atómico para aprovisionar una instancia administrada de **Azure Cache for Redis** bajo el modelo de seguridad Zero-Trust.

## Características
- SKU por defecto `Basic C0` (250 MB) con compatibilidad para `Standard` o `Premium`.
- Restricción estricta de TLS: `minimum_tls_version = "1.2"`.
- Puerto inseguro desactivado por defecto (`non_ssl_port_enabled = false`).
- Desactivación de acceso público por defecto (`public_network_access_enabled = false`).
- Exportación segura de claves de acceso y cadenas de conexión sensibles.

## Entradas
- `redis_name` / `name`: Nombre de la instancia.
- `resource_group_name`: Grupo de recursos.
- `location`: Región de Azure (default `northcentralus`).
- `sku_name`: Nivel del servicio (`Basic`, `Standard`, `Premium`).
- `capacity`: Capacidad de cómputo del caché (0 para C0).
- `family`: Familia (`C` o `P`).
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `redis_id`: ID del recurso.
- `hostname` / `redis_hostname`: Nombre DNS del servicio.
- `ssl_port` / `redis_ssl_port`: Puerto TLS (6380).
- `primary_access_key`: Clave de acceso primaria sensible.
- `primary_connection_string`: Cadena de conexión sensible.
