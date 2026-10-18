# ==============================================================================
# Script: scripts/test-e2e-resilience.ps1
# Suite de Pruebas E2E, Rendimiento Concurrente y Resiliencia Local (Lab 03)
# Cumple Invariantes: PS-01, PS-04, DC-05, REV-E2E-01 a REV-E2E-06
# ==============================================================================
param (
    [string]$BaseUrl = "http://localhost:8080",
    [string]$WebUrl = "http://localhost:3000",
    [string]$ComposeFile = "docker/docker-compose.local.yml"
)

$ErrorActionPreference = "Stop"

$totalChecks = 0
$passedChecks = 0
$failedChecks = 0

function Report-Check {
    param (
        [string]$Name,
        [bool]$Success,
        [string]$Detail = ""
    )
    $script:totalChecks++
    if ($Success) {
        $script:passedChecks++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        if ($Detail) {
            Write-Host "         $Detail" -ForegroundColor Gray
        }
    } else {
        $script:failedChecks++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        if ($Detail) {
            Write-Host "         Detalle: $Detail" -ForegroundColor Yellow
        }
    }
}

function Invoke-DockerCompose {
    param([string[]]$ArgsList)
    $oldEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & docker compose -f $ComposeFile @ArgsList 2>&1 | Out-Null
    } finally {
        $ErrorActionPreference = $oldEap
    }
}

function Wait-ContainerHealthy {
    param (
        [string]$ContainerName,
        [int]$MaxTimeoutSec = 30
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $MaxTimeoutSec) {
        $oldEap = $ErrorActionPreference
        $inspectJson = $null
        try {
            $ErrorActionPreference = "Continue"
            $inspectJson = & docker inspect $ContainerName 2>&1
        } finally {
            $ErrorActionPreference = $oldEap
        }
        if ($LASTEXITCODE -eq 0 -and $inspectJson) {
            try {
                $info = $inspectJson | ConvertFrom-Json
                $healthStatus = $info[0].State.Health.Status
                if ($healthStatus -eq "healthy") {
                    return $true
                }
            } catch {
                # JSON incompleto durante arranque
            }
        }
        Start-Sleep -Seconds 2
    }
    return $false
}

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " SUITE DE PRUEBAS E2E, RENDIMIENTO Y RESILIENCIA LOCAL (LAB 03)" -ForegroundColor Cyan
Write-Host " Target Gateway: $BaseUrl | Target Web: $WebUrl" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# ==============================================================================
# BLOQUE 1: USER JOURNEYS E2E & TELEMETRÍA DE RENDIMIENTO
# ==============================================================================
Write-Host "`n>>> BLOQUE 1: User Journeys E2E & Telemetría" -ForegroundColor Yellow

# Check 1.1: Web Portal Nginx No-Root & Cabeceras de Seguridad (REV-E2E-06)
try {
    $webResp = Invoke-WebRequest -Uri $WebUrl -Method GET -TimeoutSec 10 -UseBasicParsing
    $hasRoot = $webResp.Content -match '<div id="root">'
    $hasFrameOpt = $webResp.Headers["X-Frame-Options"] -ne $null
    $hasContentTypeOpt = $webResp.Headers["X-Content-Type-Options"] -ne $null

    $webSuccess = ($webResp.StatusCode -eq 200) -and $hasRoot -and $hasFrameOpt -and $hasContentTypeOpt
    Report-Check "Check 1.1: Web Portal Nginx No-Root y Cabeceras de Seguridad" $webSuccess "Status: $($webResp.StatusCode) | Root Div: $hasRoot | X-Frame-Options: $($webResp.Headers['X-Frame-Options']) | X-Content-Type-Options: $($webResp.Headers['X-Content-Type-Options'])"
} catch {
    Report-Check "Check 1.1: Web Portal Nginx No-Root y Cabeceras de Seguridad" $false $_.Exception.Message
}

