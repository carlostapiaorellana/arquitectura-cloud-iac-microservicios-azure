# Módulo Terraform: container_app_secret

Módulo atómico para almacenar secretos en **Azure Key Vault** y generar referencias estructuradas de plano de datos (`aca_secret_reference`) consumibles de forma segura por **Azure Container Apps**.

## Características
- Almacenamiento seguro de secretos en Azure Key Vault.
- Exportación de `versionless_id` para evitar fallos de resolución de versiones al rotar secretos.
- Objeto de salida `aca_secret_reference` formateado para el bloque `secret` de `azurerm_container_app`.

## Entradas
- `secret_name` / `name`: Nombre del secreto en Key Vault.
- `value`: Valor sensible del secreto.
- `key_vault_id`: ID del Azure Key Vault contenedor.
- `identity_id`: ID de la User-Assigned Managed Identity consumidora (opcional).

## Salidas
- `id`: ID versionado del secreto.
- `versionless_id`: ID sin versión para ACA.
- `name`: Nombre del secreto.
- `aca_secret_reference`: Estructura para inyección en Container Apps.
