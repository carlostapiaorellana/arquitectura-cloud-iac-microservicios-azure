variable "app_name" {
  type        = string
  description = "Nombre de la Container App siguiendo CAF (ej. ca-api-gateway, ca-auth-service, entre 2 y 32 caracteres)."
  default     = null

  validation {
    condition     = var.app_name == null ? true : (length(trimspace(var.app_name)) >= 2 && length(trimspace(var.app_name)) <= 32 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.app_name)))
    error_message = "app_name debe tener entre 2 y 32 caracteres alfanumÃ©ricos en minÃºscula o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre de la Container App."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 2 && length(trimspace(var.name)) <= 32 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name)))
    error_message = "name debe tener entre 2 y 32 caracteres alfanumÃ©ricos en minÃºscula o guiones."
  }
}

variable "container_app_environment_id" {
  type        = string
  description = "ID del Azure Container App Environment contenedor."

  validation {
    condition     = length(trimspace(var.container_app_environment_id)) > 0
    error_message = "container_app_environment_id no puede estar vacÃ­o."
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

variable "revision_mode" {
  type        = string
  description = "Modo de revisiÃ³n ('Single' o 'Multiple'). Default Single."
  default     = "Single"

  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode debe ser Single o Multiple."
  }
}

variable "identity_ids" {
  type        = list(string)
  description = "Lista de IDs de User-Assigned Managed Identities asignadas a la Container App."
  default     = []
}

variable "user_assigned_identity_id" {
  type        = string
  description = "ID de la User-Assigned Managed Identity asignada para autenticación ante ACR u otros servicios (opcional)."
  default     = null
}

variable "acr_login_server" {
  type        = string
  description = "Login server de Azure Container Registry para vincular el bloque registry (opcional)."
  default     = null
}

variable "registries" {
  type = list(object({
    server               = string
    identity             = optional(string)
    username             = optional(string)
    password_secret_name = optional(string)
  }))
  description = "Lista de registros de contenedores (ACR) con autenticaciÃ³n vÃ­a Managed Identity o secreto."
  default     = []
}

variable "secrets" {
  type = list(object({
    name                = string
    value               = optional(string)
    key_vault_secret_id = optional(string)
    identity            = optional(string)
  }))
  description = "Lista de secretos montados en la Container App (estÃ¡ticos o referenciados desde Azure Key Vault)."
  default     = []
}

variable "ingress_enabled" {
  type        = bool
  description = "Define si la Container App expone un endpoint HTTP/gRPC de entrada. Default true."
  default     = true
}

variable "external_enabled" {
  type        = bool
  description = "Define si el ingress es accesible desde Internet. OBLIGATORIO false para microservicios internos; solo true para API Gateway."
  default     = false
}

variable "target_port" {
  type        = number
  description = "Puerto TCP/HTTP en el contenedor al cual se enruta el trÃ¡fico (default 8080)."
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

variable "traffic_weights" {
  type = list(object({
    percentage      = number
    latest_revision = optional(bool, true)
    revision_suffix = optional(string)
    label           = optional(string)
  }))
  description = "Reglas de divisiÃ³n de trÃ¡fico entre revisiones."
  default = [{
    percentage      = 100
    latest_revision = true
  }]
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

variable "min_replicas" {
  type        = number
  description = "NÃºmero mÃ­nimo de rÃ©plicas de cÃ³mputo (default 0 para escalar a cero en reposo - FinOps)."
  default     = 0

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 30
    error_message = "min_replicas debe ser un entero entre 0 y 30."
  }
}

variable "max_replicas" {
  type        = number
  description = "NÃºmero mÃ¡ximo de rÃ©plicas de cÃ³mputo (default 3 para respetar cuotas de vCPU estudiantil)."
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 30
    error_message = "max_replicas debe ser un entero entre 1 y 30."
  }
}

variable "container_name" {
  type        = string
  description = "Nombre del contenedor en el template (default null para usar app_name)."
  default     = null
}

variable "image" {
  type        = string
  description = "Ruta completa de la imagen de contenedor (ej. mcr.microsoft.com/k8se/quickstart:latest)."
  default     = "mcr.microsoft.com/k8se/quickstart:latest"

  validation {
    condition     = length(trimspace(var.image)) > 0
    error_message = "image no puede estar vacio."
  }
}

variable "cpu" {
  type        = number
  description = "AsignaciÃ³n de vCPUs para el contenedor (default 0.25 para tier efÃ­mero)."
  default     = 0.25

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.cpu)
    error_message = "cpu debe ser un valor vÃ¡lido admitido por Azure Container Apps (ej. 0.25, 0.5, 1.0, 2.0)."
  }
}

variable "memory" {
  type        = string
  description = "AsignaciÃ³n de memoria RAM para el contenedor (default 0.5Gi para tier efÃ­mero)."
  default     = "0.5Gi"

  validation {
    condition     = contains(["0.5Gi", "1.0Gi", "1.5Gi", "2.0Gi", "3.0Gi", "4.0Gi"], var.memory)
    error_message = "memory debe ser un valor vÃ¡lido admitido por Azure Container Apps (ej. 0.5Gi, 1.0Gi, 2.0Gi)."
  }
}

variable "container_args" {
  type        = list(string)
  description = "Argumentos pasados al entrypoint del contenedor."
  default     = null
}

variable "container_command" {
  type        = list(string)
  description = "Comando de arranque que sobrescribe el entrypoint del contenedor."
  default     = null
}

variable "environment_variables" {
  type = list(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  description = "Variables de entorno inyectadas al contenedor (estÃ¡ticas o vinculadas a secret_name)."
  default     = []
}

variable "liveness_probe" {
  type = object({
    port                    = number
    transport               = optional(string, "HTTP")
    path                    = optional(string, "/health/live")
    initial_delay           = optional(number, 5)
    interval_seconds        = optional(number, 10)
    timeout                 = optional(number, 3)
    failure_count_threshold = optional(number, 3)
  })
  description = "ConfiguraciÃ³n del probe de liveness del contenedor."
  default     = null
}

variable "readiness_probe" {
  type = object({
    port                    = number
    transport               = optional(string, "HTTP")
    path                    = optional(string, "/health/live")
    interval_seconds        = optional(number, 10)
    timeout                 = optional(number, 3)
    failure_count_threshold = optional(number, 3)
    success_count_threshold = optional(number, 1)
  })
  description = "ConfiguraciÃ³n del probe de readiness del contenedor."
  default     = null
}

variable "service_role" {
  type        = string
  description = "Rol del servicio en la arquitectura ('gateway', 'microservice', 'cache'). Permite auditar reglas de ingress."
  default     = "microservice"

  validation {
    condition     = contains(["gateway", "microservice", "cache"], var.service_role)
    error_message = "service_role debe ser 'gateway', 'microservice' o 'cache'."
  }
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
