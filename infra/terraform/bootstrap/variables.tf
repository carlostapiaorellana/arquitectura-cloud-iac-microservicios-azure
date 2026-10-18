variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group para el almacenamiento del estado remoto de Terraform (ej. rg-univ-tfstate-ncus)."
  default     = "rg-univ-tfstate-ncus"

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacío y debe tener máximo 90 caracteres."
  }
}

variable "location" {
  type        = string
  description = "Región de Azure para el Resource Group y Storage Account (fijado a northcentralus para Azure for Students)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La región (location) no puede estar vacía."
  }
}

variable "storage_account_name" {
  type        = string
  description = "Nombre explícito del Storage Account (3 a 24 letras minúsculas y números). Si no se define, se genera automáticamente con un sufijo aleatorio."
  default     = null

  validation {
    condition     = var.storage_account_name == null ? true : can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "El nombre del Storage Account debe contener entre 3 y 24 caracteres alfanuméricos en minúscula."
  }
}

variable "container_name" {
  type        = string
  description = "Nombre del contenedor de blobs para el state de Terraform."
  default     = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$", var.container_name))
    error_message = "El nombre del contenedor debe cumplir con la especificación de nombres de Azure Blob Storage (3-63 caracteres alfanuméricos o guiones)."
  }
}

variable "subscription_id" {
  type        = string
  description = "ID de la suscripción de Azure for Students."
  default     = "94846a8b-9491-4312-82bb-3082c340b45f"

  validation {
    condition     = var.subscription_id == null ? true : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id debe ser un UUID válido (ej. 00000000-0000-0000-0000-000000000000)."
  }
}

variable "github_repository" {
  type        = string
  description = "Repositorio GitHub para federación OIDC (owner/repo)."
  default     = "carlostapiaorellana/arquitectura-cloud-iac-microservicios-azure"

  validation {
    condition     = var.github_repository == null ? true : can(regex("^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$", var.github_repository))
    error_message = "github_repository debe tener el formato 'owner/repository'."
  }
}

variable "service_principal_name" {
  type        = string
  description = "Nombre de la aplicación y Service Principal en Microsoft Entra ID."
  default     = "sp-github-actions-university"

  validation {
    condition     = var.service_principal_name == null ? true : (length(trimspace(var.service_principal_name)) >= 3 && length(trimspace(var.service_principal_name)) <= 128)
    error_message = "service_principal_name debe tener entre 3 y 128 caracteres."
  }
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas obligatorias según cloud-standards (Project, Environment, Owner, CostCenter, ManagedBy, DataClassification)."
  default = {
    Project            = "university-platform"
    Environment        = "dev"
    Owner              = "cloud-architecture-team"
    CostCenter         = "unfpg-academic-it-003"
    ManagedBy          = "terraform"
    DataClassification = "confidential"
  }

  validation {
    condition = alltrue([
      for k in ["Project", "Environment", "Owner", "CostCenter", "ManagedBy", "DataClassification"] :
      contains(keys(var.tags), k) && length(trimspace(var.tags[k])) > 0
    ])
    error_message = "El mapa tags debe incluir las 6 etiquetas obligatorias de cloud-standards: Project, Environment, Owner, CostCenter, ManagedBy y DataClassification."
  }
}
