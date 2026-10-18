# Módulo Terraform: azure_oidc_github

Módulo de infraestructura como código para aprovisionar federación de identidades OIDC (Workload Identity Federation) entre GitHub Actions y Microsoft Entra ID (Azure AD), eliminando el uso de credenciales estáticas o secretos en repositorios.

## Características

- Registro de Aplicación en Microsoft Entra ID (`azuread_application`).
- Creación del Service Principal correspondiente (`azuread_service_principal`).
- Credenciales federadas OIDC para:
  - Rama `main` (`ref:refs/heads/main`).
  - Entorno protegido `azure-dev` (`environment:azure-dev`).
- Asignación de rol RBAC `Contributor` sobre la suscripción de Azure.

## Entradas (Inputs)

| Nombre | Tipo | Default | Descripción |
|---|---|---|---|
| `github_repository` | `string` | `"carlostapiaorellana/arquitectura-cloud-iac-microservicios-azure"` | Repositorio GitHub (`owner/repo`). |
| `service_principal_name` | `string` | `"sp-github-actions-university"` | Nombre de la App / SP en Entra ID. |
| `subscription_id` | `string` | `"94846a8b-9491-4312-82bb-3082c340b45f"` | ID de la suscripción Azure. |
| `role_definition_name` | `string` | `"Contributor"` | Rol RBAC asignado. |
| `tenant_id` | `string` | `"6418e6e8-7843-4ffb-8c18-154e7f3fedd8"` | ID del Tenant de Entra ID. |

## Salidas (Outputs)

| Nombre | Descripción |
|---|---|
| `client_id` | Client ID de la App registrada en Entra ID (para `AZURE_CLIENT_ID`). |
| `tenant_id` | Tenant ID de Entra ID (para `AZURE_TENANT_ID`). |
| `service_principal_object_id` | Object ID del Service Principal. |
| `application_id` | Resource ID de la Aplicación. |