# Check 1.2: Login Institucional y Captura de Token JWT RS256
$token = $null
try {
    $loginBody = @{
        username = "alu01"
        password = "password123"
    } | ConvertTo-Json

    $loginResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 10
    if ($loginResp.accessToken) {
        $token = $loginResp.accessToken
        Report-Check "Check 1.2: Login Institucional (alu01) y Emisión JWT RS256" $true "Usuario: $($loginResp.username) | Rol: $($loginResp.role) | Token Chars: $($token.Length)"
    } else {
        Report-Check "Check 1.2: Login Institucional (alu01) y Emisión JWT RS256" $false "Respuesta sin accessToken"
    }
} catch {
    Report-Check "Check 1.2: Login Institucional (alu01) y Emisión JWT RS256" $false $_.Exception.Message
}

# Check 1.3: Carga Concurrente y Telemetría de Caché (test-load-runner.mjs)
$authHeader = if ($token) { @{ Authorization = "Bearer $token" } } else { @{} }
if ($token) {
    try {
        # Warmup de 1 petición para inicializar conexiones de red
        Invoke-RestMethod -Uri "$BaseUrl/api/v1/person/profile/me" -Headers $authHeader -TimeoutSec 5 | Out-Null

        $runnerScript = Join-Path $PSScriptRoot "test-load-runner.mjs"
        $loadOutput = & node "$runnerScript" --url "$BaseUrl/api/v1/person/profile/me" --token "$token" --requests 100 --concurrency 5 --output json
        $metrics = $loadOutput | ConvertFrom-Json

        $reqPass = ($metrics.successfulRequests -eq 100) -and ($metrics.failedRequests -eq 0)
        $cachePass = ($metrics.cache.hitRatioPercent -ge 90.0)
        $p95Pass = ($metrics.latenciesMs.p95 -lt 800.0)

        $loadSuccess = $reqPass -and $cachePass -and $p95Pass
        Report-Check "Check 1.3: Carga Concurrente de Perfil (100 reqs, 5 workers)" $loadSuccess "Exitosas: $($metrics.successfulRequests)/$($metrics.totalRequests) | Hit Ratio: $($metrics.cache.hitRatioPercent)% (>=90%) | p95: $($metrics.latenciesMs.p95)ms (<800ms) | Throughput: $($metrics.throughputRps) req/s"
    } catch {
        Report-Check "Check 1.3: Carga Concurrente de Perfil (100 reqs, 5 workers)" $false $_.Exception.Message
    }
} else {
    Report-Check "Check 1.3: Carga Concurrente de Perfil" $false "Omitido por falta de token JWT"
}

# Check 1.4: Exploración Académica y Récord Vigesimal
try {
    $academicResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/academic/courses" -Method GET -TimeoutSec 10
    $academicList = @(if ($academicResp.data) { $academicResp.data } else { $academicResp })
    $hasCourses = ($academicList.Count -gt 0)

    $gradesResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/enrollment/grades" -Method GET -Headers $authHeader -TimeoutSec 10
    $gradesList = @(if ($gradesResp.data) { $gradesResp.data } else { $gradesResp })
    $hasGrades = ($gradesList.Count -gt 0)

    $vigesimalValid = $true
    if ($hasGrades) {
        foreach ($g in $gradesList) {
            $val = if ($null -ne $g.score) { [double]$g.score } elseif ($null -ne $g.finalGrade) { [double]$g.finalGrade } else { 0.0 }
            if ($val -lt 0.0 -or $val -gt 20.0) {
                $vigesimalValid = $false
                break
            }
        }
    }

    $acadSuccess = $hasCourses -and $hasGrades -and $vigesimalValid
    Report-Check "Check 1.4: Exploración Académica y Récord Vigesimal (0-20)" $acadSuccess "Cursos: $($academicList.Count) | Registros de Notas: $($gradesList.Count) | Rango Vigesimal Válido: $vigesimalValid"
} catch {
    Report-Check "Check 1.4: Exploración Académica y Récord Vigesimal (0-20)" $false $_.Exception.Message
}

