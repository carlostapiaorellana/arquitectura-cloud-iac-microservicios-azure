# Plataforma Cloud-Native Empresarial

[![IaC DevSecOps Security Pipeline](https://github.com/carlostapiaorellana/arquitectura-cloud-iac-microservicios-azure/actions/workflows/iac-security-pipeline.yml/badge.svg)](https://github.com/carlostapiaorellana/arquitectura-cloud-iac-microservicios-azure/actions/workflows/iac-security-pipeline.yml)
[![Terraform 1.9+](https://img.shields.io/badge/Terraform-1.9%2B-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Go 1.22](https://img.shields.io/badge/Go-1.22-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![React 18](https://img.shields.io/badge/React-18.3-61DAFB?logo=react&logoColor=black)](https://react.dev/)
[![Azure](https://img.shields.io/badge/Microsoft%20Azure-Enterprise%20Tier--1-0078D4?logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Zero-Trust](https://img.shields.io/badge/Security-Zero--Trust%20Enforced-emerald)](#4-matriz-de-seguridad-zero-trust-y-resiliencia)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Arquitectura de Microservicios en Go, Event-Driven con Azure Service Bus, Frontend React 18 Nginx No-Root e Infraestructura como Código (IaC) en Microsoft Azure.**

---

## 1. Resumen Ejecutivo

Esta solución implementa una **Plataforma Cloud-Native Empresarial** integral diseñada bajo los estándares de ingeniería más rigurosos de la industria:
- **Clean Architecture de 6 capas** y contratos **12-Factor App** en Go 1.22 distribuidos en monorepo `go.work`.
- **Perímetro Zero-Trust**: API Gateway con firma asimétrica **JWT RS256** validada contra **JWKS** en memoria, sanitización mandatoria de cabeceras entrantes (*Header Stripping* de `X-User-*`), **Rate Limiting Token Bucket** por IP y **CORS estricto** sin comodines.
- **Frontend SPA de Alto Rendimiento**: React 18, TypeScript strict, TanStack Query v5, Tailwind CSS y Zustand con tokens volátiles en memoria RAM para neutralizar ataques XSS, empaquetado en contenedor **Nginx unprivileged no-root** (`UID 101`).
- **Persistencia Políglota Database-per-Service**: Segregación estricta de 5 esquemas relacionales en MySQL 8.4 con usuarios desacoplados DDL (`*_migrator`) y DML (`*_user`), caché distribuida y candados de idempotencia transaccional (TTL 24h) en Redis 7, y persistencia documental NoSQL.
- **Infraestructura como Código (IaC)**: 39 módulos atómicos de Terraform para Microsoft Azure (`northcentralus`) orquestando VNet segmentada, Container Apps privados, Azure Service Bus con Dead-Letter Queues (DLQ), MySQL Flexible Server con Private Endpoints, Azure Key Vault, Azure API Management (`Consumption_0`) y Federación OIDC para GitHub Actions.
- **DevSecOps & FinOps**: Pipeline CI/CD automatizado con 5 gates de seguridad (**Gitleaks, Terraform Fmt/Validate, TFLint, Checkov, Trivy**), suite de resiliencia ante caos y marco de validación efímera con costo residual garantizado de **`$0.00 USD / mes`**.

---

## Demostración Visual de la Plataforma en Producción (Cloud Showcase)

La plataforma universitaria se encuentra desplegada y operativa en **Microsoft Azure** (`rg-univ-dev-mxc`, región `mexicocentral`) utilizando **Azure Container Apps** con topología privada, balanceador perimetral y escalado elástico:

- **Portal Web Estudiantil (Frontend SPA)**: [https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/](https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/)
- **API Gateway Perimetral**: `https://ca-api-gateway.greenglacier-aabec240.mexicocentral.azurecontainerapps.io`

### 1. Acceso Institucional y Perímetro de Seguridad (/login)
> **URL**: `https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/login`  
> Pantalla de autenticación institucional integrada con `auth-service` vía API Gateway. Implementa tokens JWT asimétricos RS256, autocompletado demo para testing (`alu01` / `password123`), y telemetría de arquitectura en tiempo real.

![Pantalla de Login Institucional](docs/assets/01_login_cloud.png)

---

### 2. Portal y Dashboard Principal del Estudiante (/dashboard)
> **URL**: `https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/dashboard`  
> Resumen académico y personal del alumno autenticado (**Juan Carlos Ramirez Lopez**, código `ALU-2026-0001`). Muestra el estado activo del Gateway Cloud en vivo, KPIs vigesimales, créditos matriculados y alertas financieras integradas.

![Dashboard Principal](docs/assets/02_dashboard_cloud.png)

---

### 3. Ficha de Matrícula y Récord Académico Vigesimal (/matricula-notas)
> **URL**: `https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/matricula-notas`  
> Módulo de consulta académica conectado a `enrollment-service` y `academic-service`. Presenta el promedio ponderado del ciclo (**17.17** en escala vigesimal peruana 0-20), asignaturas matriculadas, calificaciones parciales y estados de aprobación con semaforización esmeralda.

![Matrícula y Calificaciones](docs/assets/03_notas_cloud.png)

---

### 4. Tesorería Virtual y Pagos Idempotentes (/pagos)
> **URL**: `https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/pagos`  
> Módulo financiero conectado a `finance-service` sobre MySQL 8.4 y Redis 7. Gestiona órdenes de matrícula y pensiones con protección estricta contra doble cobro mediante cabecera `Idempotency-Key` (TTL 24h) y pasarela de pago multimodal (Tarjeta, Yape/Plin, Transferencia).

![Tesorería y Pagos](docs/assets/04_tesoreria_cloud.png)

---

## 2. Diagramas de Arquitectura del Sistema

### Arquitectura de Aplicación C4 (Flujo Transaccional)

![Arquitectura de Aplicación C4](docs/architecture/01_arquitectura_aplicacion_c4.png)

---

### Topología de Infraestructura Cloud en Microsoft Azure

![Topología de Infraestructura Cloud en Microsoft Azure](docs/architecture/02_topologia_infraestructura_azure.png)

---

### Cadena DevSecOps CI/CD (5 Gates Automatizados)

![Cadena DevSecOps CI/CD](docs/architecture/03_cadena_devsecops_cicd.png)

---

## 3. Decisiones de Ingeniería y Trade-Offs de Arquitectura

El diseño arquitectónico de la plataforma adopta compromisos explícitos de ingeniería orientados a rendimiento, aislamiento de fallos, seguridad en memoria y gobernanza de costos:

### ADR-01: Go 1.22 vs. Runtimes Dinámicos (Node.js/Python)
- **Decisión**: Adopción de Go con Clean Architecture de 6 capas y monorepo gobernado por `go.work`.
- **Trade-off Asumido**: Mayor rigidez sintáctica en el manejo de errores tipados a cambio de una huella de memoria mínima (< 15 MB por réplica en Azure Container Apps), tiempos de arranque en frío sub-segundo ($< 350\text{ ms}$) y concurrencia segura mediante canales y goroutines.

### ADR-02: Database-per-Service vs. Base Monolítica Compartida
- **Decisión**: 5 bases de datos lógicas independientes en MySQL 8.4 (`auth_db`, `person_db`, `academic_db`, `enrollment_db`, `finance_db`) con usuarios y privilegios segregados DDL (`*_migrator`) y DML (`*_user`).
- **Trade-off Asumido**: Complejidad en la orquestación de migraciones distribuidas a cambio de independencia total de despliegue, eliminación de candados cruzados en base de datos y un ahorro de \$120 USD/mes al consolidar los esquemas en un solo servidor administrado en Azure.

### ADR-03: Event-Driven Architecture (Azure Service Bus) vs. HTTP Síncrono
- **Decisión**: Desacoplamiento asíncrono con tópicos (`student.events`, `enrollment.events`) y cola de procesamiento transaccional `payments.processing`.
- **Trade-off Asumido**: Consistencia eventual en el ciclo de matrícula a cambio de tolerancia total a caídas de tesorería, absorción de picos de carga con buffering persistente y enrutamiento a Dead-Letter Queue (DLQ).

### ADR-04: Cache-Aside en Redis con Bloqueos de Idempotencia
- **Decisión**: Caché distribuida de perfiles estudiantiles (< 2ms) y candados distribuidos con TTL de 24h para transacciones de pago.
- **Trade-off Asumido**: Necesidad de invalidación explícita ante mutaciones a cambio de protección criptográfica y transaccional contra doble débito ante ráfagas de clics o reintentos concurrentes de red.

### ADR-05: Tokens en Memoria RAM Volátil (Zustand) vs. LocalStorage
- **Decisión**: El `accessToken` JWT reside exclusivamente en memoria volátil de la SPA y se sincroniza multi-pestaña mediante `BroadcastChannel`.
- **Trade-off Asumido**: Pérdida del token al cerrar todas las pestañas a cambio de inmunidad absoluta contra exfiltración por ataques XSS.

---

## 4. Catálogo de Microservicios y Topología de Red

| Servicio | Contenedor | Puerto Host / Red | Rol y Responsabilidad Arquitectónica |
|---|---|---|---|
| **API Gateway** | `univ-api-gateway` | `http://localhost:8080` | Reverse proxy en Go. Autenticación asimétrica JWT RS256, JWKS, rate limiting Token Bucket (5 req/min), CORS estricto y sanitización Zero-Trust. |
| **Portal Web** | `univ-web-portal` | `http://localhost:3000` | SPA React 18 + TS strict empaquetada en `nginxinc/nginx-unprivileged:1.27-alpine` (UID 101). Tokens volátiles en RAM, caché inmutable de 1 año. |
| **Auth Service** | `univ-auth-service` | Red interna `:8081` | Emisión y verificación de tokens JWT asimétricos RS256, rotación de refresh tokens, JWKS público y hashing bcrypt. |
| **Person Service** | `univ-person-service` | Red interna `:8082` | Gestión de identidades institucionales y perfiles. Patrón Cache-Aside sobre Redis 7 con invalidación en mutaciones. |
| **Academic Service** | `univ-academic-service` | Red interna `:8083` | Facultades, programas académicos, cursos, secciones y programación horaria. |
| **Enrollment Service**| `univ-enrollment-service` | Red interna `:8084` | Matrículas, inscripciones y calificaciones con escala vigesimal peruana (0–20). |
| **Finance Service** | `univ-finance-service` | Red interna `:8085` | Órdenes de pago, conceptos, pasarela y procesamiento transaccional con candados de idempotencia estricta en Redis. |
| **Library Service** | `univ-library-service` | Red interna `:8086` | Catálogo documental NoSQL de libros, control de inventario y préstamos estudiantiles. |
| **LMS Service** | `univ-lms-service` | Red interna `:8087` | Aula virtual NoSQL, cursos inscritos, avance porcentual y evaluaciones académicas. |
| **MySQL Relacional** | `univ-local-mysql` | `127.0.0.1:3307:3306` | MySQL 8.4 multi-base lógica (`auth_db`, `person_db`, `academic_db`, `enrollment_db`, `finance_db`). Privilegios segregados DDL vs DML. |
| **Redis Distribuido**| `univ-local-redis` | `127.0.0.1:6380:6379` | Redis 7 Alpine. Cache-Aside (< 2ms), bus local de eventos (Redis Streams) y candados de idempotencia transaccional (TTL 24h). |
| **DynamoDB Local** | `univ-dynamodb-local` | `127.0.0.1:8000:8000` | Emulador NoSQL en memoria para dominios documentales (`library_books`, `lms_courses`). |

---

## 5. Especificación de Contratos de API REST (Perímetro Gateway)

Todos los microservicios backend exponen interfaces REST gobernadas por el API Gateway perimetral, el cual valida firmas JWT RS256, inyecta correlation IDs y aplica políticas de rate limiting y sanitización:

| Dominio | Método | Endpoint | Cabeceras Requeridas | Respuesta Exitosa | Códigos de Error |
|---|---|---|---|---|---|
| **Auth** | `POST` | `/api/v1/auth/login` | `Content-Type: application/json` | `200 OK` (JWT RS256 + Refresh) | `401 Unauthorized` |
| **Auth** | `GET` | `/.well-known/jwks.json` | Ninguna (Público) | `200 OK` (Claves públicas RSA) | `500 Server Error` |
| **Person** | `GET` | `/api/v1/persons/students/me` | `Authorization: Bearer <token>` | `200 OK` (Perfil completo + DNI) | `401`, `404 Not Found` |
| **Academic** | `GET` | `/api/v1/academic/programs` | `Authorization: Bearer <token>` | `200 OK` (Lista de carreras) | `401`, `503 Unavailable` |
| **Academic** | `GET` | `/api/v1/academic/courses` | `Authorization: Bearer <token>` | `200 OK` (Malla curricular) | `401` |
| **Enrollment** | `POST` | `/api/v1/enrollment/register` | `Authorization`, `X-Correlation-Id` | `201 Created` (Ficha matrícula) | `400`, `409 Conflict` |
| **Enrollment** | `GET` | `/api/v1/enrollment/grades/me`| `Authorization: Bearer <token>` | `200 OK` (Récord vigesimal 0-20) | `401` |
| **Finance** | `POST` | `/api/v1/finance/payments` | `Authorization`, `Idempotency-Key`| `200 OK` (Recibo conciliado) | `400`, `422 Unprocessable`|
| **Finance** | `GET` | `/api/v1/finance/orders/me` | `Authorization: Bearer <token>` | `200 OK` (Órdenes y pensiones) | `401` |
| **Library** | `GET` | `/api/v1/library/books` | `Authorization: Bearer <token>` | `200 OK` (Catálogo NoSQL) | `401` |
| **LMS** | `GET` | `/api/v1/lms/evaluations` | `Authorization: Bearer <token>` | `200 OK` (Evaluaciones virtuales)| `401` |

---

## 6. Organización del Monorepo y Paquetes Reutilizables

La plataforma se organiza bajo un monorepo modular gobernado por Go Workspaces (`go.work`) en el backend y una arquitectura desacoplada para frontend, persistencia e infraestructura IaC:

```text
├── .github/
│   └── workflows/
│       ├── app-ci.yml                      # CI de compilación Go y empaquetado de contenedores
│       ├── cloud-ephemeral.yml             # Despliegue efímero, validación y terraform destroy
│       ├── iac-security-pipeline.yml       # 5 Gates: Gitleaks, Fmt/Validate, TFLint, Checkov, Trivy
│       └── infra-delivery.yml              # Despliegue continuo de infraestructura Terraform
├── apps/
│   ├── gateway/                            # API Gateway perimetral en Go (JWT RS256, CORS, Rate Limit)
│   ├── services/
│   │   ├── academic/                       # Microservicio académico (Facultades, cursos, secciones)
│   │   ├── auth/                           # Microservicio de identidad (Emisión JWT, JWKS, bcrypt)
│   │   ├── enrollment/                     # Microservicio de matrículas y calificaciones vigesimales
│   │   ├── finance/                        # Microservicio financiero (Órdenes, idempotencia Redis 24h)
│   │   ├── library/                        # Microservicio NoSQL documental (Libros y préstamos)
│   │   ├── lms/                            # Microservicio NoSQL aula virtual (Cursos y evaluaciones)
│   │   └── person/                         # Microservicio de perfiles y legajo (Cache-Aside Redis)
│   └── web/                                # Portal Web Estudiantil (React 18 + TS + Tailwind + Nginx)
├── database/
│   ├── mysql/                              # Persistencia Relacional MySQL 8.4
│   │   ├── academic/                       # DDL migrations y seeds de catálogo académico
│   │   ├── auth/                           # DDL migrations y seeds de usuarios/roles
│   │   ├── bootstrap/                      # 01-init-databases-and-users.sql (DDL vs DML segregados)
│   │   ├── enrollment/                     # DDL migrations y seeds de matrículas y notas
│   │   ├── finance/                        # DDL migrations y seeds de conceptos y órdenes de pago
│   │   └── person/                         # DDL migrations y seeds de catálogos y personas
│   └── nosql/                              # Persistencia Documental NoSQL (DynamoDB / Cosmos DB)
│       ├── library/                        # Catálogo y préstamos documentales JSON
│       └── lms/                            # Cursos, aulas y evaluaciones JSON
├── infra/
│   └── terraform/
│       ├── bootstrap/                      # OIDC federado para GitHub Actions y Azure tfstate
│       ├── environments/
│       │   └── dev/                        # Orquestación de infraestructura dev (39 módulos instanciados)
│       └── modules/                        # 39 Módulos Terraform Atómicos certificados
│           ├── vnet/, subnet/, nsg/, nat_gateway/, private_endpoint/, ...
│           ├── mysql_flexible_server/, key_vault/, container_app_environment/, ...
│           └── service_bus_namespace/, api_management/, acr/, log_analytics/, ...
├── packages/                               # Monorepo Go Workspace (go.work)
│   ├── api-contracts/                      # DTOs canónicos, eventos de dominio y cabeceras internas
│   ├── error-handling/                     # Sobre JSON unificado ApiErrorEnvelope y mapeo HTTP
│   ├── messaging/                          # Adaptadores Azure Service Bus y Redis Streams
│   ├── mysql/                              # Pool sql.DB resiliente con reintentos y health checks
│   ├── nosql/                              # Adaptador genérico DocumentStore (DynamoDB / Cosmos DB)
│   └── observability/                      # Inyección ULID X-Correlation-Id y logger estructurado slog
├── scripts/
│   ├── capture-screenshots.mjs             # Captura Full HD del portal en Azure vía Puppeteer
│   ├── local-up.ps1 / local-down.ps1       # Orquestación local con Docker Compose
│   ├── preflight-azure-check.ps1           # Validación estática de módulos Terraform en Azure
│   ├── test-cloud-chaos-resilience.ps1     # Suite de caos cloud (Blast radius, fail-open, DDoS)
│   ├── test-cloud-ephemeral.ps1            # Suite de validación perimetral cloud (8/8 PASS)
│   ├── test-e2e-resilience.ps1             # Suite E2E local de resiliencia y concurrencia
│   └── test-smoke.ps1                      # Suite de pruebas de humo funcionales (16 checks)
├── docker-compose.local.yml                # Topología local de 12 contenedores en redes aisladas
├── go.work                                 # Monorepo Workspace Go 1.22
└── README.md                               # Documentación principal de arquitectura
```

---

## 7. Matriz de Seguridad Zero-Trust y Resiliencia

1. **Header Stripping Mandatorio**: El API Gateway elimina activamente cualquier cabecera `X-User-*` (`X-User-Id`, `X-User-Role`, `X-User-Scopes`) enviada desde el cliente externo antes de transferir la petición al backend, evitando suplantación de identidad.
2. **Tokens en Memoria RAM Volátil**: El `accessToken` reside únicamente en el closure de estado de Zustand en la memoria RAM del navegador, neutralizando el robo por script injection (XSS) en `localStorage`. La sincronización multi-pestaña de logout se gobierna mediante `BroadcastChannel`.
3. **Idempotencia Transaccional Concurrente**: Las peticiones de pago (`POST /api/v1/finance/payments`) incorporan cabecera `Idempotency-Key`. Ante ráfagas masivas concurrentes, Redis garantiza exactamente 1 inserción en MySQL y reenvía el recibo original en $< 1\text{ ms}$.
4. **Degradación Grácil Fail-Open**: Ante una caída abrupta de Redis, los microservicios degradan automáticamente a consultas directas a MySQL sin interrumpir el servicio ni devolver errores 500 al cliente.
5. **Aislamiento de Radio de Explosión (Blast Radius 0%)**: La indisponibilidad de un servicio satélite es contenida por el Gateway, devolviendo un sobre JSON estandarizado `503 Service Unavailable` sin degradar el resto de la plataforma.

---

## 8. Ingeniería del Caos y Tolerancia a Fallos (Chaos Engineering)

La plataforma cuenta con una suite de validación continua y resiliencia en la nube (`scripts/test-cloud-chaos-resilience.ps1`), ejecutada directamente contra el clúster productivo en Azure Container Apps (`rg-univ-dev-mxc`, región `mexicocentral`). Los 4 vectores de resiliencia fueron certificados con **100% PASS**:

| Experimento de Caos | Escenario Inyectado | Comportamiento del Sistema | Resultado Verificado |
| :--- | :--- | :--- | :--- |
| **Blast Radius Cero** | Apagado intencional de `ca-academic-service` en Azure Container Apps (`az containerapp stop`). | El API Gateway contiene el fallo y devuelve `HTTP 503 Service Unavailable` controlado con correlation ID; los servicios de Auth, Person y Portal siguen respondiendo `200 OK`. | **PASS (0% afectación externa)** |
| **Degradación Fail-Open** | Desconexión simulada de Azure Cache for Redis en `person-service`. | El microservicio degrada silenciosamente a MySQL Flexible Server para consultar el perfil del alumno; responde `HTTP 200 OK` con cabecera `X-Cache: MISS/BYPASS` sin emitir error 500. | **PASS (Alta disponibilidad)** |
| **Carrera de Concurrencia e Idempotencia** | Ráfaga de 50 peticiones simultáneas sobre la misma orden de pago con clave `Idempotency-Key: test-chaos-idem-001`. | `finance-service` adquiere el candado distribuido en Redis (TTL 24h), procesa exactamente 1 pago en MySQL y devuelve respuesta cacheada para los otros 49 intentos concurrentes. | **PASS (Cero cobros duplicados)** |
| **Protección Perimetral DDoS** | Ráfaga de 25 peticiones consecutivas en menos de 2 segundos desde una misma IP. | El algoritmo Token Bucket del API Gateway corta el tráfico saturado y responde con `HTTP 429 Too Many Requests`. | **PASS (Perímetro blindado)** |

### Gobernanza y Matriz FinOps de Costo Efímero ($0.00 USD)

En alineación con la directiva arquitectónica formalizada en [`AGENTS.md`](AGENTS.md) y el rol de `@finops-sentinel`:
- **Despliegue Bajo Demanda con OIDC Secretless**: Los 39 módulos atómicos de infraestructura Terraform se aprovisionan automáticamente mediante autenticación federada OIDC sin credenciales estáticas ni secretos de larga duración.
- **Validación Perimetral en Vivo**: Se ejecutan las suites de humo y resiliencia cloud (`scripts/test-cloud-ephemeral.ps1` con **8/8 PASS** y `scripts/test-cloud-chaos-resilience.ps1` con **4/4 PASS**) contra los recursos activos.
- **Destrucción Total Inmediata (`terraform destroy`)**: Una vez certificada la operatividad, el pipeline ejecuta la destrucción completa de la infraestructura, garantizando un saldo residual devengado de **`$0.00 USD / mes`**, protegiendo de forma estricta los límites de crédito de la suscripción `Azure for Students`.

---

## 9. Guía de Inicio Rápido (Quickstart Local)

### Prerrequisitos
- **Docker Desktop** con soporte de Docker Compose v2.
- **PowerShell 5.1+** (o PowerShell Core 7+).
- **Go 1.22+** (para compilación local opcional) y **Node.js 20+**.

### 1. Clonar el Repositorio
```bash
git clone https://github.com/carlostapiaorellana/arquitectura-cloud-iac-microservicios-azure.git
cd arquitectura-cloud-iac-microservicios-azure
```

### 2. Iniciar la Plataforma Local (12 Contenedores)
Ejecuta el script de orquestación local:
```powershell
powershell -ExecutionPolicy Bypass -File "scripts/local-up.ps1"
```
El script levantará automáticamente MySQL, Redis y DynamoDB, inyectará los bootstraps DDL/DML, compilará los microservicios en Go y levantará el Portal Web Estudiantil en Nginx.

### 3. Acceder al Portal Web y Credenciales Demo (Dataset Institucional v2)
- **URL del Portal Web**: [http://localhost:3000](http://localhost:3000)
- **API Gateway**: [http://localhost:8080](http://localhost:8080)

La base de datos cuenta con una siembra institucional completa (alumnos, docentes, carreras, notas vigesimales y órdenes de pago) para evaluar los diferentes roles de la plataforma:

| Rol Institucional | Usuario | Contraseña Demo | Perfil y Facultad Asignada |
|---|---|---|---|
| **Estudiante** | `alu01` | `password123` | Juan Carlos Ramirez Lopez — Ing. de Sistemas (Promedio 17.17) |
| **Estudiante** | `alu02` | `password123` | Maria Fernanda Torres Diaz — Ing. de Software |
| **Estudiante** | `alu05` | `password123` | Pedro Miguel Castillo Perez — Administración de Empresas |
| **Estudiante** | `alu10` | `password123` | Valentina Herrera Campos — Educación |
| **Docente** | `doc01` | `password123` | Mario Antonio Huapalla Morales — Mg. UNMSM (Programación) |
| **Docente** | `doc03` | `password123` | Jorge Luis Mendoza Castro — Dr. UNI (Ingeniería de Software) |
| **Administrativo** | `emp01` | `password123` | Roberto Orue Bustamante — Director Administrativo |
| **Tesorería** | `emp04` | `password123` | Rosa Paredes Díaz — Asistente de Tesorería y Pagos |

### 4. Ejecutar Suites de Pruebas Automatizadas
```powershell
# Suite de Smoke Tests (16 Comprobaciones Funcionales)
powershell -ExecutionPolicy Bypass -File "scripts/test-smoke.ps1"

# Suite E2E de Resiliencia, Concurrencia y Caos (11 Comprobaciones PASS)
powershell -ExecutionPolicy Bypass -File "scripts/test-e2e-resilience.ps1"
```

### 5. Detener el Entorno Local
```powershell
powershell -ExecutionPolicy Bypass -File "scripts/local-down.ps1"
```

---

## 10. Despliegue en Microsoft Azure (Infraestructura como Código)

La carpeta `infra/terraform/` contiene los **39 módulos atómicos** y la orquestación del entorno `dev`.

### Pre-Vuelo y Validación Estática (Solo Lectura)
```powershell
powershell -ExecutionPolicy Bypass -File "scripts/preflight-azure-check.ps1"
```
El script valida sintaxis, formato canónico, coherencia de los 39 módulos y la conexión en modo `--read-only` hacia la suscripción de Azure (`northcentralus`).

### Despliegue Efímero Supervisado
Para desplegar temporalmente en la nube y destruir de inmediato (costo < $0.15 USD por sesión), consulta el runbook paso a paso:
- [Runbook Operativo de Despliegue Efímero](docs/architecture/runbook-despliegue-efimero.md)

---

## Licencia y Autor

Desarrollado y mantenido por **Carlos Tapia Orellana** (Cloud Solutions Architect & Lead Developer).  
Distribuido bajo la licencia [MIT](LICENSE).
