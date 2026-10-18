resource "terraform_data" "ingress_validation" {
  input = {
    service_role               = var.service_role
    external_enabled           = var.external_enabled
    target_port                = var.target_port
    transport                  = var.transport
    allow_insecure_connections = var.allow_insecure_connections
  }

  lifecycle {
    precondition {
      condition     = !(var.external_enabled == true && var.service_role != "gateway")
      error_message = "Violación de Regla Dura de Seguridad Zero-Trust (@secops-guardian / AGENTS.md): external_enabled = true solo está permitido para el servicio con service_role = 'gateway'. Los microservicios de dominio y caché deben tener external_enabled = false."
    }
  }
}
