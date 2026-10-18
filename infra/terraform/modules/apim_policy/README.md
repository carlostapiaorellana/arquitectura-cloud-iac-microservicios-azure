# Módulo Terraform: apim_policy (Módulo 36)

Gestiona políticas XML perimetrales tanto a nivel de API individual como global en **Azure API Management**.

## Características Técnicas
- **CORS Zero-Trust**: Lista blanca estricta de orígenes autorizados (`http://localhost:3000`, `http://localhost:5173`), métodos HTTP estándar y cabeceras expuestas.
- **Header Stripping**: Eliminación preventiva de cabeceras de identidad entrantes (`X-User-Id`, `X-User-Role`, `X-User-Scopes`) para evitar spoofing desde el exterior.
- **Trazabilidad Distribuida**: Generación automática de `X-Correlation-Id` (GUID/ULID) si el cliente no lo envía.
- **Rate Limiting**: Control de flujo por dirección IP cliente (`rate-limit-by-key`).
- **Enrutamiento a Backend**: Inyección declarativa de `<set-backend-service>` cuando se proporciona `backend_id`.

## Entradas Principales
- `api_name`: Nombre de la API (para política a nivel de API). Si es null, aplica globalmente.
- `api_management_name`: Nombre del servicio APIM.
- `api_management_id`: ID del servicio APIM (requerido para políticas globales).
- `resource_group_name`: Nombre del Resource Group.
- `backend_id`: ID del backend de APIM de destino.
- `allowed_origins`: Lista de orígenes autorizados para CORS.
- `rate_limit_calls` / `rate_limit_period_seconds`: Cuota de peticiones por ventana de tiempo.

## Salidas
- `id`: Resource ID de la política aplicada.
- `xml_content`: Contenido XML de la política efectiva.
