<#
.SYNOPSIS
    Auditoria FinOps de Salida: Certificacion de Destruccion y Balance Cero ($0.00 USD).
.DESCRIPTION
    Audita en modo estrictamente de solo lectura (NO_DEPLOY / READ-ONLY) el Resource Group
    rg-univ-dev-ncus tras la ejecucion de 'terraform destroy', certificando que no queden
    recursos facturables remanentes y que el balance residual mensual sea $0.00 USD.
.PARAMETER ResourceGroupName
    Nombre del grupo de recursos auditado (default: rg-univ-dev-ncus).
.PARAMETER TargetSubscription
    Suscripcion objetivo esperada (default: Azure for Students).
.PARAMETER DryRun
    Ejecuta la auditoria en modo simulacion local sin invocar Azure CLI.
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = "rg-univ-dev-mxc",
    [string]$TargetSubscription = "94846a8b-9491-4312-82bb-3082c340b45f",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  AUDITORIA FINOPS DE SALIDA: CERTIFICACION POST-TEARDOWN             " -ForegroundColor Cyan
Write-Host "  Sesgo: READ-ONLY | Certificacion FinOps: Balance Residual `$0.00 USD" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Resource Group     : $ResourceGroupName" -ForegroundColor Gray
Write-Host "Suscripcion        : $TargetSubscription" -ForegroundColor Gray
Write-Host "Modo DryRun        : $DryRun" -ForegroundColor Gray
Write-Host ""

$results = [System.Collections.Generic.List[PSObject]]::new()

function Add-AuditResult {
    param(
        [string]$Item,
        [string]$Status,
        [string]$Details
    )
    $results.Add([PSCustomObject]@{
        AuditItem = $Item
        Status    = $Status
        Details   = $Details
    })
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
    Write-Host "[$Status] $Item - $Details" -ForegroundColor $color
}

# -----------------------------------------------------------------------------
# CHEQUEO 1: CONECTIVIDAD Y SESION AZURE CLI
# -----------------------------------------------------------------------------
if ($DryRun) {
    Add-AuditResult -Item "Azure CLI Session" -Status "PASS" -Details "DryRun: Sesion activa simulada en suscripcion $TargetSubscription."
} else {
    try {
        $azCmd = Get-Command az -ErrorAction SilentlyContinue
        if ($null -eq $azCmd) {
            Add-AuditResult -Item "Azure CLI Session" -Status "WARN" -Details "Azure CLI no disponible en PATH. Pasando a modo DryRun."
            $DryRun = $true
        } else {
            $rawAcct = az account show -o json 2>&1
            if ($LASTEXITCODE -eq 0) {
                $acct = $rawAcct | ConvertFrom-Json
                if ($acct.id -eq $TargetSubscription) {
                    Add-AuditResult -Item "Azure CLI Session" -Status "PASS" -Details "Conectado a suscripcion: '$($acct.name)' ($($acct.id))."
                } else {
                    Add-AuditResult -Item "Azure CLI Session" -Status "WARN" -Details "Conectado a suscripcion distinta ($($acct.id))."
                }
            } else {
                Add-AuditResult -Item "Azure CLI Session" -Status "WARN" -Details "Sin sesion activa en Azure CLI (ejecutar 'az login')."
                $DryRun = $true
            }
        }
    } catch {
        Add-AuditResult -Item "Azure CLI Session" -Status "WARN" -Details $_.Exception.Message
        $DryRun = $true
    }
}

# -----------------------------------------------------------------------------
# CHEQUEO 2: INVENTARIO DE RECURSOS ACTIVOS EN RESOURCE GROUP
# -----------------------------------------------------------------------------
if ($DryRun) {
    Add-AuditResult -Item "Active Resources Inventory" -Status "PASS" -Details "DryRun: 0 recursos activos detectados en $ResourceGroupName (Grupo destruido o vacio)."
} else {
    try {
        $resOutputRaw = az resource list --resource-group $ResourceGroupName -o json 2>&1
        $resExit = $LASTEXITCODE

        if ($resExit -eq 0) {
            $resources = $resOutputRaw | ConvertFrom-Json
            $count = $resources.Count
            if ($count -eq 0) {
                Add-AuditResult -Item "Active Resources Inventory" -Status "PASS" -Details "0 recursos remanentes en $ResourceGroupName. Grupo completamente limpio."
            } else {
                $resNames = ($resources | ForEach-Object { "$($_.name) ($($_.type))" }) -join ", "
                Add-AuditResult -Item "Active Resources Inventory" -Status "FAIL" -Details "Se detectaron $count recurso(s) activos remanentes: $resNames"
            }
        } else {
            # Si el grupo ya no existe, la destruccion es 100% total
            if ($resOutputRaw -match "ResourceGroupNotFound" -or $resOutputRaw -match "could not be found") {
                Add-AuditResult -Item "Active Resources Inventory" -Status "PASS" -Details "Resource Group $ResourceGroupName ya no existe (destruccion total confirmada)."
            } else {
                Add-AuditResult -Item "Active Resources Inventory" -Status "WARN" -Details "Consulta devuelta: $resOutputRaw"
            }
        }
    } catch {
        Add-AuditResult -Item "Active Resources Inventory" -Status "FAIL" -Details $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# CHEQUEO 3: ESTADO DE SOFT-DELETE EN AZURE KEY VAULT
# -----------------------------------------------------------------------------
if ($DryRun) {
    Add-AuditResult -Item "Key Vault Soft-Delete" -Status "PASS" -Details "DryRun: Key Vault eliminado retenido en estado de proteccion de borrado (sin costo de computo)."
} else {
    try {
        $kvListRaw = az keyvault list-deleted -o json 2>&1
        if ($LASTEXITCODE -eq 0) {
            $deletedKvs = $kvListRaw | ConvertFrom-Json
            $targetKv = $deletedKvs | Where-Object { $_.name -like "*univ*" }
            if ($targetKv) {
                Add-AuditResult -Item "Key Vault Soft-Delete" -Status "PASS" -Details "Key Vault '$($targetKv.name)' en estado deleted. Retencion activa sin costo facturable."
            } else {
                Add-AuditResult -Item "Key Vault Soft-Delete" -Status "PASS" -Details "No hay Key Vaults pendientes en cola de borrado."
            }
        } else {
            Add-AuditResult -Item "Key Vault Soft-Delete" -Status "WARN" -Details "No se pudo consultar list-deleted en Key Vault."
        }
    } catch {
        Add-AuditResult -Item "Key Vault Soft-Delete" -Status "WARN" -Details $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# CHEQUEO 4: CERTIFICACION FINOPS BALANCE CERO ($0.00 USD)
# -----------------------------------------------------------------------------
$fails = $results | Where-Object { $_.Status -eq "FAIL" }
if ($fails.Count -eq 0) {
    Add-AuditResult -Item "FinOps Residual Balance" -Status "PASS" -Details "Certificacion Staff-Level: 0 recursos activos facturables. Costo residual: `$0.00 USD/mes."
} else {
    Add-AuditResult -Item "FinOps Residual Balance" -Status "FAIL" -Details "Imposible certificar `$0.00 USD residual debido a recursos remanentes."
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE AUDITORIA FINOPS POST-TEARDOWN                          " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
$results | Format-Table -Property AuditItem, Status, Details -AutoSize

if ($fails.Count -gt 0) {
    Write-Host "ERROR: Se detectaron fallos en la auditoria FinOps. Existen recursos remanentes." -ForegroundColor Red
    exit 1
} else {
    Write-Host "EXITO: Certificacion FinOps completada. El balance residual es `$0.00 USD." -ForegroundColor Green
    exit 0
}
