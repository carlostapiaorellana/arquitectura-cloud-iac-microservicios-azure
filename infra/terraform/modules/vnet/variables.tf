variable "vnet_name" {
  type        = string
  description = "Nombre de la red virtual (Azure Virtual Network) siguiendo la convenciÃ³n CAF (ej. vnet-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.vnet_name == null ? true : (length(trimspace(var.vnet_name)) >= 2 && length(trimspace(var.vnet_name)) <= 64)
    error_message = "El nombre de la VNet (vnet_name) debe tener entre 2 y 64 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre de la red virtual cuando no se especifica vnet_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 2 && length(trimspace(var.name)) <= 64)
    error_message = "El nombre de la VNet (name) debe tener entre 2 y 64 caracteres."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde se aprovisionarÃ¡ la red virtual."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o y debe tener mÃ¡ximo 90 caracteres."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se desplegarÃ¡ la VNet (por defecto northcentralus para Azure for Students)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "address_space" {
  type        = list(string)
  description = "Lista de bloques CIDR para el espacio de direcciones de la VNet (ej. [\"10.0.0.0/16\"])."

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Debe especificar al menos un bloque CIDR vÃ¡lido en address_space (ej. 10.0.0.0/16)."
  }
}

variable "dns_servers" {
  type        = list(string)
  description = "Lista opcional de servidores DNS personalizados para la VNet. Si estÃ¡ vacÃ­a, utiliza Azure-provided DNS."
  default     = []
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
