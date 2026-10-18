variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor del servidor MySQL."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacío."
  }
}

variable "server_name" {
  type        = string
  description = "Nombre del servidor MySQL Flexible Server."

  validation {
    condition     = length(trimspace(var.server_name)) >= 1
    error_message = "server_name no puede estar vacío."
  }
}

variable "configurations" {
  type        = map(string)
  description = "Mapa de configuraciones/parámetros para el servidor MySQL Flexible (ej. require_secure_transport = 'ON', tls_version = 'TLSv1.2,TLSv1.3', max_connections = '150')."
  default     = {}
}

variable "configuration_name" {
  type        = string
  description = "Nombre de un parámetro individual a configurar si no se utiliza el mapa configurations."
  default     = null
}

variable "value" {
  type        = string
  description = "Valor del parámetro individual a configurar."
  default     = null
}
