param(
    [string]$ResourceGroup = 'rg-cipherlab-dev',
    [string]$Location = 'polandcentral',
    [string]$PlanName = 'asp-cipherlab-linux',
    [string]$WebAppName,
    [string]$StorageAccountName,
    [string]$AppServiceSku = 'F1'
)

. (Join-Path $PSScriptRoot 'common.ps1')
Assert-AzureCliReady

$suffix = Get-SubscriptionSuffix
if ([string]::IsNullOrWhiteSpace($WebAppName)) {
    $WebAppName = "cipherlab-api-$suffix"
}
if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
    $StorageAccountName = "cipherlabui$suffix"
}

Write-Host ">>> Крок 1: Деплой бекенду (ASP.NET Core Web API)..." -ForegroundColor Magenta
$backendResult = & (Join-Path $PSScriptRoot 'deploy-backend.ps1') `
    -ResourceGroup $ResourceGroup `
    -Location $Location `
    -PlanName $PlanName `
    -WebAppName $WebAppName `
    -Sku $AppServiceSku
$backendUrl = ($backendResult | Select-Object -Last 1).ToString().Trim()

Write-Host ">>> Крок 2: Деплой фронтенду (Angular SPA)..." -ForegroundColor Magenta
$frontendResult = & (Join-Path $PSScriptRoot 'deploy-frontend.ps1') `
    -ResourceGroup $ResourceGroup `
    -Location $Location `
    -StorageAccountName $StorageAccountName `
    -ApiBaseUrl $backendUrl
$frontendUrl = ($frontendResult | Select-Object -Last 1).ToString().Trim()

Write-Host ">>> Крок 3: Оновлення CORS на бекенді для $frontendUrl..." -ForegroundColor Magenta
Invoke-Checked {
    az webapp config appsettings set `
        --resource-group $ResourceGroup `
        --name $WebAppName `
        --settings "Cors__AllowedOrigins__0=$frontendUrl" `
        --only-show-errors | Out-Null
} "Не вдалося налаштувати CORS на бекенді."

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Деплой завершено!" -ForegroundColor Green
Write-Host "Frontend URL: $frontendUrl" -ForegroundColor White
Write-Host "Backend URL : $backendUrl" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