# Check 1.5: Catálogo y Biblioteca NoSQL (DynamoDB Local)
try {
    $booksResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/library/books" -Method GET -TimeoutSec 10
    $booksList = @(if ($booksResp.data) { $booksResp.data } else { $booksResp })
    $hasBooks = ($booksList.Count -gt 0)

    $lmsResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/lms/my-courses" -Method GET -Headers $authHeader -TimeoutSec 10
    $lmsList = @(if ($lmsResp.data) { $lmsResp.data } else { $lmsResp })
    $hasLms = ($lmsList.Count -gt 0)

    $nosqlSuccess = $hasBooks -and $hasLms
    Report-Check "Check 1.5: Catálogo y Biblioteca NoSQL (DynamoDB Local)" $nosqlSuccess "Libros en Biblioteca: $($booksList.Count) | Cursos LMS Virtual: $($lmsList.Count)"
} catch {
    Report-Check "Check 1.5: Catálogo y Biblioteca NoSQL (DynamoDB Local)" $false $_.Exception.Message
}

# ==============================================================================
# BLOQUE 2: IDEMPOTENCIA Y CONCURRENCIA FINANCIERA (REV-E2E-03 / REV-E2E-04)
# ==============================================================================
Write-Host "`n>>> BLOQUE 2: Idempotencia y Concurrencia Financiera" -ForegroundColor Yellow

try {
    $ordersResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/finance/my-orders" -Method GET -Headers $authHeader -TimeoutSec 10
    $ordersList = @(if ($ordersResp.data) { $ordersResp.data } else { $ordersResp })
    $pendingOrder = $ordersList | Where-Object { $_.statusId -eq 1 -or $_.status -eq "PENDING" -or $_.statusCode -eq "PENDING" } | Select-Object -First 1

    if (-not $pendingOrder) {
        # Auto-recuperación idempotente: asegurar orden 2 en estado PENDING en MySQL
        Write-Host "  [INFO] Sin órdenes PENDING en memoria; ejecutando re-activación de orden 2 en finance_db..." -ForegroundColor Cyan
        $oldEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            & docker exec -e MYSQL_PWD=root_dev_password_123 -i univ-local-mysql mysql -uroot -e "USE finance_db; UPDATE payment_orders SET status_id = 1 WHERE id = 2;" 2>&1 | Out-Null
        } finally {
            $ErrorActionPreference = $oldEap
        }
        $ordersResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/finance/my-orders" -Method GET -Headers $authHeader -TimeoutSec 10
        $ordersList = @(if ($ordersResp.data) { $ordersResp.data } else { $ordersResp })
        $pendingOrder = $ordersList | Where-Object { $_.id -eq 2 } | Select-Object -First 1
    }

    $targetOrderId = if ($pendingOrder) { $pendingOrder.id } else { 2 }
    $targetAmount = if ($pendingOrder -and $pendingOrder.amount) { $pendingOrder.amount } else { 850.00 }
    $idempKey = "PAY-IDEMP-STRESS-$([System.DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"

    Write-Host "  [INFO] Ejecutando ráfaga concurrente de 10 pagos hacia Orden ID $targetOrderId con clave: $idempKey" -ForegroundColor Cyan

    $payPayload = @{
        paymentOrderId = [int]$targetOrderId
        amount = [double]$targetAmount
        methodCode = "CARD"
    } | ConvertTo-Json -Compress

    $bodyB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payPayload))

    $runnerScript = Join-Path $PSScriptRoot "test-load-runner.mjs"
    $payOutput = & node "$runnerScript" --url "$BaseUrl/api/v1/finance/payments" --method POST --token "$token" --header "Idempotency-Key: $idempKey" --body-base64 "$bodyB64" --requests 10 --concurrency 10 --output json
    $payMetrics = $payOutput | ConvertFrom-Json

    # Aserción 1: En ráfaga concurrente pura, exactamente 1 transacción es procesada (200/201),
    # y las carreras concurrentes son contenidas con 409 Conflict o 200 sin arrojar errores 500 (REV-E2E-03)
    $validBurstCodes = @(200, 201, 409)
    $burstSafe = $true
    foreach ($sc in $payMetrics.statusCodes.PSObject.Properties) {
        if ([int]$sc.Name -notin $validBurstCodes) {
            $burstSafe = $false
        }
    }

    # Aserción 2: Reintento secuencial inmediato con la misma Idempotency-Key
    # Certifica que Redis retorna HTTP 200/201 con el recibo idéntico cacheado sin tocar MySQL
    $replayResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/finance/payments" -Method POST -Headers @{ Authorization = "Bearer $token"; "Idempotency-Key" = $idempKey; "Content-Type" = "application/json" } -Body $payPayload -TimeoutSec 10 -UseBasicParsing
    $replaySuccess = ($replayResp.StatusCode -eq 200 -or $replayResp.StatusCode -eq 201)

    # Aserción 3: Verificación de persistencia única en MySQL (REV-E2E-04)
    $sqlQuery = "SELECT COUNT(*) FROM payments WHERE idempotency_key = '$idempKey';"
    $oldEap = $ErrorActionPreference
    $dbCountRaw = ""
    try {
        $ErrorActionPreference = "Continue"
        $dbCountRaw = & docker exec -e MYSQL_PWD=root_dev_password_123 -i univ-local-mysql mysql -uroot -N -e "USE finance_db; $sqlQuery" 2>&1
    } finally {
        $ErrorActionPreference = $oldEap
    }
    $dbRowCount = -1
    if ($dbCountRaw) {
        $dbRowCount = [int]($dbCountRaw.ToString().Trim())
    }

    $idempSuccess = $burstSafe -and $replaySuccess -and ($dbRowCount -eq 1)
    Report-Check "Check 2.1: Idempotencia Financiera Concurrente (10 POSTs concurrentes)" $idempSuccess "Ráfaga Concurrente Segura (0 errores 500): $burstSafe | Reintento Redis 200 OK: $replaySuccess | Filas en MySQL finance_db.payments: $dbRowCount (estrictamente 1)"
} catch {
    Report-Check "Check 2.1: Idempotencia Financiera Concurrente" $false $_.Exception.Message
}

