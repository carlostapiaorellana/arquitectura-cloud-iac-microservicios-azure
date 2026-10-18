variable "nat_gateway_name" {
  type        = string
  description = "Nombre del recurso Azure NAT Gateway siguiendo CAF (ej. nat-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.nat_gateway_name == null ? true : (length(trimspace(var.nat_gateway_name)) >= 1 && length(trimspace(var.nat_gateway_name)) <= 80)
    error_message = "El nombre del NAT Gateway (nat_gateway_name) debe tener entre 1 y 80 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre del NAT Gateway cuando no se especifica nat_gateway_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80)
    error_message = "El nombre del NAT Gateway (name) debe tener entre 1 y 80 caracteres."
  }
}

variable "public_ip_name" {
  type        = string
  description = "Nombre opcional para la IP pÃºblica estÃ¡tica asociada al NAT Gateway. Si es null, se deriva del nombre del NAT Gateway."
  default     = null
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se desplegarÃ¡ el NAT Gateway y su IP pÃºblica."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
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

variable "sku_name" {
  type        = string
  description = "SKU del NAT Gateway y de la IP pÃºblica (debe ser Standard)."
  default     = "Standard"

  validation {
    condition     = var.sku_name == "Standard"
    error_message = "Azure NAT Gateway Ãºnicamente soporta el SKU 'Standard'."
  }
}

variable "idle_timeout_in_minutes" {
  type        = number
  description = "Tiempo de espera de inactividad TCP en minutos para el NAT Gateway (entre 4 y 120 minutos)."
  default     = 10

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "idle_timeout_in_minutes debe estar entre 4 y 120 minutos."
  }
}

variable "zones" {
  type        = list(string)
  description = "Lista opcional de zonas de disponibilidad para el NAT Gateway y su Public IP."
  default     = []
}

variable "subnet_ids" {
  type        = set(string)
  description = "Conjunto de IDs de subredes privadas que utilizarÃ¡n este NAT Gateway para salida SNAT determinista."
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
