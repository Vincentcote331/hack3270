<#
.SYNOPSIS
    Universal 1-Line Bootstrapper for hack3270 TELUS Edition.

.DESCRIPTION
    Clones the repository to C:\dev\tools\hack3270 (if not already cloned)
    and executes setup-telus-3270.ps1 to configure BlueZone, Python, MCP, and Skills.

.EXAMPLE
    irm https://raw.githubusercontent.com/Vincentcote331/hack3270/main/setup.ps1 | iex
#>
param(
    [string]$InstallDir = "C:\dev\tools\hack3270"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Bootstrapping hack3270 (TELUS Edition)..." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

if (-not (Test-Path $InstallDir)) {
    Write-Host "Cloning repository into $InstallDir..." -ForegroundColor White
    $ParentDir = Split-Path $InstallDir
    if (-not (Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Force -Path $ParentDir | Out-Null
    }
    & git clone https://github.com/Vincentcote331/hack3270.git $InstallDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone repository from GitHub. Verify git and network access."
    }
} else {
    Write-Host "Repository already present at $InstallDir." -ForegroundColor Green
}

$SetupScript = Join-Path $InstallDir "setup-telus-3270.ps1"
if (-not (Test-Path $SetupScript)) {
    Write-Error "Cannot find setup script at: $SetupScript"
}

& powershell -ExecutionPolicy Bypass -File $SetupScript
