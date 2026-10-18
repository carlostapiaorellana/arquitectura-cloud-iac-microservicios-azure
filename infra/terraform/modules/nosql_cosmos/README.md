# Módulo Terraform: nosql_cosmos

Módulo atómico para aprovisionar una cuenta **Azure Cosmos DB NoSQL API**, base de datos y contenedores documentales bajo el beneficio de **Cosmos DB Free Tier** (1000 RU/s y 25 GB de almacenamiento incluidos a $0.00).

## Características
- Consistencia por defecto `Session`.
- Habilitación de `free_tier_enabled = true`.
- Base de datos `univ_nosql_db` con throughput compartido de 1000 RU/s.
- 4 contenedores particionados para los microservicios documentales:
  - `library_catalogs`: PK `/category` (Biblioteca NoSQL)
  - `library_loans`: PK `/studentId` (Préstamos Biblioteca)
  - `lms_courses`: PK `/sectionId` (Cursos y Sílabos LMS)
  - `lms_enrollments`: PK `/courseId` (Inscripciones y Evaluaciones LMS)
- Seguridad Zero-Trust con `public_network_access_enabled = false` por defecto.

## Entradas
- `account_name` / `name`: Nombre de la cuenta de Cosmos DB.
- `resource_group_name`: Grupo de recursos.
- `location`: Región de Azure (default `northcentralus`).
- `database_name`: Nombre de la base NoSQL (default `univ_nosql_db`).
- `throughput`: Throughput compartido (default `1000`).
- `containers`: Mapa de especificaciones de contenedores con rutas de partición.
- `tags`: Etiquetas obligatorias de gobernanza.

## Salidas
- `id` / `account_id` / `cosmos_account_id`: ID de la cuenta.
- `endpoint` / `cosmos_endpoint`: Endpoint HTTPS para los SDKs.
- `primary_key` / `cosmos_primary_key`: Clave primaria sensible.
- `database_id`: ID de la base de datos.
- `container_ids`: Mapa de IDs de los contenedores.