# ==============================================================================
# BLOQUE 3: INYECCIÓN DE CAOS (CHAOS ENGINEERING) & BLAST RADIUS CERO
# ==============================================================================
Write-Host "`n>>> BLOQUE 3: Inyección de Caos (Chaos Engineering) & Blast Radius Cero" -ForegroundColor Yellow

# Escenario Caos A: Caída Temporal de Redis (Fail-Open de degradación grácil)
try {
    Write-Host "  [CAOS A] Deteniendo contenedor 'redis'..." -ForegroundColor Cyan
    Invoke-DockerCompose @("stop", "redis")

    # Consulta inmediata esperando Fail-Open (200 OK consultando MySQL)
    $failOpenResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/person/profile/me" -Method GET -Headers $authHeader -TimeoutSec 10 -UseBasicParsing
    $failOpenOk = ($failOpenResp.StatusCode -eq 200)

    Write-Host "  [CAOS A] Reiniciando contenedor 'redis'..." -ForegroundColor Cyan
    Invoke-DockerCompose @("start", "redis")
    $redisHealthy = Wait-ContainerHealthy "univ-local-redis" 30

    $caosASuccess = $failOpenOk -and $redisHealthy
    Report-Check "Check 3.1: Caos A - Degradación Grácil Fail-Open ante Caída de Redis" $caosASuccess "Status con Redis DOWN: $($failOpenResp.StatusCode) (200 OK) | Redis recuperado healthy: $redisHealthy"
} catch {
    Report-Check "Check 3.1: Caos A - Degradación Grácil Fail-Open ante Caída de Redis" $false $_.Exception.Message
    # Intento de rescate si falló
    Invoke-DockerCompose @("start", "redis")
}

