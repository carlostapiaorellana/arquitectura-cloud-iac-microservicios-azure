$gw = "https://ca-api-gateway.greenglacier-aabec240.mexicocentral.azurecontainerapps.io/api/v1"

Write-Host "=== TEST 1: alu05 LOGIN & PROFILE ==="
$body5 = @{ username = "alu05"; password = "password123" } | ConvertTo-Json
$res5 = Invoke-RestMethod -Uri "$gw/auth/login" -Method Post -Body $body5 -ContentType "application/json"
Write-Host "alu05 Token Subject/ID: $($res5.userId), Username: $($res5.username)"

$headers5 = @{ Authorization = "Bearer $($res5.accessToken)" }
$prof5 = Invoke-RestMethod -Uri "$gw/person/profile/me" -Method Get -Headers $headers5
Write-Host "alu05 Perfil: $($prof5.fullName), Codigo: $($prof5.institutionalCode), Direccion: $($prof5.address)"

$orders5 = Invoke-RestMethod -Uri "$gw/finance/my-orders" -Method Get -Headers $headers5
Write-Host "alu05 Total Ordenes: $($orders5.Count)"
foreach ($o in $orders5) {
    Write-Host "  - Orden ID: $($o.id) | Concepto: $($o.conceptName) | Monto: S/ $($o.amount) | Estado: $($o.statusName)"
}

Write-Host "`n=== TEST 2: alu10 LOGIN & PROFILE ==="
$body10 = @{ username = "alu10"; password = "password123" } | ConvertTo-Json
$res10 = Invoke-RestMethod -Uri "$gw/auth/login" -Method Post -Body $body10 -ContentType "application/json"
Write-Host "alu10 Token Subject/ID: $($res10.userId), Username: $($res10.username)"

$headers10 = @{ Authorization = "Bearer $($res10.accessToken)" }
$prof10 = Invoke-RestMethod -Uri "$gw/person/profile/me" -Method Get -Headers $headers10
Write-Host "alu10 Perfil: $($prof10.fullName), Codigo: $($prof10.institutionalCode), Direccion: $($prof10.address)"

$orders10 = Invoke-RestMethod -Uri "$gw/finance/my-orders" -Method Get -Headers $headers10
Write-Host "alu10 Total Ordenes: $($orders10.Count)"
foreach ($o in $orders10) {
    Write-Host "  - Orden ID: $($o.id) | Concepto: $($o.conceptName) | Monto: S/ $($o.amount) | Estado: $($o.statusName)"
}
