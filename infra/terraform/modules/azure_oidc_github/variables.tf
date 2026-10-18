variable "github_repository" {
  type        = string
  description = "Nombre completo del repositorio de GitHub en formato 'owner/repository'."
  default     = "carlostapiaorellana/arquitectura-cloud-iac-microservicios-azure"

  validation {
    condition     = var.github_repository == null ? true : can(regex("^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$", var.github_repository))
    error_message = "github_repository debe tener el formato 'owner/repository'."
  }
}

variable "service_principal_name" {
  type        = string
  description = "Nombre de la aplicación y del Service Principal en Microsoft Entra ID."
  default     = "sp-github-actions-university"

  validation {
    condition     = var.service_principal_name == null ? true : (length(trimspace(var.service_principal_name)) >= 3 && length(trimspace(var.service_principal_name)) <= 128)
    error_message = "service_principal_name debe tener entre 3 y 128 caracteres."
  }
}

variable "subscription_id" {
  type        = string
  description = "ID de la suscripción de Azure sobre la cual se asignará el rol RBAC."
  default     = "94846a8b-9491-4312-82bb-3082c340b45f"

  validation {
    condition     = var.subscription_id == null ? true : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id debe ser un UUID válido (ej. 00000000-0000-0000-0000-000000000000)."
  }
}

variable "role_definition_name" {
  type        = string
  description = "Nombre del rol RBAC asignado al Service Principal en la suscripción."
  default     = "Contributor"
}

variable "tenant_id" {
  type        = string
  description = "ID del Tenant de Microsoft Entra ID (opcional si se consulta del contexto)."
  default     = "6418e6e8-7843-4ffb-8c18-154e7f3fedd8"
}

variable "github_owner_id" {
  type        = string
  description = "ID numérico del propietario/organización en GitHub (para formato inmutable OIDC)."
  default     = "276114035"
}

variable "github_repository_id" {
  type        = string
  description = "ID numérico del repositorio en GitHub (para formato inmutable OIDC)."
  default     = "1423825990"
}
