param(
    [string]$ResourceGroup = 'rg-cipherlab-dev',
    [string]$Location = 'polandcentral',
    [string]$PlanName = 'asp-cipherlab-linux',
    [string]$WebAppName,
    [string]$Sku = 'F1',
    [string]$FrontendOrigin = ''
)

. (Join-Path $PSScriptRoot 'common.ps1')
Assert-AzureCliReady

if ([string]::IsNullOrWhiteSpace($WebAppName)) {
    $suffix = Get-SubscriptionSuffix
    $WebAppName = "cipherlab-api-$suffix"
}

$repoRoot = Get-RepoRoot
$projectPath = Join-Path $repoRoot 'backend\CipherLab.Api\CipherLab.Api.csproj'
$publishDir = Join-Path $env:TEMP "cipherlab-api-publish-$PID"
$zipPath = Join-Path $env:TEMP "cipherlab-api-$PID.zip"

try {
    Write-Host "=== 1/4 Перевірка / створення Resource Group ($ResourceGroup) ===" -ForegroundColor Cyan
    Invoke-Checked { az group create --name $ResourceGroup --location $Location --only-show-errors | Out-Null } "Не вдалося створити Resource Group."

    Write-Host "=== 2/4 Перевірка / створення App Service Plan ($PlanName, SKU: $Sku) ===" -ForegroundColor Cyan
    $planExists = az appservice plan show --name $PlanName --resource-group $ResourceGroup --query name -o tsv 2>$null
    if ([string]::IsNullOrWhiteSpace($planExists)) {
        Invoke-Checked { az appservice plan create --name $PlanName --resource-group $ResourceGroup --location $Location --is-linux --sku $Sku --only-show-errors | Out-Null } "Не вдалося створити App Service Plan."
    }

    Write-Host "=== 3/4 Перевірка / створення Web App ($WebAppName, .NET 10) ===" -ForegroundColor Cyan
    $appExists = az webapp show --name $WebAppName --resource-group $ResourceGroup --query name -o tsv 2>$null
    if ([string]::IsNullOrWhiteSpace($appExists)) {
        Invoke-Checked { az webapp create --name $WebAppName --resource-group $ResourceGroup --plan $PlanName --runtime "DOTNETCORE:10.0" --only-show-errors | Out-Null } "Не вдалося створити Web App."
    }

    Write-Host "=== 4/4 Публікація та деплой ASP.NET Core API ===" -ForegroundColor Cyan
    if (Test-Path $publishDir) { Remove-Item $publishDir -Recurse -Force }
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    Invoke-Checked { dotnet publish $projectPath -c Release -o $publishDir | Out-Host } "Помилка 'dotnet publish'."
    Compress-Archive -Path (Join-Path $publishDir '*') -DestinationPath $zipPath -Force

    Invoke-Checked { az webapp deploy --resource-group $ResourceGroup --name $WebAppName --src-path $zipPath --type zip --only-show-errors | Out-Null } "Помилка деплою бекенду в Azure Web App."

    $appSettings = @('ASPNETCORE_ENVIRONMENT=Production')
    if (-not [string]::IsNullOrWhiteSpace($FrontendOrigin)) {
        $cleanOrigin = $FrontendOrigin.TrimEnd('/')
        $appSettings += "Cors__AllowedOrigins__0=$cleanOrigin"
    }

    Invoke-Checked { az webapp config appsettings set --resource-group $ResourceGroup --name $WebAppName --settings @appSettings --only-show-errors | Out-Null } "Не вдалося оновити App Settings."

    $defaultHost = (az webapp show --name $WebAppName --resource-group $ResourceGroup --query defaultHostName -o tsv --only-show-errors).Trim()
    $backendUrl = "https://$defaultHost"
    Write-Host "Бекенд успішно задеплоєно: $backendUrl" -ForegroundColor Green
    return $backendUrl
}
finally {
    if (Test-Path $publishDir) { Remove-Item $publishDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
}
