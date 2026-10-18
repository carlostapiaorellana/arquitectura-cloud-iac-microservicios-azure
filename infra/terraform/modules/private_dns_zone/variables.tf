variable "dns_zone_name" {
  type        = string
  description = "Nombre del dominio FQDN de la Zona DNS Privada (ej. privatelink.mysql.database.azure.com, privatelink.vaultcore.azure.net)."
  default     = null

  validation {
    condition     = var.dns_zone_name == null ? true : (length(trimspace(var.dns_zone_name)) >= 3 && can(regex("^[a-zA-Z0-9.-]+$", var.dns_zone_name)))
    error_message = "El nombre de la zona DNS privada (dns_zone_name) debe ser un FQDN vÃ¡lido."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre de la Zona DNS Privada cuando no se especifica dns_zone_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 3 && can(regex("^[a-zA-Z0-9.-]+$", var.name)))
    error_message = "El nombre de la zona DNS privada (name) debe ser un FQDN vÃ¡lido."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde se crearÃ¡ la Zona DNS Privada."

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
