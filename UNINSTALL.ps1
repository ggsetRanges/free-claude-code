#requires -Version 5.1

<#
.SYNOPSIS
    Uninstaller for Free Claude Code
.DESCRIPTION
    Removes Free Claude Code installation and optionally cleans up dependencies
.PARAMETER RemoveVenv
    Remove Python virtual environment
.PARAMETER RemoveShortcuts
    Remove desktop and startup shortcuts
.PARAMETER RemovePM2
    Stop and remove PM2 service
.PARAMETER RemoveConfig
    Remove .env configuration file
.PARAMETER KeepLogs
    Keep log files
.EXAMPLE
    .\UNINSTALL.ps1
    Interactive uninstallation
.EXAMPLE
    .\UNINSTALL.ps1 -RemoveVenv -RemoveShortcuts -RemovePM2
    Remove everything except config
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$RemoveVenv,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveShortcuts,

    [Parameter(Mandatory = $false)]
    [switch]$RemovePM2,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveConfig,

    [Parameter(Mandatory = $false)]
    [switch]$KeepLogs,

    [Parameter(Mandatory = $false)]
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'
$ProjectRoot = $PSScriptRoot

function Read-Confirmation {
    param([string]$Prompt, [switch]$DefaultYes)
    if ($Silent) { return $true }
    $default = if ($DefaultYes) { 'Y' } else { 'n' }
    $response = Read-Host "$Prompt [$default]"
    if ([string]::IsNullOrWhiteSpace($response)) { return $DefaultYes.IsPresent }
    return $response -match '^[Yy]'
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host "  Free Claude Code - Uninstaller" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host ""
Write-Host "This will remove Free Claude Code from your system." -ForegroundColor Yellow
Write-Host ""

if (-not (Read-Confirmation "Continue with uninstallation?" -DefaultYes:$false)) {
    Write-Host "Uninstallation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Uninstalling..." -ForegroundColor Cyan
Write-Host ""

# Stop and remove PM2 service
if ($RemovePM2 -or (Read-Confirmation "Stop and remove PM2 service?" -DefaultYes:$true)) {
    Write-Host "[⟳] Stopping PM2 service..." -ForegroundColor Cyan
    
    $pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
    if ($pm2) {
        & pm2 stop free-claude-code 2>&1 | Out-Null
        & pm2 delete free-claude-code 2>&1 | Out-Null
        & pm2 save 2>&1 | Out-Null
        Write-Host "[✓] PM2 service removed" -ForegroundColor Green
    } else {
        Write-Host "[ℹ] PM2 not found, skipping" -ForegroundColor Gray
    }
}

# Remove configuration files
$filesToRemove = @(
    'ecosystem.config.js'
)

if ($RemoveConfig -or (Read-Confirmation "Remove .env configuration?" -DefaultYes:$false)) {
    $filesToRemove += '.env'
}

Write-Host "[⟳] Removing configuration files..." -ForegroundColor Cyan
foreach ($file in $filesToRemove) {
    $path = Join-Path $ProjectRoot $file
    if (Test-Path $path) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
        Write-Host "  [✓] Removed: $file" -ForegroundColor Gray
    }
}

# Remove backup files
$backups = Get-ChildItem -Path $ProjectRoot -Filter "*.backup.*" -ErrorAction SilentlyContinue
foreach ($backup in $backups) {
    Remove-Item $backup.FullName -Force -ErrorAction SilentlyContinue
    Write-Host "  [✓] Removed backup: $($backup.Name)" -ForegroundColor Gray
}

# Remove virtual environment
if ($RemoveVenv -or (Read-Confirmation "Remove Python virtual environment (.venv)?" -DefaultYes:$true)) {
    Write-Host "[⟳] Removing virtual environment..." -ForegroundColor Cyan
    $venvPath = Join-Path $ProjectRoot ".venv"
    if (Test-Path $venvPath) {
        Remove-Item $venvPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[✓] Virtual environment removed" -ForegroundColor Green
    } else {
        Write-Host "[ℹ] Virtual environment not found" -ForegroundColor Gray
    }
}

# Remove shortcuts
if ($RemoveShortcuts -or (Read-Confirmation "Remove shortcuts?" -DefaultYes:$true)) {
    Write-Host "[⟳] Removing shortcuts..." -ForegroundColor Cyan
    
    $desktop = [Environment]::GetFolderPath('Desktop')
    $startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $startMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    
    $shortcuts = @(
        (Join-Path $desktop "Start Claude Proxy.lnk"),
        (Join-Path $startup "Claude-Proxy.lnk"),
        (Join-Path $startMenu "Free Claude Code")
    )
    
    foreach ($shortcut in $shortcuts) {
        if (Test-Path $shortcut) {
            Remove-Item $shortcut -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [✓] Removed: $shortcut" -ForegroundColor Gray
        }
    }
    
    Write-Host "[✓] Shortcuts removed" -ForegroundColor Green
}

# Remove logs
if (-not $KeepLogs -and (Read-Confirmation "Remove log files?" -DefaultYes:$false)) {
    Write-Host "[⟳] Removing logs..." -ForegroundColor Cyan
    
    $logsPath = Join-Path $ProjectRoot "logs"
    if (Test-Path $logsPath) {
        Remove-Item $logsPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[✓] Logs removed" -ForegroundColor Green
    }
    
    $setupLog = Join-Path $ProjectRoot "setup.log"
    if (Test-Path $setupLog) {
        Remove-Item $setupLog -Force -ErrorAction SilentlyContinue
        Remove-Item "$setupLog.*" -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Uninstallation Complete" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Free Claude Code has been uninstalled." -ForegroundColor White
Write-Host ""
Write-Host "Note: System prerequisites (Python, Node.js, PM2, etc.) were NOT removed." -ForegroundColor Gray
Write-Host "You can manually uninstall them if no longer needed." -ForegroundColor Gray
Write-Host ""
Write-Host "You can safely delete this folder: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

if (-not $Silent) {
    Read-Host "Press Enter to exit"
}
