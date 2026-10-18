variable "subscription_id" {
  type        = string
  description = "Identificador opcional de la suscripción. Si es null, Azure genera uno automáticamente."
  default     = null
}

variable "api_management_name" {
  type        = string
  description = "Nombre de la instancia de Azure API Management."
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde reside el servicio de APIM."
}

variable "display_name" {
  type        = string
  description = "Nombre descriptivo de la suscripción (ej. 'Portal Web Estudiantil Subscription')."
}

variable "product_id" {
  type        = string
  description = "Resource ID o Product ID del producto al que se asocia la suscripción."
  default     = null
}

variable "api_id" {
  type        = string
  description = "Resource ID o API ID de la API individual a la que se asocia la suscripción."
  default     = null
}

variable "user_id" {
  type        = string
  description = "Resource ID del usuario propietario de la suscripción en APIM (opcional)."
  default     = null
}

variable "state" {
  type        = string
  description = "Estado de la suscripción: active, suspended, submitted, rejected, cancelled."
  default     = "active"

  validation {
    condition     = contains(["active", "suspended", "submitted", "rejected", "cancelled"], var.state)
    error_message = "El estado debe ser uno de: active, suspended, submitted, rejected, cancelled."
  }
}

variable "allow_tracing" {
  type        = bool
  description = "Permite trazabilidad detallada en el Gateway para depuración."
  default     = false
}

variable "primary_key" {
  type        = string
  description = "Clave primaria personalizada (sensible). Si es null, se genera automáticamente."
  default     = null
  sensitive   = true
}

variable "secondary_key" {
  type        = string
  description = "Clave secundaria personalizada (sensible). Si es null, se genera automáticamente."
  default     = null
  sensitive   = true
}
