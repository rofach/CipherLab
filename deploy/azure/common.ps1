Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-AzureCliReady {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) не знайдено. Встановіть Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli"
    }

    az account show --only-show-errors 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Ви не авторизовані в Azure. Запускаємо 'az login'..." -ForegroundColor Yellow
        az login
        if ($LASTEXITCODE -ne 0) {
            throw "Не вдалося авторизуватися в Azure."
        }
    }
}

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Get-SubscriptionSuffix {
    $subId = (az account show --query id -o tsv --only-show-errors).Replace('-', '')
    if ([string]::IsNullOrWhiteSpace($subId) -or $subId.Length -lt 6) {
        return 'lab3'
    }
    return $subId.Substring(0, 6).ToLowerInvariant()
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
}
