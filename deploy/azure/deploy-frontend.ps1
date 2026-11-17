param(
    [string]$ResourceGroup = 'rg-cipherlab-dev',
    [string]$Location = 'polandcentral',
    [string]$StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl
)

. (Join-Path $PSScriptRoot 'common.ps1')
Assert-AzureCliReady

if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
    $suffix = Get-SubscriptionSuffix
    $StorageAccountName = "cipherlabui$suffix"
}

$repoRoot = Get-RepoRoot
$frontendDir = Join-Path $repoRoot 'frontend'
$distBrowserDir = Join-Path $frontendDir 'dist\frontend\browser'
$cleanApiUrl = $ApiBaseUrl.Trim().TrimEnd('/')

Write-Host "=== 1/4 Перевірка / створення Resource Group ($ResourceGroup) ===" -ForegroundColor Cyan
Invoke-Checked { az group create --name $ResourceGroup --location $Location --only-show-errors | Out-Null } "Не вдалося створити Resource Group."

Write-Host "=== 2/4 Перевірка / створення Storage Account ($StorageAccountName) ===" -ForegroundColor Cyan
$saExists = az storage account show --name $StorageAccountName --resource-group $ResourceGroup --query name -o tsv 2>$null
if ([string]::IsNullOrWhiteSpace($saExists)) {
    Invoke-Checked { az storage account create --name $StorageAccountName --resource-group $ResourceGroup --location $Location --sku Standard_LRS --kind StorageV2 --allow-blob-public-access true --only-show-errors | Out-Null } "Не вдалося створити Storage Account."
}

$storageKey = (az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccountName --query "[0].value" -o tsv --only-show-errors).Trim()
if ([string]::IsNullOrWhiteSpace($storageKey)) {
    throw "Не вдалося отримати ключ доступу Storage Account."
}

Invoke-Checked {
    az storage blob service-properties update `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --static-website `
        --index-document index.html `
        --404-document index.html `
        --only-show-errors | Out-Null
} "Не вдалося увімкнути Static Website у Storage Account."

Write-Host "=== 3/4 Збірка Angular-застосунку ===" -ForegroundColor Cyan
Push-Location $frontendDir
try {
    if (-not (Test-Path (Join-Path $frontendDir 'node_modules'))) {
        Invoke-Checked { npm install --registry=https://registry.npmjs.org | Out-Host } "Помилка 'npm install'."
    }
    Invoke-Checked { npm run build | Out-Host } "Помилка 'npm run build'."
}
finally {
    Pop-Location
}

if (-not (Test-Path $distBrowserDir)) {
    throw "Не знайдено зібраний фронтенд у $distBrowserDir"
}

$distConfigPath = Join-Path $distBrowserDir 'config.json'
@{ apiBaseUrl = $cleanApiUrl } | ConvertTo-Json | Set-Content -Path $distConfigPath -Encoding UTF8

Write-Host "=== 4/4 Завантаження файлів у `$web контейнер ===" -ForegroundColor Cyan
Invoke-Checked {
    az storage blob upload-batch `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --source $distBrowserDir `
        --destination '$web' `
        --overwrite `
        --only-show-errors | Out-Null
} "Помилка завантаження статичних файлів фронтенду в Azure Storage."

$webEndpoint = (az storage account show --name $StorageAccountName --resource-group $ResourceGroup --query "primaryEndpoints.web" -o tsv --only-show-errors).Trim().TrimEnd('/')
Write-Host "Фронтенд успішно задеплоєно: $webEndpoint" -ForegroundColor Green
return $webEndpoint
