# Contrato de Configuración de Entornos (12-Factor App & Configuration by Contract)

## 1. Principio Fundamental: 12-Factor App (III. Configuración)

En la arquitectura de la **Plataforma Universitaria Cloud-Native (Lab 03)**, ningún microservicio ni componente de infraestructura contiene credenciales, URLs de red, cadenas de conexión o banderas de entorno hardcodeadas en su código fuente binario compilado.

El principio **III de The Twelve-Factor App** estipula una separación estricta de la configuración respecto al código:
1. **Código 100% Agnóstico**: La misma imagen de contenedor (`distroless/static-debian12:nonroot`) generada a partir de los binarios Go se ejecuta sin modificación alguna tanto en el entorno de desarrollo local con Docker Compose ($0.00/mes) como en el entorno de nube en Azure (`northcentralus`).
2. **Inyección por Contrato**: Toda la variabilidad del comportamiento en tiempo de ejecución se inyecta exclusivamente mediante **variables de entorno del sistema operativo**.
3. **Cero Secretos en Repositorio**: Los archivos `.env` reales están excluidos en `.gitignore`. Se proporcionan plantillas contractuales `.env.local.example` y `.env.azure.example`. En Azure, los secretos sensibles son resueltos mediante identidades administradas (User-Assigned Managed Identity) contra Azure Key Vault o inyectados como secretos seguros en Azure Container Apps.

---

## 2. Matriz Exhaustiva de Variables de Entorno

A continuación se detalla la matriz contractual de configuración requerida para los 7 microservicios de dominio (`auth`, `person`, `academic`, `enrollment`, `finance`, `library`, `lms`) y el API Gateway (`gateway`).

### 2.1 Conexión Relacional SQL (MySQL Flexible Server / MySQL Local)
Aplica a los microservicios relacionales: `auth-service`, `person-service`, `academic-service`, `enrollment-service` y `finance-service`.

| Variable | Tipo | Requerida | Propósito / Descripción |
|---|---|---|---|
| `DB_HOST` | `string` | Sí | Nombre de host o FQDN del servidor MySQL. |
| `DB_PORT` | `int` | Sí | Puerto TCP de escucha del motor MySQL. |
| `DB_NAME` | `string` | Sí | Nombre de la base de datos lógica asignada al microservicio (`auth_db`, `person_db`, `academic_db`, `enrollment_db`, `finance_db`). |
| `DB_USER` | `string` | Sí | Usuario de base de datos con privilegios exclusivamente DML (`*_user`). |
| `DB_PASSWORD` | `string` | Sí | Contraseña del usuario DML (gestionada en Key Vault en cloud). |
| `DB_MAX_OPEN_CONNS` | `int` | No | Número máximo de conexiones abiertas simultáneas en el pool de `sql.DB`. |
| `DB_MAX_IDLE_CONNS` | `int` | No | Número máximo de conexiones ociosas mantenidas en el pool de `sql.DB`. |
| `DB_CONN_MAX_LIFETIME` | `string` | No | Duración máxima de vida de una conexión (formato parseable por `time.ParseDuration`, ej. `5m`). |
| `DB_CONN_MAX_IDLE_TIME` | `string` | No | Tiempo máximo que una conexión puede permanecer inactiva antes de cerrarse (ej. `2m`). |

### 2.2 Persistencia NoSQL Documental (Cosmos DB NoSQL / DynamoDB Local)
Aplica a los microservicios NoSQL: `library-service` y `lms-service`.

| Variable | Tipo | Requerida | Propósito / Descripción |
|---|---|---|---|
| `NOSQL_ENDPOINT` | `string` | Sí | URI o endpoint HTTPS de acceso a la base de datos documental. |
| `NOSQL_KEY` | `string` | Condicional | Clave primaria/maestra de acceso (requerida en Cosmos DB con clave o emuladores locales). |
| `NOSQL_DATABASE_NAME` | `string` | Sí | Nombre de la base de datos documental (`library_db` o `lms_db`). |
| `NOSQL_USE_MANAGED_IDENTITY` | `bool` | No | Si es `true`, el cliente Cosmos DB utiliza DefaultAzureCredential en vez de `NOSQL_KEY`. |
| `NOSQL_REGION` | `string` | No | Región primaria de Azure o región emulada AWS para DynamoDB local (`northcentralus` / `us-east-1`). |

### 2.3 Mensajería y Eventos (Azure Service Bus / Redis Streams Local)
Aplica a todos los microservicios que publican o consumen eventos EDA (`person-service`, `auth-service`, `enrollment-service`, `academic-service`, `finance-service`, `library-service`, `lms-service`).

| Variable | Tipo | Requerida | Propósito / Descripción |
|---|---|---|---|
| `EVENT_BUS_TYPE` | `string` | Sí | Discriminador del motor de mensajería: `local_redis` para Docker local o `azure_servicebus` para Azure. |
| `SERVICEBUS_FQDN` | `string` | Condicional | FQDN del Namespace de Azure Service Bus (ej. `sb-univ-dev-ncus.servicebus.windows.net`). |
| `SERVICEBUS_CONNECTION_STRING`| `string` | Condicional | Connection String alternativa para entornos sin Managed Identity. |
| `REDIS_ADDR` | `string` | Condicional | Dirección TCP `host:port` del servidor Redis para Streams y Caché (ej. `redis:6379` o `ca-redis:6379`). |
| `REDIS_PASSWORD` | `string` | No | Contraseña de autenticación de Redis (opcional en red interna local). |
| `REDIS_DB` | `int` | No | Índice numérico de base de datos Redis (default `0`). |

