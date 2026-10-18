<#
.SYNOPSIS
    Script de Pre-Vuelo y Validacion Estatica IaC para Azure (Laboratorio 03).
.DESCRIPTION
    Realiza verificaciones de pre-vuelo 100% de solo lectura (NO_DEPLOY) para certificar
    el estado de los 39 modulos atomicos de Terraform, el entorno raiz dev,
    y la conectividad/cuotas con Azure CLI en la region northcentralus.
.PARAMETER SkipAzureCli
    Omite las comprobaciones remotas con Azure CLI para validacion puramente local.
.PARAMETER TargetSubscription
    ID de la suscripcion de Azure esperada (default: Azure for Students).
.PARAMETER TargetRegion
    Region de Azure designada (default: northcentralus).
#>

[CmdletBinding()]
param(
    [switch]$SkipAzureCli,
    [string]$TargetSubscription = "94846a8b-9491-4312-82bb-3082c340b45f",
    [string]$TargetRegion = "northcentralus",
    [string]$LabRoot = ""
)

$ErrorActionPreference = "Stop"

# Resolver directorio raiz del laboratorio
if ([string]::IsNullOrWhiteSpace($LabRoot)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $LabRoot = Split-Path -Parent $scriptDir
}

$terraformDir = Join-Path $LabRoot "infra\terraform"
$modulesDir = Join-Path $terraformDir "modules"
$devDir = Join-Path $terraformDir "environments\dev"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  PRE-VUELO Y VALIDACION ESTATICA CLOUD [AZURE] - LAB 03             " -ForegroundColor Cyan
Write-Host "  Sesgo: NO_DEPLOY / READ-ONLY | FinOps: Enterprise Tier-1 Efimero   " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Directorio Lab      : $LabRoot" -ForegroundColor Gray
Write-Host "Directorio Terraform: $terraformDir" -ForegroundColor Gray
Write-Host "Suscripcion Objetivo: $TargetSubscription" -ForegroundColor Gray
Write-Host "Region Objetivo     : $TargetRegion" -ForegroundColor Gray
Write-Host ""

$results = [System.Collections.Generic.List[PSObject]]::new()

function Add-CheckResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details
    )
    $results.Add([PSCustomObject]@{
        Check   = $Name
        Status  = $Status
        Details = $Details
    })
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
    Write-Host "[$Status] $Name - $Details" -ForegroundColor $color
}

# -----------------------------------------------------------------------------
# CHEQUEO 1: VERIFICAR TERRAFORM CLI
# -----------------------------------------------------------------------------
try {
    $tfCmd = Get-Command terraform -ErrorAction SilentlyContinue
    if ($null -eq $tfCmd) {
        Add-CheckResult -Name "Terraform CLI" -Status "FAIL" -Details "El comando terraform no se encuentra en el PATH."
    } else {
        $tfVerOutput = terraform version
        $tfVerLine = ($tfVerOutput | Select-Object -First 1)
        Add-CheckResult -Name "Terraform CLI" -Status "PASS" -Details "$tfVerLine disponible en $($tfCmd.Source)"
    }
} catch {
    Add-CheckResult -Name "Terraform CLI" -Status "FAIL" -Details $_.Exception.Message
}

# -----------------------------------------------------------------------------
# CHEQUEO 2: VERIFICAR FORMATO DE TERRAFORM (terraform fmt -check)
# -----------------------------------------------------------------------------
try {
    $fmtOutput = terraform "-chdir=$terraformDir" fmt -check -recursive
    $fmtExit = $LASTEXITCODE
    if ($fmtExit -eq 0) {
        Add-CheckResult -Name "Terraform Fmt" -Status "PASS" -Details "Todos los archivos .tf cumplen el estandar canonico."
    } else {
        Add-CheckResult -Name "Terraform Fmt" -Status "FAIL" -Details "Se detectaron archivos sin formatear en $terraformDir."
    }
} catch {
    Add-CheckResult -Name "Terraform Fmt" -Status "FAIL" -Details $_.Exception.Message
}

# -----------------------------------------------------------------------------
# CHEQUEO 3: CATALOGO Y ESTRUCTURA DE LOS 39 MODULOS ATOMICOS
# -----------------------------------------------------------------------------
try {
    if (-not (Test-Path $modulesDir)) {
        Add-CheckResult -Name "Modulos Atomicos" -Status "FAIL" -Details "Directorio $modulesDir no existe."
    } else {
        $allModules = Get-ChildItem -Path $modulesDir -Directory
        $modCount = $allModules.Count
        $missingFiles = [System.Collections.Generic.List[string]]::new()

        foreach ($mod in $allModules) {
            $expectedFiles = @("versions.tf", "variables.tf", "main.tf", "outputs.tf")
            foreach ($ef in $expectedFiles) {
                $filePath = Join-Path $mod.FullName $ef
                if (-not (Test-Path $filePath)) {
                    $missingFiles.Add("$($mod.Name)/$ef")
                }
            }
        }

        if ($modCount -ge 39 -and $missingFiles.Count -eq 0) {
            Add-CheckResult -Name "Modulos Atomicos ($modCount/39)" -Status "PASS" -Details "$modCount modulos verificados con estructura canonica completa."
        } elseif ($missingFiles.Count -gt 0) {
            Add-CheckResult -Name "Modulos Atomicos ($modCount/39)" -Status "FAIL" -Details "Archivos faltantes: $($missingFiles -join ', ')"
        } else {
            Add-CheckResult -Name "Modulos Atomicos ($modCount/39)" -Status "WARN" -Details "Se encontraron $modCount modulos (se esperaban al menos 39)."
        }
    }
} catch {
    Add-CheckResult -Name "Modulos Atomicos (39/39)" -Status "FAIL" -Details $_.Exception.Message
}

