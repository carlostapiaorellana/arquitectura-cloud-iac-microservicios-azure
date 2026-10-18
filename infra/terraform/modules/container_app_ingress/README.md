# Módulo Terraform: container_app_ingress

Módulo de gobernanza arquitectónica y validación de **Ingress Zero-Trust** para **Azure Container Apps**.

## Características
- Aplica la directiva dura de seguridad de `@secops-guardian` (`AGENTS.md`): bloquea el despliegue si `external_enabled = true` en microservicios que no cumplan `service_role == "gateway"`.
- Estructura las reglas de transporte, puerto destino y restricciones IP.
- Exporta el objeto tipado `ingress_configuration` listo para inyección modular en `container_app`.

## Entradas
- `service_role`: Rol arquitectónico (`gateway`, `microservice`, `cache`).
- `external_enabled`: Exposición pública (default `false`).
- `target_port`: Puerto destino (default `8080`).
- `transport`: Protocolo de transporte (default `auto`).
- `allow_insecure_connections`: Conexiones no seguras (default `false`).
- `ip_security_restrictions`: Restricciones de IP.

## Salidas
- `external_enabled`: Flag validado.
- `target_port`: Puerto validado.
- `ingress_configuration`: Objeto estructurado para Container Apps.
