$gateway = "https://ca-api-gateway.greenglacier-aabec240.mexicocentral.azurecontainerapps.io"
$users = @("alu01", "alu02", "alu05", "alu09")

foreach ($u in $users) {
    $loginBody = @{ username = $u; password = "password123" } | ConvertTo-Json
    $auth = Invoke-RestMethod -Uri "$gateway/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    Write-Host "`n=== Login $u ===" -ForegroundColor Cyan
    Write-Host "UserID: $($auth.userId) | Role: $($auth.role)"
    $headers = @{ Authorization = "Bearer $($auth.accessToken)" }
    try {
        $profile = Invoke-RestMethod -Uri "$gateway/api/v1/person/profile/me" -Headers $headers
        Write-Host "Profile: $($profile.institutionalCode) - $($profile.fullName) | AuthUserID: $($profile.authUserId)" -ForegroundColor Green
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
