variable "api_name" {
  type        = string
  description = "Nombre de la API a la que se aplicará la política (si es null, se aplica a nivel global de APIM)."
  default     = null
}

variable "api_management_name" {
  type        = string
  description = "Nombre de la instancia de Azure API Management (requerido para políticas a nivel de API)."
  default     = null
}

variable "api_management_id" {
  type        = string
  description = "ID del recurso de Azure API Management (requerido para políticas a nivel global)."
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor (requerido para políticas a nivel de API)."
  default     = null
}

variable "xml_content" {
  type        = string
  description = "Contenido XML explícito de la política. Si es null, se autogenera la política canónica Zero-Trust."
  default     = null
}

variable "xml_link" {
  type        = string
  description = "URI externa hacia el archivo de política XML (opcional)."
  default     = null
}

variable "backend_id" {
  type        = string
  description = "ID del backend al que se enrutará el tráfico (<set-backend-service>)."
  default     = null
}

variable "allowed_origins" {
  type        = list(string)
  description = "Lista blanca estricta de orígenes autorizados para CORS."
  default     = ["http://localhost:3000", "http://localhost:5173"]
}

variable "rate_limit_calls" {
  type        = number
  description = "Número máximo de llamadas permitidas dentro de la ventana de renovación."
  default     = 100
}

variable "rate_limit_period_seconds" {
  type        = number
  description = "Duración en segundos de la ventana de renovación para el rate limiting."
  default     = 60
}
