variable "nsg_name" {
  type        = string
  description = "Nombre del Network Security Group siguiendo la convenciÃ³n CAF (ej. nsg-aca-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.nsg_name == null ? true : (length(trimspace(var.nsg_name)) >= 1 && length(trimspace(var.nsg_name)) <= 80)
    error_message = "El nombre del NSG (nsg_name) debe tener entre 1 y 80 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre del Network Security Group cuando no se especifica nsg_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80)
    error_message = "El nombre del NSG (name) debe tener entre 1 y 80 caracteres."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se crearÃ¡ el Network Security Group."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor del NSG."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group es obligatorio."
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
