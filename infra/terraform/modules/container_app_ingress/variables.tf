variable "service_role" {
  type        = string
  description = "Rol del servicio en la arquitectura ('gateway', 'microservice', 'cache')."
  default     = "microservice"

  validation {
    condition     = contains(["gateway", "microservice", "cache"], var.service_role)
    error_message = "service_role debe ser 'gateway', 'microservice' o 'cache'."
  }
}

variable "external_enabled" {
  type        = bool
  description = "Define si el ingress es accesible desde Internet. OBLIGATORIO false para microservicios internos; solo true para API Gateway."
  default     = false
}

variable "target_port" {
  type        = number
  description = "Puerto de destino en el contenedor (default 8080)."
  default     = 8080

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "target_port debe estar entre 1 y 65535."
  }
}

variable "transport" {
  type        = string
  description = "Protocolo de transporte para el Ingress ('auto', 'http', 'http2', 'tcp'). Default auto."
  default     = "auto"

  validation {
    condition     = contains(["auto", "http", "http2", "tcp"], var.transport)
    error_message = "transport debe ser auto, http, http2 o tcp."
  }
}

variable "allow_insecure_connections" {
  type        = bool
  description = "Permite conexiones HTTP sin TLS en el Ingress. Default false (Zero-Trust)."
  default     = false
}

variable "ip_security_restrictions" {
  type = list(object({
    name             = string
    ip_address_range = string
    action           = string
    description      = optional(string)
  }))
  description = "Reglas de filtrado IP para el Ingress."
  default     = []
}