### 2.4 Seguridad, Perímetro y Observabilidad
Aplica a todos los servicios y al API Gateway.

| Variable | Tipo | Requerida | Propósito / Descripción |
|---|---|---|---|
| `ENV` | `string` | Sí | Entorno de despliegue: `local`, `dev`, `staging`, `prod`. |
| `PORT` | `int` | Sí | Puerto TCP HTTP de escucha del microservicio (`8080` para gateway, `8081`..`8087` para microservicios). |
| `SERVICE_NAME` | `string` | Sí | Identificador canónico del servicio inyectado en logs estructurados `log/slog`. |
| `JWT_ISSUER` | `string` | Sí | Emisor válido esperado en tokens JWT (ej. `https://auth.universidad.edu.pe`). |
| `JWKS_URL` | `string` | Sí | Endpoint público/interno para recuperación de claves públicas RS256 (`/.well-known/jwks.json`). |
| `KEYVAULT_URI` | `string` | Condicional | URI del Azure Key Vault para carga de secretos de arranque (en perfil Azure). |
| `LOG_LEVEL` | `string` | No | Nivel de logging (`DEBUG`, `INFO`, `WARN`, `ERROR`). Default: `INFO`. |

---

## 3. Tabla Comparativa de Valores por Entorno

| Variable | Tipo | Default | Valor Local (Docker Compose) | Valor Azure (`northcentralus`) |
|---|---|---|---|---|
| `ENV` | `string` | `local` | `local` | `dev` |
| `SERVICE_NAME` | `string` | `service` | `auth-service` (según microservicio) | `auth-service` (según microservicio) |
| `PORT` | `int` | `8080` | `8080` (Gateway), `8081`–`8087` (Servicios) | `8080` (en contenedor Container App) |
| `LOG_LEVEL` | `string` | `INFO` | `DEBUG` | `INFO` |
| `DB_HOST` | `string` | `127.0.0.1` | `mysql` (red Docker interna) / `127.0.0.1:3307` (host) | `privatelink.mysql.database.azure.com` |
| `DB_PORT` | `int` | `3306` | `3306` | `3306` |
| `DB_NAME` | `string` | `univ_db` | `auth_db`, `person_db`, `academic_db`, etc. | `auth_db`, `person_db`, `academic_db`, etc. |
| `DB_USER` | `string` | `root` | `auth_user`, `person_user`, etc. | `auth_user`, `person_user`, etc. |
| `DB_PASSWORD` | `string` | `""` | `DevSecret2026!` (según servicio) | Inyectado vía Key Vault Secret |
| `DB_MAX_OPEN_CONNS` | `int` | `25` | `10` | `25` |
| `DB_MAX_IDLE_CONNS` | `int` | `10` | `5` | `10` |
| `DB_CONN_MAX_LIFETIME` | `string` | `5m` | `5m` | `5m` |
| `DB_CONN_MAX_IDLE_TIME` | `string` | `2m` | `2m` | `2m` |
| `NOSQL_ENDPOINT` | `string` | `""` | `http://dynamodb-local:8000` | `https://cosmos-univ-dev-ncus.documents.azure.com:443/` |
| `NOSQL_KEY` | `string` | `""` | `dummyKeyLocal123` | Inyectado vía Key Vault Secret / Managed Identity |
| `NOSQL_DATABASE_NAME`| `string`| `univ_nosql`| `library_db` / `lms_db` | `library_db` / `lms_db` |
| `NOSQL_USE_MANAGED_IDENTITY` | `bool` | `false` | `false` | `true` |
| `NOSQL_REGION` | `string` | `northcentralus` | `us-east-1` (DynamoDB emulador) | `northcentralus` |
| `EVENT_BUS_TYPE` | `string` | `local_redis` | `local_redis` | `azure_servicebus` |
| `SERVICEBUS_FQDN` | `string` | `""` | `""` | `sb-univ-dev-ncus.servicebus.windows.net` |
| `REDIS_ADDR` | `string` | `localhost:6379`| `redis:6379` | `ca-redis:6379` (Container App interno VNet) |
| `REDIS_PASSWORD` | `string` | `""` | `""` | Inyectado vía Key Vault Secret |
| `REDIS_DB` | `int` | `0` | `0` | `0` |
| `JWT_ISSUER` | `string` | `""` | `http://gateway:8080/api/v1/auth` | `https://api.universidad.edu.pe/api/v1/auth` |
| `JWKS_URL` | `string` | `""` | `http://auth-service:8081/.well-known/jwks.json` | `http://auth-service:8080/.well-known/jwks.json` |
| `KEYVAULT_URI` | `string` | `""` | `""` | `https://kv-univ-dev-ncus.vault.azure.net/` |
