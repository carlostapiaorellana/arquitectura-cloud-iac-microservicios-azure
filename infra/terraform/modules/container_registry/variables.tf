variable "registry_name" {
  type        = string
  description = "Nombre globalmente Ãºnico del Azure Container Registry (alfanumÃ©rico Ãºnicamente, entre 5 y 50 caracteres, ej. crunivdevncus)."
  default     = null

  validation {
    condition     = var.registry_name == null ? true : (length(trimspace(var.registry_name)) >= 5 && length(trimspace(var.registry_name)) <= 50 && can(regex("^[a-zA-Z0-9]+$", var.registry_name)))
    error_message = "registry_name debe contener exclusivamente caracteres alfanumÃ©ricos (sin guiones ni sÃ­mbolos) y tener entre 5 y 50 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Azure Container Registry."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 5 && length(trimspace(var.name)) <= 50 && can(regex("^[a-zA-Z0-9]+$", var.name)))
    error_message = "name debe contener exclusivamente caracteres alfanumÃ©ricos (sin guiones ni sÃ­mbolos) y tener entre 5 y 50 caracteres."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se aprovisionarÃ¡ el ACR (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "sku" {
  type        = string
  description = "SKU de precios de Azure Container Registry ('Basic', 'Standard' o 'Premium'). Default Basic."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku debe ser Basic, Standard o Premium."
  }
}

variable "admin_enabled" {
  type        = bool
  description = "Habilita la cuenta de usuario administrador con credenciales estÃ¡ticas. Default false por seguridad Zero-Trust (autenticaciÃ³n vÃ­a Managed Identity AcrPull)."
  default     = false
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Habilita el acceso desde redes pÃºblicas al ACR. Default true para dev."
  default     = true
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Habilita redundancia de zona (solo aplicable a SKU Premium)."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas obligatorias segÃºn cloud-standards (Project, Environment, Owner, CostCenter, ManagedBy, DataClassification)."

  validation {
    condition = alltrue([
      for k in ["Project", "Environment", "Owner", "CostCenter", "ManagedBy", "DataClassification"] :
      contains(keys(var.tags), k) && length(trimspace(var.tags[k])) > 0
    ])
    error_message = "El mapa tags debe incluir las 6 etiquetas obligatorias de cloud-standards: Project, Environment, Owner, CostCenter, ManagedBy y DataClassification."
  }
}
