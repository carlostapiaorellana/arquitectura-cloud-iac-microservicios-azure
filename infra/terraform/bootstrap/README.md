# Bootstrap: Backend Remoto de Terraform State en Azure Storage

## Propósito
Este módulo aprovisiona el Resource Group, Azure Storage Account y Blob Container dedicados para almacenar el estado remoto (`.tfstate`) de Terraform para el Laboratorio 03 (`university-platform`) en Microsoft Azure (`northcentralus`).

## Patrones y Reglas de Seguridad Aplicadas
- **`INC-001` / `AZ-01` (`patron-azure-storage-dev`)**:
  - `public_network_access_enabled = true`
  - `shared_access_key_enabled = true`
  - `https_traffic_only_enabled = true`
  - `min_tls_version = "TLS1_2"`
  - `storage_account_id` referenciado directamente en `azurerm_storage_container` (evita propiedad deprecada `storage_account_name`).
  - `storage_use_azuread = false` en provider azurerm para evitar deadlock 403 AuthorizationFailure en hosts locales.
- **Protección de Datos**:
  - Versionado de blobs activo (`versioning_enabled = true`).
  - Retención de eliminación suave por 7 días (`delete_retention_policy`).
  - `allow_nested_items_to_be_public = false` para garantizar que el state permanezca privado.

## Entradas Principales (Variables)
- `resource_group_name`: Nombre del RG (por defecto `rg-univ-tfstate-ncus`).
- `location`: Región de Azure (por defecto `northcentralus`).
- `storage_account_name`: Nombre explícito o autogenerado con sufijo aleatorio.
- `container_name`: Nombre del contenedor (por defecto `tfstate`).
- `tags`: Mapa con las 6 etiquetas obligatorias de `cloud-standards`.

## Salidas (Outputs)
- `resource_group_name`: Nombre del RG.
- `storage_account_id`: ID del Storage Account.
- `storage_account_name`: Nombre del Storage Account.
- `container_name`: Nombre del contenedor (`tfstate`).
- `primary_access_key`: Clave primaria de acceso (sensitive).
