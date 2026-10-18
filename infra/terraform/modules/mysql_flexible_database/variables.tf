variable "database_name" {
  type        = string
  description = "Nombre de la base de datos lÃ³gica en MySQL Flexible Server (ej. auth_db, person_db, academic_db, enrollment_db, finance_db)."
  default     = null

  validation {
    condition     = var.database_name == null ? true : (length(trimspace(var.database_name)) >= 1 && length(trimspace(var.database_name)) <= 64 && can(regex("^[a-zA-Z0-9_]+$", var.database_name)))
    error_message = "database_name debe tener entre 1 y 64 caracteres alfanumÃ©ricos o guiones bajos."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre de la base de datos lÃ³gica en MySQL Flexible Server."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 64 && can(regex("^[a-zA-Z0-9_]+$", var.name)))
    error_message = "name debe tener entre 1 y 64 caracteres alfanumÃ©ricos o guiones bajos."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor del servidor MySQL."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "server_name" {
  type        = string
  description = "Nombre del servidor MySQL Flexible Server en el que se crearÃ¡ la base de datos."

  validation {
    condition     = length(trimspace(var.server_name)) >= 1
    error_message = "server_name no puede estar vacÃ­o."
  }
}

variable "charset" {
  type        = string
  description = "Juego de caracteres (charset) para la base de datos (default utf8mb4)."
  default     = "utf8mb4"
}

variable "collation" {
  type        = string
  description = "Collation para la base de datos (default utf8mb4_unicode_ci)."
  default     = "utf8mb4_unicode_ci"
}
