variable "api_name" {
  type        = string
  description = "Identificador único de la API en Azure API Management."
  default     = null
}

variable "name" {
  type        = string
  description = "Alias para api_name."
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

variable "revision" {
  type        = string
  description = "Revisión de la API dentro de Azure API Management."
  default     = "1"
}

variable "display_name" {
  type        = string
  description = "Nombre descriptivo de la API visible en los portales."
}

variable "path" {
  type        = string
  description = "Ruta relativa del endpoint perimetral de la API (ej. 'api/v1/auth')."
}

variable "protocols" {
  type        = list(string)
  description = "Protocolos de transporte permitidos."
  default     = ["https"]
}

variable "service_url" {
  type        = string
  description = "URL del servicio backend de destino (opcional si se enruta vía backend policy)."
  default     = null
}

variable "subscription_required" {
  type        = bool
  description = "Indica si las peticiones requieren una clave de suscripción Ocp-Apim-Subscription-Key."
  default     = false
}

variable "subscription_key_parameter_names_header" {
  type        = string
  description = "Nombre del encabezado HTTP para la clave de suscripción."
  default     = "Ocp-Apim-Subscription-Key"
}

variable "subscription_key_parameter_names_query" {
  type        = string
  description = "Nombre del parámetro query string para la clave de suscripción."
  default     = "subscription-key"
}

variable "description" {
  type        = string
  description = "Descripción funcional de la API."
  default     = null
}