# Escenario Caos B: Caída de academic-service y Verificación de Blast Radius 0% (REV-E2E-02, REV-E2E-05)
try {
    Write-Host "  [CAOS B] Deteniendo contenedor 'academic-service'..." -ForegroundColor Cyan
    Invoke-DockerCompose @("stop", "academic-service")

    # 1. Gateway debe responder 503 con sobre canónico JSON
    $academic503Ok = $false
    $corrIdPresent = $false
    $canonicalCodeOk = $false

    try {
        $acadReq = [System.Net.HttpWebRequest]::Create("$BaseUrl/api/v1/academic/courses")
        $acadReq.Method = "GET"
        $acadReq.Timeout = 10000
        $acadReq.GetResponse() | Out-Null
    } catch [System.Net.WebException] {
        $webEx = $_.Exception
        if ($webEx.Response) {
            $resp503 = [System.Net.HttpWebResponse]$webEx.Response
            if ([int]$resp503.StatusCode -eq 503) {
                $academic503Ok = $true
            }
            $corrIdHeader = $resp503.Headers["X-Correlation-Id"]
            if ($corrIdHeader) { $corrIdPresent = $true }

            $reader = [System.IO.StreamReader]::new($resp503.GetResponseStream())
            $body503 = $reader.ReadToEnd()
            $reader.Close()

            try {
                $json503 = $body503 | ConvertFrom-Json
                if ($json503.error.code -eq "SERVICE_UNAVAILABLE" -and $json503.error.status -eq 503) {
                    $canonicalCodeOk = $true
                }
            } catch {
                # Body no era JSON
            }
            $resp503.Close()
        }
    }

    $gw503Success = $academic503Ok -and $corrIdPresent -and $canonicalCodeOk
    Report-Check "Check 3.2.1: Gateway Intercepta Upstream Caído con HTTP 503 y JSON Canónico" $gw503Success "HTTP 503: $academic503Ok | X-Correlation-Id: $corrIdPresent | Code SERVICE_UNAVAILABLE: $canonicalCodeOk"

    # 2. Verificación de Blast Radius 0% en los otros 6 microservicios (REV-E2E-05)
    $authCheck = $false
    try { $authCheck = (Invoke-WebRequest -Uri "$BaseUrl/.well-known/jwks.json" -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 } catch {}
    $personCheck = $false
    try { $personCheck = (Invoke-WebRequest -Uri "$BaseUrl/api/v1/person/profile/me" -Headers $authHeader -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 } catch {}
    $enrollCheck = $false
    try { $enrollCheck = (Invoke-WebRequest -Uri "$BaseUrl/api/v1/enrollment/my-enrollments" -Headers $authHeader -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 } catch {}
    $financeCheck = $false
    try { $financeCheck = (Invoke-WebRequest -Uri "$BaseUrl/api/v1/finance/my-orders" -Headers $authHeader -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 } catch {}
    $libraryCheck = $false
    try { $libraryCheck = (Invoke-WebRequest -Uri "$BaseUrl/api/v1/library/books" -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 } catch {}
    $lmsCheck = $false
    try { $lmsCheck = (Invoke-WebRequest -Uri "$BaseUrl/api/v1/lms/my-courses" -Headers $authHeader -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 } catch {}

    $blastRadiusZero = $authCheck -and $personCheck -and $enrollCheck -and $financeCheck -and $libraryCheck -and $lmsCheck
    Report-Check "Check 3.2.2: Blast Radius 0% (Los otros 6 microservicios responden 200 OK)" $blastRadiusZero "Auth: $authCheck | Person: $personCheck | Enrollment: $enrollCheck | Finance: $financeCheck | Library: $libraryCheck | LMS: $lmsCheck"

    # Recuperación de academic-service
    Write-Host "  [CAOS B] Reiniciando contenedor 'academic-service'..." -ForegroundColor Cyan
    Invoke-DockerCompose @("start", "academic-service")
    $academicHealthy = Wait-ContainerHealthy "univ-academic-service" 30

    Report-Check "Check 3.2.3: Auto-Recuperación de academic-service a estado Healthy" $academicHealthy "univ-academic-service saludable: $academicHealthy"
} catch {
    Report-Check "Check 3.2: Caos B - Aislamiento Perimetral" $false $_.Exception.Message
    Invoke-DockerCompose @("start", "academic-service")
}

# ==============================================================================
# BLOQUE 4: PRUEBA DE SATURACIÓN PERIMETRAL (RATE LIMITING REV-E2E-01)
# ==============================================================================
Write-Host "`n>>> BLOQUE 4: Prueba de Saturación Perimetral (Rate Limiting)" -ForegroundColor Yellow

try {
    $probeBody = @{
        username = "probe_user"
        password = "bad_password"
    } | ConvertTo-Json

    $rateCodes = @()
    $retryAfterDetected = $false
    $rateLimitCodeDetected = $false

    # Ráfaga secuencial rápida de 10 peticiones
    for ($i = 1; $i -le 10; $i++) {
        try {
            $req = [System.Net.HttpWebRequest]::Create("$BaseUrl/api/v1/auth/login")
            $req.Method = "POST"
            $req.ContentType = "application/json"
            $req.Timeout = 5000

            $byteData = [System.Text.Encoding]::UTF8.GetBytes($probeBody)
            $req.ContentLength = $byteData.Length
            $postStream = $req.GetRequestStream()
            $postStream.Write($byteData, 0, $byteData.Length)
            $postStream.Close()

            $httpResp = [System.Net.HttpWebResponse]$req.GetResponse()
            $rateCodes += [int]$httpResp.StatusCode
            $httpResp.Close()
        } catch [System.Net.WebException] {
            $webEx = $_.Exception
            if ($webEx.Response) {
                $status = [int]$webEx.Response.StatusCode
                $rateCodes += $status

                if ($status -eq 429) {
                    $retryHeader = $webEx.Response.Headers["Retry-After"]
                    if ($retryHeader -eq "60") {
                        $retryAfterDetected = $true
                    }

                    $reader = [System.IO.StreamReader]::new($webEx.Response.GetResponseStream())
                    $body429 = $reader.ReadToEnd()
                    $reader.Close()

                    try {
                        $json429 = $body429 | ConvertFrom-Json
                        if ($json429.error.code -eq "RATE_LIMIT_EXCEEDED") {
                            $rateLimitCodeDetected = $true
                        }
                    } catch {}
                }
                $webEx.Response.Close()
            } else {
                $rateCodes += 0
            }
        }
    }

    $blockedCount = ($rateCodes | Where-Object { $_ -eq 429 }).Count
    $processedCount = ($rateCodes | Where-Object { $_ -ne 429 }).Count

    # Validamos que se hayan procesado peticiones antes del límite y que al excederse se bloquee con 429
    $rateSuccess = ($processedCount -ge 3 -and $blockedCount -ge 5 -and $retryAfterDetected -and $rateLimitCodeDetected)
    Report-Check "Check 4.1: Saturación Perimetral de Login (Límite 5 req/min/IP -> HTTP 429)" $rateSuccess "Secuencia de códigos: $($rateCodes -join ', ') | Retry-After: $retryAfterDetected | Code RATE_LIMIT_EXCEEDED: $rateLimitCodeDetected"
} catch {
    Report-Check "Check 4.1: Saturación Perimetral de Login" $false $_.Exception.Message
}

# ==============================================================================
# RESUMEN GENERAL DE EJECUCIÓN
# ==============================================================================
Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host " RESUMEN FINAL DE LA SUITE DE RESILIENCIA Y CAOS" -ForegroundColor Cyan
Write-Host " Total Checks : $totalChecks" -ForegroundColor Cyan
Write-Host " Aprobados    : $passedChecks" -ForegroundColor Green
Write-Host " Fallidos     : $failedChecks" -ForegroundColor $(if ($failedChecks -eq 0) { "Green" } else { "Red" })
Write-Host " Tasa de Éxito: $([math]::Round(($passedChecks / [math]::Max($totalChecks, 1)) * 100, 1))%" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

if ($failedChecks -gt 0) {
    exit 1
} else {
    exit 0
}
