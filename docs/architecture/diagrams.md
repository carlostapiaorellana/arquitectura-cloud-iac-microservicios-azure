# Especificación de Diagramas de Arquitectura (Mermaid)

Este documento contiene las especificaciones formales de arquitectura para la **Plataforma Cloud-Native Empresarial**: arquitectura de aplicación C4, topología de infraestructura en Microsoft Azure y la cadena de suministro de seguridad DevSecOps CI/CD.

---

## 1. Arquitectura de Aplicación (C4 / Flujo de Solicitudes)

```mermaid
flowchart TD
    subgraph ClientLayer["Capa de Cliente & Presentación"]
        SPA["Portal Web Estudiantil\n(React 18 + TS + Tailwind)\nNginx No-Root (UID 101) :3000"]
    end

    subgraph PerimetralGateway["Perímetro & Seguridad Zero-Trust"]
        GW["API Gateway en Go :8080\n- JWT RS256 / JWKS Cliente\n- Stripping de cabeceras X-User-*\n- Token Bucket Rate Limiting (5 req/min)\n- Inyección X-Correlation-Id\n- CORS Whitelist Estricta"]
    end

    subgraph CoreServices["Microservicios Backend (Go 1.22 / Clean Architecture)"]
        S_Auth["auth-service :8081\n(Emisión JWT RS256, Refresh Token, JWKS)"]
        S_Person["person-service :8082\n(Gestión Perfiles, Cache-Aside)"]
        S_Academic["academic-service :8083\n(Cursos, Secciones, Malla Curricular)"]
        S_Enrollment["enrollment-service :8084\n(Matrículas, Notas Vigesimales 0-20)"]
        S_Finance["finance-service :8085\n(Órdenes de Pago, Idempotencia Redis 24h)"]
        S_Library["library-service :8086\n(Catálogo de Libros, Préstamos NoSQL)"]
        S_Lms["lms-service :8087\n(Aula Virtual, Evaluaciones NoSQL)"]
    end

    subgraph DataPersistence["Persistencia Políglota Database-per-Service"]
        MySQL[("MySQL 8.4 (:3307)\n- auth_db\n- person_db\n- academic_db\n- enrollment_db\n- finance_db\nPrivilegios DDL vs DML segregados")]
        Redis[("Redis 7 (:6380)\n- Cache-Aside Perfiles (< 2ms)\n- Idempotency Keys (TTL 24h)\n- EDA con Redis Streams")]
        Dynamo[("DynamoDB Local (:8000)\n- library_books & loans\n- lms_courses & evaluations")]
    end

    SPA -->|HTTPS / REST| GW
    GW -->|Enrutamiento Interno| S_Auth
    GW -->|Enrutamiento Interno| S_Person
    GW -->|Enrutamiento Interno| S_Academic
    GW -->|Enrutamiento Interno| S_Enrollment
    GW -->|Enrutamiento Interno| S_Finance
    GW -->|Enrutamiento Interno| S_Library
    GW -->|Enrutamiento Interno| S_Lms

    S_Auth -->|DDL/DML| MySQL
    S_Person -->|DDL/DML| MySQL
    S_Person <-->|Cache-Aside| Redis
    S_Academic -->|DDL/DML| MySQL
    S_Enrollment -->|DDL/DML| MySQL
    S_Enrollment -->|Eventos Matrícula| Redis
    S_Finance -->|DDL/DML Transaccional| MySQL
    S_Finance <-->|Candados Idempotencia| Redis
    S_Library <-->|Documentos JSON| Dynamo
    S_Lms <-->|Documentos JSON| Dynamo
```

---

## 2. Topología de Infraestructura Cloud en Microsoft Azure

```mermaid
flowchart TD
    Internet((Tráfico Público HTTPS)) --> APIM["Azure API Management (Consumption_0)\n- Rate Limiting por IP\n- CORS Whitelist\n- Header Sanitization"]

    subgraph VNet["Virtual Network: vnet-univ-dev-ncus (10.0.0.0/16) - northcentralus"]
        subgraph SubnetAPIM["snet-apim (10.0.1.0/24)"]
            APIM_EP["APIM Gateway Ingress"]
        end

        subgraph SubnetACA["snet-aca (10.0.2.0/23) - Delegated Microsoft.App/environments"]
            ACA_Env["Container Apps Environment (Privado)\n- ca-gateway\n- ca-auth, ca-person, ca-academic\n- ca-enrollment, ca-finance\n- ca-library, ca-lms"]
        end

        subgraph SubnetPE["snet-pe (10.0.4.0/24)"]
            PE_MySQL["Private Endpoint MySQL"]
            PE_SB["Private Endpoint Service Bus"]
            PE_KV["Private Endpoint Key Vault"]
            PE_Redis["Private Endpoint Redis"]
        end

        subgraph SubnetData["snet-data (10.0.5.0/24) - Delegated Flexible Servers"]
            MySQL_Flex["Azure Database for MySQL Flexible Server\n(B_Standard_B1ms / Zona Redundante / SSL TLS 1.2)"]
        end
    end

    subgraph PaaSServices["Servicios PaaS Gestionados"]
        ASB["Azure Service Bus (Namespace Standard)\n- Topics: student.events, payment.events\n- Queues & Dead-Letter Queues (DLQ)"]
        AKV["Azure Key Vault (Zero-Trust RBAC)\n- Secretos DDL/DML\n- Certificados y Claves"]
        ACR["Azure Container Registry\n(acrunivdevncus.azurecr.io)"]
    end

    APIM --> APIM_EP
    APIM_EP -->|Private DNS Link| ACA_Env
    ACA_Env -->|Private Link| PE_MySQL --> MySQL_Flex
    ACA_Env -->|Private Link| PE_SB --> ASB
    ACA_Env -->|Private Link| PE_KV --> AKV
    ACA_Env -->|User Assigned Identity| ACR
```

---

## 3. Cadena DevSecOps CI/CD y Gates de Seguridad

```mermaid
flowchart LR
    Push["Git Push / Pull Request\n(Rama main)"] --> Gate1

    subgraph GHA["GitHub Actions: iac-security-pipeline.yml"]
        Gate1["Gate 1: Gitleaks\n(Detección de Secretos)"] --> Gate2["Gate 2: Terraform\n(fmt -check & validate)"]
        Gate2 --> Gate3["Gate 3: TFLint\n(Reglas AzureRM)"]
        Gate3 --> Gate4["Gate 4: Checkov\n(Políticas CIS / Zero-Trust)"]
        Gate4 --> Gate5["Gate 5: Trivy\n(Vulnerabilidades & Misconfig)"]
    end

    Gate5 --> PreFlight["Pre-Flight Read-Only\n(preflight-azure-check.ps1: 7/7 PASS)"]
    PreFlight --> Deploy["Aprobación Humana &\nDespliegue Efímero (< $0.15 USD)"]
```
