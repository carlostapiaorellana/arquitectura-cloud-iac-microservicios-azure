variable "identity_name" {
  type        = string
  description = "Nombre de la User-Assigned Managed Identity siguiendo CAF (ej. id-person-service-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.identity_name == null ? true : (length(trimspace(var.identity_name)) >= 3 && length(trimspace(var.identity_name)) <= 128)
    error_message = "El nombre de la identidad (identity_name) debe tener entre 3 y 128 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre de la User-Assigned Managed Identity cuando no se especifica identity_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 3 && length(trimspace(var.name)) <= 128)
    error_message = "El nombre de la identidad (name) debe tener entre 3 y 128 caracteres."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se aprovisionarÃ¡ la identidad administrada."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor de la identidad administrada."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
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
