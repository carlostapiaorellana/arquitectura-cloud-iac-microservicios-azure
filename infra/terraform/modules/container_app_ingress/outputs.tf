output "external_enabled" {
  description = "Valor validado de external_enabled."
  value       = var.external_enabled
}

output "target_port" {
  description = "Puerto de destino validado."
  value       = var.target_port
}

output "transport" {
  description = "Protocolo de transporte validado."
  value       = var.transport
}

output "allow_insecure_connections" {
  description = "Permiso de conexiones inseguras validado."
  value       = var.allow_insecure_connections
}

output "ip_security_restrictions" {
  description = "Reglas de filtrado IP validadas."
  value       = var.ip_security_restrictions
}

output "ingress_configuration" {
  description = "Objeto estructurado con la configuración validada de Ingress para azurerm_container_app."
  value = {
    external_enabled           = var.external_enabled
    target_port                = var.target_port
    transport                  = var.transport
    allow_insecure_connections = var.allow_insecure_connections
    ip_security_restrictions   = var.ip_security_restrictions
  }
  depends_on = [terraform_data.ingress_validation]
}
