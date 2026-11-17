param(
    [string]$ResourceGroup = 'rg-cipherlab-dev'
)

. (Join-Path $PSScriptRoot 'common.ps1')
Assert-AzureCliReady

Write-Host "Видалення Resource Group '$ResourceGroup'..." -ForegroundColor Yellow
Invoke-Checked { az group delete --name $ResourceGroup --yes --no-wait --only-show-errors } "Не вдалося запустити видалення Resource Group."
Write-Host "Запит на видалення '$ResourceGroup' надіслано в Azure." -ForegroundColor Green
