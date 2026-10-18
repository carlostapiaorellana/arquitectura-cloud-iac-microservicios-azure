variable "server_name" {
  type        = string
  description = "Nombre Ãºnico del servidor MySQL Flexible Server siguiendo CAF (ej. mysql-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.server_name == null ? true : (length(trimspace(var.server_name)) >= 3 && length(trimspace(var.server_name)) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.server_name)))
    error_message = "server_name debe tener entre 3 y 63 caracteres alfanumÃ©ricos en minÃºscula o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del servidor MySQL Flexible Server."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 3 && length(trimspace(var.name)) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name)))
    error_message = "name debe tener entre 3 y 63 caracteres alfanumÃ©ricos en minÃºscula o guiones."
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
  description = "RegiÃ³n de Azure donde se aprovisionarÃ¡ el servidor MySQL (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "administrator_login" {
  type        = string
  description = "Nombre de usuario administrador del servidor MySQL."
  default     = "mysqladmin"

  validation {
    condition     = length(trimspace(var.administrator_login)) >= 1 && length(trimspace(var.administrator_login)) <= 32 && !can(regex("^(admin|administrator|root|guest|public)$", lower(var.administrator_login)))
    error_message = "administrator_login no puede ser palabras reservadas (admin, root, etc.) ni exceder 32 caracteres."
  }
}

variable "administrator_password" {
  type        = string
  description = "ContraseÃ±a de administrador del servidor MySQL."
  sensitive   = true

  validation {
    condition     = length(var.administrator_password) >= 8 && length(var.administrator_password) <= 128
    error_message = "administrator_password debe tener entre 8 y 128 caracteres."
  }
}

variable "sku_name" {
  type        = string
  description = "SKU de cÃ³mputo del servidor MySQL Flexible (default B_Standard_B1ms para Azure for Students)."
  default     = "B_Standard_B1ms"
}

variable "mysql_version" {
  type        = string
  description = "VersiÃ³n del motor MySQL (default 8.0.21)."
  default     = "8.0.21"
}

variable "storage_gb" {
  type        = number
  description = "Capacidad de almacenamiento en GB (mÃ­nimo 20 GB)."
  default     = 20

  validation {
    condition     = var.storage_gb >= 20 && var.storage_gb <= 16384
    error_message = "storage_gb debe ser entre 20 y 16384 GB."
  }
}

variable "auto_grow_enabled" {
  type        = bool
  description = "Habilita el auto-crecimiento del disco de almacenamiento."
  default     = false
}

variable "io_scaling_enabled" {
  type        = bool
  description = "Habilita el auto-escalado de IOPS."
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "DÃ­as de retenciÃ³n de copias de seguridad automÃ¡ticas (7 a 35 dÃ­as)."
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days debe ser un nÃºmero entre 7 y 35 dÃ­as."
  }
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  description = "Habilita copias geo-redundantes (desactivado por defecto para entornos dev/efÃ­meros)."
  default     = false
}

variable "delegated_subnet_id" {
  type        = string
  description = "ID de la subred delegada (snet-data) para aislamiento privado en VNet."
  default     = null
}

variable "private_dns_zone_id" {
  type        = string
  description = "ID de la zona DNS privada para resoluciÃ³n de nombres de MySQL en la VNet."
  default     = null
}

variable "zone" {
  type        = string
  description = "Zona de disponibilidad (ej. '1', '2', '3') o null para sin redundancia de zona."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Habilita o deshabilita el acceso desde redes pÃºblicas (default false para Zero-Trust)."
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
