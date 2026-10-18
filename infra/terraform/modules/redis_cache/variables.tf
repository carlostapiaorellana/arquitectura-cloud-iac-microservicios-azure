variable "redis_name" {
  type        = string
  description = "Nombre globalmente Ãºnico del Azure Cache for Redis siguiendo CAF (ej. redis-univ-dev-ncus, entre 1 y 63 caracteres alfanumÃ©ricos o guiones)."
  default     = null

  validation {
    condition     = var.redis_name == null ? true : (length(trimspace(var.redis_name)) >= 1 && length(trimspace(var.redis_name)) <= 63 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.redis_name)))
    error_message = "redis_name debe tener entre 1 y 63 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Azure Cache for Redis."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 63 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name)))
    error_message = "name debe tener entre 1 y 63 caracteres alfanumÃ©ricos o guiones."
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
  description = "RegiÃ³n de Azure para Redis (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "capacity" {
  type        = number
  description = "Capacidad del SKU de Redis (0 para C0, 1 para C1, etc.)."
  default     = 0

  validation {
    condition     = var.capacity >= 0 && var.capacity <= 6
    error_message = "capacity debe estar entre 0 y 6."
  }
}

variable "family" {
  type        = string
  description = "Familia de SKU de Redis ('C' para Basic/Standard, 'P' para Premium)."
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "family debe ser 'C' o 'P'."
  }
}

variable "sku_name" {
  type        = string
  description = "SKU de Azure Cache for Redis ('Basic', 'Standard' o 'Premium')."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name debe ser 'Basic', 'Standard' o 'Premium'."
  }
}

variable "enable_non_ssl_port" {
  type        = bool
  description = "Define si se habilita el puerto inseguro sin SSL (puerto 6379). Default false por seguridad Zero-Trust."
  default     = false
}

variable "non_ssl_port_enabled" {
  type        = bool
  description = "Alias para habilitar o no el puerto sin SSL (default null para usar enable_non_ssl_port)."
  default     = null
}

variable "minimum_tls_version" {
  type        = string
  description = "VersiÃ³n mÃ­nima de TLS requerida para conexiones con Redis (default 1.2)."
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version debe ser '1.0', '1.1' o '1.2'."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Define si se permite el acceso pÃºblico al endpoint de Redis (default false para Zero-Trust)."
  default     = false
}

variable "redis_configuration" {
  type = object({
    maxmemory_reserved              = optional(number)
    maxmemory_delta                 = optional(number)
    maxfragmentationmemory_reserved = optional(number)
    maxmemory_policy                = optional(string, "volatile-lru")
    rdb_backup_enabled              = optional(bool, false)
    rdb_backup_frequency            = optional(number)
    rdb_backup_max_snapshot_count   = optional(number)
    rdb_storage_connection_string   = optional(string)
  })
  description = "ConfiguraciÃ³n avanzada del motor de Redis."
  default     = {}
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