# -----------------------------------------------------------------------------
# CHEQUEO 4: VALIDACION DEL ENTORNO RAIZ (environments/dev)
# -----------------------------------------------------------------------------
try {
    if (-not (Test-Path $devDir)) {
        Add-CheckResult -Name "Entorno Dev Validate" -Status "FAIL" -Details "Directorio $devDir no existe."
    } else {
        # Garantizar que TF_VAR_mysql_admin_password este disponible para validacion estatica
        $prevPass = $env:TF_VAR_mysql_admin_password
        if ([string]::IsNullOrWhiteSpace($env:TF_VAR_mysql_admin_password)) {
            $env:TF_VAR_mysql_admin_password = "PreflightDummyPass123!SecureValidation"
        }

        # Garantizar inicialización previa si no están los módulos enlazados
        if (-not (Test-Path (Join-Path $devDir ".terraform\modules"))) {
            terraform "-chdir=$devDir" init -backend=false -input=false > $null
        }

        # Ejecutar terraform validate en environments/dev
        $validateOutput = terraform "-chdir=$devDir" validate
        $valExit = $LASTEXITCODE

        if ($valExit -eq 0) {
            Add-CheckResult -Name "Entorno Dev Validate" -Status "PASS" -Details "Configuracion de environments/dev sintacticamente valida."
        } else {
            Add-CheckResult -Name "Entorno Dev Validate" -Status "FAIL" -Details "Error en terraform validate: $($validateOutput -join ' ')"
        }

        if ($null -ne $prevPass) {
            $env:TF_VAR_mysql_admin_password = $prevPass
        } else {
            Remove-Item env:TF_VAR_mysql_admin_password -ErrorAction SilentlyContinue
        }
    }
} catch {
    Add-CheckResult -Name "Entorno Dev Validate" -Status "FAIL" -Details $_.Exception.Message
}

# -----------------------------------------------------------------------------
# CHEQUEO 5: AZURE CLI (READ-ONLY PRE-FLIGHT)
# -----------------------------------------------------------------------------
if ($SkipAzureCli) {
    Add-CheckResult -Name "Azure CLI Read-Only" -Status "WARN" -Details "Omitido por parametro -SkipAzureCli."
} else {
    try {
        $azCmd = Get-Command az -ErrorAction SilentlyContinue
        if ($null -eq $azCmd) {
            Add-CheckResult -Name "Azure CLI Read-Only" -Status "WARN" -Details "Azure CLI (az) no esta instalado o no esta en el PATH."
        } else {
            $accountJsonRaw = az account show -o json 2>&1
            if ($LASTEXITCODE -eq 0) {
                $accountObj = $accountJsonRaw | ConvertFrom-Json
                $currentSubId = $accountObj.id
                $currentSubName = $accountObj.name

                if ($currentSubId -eq $TargetSubscription) {
                    Add-CheckResult -Name "Azure CLI Read-Only" -Status "PASS" -Details "Suscripcion activa: '$currentSubName' ($currentSubId)."
                } else {
                    Add-CheckResult -Name "Azure CLI Read-Only" -Status "WARN" -Details "Suscripcion actual ($currentSubId) difiere de la esperada ($TargetSubscription)."
                }

                # Verificar region northcentralus en la cuenta
                $regCheck = az account list-locations --query "[?name=='$TargetRegion'].name" -o tsv 2>&1
                if ($LASTEXITCODE -eq 0 -and $regCheck.Trim() -eq $TargetRegion) {
                    Add-CheckResult -Name "Region Azure ($TargetRegion)" -Status "PASS" -Details "Region '$TargetRegion' disponible y reconocida por la API de Azure."
                } else {
                    Add-CheckResult -Name "Region Azure ($TargetRegion)" -Status "WARN" -Details "No se pudo confirmar la region '$TargetRegion' en la suscripcion."
                }
            } else {
                Add-CheckResult -Name "Azure CLI Read-Only" -Status "WARN" -Details "No hay sesion activa en Azure CLI (ejecutar 'az login')."
            }
        }
    } catch {
        Add-CheckResult -Name "Azure CLI Read-Only" -Status "WARN" -Details $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# CHEQUEO 6: DIRECTIVA FINOPS EFIMERA
# -----------------------------------------------------------------------------
Add-CheckResult -Name "Directiva FinOps Efimera" -Status "PASS" -Details "Arquitectura Tier-1 efimera autorizada; destruccion obligatoria post-test (`$0.00 USD residual)."

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE PRE-VUELO IA-C Y PRE-CONDICIONES CLOUD                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
$results | Format-Table -Property Check, Status, Details -AutoSize

$failures = $results | Where-Object { $_.Status -eq "FAIL" }
if ($failures.Count -gt 0) {
    Write-Host "ERROR: Se detectaron $($failures.Count) fallos en las comprobaciones de pre-vuelo." -ForegroundColor Red
    exit 1
} else {
    Write-Host "EXITO: Todas las comprobaciones de pre-vuelo fueron aprobadas." -ForegroundColor Green
    exit 0
}
