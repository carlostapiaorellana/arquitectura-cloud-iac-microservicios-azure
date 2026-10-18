# Entorno de Despliegue: dev (Azure for Students)

Orquestador raíz de infraestructura como código que compone los **38 módulos Terraform atómicos** bajo la arquitectura **Enterprise Tier-1 Efímera** para la Plataforma Universitaria Cloud-Native en Azure.

## Topología de Arquitectura
- **Red & Seguridad (Móds 1–13)**: VNet `10.0.0.0/16`, Subnets (`snet-aca`, `snet-data`, `snet-pe`), NSGs deny-by-default, Private DNS Zones para MySQL y Key Vault, Key Vault con RBAC y Managed Identity perimetral.
- **Persistencia & Observabilidad (Móds 14–21)**: Azure Database for MySQL Flexible Server (`B_Standard_B1ms`, 5 bases lógicas independientes), Cosmos DB NoSQL (Free Tier 1000 RU/s), Log Analytics Workspace (`0.5 GB/día`) y Application Insights.
- **Bus de Eventos EDA (Móds 22–26)**: Azure Service Bus Namespace `Standard`, tópicos `student.events` y `enrollment.events`, suscripciones y cola transaccional `payments.processing`.
- **Cómputo ACA & ACR (Móds 27–33)**: Container Registry `Basic` (`admin_enabled = false`), Container App Environment en `snet-aca`, Container App `ca-api-gateway` con `external_enabled = true` y conexión HTTPS directa desde APIM.
- **APIM Perimetral & Políticas (Móds 34–38)**: Azure API Management `Consumption_0` ($0.00 hasta 1M llamadas/mes), 7 APIs versionadas, políticas de Header Stripping de `X-User-*`, CORS Zero-Trust y emisión de credenciales de suscripción.

## Comandos de Verificación en Sandbox (Solo Lectura)
```powershell
$ErrorActionPreference = "Stop"

# Inicializar sin backend remoto
terraform init -backend=false

# Validar sintaxis y coherencia de grafo
terraform validate
```

> [!WARNING]
> En cumplimiento estricto del sesgo `NO_DEPLOY` / `PLAN_FIRST`, **queda prohibido** ejecutar `terraform apply` sin aprobación humana explícita.
