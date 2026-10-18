variable "link_name" {
  type        = string
  description = "Nombre del enlace entre la Zona DNS Privada y la VNet (ej. link-vnet-mysql-dns)."
  default     = null

  validation {
    condition     = var.link_name == null ? true : (length(trimspace(var.link_name)) >= 1 && length(trimspace(var.link_name)) <= 80)
    error_message = "El nombre del enlace (link_name) debe tener entre 1 y 80 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre del enlace cuando no se especifica link_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80)
    error_message = "El nombre del enlace (name) debe tener entre 1 y 80 caracteres."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde reside la Zona DNS Privada."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "private_dns_zone_name" {
  type        = string
  description = "Nombre FQDN de la Zona DNS Privada a enlazar."

  validation {
    condition     = length(trimspace(var.private_dns_zone_name)) >= 3
    error_message = "El nombre de la Zona DNS Privada (private_dns_zone_name) es obligatorio."
  }
}

variable "virtual_network_id" {
  type        = string
  description = "ID de recurso de la Virtual Network en Azure que resolverÃ¡ registros en esta zona."

  validation {
    condition     = length(trimspace(var.virtual_network_id)) > 0
    error_message = "El ID de la Virtual Network (virtual_network_id) no puede estar vacÃ­o."
  }
}

variable "registration_enabled" {
  type        = bool
  description = "Habilita el autorregistro dinÃ¡mico de mÃ¡quinas virtuales de la VNet en la Zona DNS Privada (false para zonas privatelink.*)."
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
