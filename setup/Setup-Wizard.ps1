#requires -Version 5.1

<#
.SYNOPSIS
    Free Claude Code Setup Wizard - Main Orchestrator
.DESCRIPTION
    Automated installation wizard for Free Claude Code proxy server
.PARAMETER Mode
    Installation mode: install, repair, or update
.PARAMETER Silent
    Run in silent mode (no interactive prompts)
.PARAMETER SkipPrereqs
    Skip prerequisite checks
.PARAMETER SkipShortcuts
    Skip shortcut creation
.PARAMETER SkipPM2
    Skip PM2 service setup
.PARAMETER SkipValidation
    Skip post-install validation
.PARAMETER Force
    Force reinstallation
.PARAMETER LogPath
    Custom log file path
.EXAMPLE
    .\Setup-Wizard.ps1
    Run full interactive installation
.EXAMPLE
    .\Setup-Wizard.ps1 -Mode repair
    Repair existing installation
.EXAMPLE
    .\Setup-Wizard.ps1 -SkipShortcuts -SkipValidation
    Install without shortcuts and validation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('install', 'repair', 'update')]
    [string]$Mode = 'install',

    [Parameter(Mandatory = $false)]
    [switch]$Silent,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPrereqs,

    [Parameter(Mandatory = $false)]
    [switch]$SkipShortcuts,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPM2,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$LogPath,

    [Parameter(Mandatory = $false)]
    [Alias('h', 'help')]
    [switch]$ShowHelp
)

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

if ($ShowHelp) {
    Write-Host @"

Free Claude Code Setup Wizard v2.0.0

USAGE:
    .\Setup-Wizard.ps1 [OPTIONS]

OPTIONS:
    -Mode <install|repair|update>   Installation mode (default: install)
    -Silent                         Run without interactive prompts
    -SkipPrereqs                    Skip prerequisite installation
    -SkipShortcuts                  Skip desktop/startup shortcuts
    -SkipPM2                        Skip PM2 service setup
    -SkipValidation                 Skip post-install validation
    -Force                          Force reinstallation
    -LogPath <path>                 Custom log file path
    -ShowHelp, -h, -help            Show this help message

EXAMPLES:
    .\Setup-Wizard.ps1
        Full interactive installation

    .\Setup-Wizard.ps1 -Mode repair
        Repair existing installation

    .\Setup-Wizard.ps1 -SkipShortcuts
        Install without creating shortcuts

For more information, see SETUP_GUIDE.md

"@
    exit 0
}

# ═══════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = 'Stop'
$ProjectRoot = Resolve-Path "$PSScriptRoot\.."

# Import modules
Import-Module "$PSScriptRoot\modules\Logger.psm1" -Force
Import-Module "$PSScriptRoot\modules\ProgressDisplay.psm1" -Force
Import-Module "$PSScriptRoot\modules\RollbackManager.psm1" -Force
Import-Module "$PSScriptRoot\modules\UIModules.psm1" -Force
Import-Module "$PSScriptRoot\modules\PrerequisiteChecker.psm1" -Force
Import-Module "$PSScriptRoot\modules\ConfigWizard.psm1" -Force
Import-Module "$PSScriptRoot\modules\ShortcutManager.psm1" -Force
Import-Module "$PSScriptRoot\modules\PM2Manager.psm1" -Force
Import-Module "$PSScriptRoot\modules\Validator.psm1" -Force

# Initialize logger
if (-not $LogPath) {
    $LogPath = Join-Path $ProjectRoot "setup.log"
}
Initialize-Logger -LogPath $LogPath

Write-Log "═══════════════════════════════════════════════════════════════════" -Level INFO
Write-Log "Starting Setup Wizard (Mode: $Mode)" -Level INFO
Write-Log "Project root: $ProjectRoot" -Level INFO
Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" -Level INFO
Write-Log "═══════════════════════════════════════════════════════════════════" -Level INFO

# ═══════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

