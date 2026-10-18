variable "product_id" {
  type        = string
  description = "Identificador único del producto en Azure API Management."
  default     = null
}

variable "name" {
  type        = string
  description = "Alias para product_id."
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
  description = "Nombre descriptivo del producto visible para los consumidores."
}

variable "description" {
  type        = string
  description = "Descripción del producto y alcance de las APIs agrupadas."
  default     = null
}

variable "subscription_required" {
  type        = bool
  description = "Indica si se requiere suscripción para consumir las APIs del producto."
  default     = true
}

variable "approval_required" {
  type        = bool
  description = "Indica si la suscripción requiere aprobación administrativa previa."
  default     = false
}

variable "published" {
  type        = bool
  description = "Indica si el producto está publicado y disponible en el catálogo."
  default     = true
}

variable "subscriptions_limit" {
  type        = number
  description = "Número máximo de suscripciones simultáneas permitidas para el producto."
  default     = 10
}

variable "terms" {
  type        = string
  description = "Términos y condiciones de uso del producto."
  default     = null
}

variable "api_names" {
  type        = list(string)
  description = "Lista de nombres de APIs a vincular declarativamente a este producto."
  default     = []
}
