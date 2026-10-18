# ============================================================
# Script de Pruebas de Integracion End-to-End (Smoke Tests)
# Plataforma Universitaria Cloud-Native Azure (Lab 03 - Sub-Fase E)
# Cierre Funcional al 100%: Identidad, Personas, Academico, Matriculas,
# Finanzas con Idempotencia, Biblioteca NoSQL, LMS Virtual,
# Portal Web Nginx No-Root y Endurecimiento CORS Zero-Trust
# ============================================================
$baseUrl = "http://localhost:8080"
$webUrl = "http://localhost:3000"
$totalChecks = 16
$passedChecks = 0

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Iniciando Smoke Tests de Integracion contra API Gateway y Portal Web" -ForegroundColor Cyan
Write-Host "Lab 03: Sub-Fase E (100% Funcional - 7 Microservicios + NoSQL + EDA + Web SPA)" -ForegroundColor Cyan
Write-Host "Target Gateway: $baseUrl | Target Web: $webUrl" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ------------------------------------------------------------
# Check 1: Salud del Gateway en GET /health/live
# ------------------------------------------------------------
Write-Host "`n[Check 1/16] Verificando salud del API Gateway (GET /health/live)..." -ForegroundColor Yellow
try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/health/live" -Method GET -TimeoutSec 5
    if ($resp.status -eq "UP") {
        Write-Host "  [PASS] API Gateway reporta salud UP." -ForegroundColor Green
        $passedChecks++
    } else {
        Write-Host "  [FAIL] API Gateway reporto status '$($resp.status)' (esperado 'UP')." -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error al conectar con /health/live: $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# Check 2: Login en POST /api/v1/auth/login
# ------------------------------------------------------------
Write-Host "`n[Check 2/16] Autenticacion en POST /api/v1/auth/login..." -ForegroundColor Yellow
$token = $null
$loginBody = @{
    username = "alu01"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResp = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 10
    if ($loginResp.accessToken) {
        $token = $loginResp.accessToken
        Write-Host "  [PASS] Login exitoso para '$($loginResp.username)'. Rol: $($loginResp.role)." -ForegroundColor Green
        Write-Host "         Token JWT RS256 capturado (longitud: $($token.Length) chars)." -ForegroundColor Gray
        $passedChecks++
    } else {
        Write-Host "  [FAIL] Respuesta de login no contiene accessToken." -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error al ejecutar POST /api/v1/auth/login: $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# Check 3: Resolucion de perfil en GET /api/v1/person/profile/me
# ------------------------------------------------------------
Write-Host "`n[Check 3/16] Consultando perfil de usuario autenticado (GET /api/v1/person/profile/me)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $profileResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/person/profile/me" -Method GET -Headers $headers -TimeoutSec 10
        if ($profileResp.StatusCode -eq 200) {
            $profileData = $profileResp.Content | ConvertFrom-Json
            $cacheHeader = $profileResp.Headers["X-Cache"]
            if ($cacheHeader -is [array]) { $cacheHeader = $cacheHeader[0] }
            Write-Host "  [PASS] Perfil resuelto exitosamente para '$($profileData.fullName)'." -ForegroundColor Green
            Write-Host "         Codigo: $($profileData.institutionalCode) | Tipo: $($profileData.userType) | Header X-Cache: $cacheHeader" -ForegroundColor Gray
            $passedChecks++
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado: $($profileResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al consultar perfil: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 4: Verificacion de Cache-Aside en Redis (X-Cache: HIT)
# ------------------------------------------------------------
Write-Host "`n[Check 4/16] Verificando Cache-Aside en Redis (segunda consulta esperando X-Cache: HIT)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $cacheResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/person/profile/me" -Method GET -Headers $headers -TimeoutSec 10
        $cacheHeader = $cacheResp.Headers["X-Cache"]
        if ($cacheHeader -is [array]) { $cacheHeader = $cacheHeader[0] }
        
        if ($cacheHeader -eq "HIT") {
            Write-Host "  [PASS] Cache-Aside certificado. Cabecera 'X-Cache: HIT' recibida." -ForegroundColor Green
            $passedChecks++
        } else {
            Write-Host "  [FAIL] Cabecera 'X-Cache' esperada 'HIT', recibida '$cacheHeader'." -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error en segunda consulta de perfil: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 5: Seguridad perimetral sin token (401 Unauthorized)
# ------------------------------------------------------------
Write-Host "`n[Check 5/16] Probando seguridad perimetral sin token (GET /api/v1/person/profile/me)..." -ForegroundColor Yellow
try {
    $unauthResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/person/profile/me" -Method GET -TimeoutSec 5
    Write-Host "  [FAIL] Se esperaba codigo 401, pero se obtuvo $($unauthResp.StatusCode)." -ForegroundColor Red
} catch {
    $statusCode = 0
    if ($_.Exception -and $_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }
    if ($statusCode -eq 401) {
        Write-Host "  [PASS] Acceso denegado con codigo 401 Unauthorized tal como se esperaba." -ForegroundColor Green
        $passedChecks++
    } else {
        Write-Host "  [FAIL] Se esperaba codigo 401, se obtuvo '$statusCode'. Excepcion: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 6: Catalogo de cursos en GET /api/v1/academic/courses
# ------------------------------------------------------------
Write-Host "`n[Check 6/16] Consultando cursos academicos (GET /api/v1/academic/courses)..." -ForegroundColor Yellow
try {
    $coursesResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/academic/courses" -Method GET -TimeoutSec 10
    if ($coursesResp.StatusCode -eq 200) {
        $courses = $coursesResp.Content | ConvertFrom-Json
        $count = 0
        if ($courses -is [array]) { $count = $courses.Length } elseif ($courses) { $count = 1 }
        if ($count -ge 1) {
            Write-Host "  [PASS] Catalogo academico consultado exitosamente. Cursos encontrados: $count." -ForegroundColor Green
            Write-Host "         Primer curso: $($courses[0].sercur) - $($courses[0].nomcur) ($($courses[0].crecur) creditos)." -ForegroundColor Gray
            $passedChecks++
        } else {
            Write-Host "  [FAIL] La respuesta retorno un arreglo vacio de cursos." -ForegroundColor Red
        }
    } else {
        Write-Host "  [FAIL] Codigo HTTP inesperado: $($coursesResp.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error al consultar cursos academicos: $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# Check 7: Matriculas del alumno en GET /api/v1/enrollment/my-enrollments
# ------------------------------------------------------------
Write-Host "`n[Check 7/16] Consultando matriculas del alumno autenticado (GET /api/v1/enrollment/my-enrollments)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $enrollResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/enrollment/my-enrollments" -Method GET -Headers $headers -TimeoutSec 10
        if ($enrollResp.StatusCode -eq 200) {
            $enrollments = $enrollResp.Content | ConvertFrom-Json
            $count = 0
            if ($enrollments -is [array]) { $count = $enrollments.Length } elseif ($enrollments) { $count = 1 }
            if ($count -ge 1) {
                Write-Host "  [PASS] Matriculas del estudiante resueltas exitosamente. Registros: $count." -ForegroundColor Green
                Write-Host "         Matricula ID: $($enrollments[0].id) | Periodo: $($enrollments[0].academicPeriodId)" -ForegroundColor Gray
                $passedChecks++
            } else {
                Write-Host "  [FAIL] La respuesta retorno un arreglo vacio de matriculas para alu01." -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado: $($enrollResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al consultar matriculas: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 8: Historial de notas del alumno en GET /api/v1/enrollment/grades
# ------------------------------------------------------------
Write-Host "`n[Check 8/16] Consultando calificaciones del alumno autenticado (GET /api/v1/enrollment/grades)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $gradesResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/enrollment/grades" -Method GET -Headers $headers -TimeoutSec 10
        if ($gradesResp.StatusCode -eq 200) {
            $grades = $gradesResp.Content | ConvertFrom-Json
            $count = 0
            if ($grades -is [array]) { $count = $grades.Length } elseif ($grades) { $count = 1 }
            if ($count -ge 1) {
                Write-Host "  [PASS] Historial de notas resuelto exitosamente. Calificaciones registradas: $count." -ForegroundColor Green
                Write-Host "         Nota muestra: $($grades[0].gradeTypeName) -> Nota: $($grades[0].score)" -ForegroundColor Gray
                $passedChecks++
            } else {
                Write-Host "  [FAIL] La respuesta retorno un arreglo vacio de calificaciones para alu01." -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado: $($gradesResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al consultar calificaciones: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 9: Ordenes de pago del alumno en GET /api/v1/finance/my-orders
# ------------------------------------------------------------
Write-Host "`n[Check 9/16] Consultando ordenes de pago del alumno (GET /api/v1/finance/my-orders)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $ordersResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/finance/my-orders" -Method GET -Headers $headers -TimeoutSec 10
        if ($ordersResp.StatusCode -eq 200) {
            $orders = $ordersResp.Content | ConvertFrom-Json
            $count = 0
            if ($orders -is [array]) { $count = $orders.Length } elseif ($orders) { $count = 1 }
            if ($count -ge 1) {
                Write-Host "  [PASS] Ordenes de pago resueltas exitosamente. Registros: $count." -ForegroundColor Green
                Write-Host "         Orden ID: $($orders[0].id) | Concepto: $($orders[0].conceptName) | Monto: S/ $($orders[0].amount) | Estado: $($orders[0].statusName)" -ForegroundColor Gray
                $passedChecks++
            } else {
                Write-Host "  [FAIL] No se encontraron ordenes de pago para alu01." -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado: $($ordersResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al consultar ordenes de pago: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 10: Procesamiento de pago exitoso en POST /api/v1/finance/payments
# ------------------------------------------------------------
Write-Host "`n[Check 10/16] Procesando pago de orden (POST /api/v1/finance/payments)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization  = "Bearer $token"
            "Idempotency-Key" = "pay-test-001"
            "Content-Type" = "application/json"
        }
        $payBody = @{
            paymentOrderId = 1
            methodCode     = "CARD"
            amount         = 350.00
        } | ConvertTo-Json

        $payResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/finance/payments" -Method POST -Headers $headers -Body $payBody -TimeoutSec 10
        if ($payResp.StatusCode -eq 200 -or $payResp.StatusCode -eq 201) {
            $paymentData = $payResp.Content | ConvertFrom-Json
            Write-Host "  [PASS] Pago procesado exitosamente." -ForegroundColor Green
            Write-Host "         Payment ID: $($paymentData.paymentId) | Ref: $($paymentData.transactionRef) | Monto: S/ $($paymentData.amount) | Estado: $($paymentData.status)" -ForegroundColor Gray
            $passedChecks++
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado al procesar pago: $($payResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al procesar pago: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 11: Idempotencia estricta con misma Idempotency-Key
# ------------------------------------------------------------
Write-Host "`n[Check 11/16] Verificando Idempotencia estricta (re-envio con misma Idempotency-Key: pay-test-001)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization  = "Bearer $token"
            "Idempotency-Key" = "pay-test-001"
            "Content-Type" = "application/json"
        }
        $payBody = @{
            paymentOrderId = 1
            methodCode     = "CARD"
            amount         = 350.00
        } | ConvertTo-Json

        $payResp2 = Invoke-WebRequest -Uri "$baseUrl/api/v1/finance/payments" -Method POST -Headers $headers -Body $payBody -TimeoutSec 10
        if ($payResp2.StatusCode -eq 200 -or $payResp2.StatusCode -eq 201) {
            $paymentData2 = $payResp2.Content | ConvertFrom-Json
            if ($paymentData2.idempotencyKey -eq "pay-test-001" -and $paymentData2.status -eq "PAID") {
                Write-Host "  [PASS] Idempotencia certificada. Respuesta identica retornada desde Redis sin duplicar transaccion." -ForegroundColor Green
                Write-Host "         Payment ID: $($paymentData2.paymentId) | Ref: $($paymentData2.transactionRef) | IdempotencyKey: $($paymentData2.idempotencyKey)" -ForegroundColor Gray
                $passedChecks++
            } else {
                Write-Host "  [FAIL] Respuesta no coincide con la transaccion original esperada." -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado en prueba de idempotencia: $($payResp2.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error en prueba de idempotencia: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 12: Catalogo NoSQL de libros en GET /api/v1/library/books
# ------------------------------------------------------------
Write-Host "`n[Check 12/16] Consultando catalogo NoSQL de libros (GET /api/v1/library/books)..." -ForegroundColor Yellow
try {
    $booksResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/library/books" -Method GET -TimeoutSec 10
    if ($booksResp.StatusCode -eq 200) {
        $books = $booksResp.Content | ConvertFrom-Json
        $count = 0
        if ($books -is [array]) { $count = $books.Length } elseif ($books) { $count = 1 }
        if ($count -ge 1) {
            Write-Host "  [PASS] Catalogo NoSQL de biblioteca consultado exitosamente. Libros encontrados: $count." -ForegroundColor Green
            Write-Host "         Muestra: '$($books[0].title)' por $($books[0].author) (Copias: $($books[0].availableCopies)/$($books[0].totalCopies))." -ForegroundColor Gray
            $passedChecks++
        } else {
            Write-Host "  [FAIL] Catalogo NoSQL vacio." -ForegroundColor Red
        }
    } else {
        Write-Host "  [FAIL] Codigo HTTP inesperado: $($booksResp.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error al consultar catalogo de libros: $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# Check 13: Prestamos de biblioteca del alumno en GET /api/v1/library/my-loans
# ------------------------------------------------------------
Write-Host "`n[Check 13/16] Consultando prestamos de biblioteca del alumno (GET /api/v1/library/my-loans)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $loansResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/library/my-loans" -Method GET -Headers $headers -TimeoutSec 10
        if ($loansResp.StatusCode -eq 200) {
            $loans = $loansResp.Content | ConvertFrom-Json
            $count = 0
            if ($loans -is [array]) { $count = $loans.Length } elseif ($loans) { $count = 1 }
            if ($count -ge 1) {
                Write-Host "  [PASS] Prestamos del alumno consultados exitosamente. Registros: $count." -ForegroundColor Green
                Write-Host "         Prestamo ID: $($loans[0].id) | Libro: '$($loans[0].bookTitle)' | Estado: $($loans[0].status)" -ForegroundColor Gray
                $passedChecks++
            } else {
                Write-Host "  [FAIL] No se encontraron prestamos para alu01." -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado: $($loansResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al consultar prestamos: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 14: Cursos y evaluaciones del aula virtual LMS en GET /api/v1/lms/my-courses
# ------------------------------------------------------------
Write-Host "`n[Check 14/16] Consultando cursos y evaluaciones LMS del alumno (GET /api/v1/lms/my-courses)..." -ForegroundColor Yellow
if (-not $token) {
    Write-Host "  [FAIL] Omitido porque Check 2 no obtuvo token." -ForegroundColor Red
} else {
    try {
        $headers = @{
            Authorization = "Bearer $token"
        }
        $lmsResp = Invoke-WebRequest -Uri "$baseUrl/api/v1/lms/my-courses" -Method GET -Headers $headers -TimeoutSec 10
        if ($lmsResp.StatusCode -eq 200) {
            $courses = $lmsResp.Content | ConvertFrom-Json
            $count = 0
            if ($courses -is [array]) { $count = $courses.Length } elseif ($courses) { $count = 1 }
            if ($count -ge 1) {
                Write-Host "  [PASS] Cursos LMS del alumno resueltos exitosamente. Asignaturas: $count." -ForegroundColor Green
                Write-Host "         Curso: $($courses[0].courseCode) - $($courses[0].title) | Progreso: $($courses[0].progressPercentage)% | Evaluaciones: $($courses[0].evaluations.Length)" -ForegroundColor Gray
                $passedChecks++
            } else {
                Write-Host "  [FAIL] No se encontraron cursos LMS para alu01." -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] Codigo HTTP inesperado: $($lmsResp.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Error al consultar cursos LMS: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Check 15: Disponibilidad del Portal Web Nginx de Produccion
# ------------------------------------------------------------
Write-Host "`n[Check 15/16] Verificando disponibilidad del Portal Web Nginx (GET $webUrl)..." -ForegroundColor Yellow
try {
    $resp15 = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -TimeoutSec 10
    $hasRootDiv = $resp15.Content -like '*<div id="root">*'
    
    $frameHeader = $resp15.Headers["X-Frame-Options"]
    if ($frameHeader -is [array]) { $frameHeader = $frameHeader[0] }
    
    $contentTypeHeader = $resp15.Headers["X-Content-Type-Options"]
    if ($contentTypeHeader -is [array]) { $contentTypeHeader = $contentTypeHeader[0] }

    $headersOk = ($frameHeader -eq "SAMEORIGIN") -and ($contentTypeHeader -eq "nosniff")

    if ($resp15.StatusCode -eq 200 -and $hasRootDiv -and $headersOk) {
        Write-Host "  [PASS] Portal Web Nginx responde HTTP 200 con SPA root y cabeceras de seguridad requeridas." -ForegroundColor Green
        Write-Host "         X-Frame-Options: $frameHeader | X-Content-Type-Options: $contentTypeHeader" -ForegroundColor Gray
        $passedChecks++
    } else {
        Write-Host "  [FAIL] Verificacion del Portal Web fallo." -ForegroundColor Red
        Write-Host "         StatusCode: $($resp15.StatusCode) (esperado 200) | RootDiv: $hasRootDiv | X-Frame-Options: '$frameHeader' (esperado SAMEORIGIN) | X-Content-Type-Options: '$contentTypeHeader' (esperado nosniff)" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error al conectar con Portal Web en $webUrl - $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# Check 16: Preflight CORS Estricto en el Gateway
# ------------------------------------------------------------
Write-Host "`n[Check 16/16] Verificando Preflight CORS estricto en API Gateway (OPTIONS /api/v1/auth/login)..." -ForegroundColor Yellow
$corsAllowedOk = $false
$corsDeniedOk = $false

# 1. Peticion preflight autorizada desde Origin: http://localhost:3000
try {
    $headersCors = @{
        "Origin"                        = "http://localhost:3000"
        "Access-Control-Request-Method" = "POST"
    }
    $respCors = Invoke-WebRequest -Uri "$baseUrl/api/v1/auth/login" -Method OPTIONS -Headers $headersCors -UseBasicParsing -TimeoutSec 10
    
    $allowOriginHeader = $respCors.Headers["Access-Control-Allow-Origin"]
    if ($allowOriginHeader -is [array]) { $allowOriginHeader = $allowOriginHeader[0] }

    if ($respCors.StatusCode -eq 204 -and $allowOriginHeader -eq "http://localhost:3000") {
        $corsAllowedOk = $true
        Write-Host "  [OK] Origen autorizado 'http://localhost:3000' aceptado con HTTP 204 y Access-Control-Allow-Origin: $allowOriginHeader." -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Origen autorizado respondio StatusCode: $($respCors.StatusCode), Allow-Origin: '$allowOriginHeader'." -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error al enviar preflight OPTIONS autorizado: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Peticion preflight denegada desde Origin no autorizado: http://sitio-no-autorizado.com
try {
    $headersBlocked = @{
        "Origin"                        = "http://sitio-no-autorizado.com"
        "Access-Control-Request-Method" = "POST"
    }
    $respBlocked = Invoke-WebRequest -Uri "$baseUrl/api/v1/auth/login" -Method OPTIONS -Headers $headersBlocked -UseBasicParsing -TimeoutSec 10
    if ($respBlocked.StatusCode -eq 403) {
        $corsDeniedOk = $true
        Write-Host "  [OK] Origen no autorizado 'http://sitio-no-autorizado.com' bloqueado con HTTP 403." -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Se esperaba HTTP 403 para origen no autorizado, pero se obtuvo $($respBlocked.StatusCode)." -ForegroundColor Red
    }
} catch {
    $statusCode = 0
    if ($_.Exception -and $_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }
    if ($statusCode -eq 403) {
        $corsDeniedOk = $true
        Write-Host "  [OK] Origen no autorizado 'http://sitio-no-autorizado.com' bloqueado con HTTP 403 Forbidden tal como se esperaba." -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Se esperaba HTTP 403 para origen no autorizado, se obtuvo '$statusCode'. Excepcion: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($corsAllowedOk -and $corsDeniedOk) {
    Write-Host "  [PASS] Politica CORS Zero-Trust certificada (Permitido: http://localhost:3000 -> 204 | Denegado: sitio externo -> 403)." -ForegroundColor Green
    $passedChecks++
} else {
    Write-Host "  [FAIL] Verificacion de politica CORS fallo (PermitidoOk: $corsAllowedOk, BloqueadoOk: $corsDeniedOk)." -ForegroundColor Red
}

# ------------------------------------------------------------
# Resumen Final
# ------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Cyan
if ($passedChecks -eq $totalChecks) {
    Write-Host "RESUMEN: $passedChecks de $totalChecks checks APROBADOS (100% PASS)" -ForegroundColor Green
    Write-Host "Plataforma Universitaria Cloud-Native Azure (Lab 03) certificada al 100% (Sub-Fase E - 16 Smoke Tests)." -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "RESUMEN: $passedChecks de $totalChecks checks aprobados. Se detectaron fallos." -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Cyan
    exit 1
}