try {
    Clear-Host
    Show-RetroLogo
    Write-Host ""

    # Check admin rights
    if (-not (Test-IsAdmin)) {
        Write-Host ""
        Write-Status "Running without administrator privileges" -Level Warning
        Write-Host "  Some operations may fail without admin rights." -ForegroundColor Yellow
        Write-Host "  Consider running as Administrator for best results." -ForegroundColor Yellow
        Write-Host ""
        
        if (-not $Silent) {
            Start-Sleep -Seconds 2
        }
    }

    Write-Log "Admin check completed" -Level INFO

    # ═══════════════════════════════════════════════════════════════
    # PHASE 1: PREREQUISITES
    # ═══════════════════════════════════════════════════════════════

    if (-not $SkipPrereqs -and $Mode -ne 'repair') {
        Show-StepIndicator -Current 1 -Total 6 -StepName "Checking Prerequisites"
        Write-Log "Phase 1: Checking prerequisites" -Level INFO

        $prereqs = Test-Prerequisites

        Write-Host "Prerequisite Status:" -ForegroundColor Cyan
        Write-Host ""

        foreach ($key in $prereqs.Keys) {
            if ($key -eq 'AllRequiredPass') { continue }
            
            $item = $prereqs[$key]
            if ($item.Installed) {
                Write-Status "$key $($item.Version) [OK]" -Level Success
            } else {
                $status = if ($item.Required) { "REQUIRED" } else { "OPTIONAL" }
                Write-Status "$key [$status - $($item.Status)]" -Level Warning
            }
        }

        Write-Host ""

        if (-not $prereqs.AllRequiredPass) {
            Write-Log "Missing prerequisites detected" -Level WARN
            
            if ($Silent -or (Read-Confirmation "Install missing prerequisites?" -DefaultYes:$true)) {
                Invoke-PrerequisiteInstallation -Results $prereqs
                Write-Log "Prerequisites installed successfully" -Level INFO
            } else {
                Write-Host "Skipping prerequisite installation. Setup may fail." -ForegroundColor Yellow
                Write-Log "User skipped prerequisite installation" -Level WARN
            }
        } else {
            Write-Status "All prerequisites satisfied!" -Level Success
            Write-Log "All prerequisites satisfied" -Level INFO
        }

        Write-Host ""
        if (-not $Silent) {
            Read-Host "Press Enter to continue"
        }
    }

    # ═══════════════════════════════════════════════════════════════
    # PHASE 2: PYTHON ENVIRONMENT
    # ═══════════════════════════════════════════════════════════════

    if ($Mode -in 'install', 'update') {
        Show-StepIndicator -Current 2 -Total 6 -StepName "Setting up Python Environment"
        Write-Log "Phase 2: Setting up Python environment" -Level INFO

        Write-Status "Installing Python dependencies..." -Level Processing

        Push-Location $ProjectRoot
        try {
            $output = & uv sync 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "uv sync failed: $output"
            }
            
            Write-Status "Python environment ready" -Level Success
            Write-Log "Python dependencies installed" -Level INFO
        } catch {
            Write-Log "uv sync failed: $_" -Level ERROR
            throw "Failed to set up Python environment: $_"
        } finally {
            Pop-Location
        }

        Write-Host ""
        if (-not $Silent) {
            Read-Host "Press Enter to continue"
        }
    }

    # ═══════════════════════════════════════════════════════════════
    # PHASE 3: CONFIGURATION
    # ═══════════════════════════════════════════════════════════════

    if ($Mode -ne 'repair' -or $Force) {
        Show-StepIndicator -Current 3 -Total 6 -StepName "Configuration"
        Write-Log "Phase 3: Configuration wizard" -Level INFO

        if (-not $Silent) {
            $config = Get-UserConfiguration -ProjectRoot $ProjectRoot

            if ($null -eq $config) {
                throw "Configuration cancelled by user"
            }

            # Backup existing .env
            $envPath = Join-Path $ProjectRoot ".env"
            if (Test-Path $envPath) {
                $backup = "$envPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item $envPath $backup -Force
                Register-Change -Action CreateFile -Path $backup
                Write-Log "Backed up existing .env to: $backup" -Level INFO
            }

            # Write new .env
            New-EnvironmentFile -Config $config -OutputPath $envPath
            Register-Change -Action CreateFile -Path $envPath

            Write-Host ""
            Write-Status "Configuration saved to .env" -Level Success
            Write-Log "Configuration file created" -Level INFO
        } else {
            Write-Host "Silent mode: Skipping configuration (using existing .env)" -ForegroundColor Yellow
            Write-Log "Silent mode: Skipped configuration" -Level WARN
        }

        Write-Host ""
        if (-not $Silent) {
            Read-Host "Press Enter to continue"
        }
    }

    # ═══════════════════════════════════════════════════════════════
    # PHASE 4: SHORTCUTS
    # ═══════════════════════════════════════════════════════════════

    if (-not $SkipShortcuts) {
        Show-StepIndicator -Current 4 -Total 6 -StepName "Creating Shortcuts"
        Write-Log "Phase 4: Creating shortcuts" -Level INFO

        $batPath = Join-Path $ProjectRoot "start-claude-proxy.bat"
        
        # Check if bat file exists, if not use alternative
        if (-not (Test-Path $batPath)) {
            $batPath = Join-Path $ProjectRoot "claude-free.bat"
        }

        if (Test-Path $batPath) {
            if ($Silent -or (Read-Confirmation "Create desktop shortcut?" -DefaultYes:$true)) {
                try {
                    $shortcut = New-DesktopShortcut -Target $batPath -ShortcutName "Start Claude Proxy" -WorkingDirectory $ProjectRoot
                    Write-Status "Desktop shortcut created" -Level Success
                    Write-Log "Desktop shortcut created: $shortcut" -Level INFO
                } catch {
                    Write-Status "Failed to create desktop shortcut: $_" -Level Warning
                    Write-Log "Desktop shortcut failed: $_" -Level WARN
                }
            }

            if ($Silent -or (Read-Confirmation "Create startup shortcut (auto-start on login)?" -DefaultYes:$false)) {
                try {
                    $shortcut = New-StartupShortcut -Target $batPath -ShortcutName "Claude-Proxy" -WorkingDirectory $ProjectRoot
                    Write-Status "Startup shortcut created" -Level Success
                    Write-Log "Startup shortcut created: $shortcut" -Level INFO
                } catch {
                    Write-Status "Failed to create startup shortcut: $_" -Level Warning
                    Write-Log "Startup shortcut failed: $_" -Level WARN
                }
            }
        } else {
            Write-Status "Batch file not found, skipping shortcuts" -Level Warning
            Write-Log "Batch file not found at: $batPath" -Level WARN
        }

        Write-Host ""
        if (-not $Silent) {
            Read-Host "Press Enter to continue"
        }
    }

    # ═══════════════════════════════════════════════════════════════
    # PHASE 5: PM2 SERVICE
    # ═══════════════════════════════════════════════════════════════

    if (-not $SkipPM2 -and $Mode -ne 'repair') {
        Show-StepIndicator -Current 5 -Total 6 -StepName "Configuring PM2 Service"
        Write-Log "Phase 5: Configuring PM2 service" -Level INFO

        Write-Status "Generating PM2 ecosystem config..." -Level Processing

        # Read .env file
        $envPath = Join-Path $ProjectRoot ".env"
        if (Test-Path $envPath) {
            $envContent = Get-Content $envPath
            $envConfig = @{}
            
            foreach ($line in $envContent) {
                if ($line -match '^([^#=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim().Trim('"')
                    $envConfig[$key] = $value
                }
            }

            $ecosystemPath = Join-Path $ProjectRoot "ecosystem.config.js"
            New-PM2EcosystemConfig -Config $envConfig -OutputPath $ecosystemPath -ProjectRoot $ProjectRoot
            Write-Status "PM2 config created" -Level Success
            Write-Log "PM2 ecosystem config created" -Level INFO

            if ($Silent -or (Read-Confirmation "Start PM2 service now?" -DefaultYes:$true)) {
                try {
                    Register-PM2Service -ProjectRoot $ProjectRoot
                    Write-Status "PM2 service started" -Level Success
                    Write-Log "PM2 service started" -Level INFO
                    
                    Write-Host ""
                    Write-Host "  Server is now running at: http://localhost:8082" -ForegroundColor Green
                    Write-Host "  Use 'pm2 logs free-claude-code' to view logs" -ForegroundColor Gray
                    Write-Host ""
                } catch {
                    Write-Status "Failed to start PM2 service: $_" -Level Warning
                    Write-Log "PM2 service start failed: $_" -Level WARN
                }
            }
        } else {
            Write-Status ".env file not found, skipping PM2 setup" -Level Warning
            Write-Log ".env file not found" -Level WARN
        }

        Write-Host ""
        if (-not $Silent) {
            Read-Host "Press Enter to continue"
        }
    }

    # ═══════════════════════════════════════════════════════════════
    # PHASE 6: VALIDATION
    # ═══════════════════════════════════════════════════════════════

    if (-not $SkipValidation) {
        Show-StepIndicator -Current 6 -Total 6 -StepName "Validation"
        Write-Log "Phase 6: Post-install validation" -Level INFO

        Write-Status "Running post-install checks..." -Level Processing
        Write-Host ""

        $validation = Test-Installation -ProjectRoot $ProjectRoot
        Show-VerificationReport -Results $validation

        Write-Log "Validation completed. AllPass: $($validation.AllPass)" -Level INFO

        if (-not $validation.AllPass -and -not $Silent) {
            if (-not (Read-Confirmation "Some checks failed. Continue anyway?" -DefaultYes:$true)) {
                throw "Validation failed"
            }
        }

        if (-not $Silent) {
            Read-Host "Press Enter to continue"
        }
    }

    # ═══════════════════════════════════════════════════════════════
    # COMPLETION
    # ═══════════════════════════════════════════════════════════════

    Clear-Host
    Show-RetroLogo
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your free-claude-code server is ready to use!" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host "  • Start server: " -NoNewline -ForegroundColor Gray
    Write-Host "pm2 start free-claude-code" -ForegroundColor White
    Write-Host "  • View logs: " -NoNewline -ForegroundColor Gray
    Write-Host "pm2 logs free-claude-code" -ForegroundColor White
    Write-Host "  • Stop server: " -NoNewline -ForegroundColor Gray
    Write-Host "pm2 stop free-claude-code" -ForegroundColor White
    Write-Host "  • API docs: " -NoNewline -ForegroundColor Gray
    Write-Host "http://localhost:8082/docs" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Configure VSCode extension (see README.md)" -ForegroundColor Gray
    Write-Host "  2. Test API: curl http://localhost:8082/v1/models" -ForegroundColor Gray
    Write-Host "  3. Read documentation: SETUP_GUIDE.md" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Logs:" -ForegroundColor Cyan
    Write-Host "  • Setup log: $LogPath" -ForegroundColor Gray
    Write-Host ""

    Write-Log "Setup completed successfully" -Level INFO
    Close-Logger

    # Clear rollback stack on success
    Clear-RollbackStack

} catch {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  SETUP FAILED" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the log file for details: $LogPath" -ForegroundColor Yellow
    Write-Host ""

    Write-Log "Setup failed: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR

    if (-not $Silent) {
        $rollback = Read-Confirmation "Attempt to rollback changes?" -DefaultYes:$true
        if ($rollback) {
            Write-Host ""
            Invoke-Rollback
        }
    }

    Close-Logger
    exit 1
}
