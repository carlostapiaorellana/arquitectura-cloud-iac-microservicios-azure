# Módulo Terraform: mysql_flexible_database

Módulo atómico para aprovisionar una base de datos lógica individual en un servidor **Azure Database for MySQL - Flexible Server**, cumpliendo con el patrón de aislamiento **Database-per-Service** (`auth_db`, `person_db`, `academic_db`, `enrollment_db`, `finance_db`).

## Características
- Configuración canónica de codificación `utf8mb4` y ordenamiento `utf8mb4_unicode_ci`.
- Diseño atómico instanciable de forma modular o iterativa por cada microservicio.

## Entradas
- `database_name` / `name`: Nombre de la base de datos lógica.
- `resource_group_name`: Nombre del Resource Group contenedor.
- `server_name`: Nombre del servidor MySQL Flexible Server.
- `charset`: Juego de caracteres (default `utf8mb4`).
- `collation`: Collation (default `utf8mb4_unicode_ci`).

## Salidas
- `id` / `database_id`: ID del recurso de base de datos en Azure.
- `name` / `database_name`: Nombre de la base de datos creada.
- `server_name`: Nombre del servidor asociado.
