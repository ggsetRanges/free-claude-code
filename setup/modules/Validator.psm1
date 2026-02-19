#requires -Version 5.1

<#
.SYNOPSIS
    Post-installation validator
.DESCRIPTION
    Verifies that the installation was successful and all components are working
#>

function Test-Installation {
    <#
    .SYNOPSIS
        Run comprehensive installation tests
    .PARAMETER ProjectRoot
        Root directory of the project
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $results = [PSCustomObject]@{
        PythonEnvironment = $false
        Dependencies = $false
        Configuration = $false
        PM2Service = $false
        ServerStartup = $false
        APIHealth = $false
        ModelsEndpoint = $false
        Warnings = @()
        Errors = @()
        AllPass = $false
    }

    # Test 1: Python Environment
    try {
        $venvPath = Join-Path $ProjectRoot ".venv"
        if (Test-Path $venvPath) {
            $results.PythonEnvironment = $true
        } else {
            $results.Errors += "Virtual environment not found at: $venvPath"
        }
    } catch {
        $results.Errors += "Python environment check failed: $_"
    }

    # Test 2: Dependencies
    try {
        $pythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
        if (Test-Path $pythonExe) {
            $testImport = & $pythonExe -c "import fastapi, uvicorn, httpx; print('OK')" 2>&1
            if ($testImport -match 'OK') {
                $results.Dependencies = $true
            } else {
                $results.Errors += "Failed to import required Python packages"
            }
        } else {
            $results.Errors += "Python executable not found in virtual environment"
        }
    } catch {
        $results.Errors += "Dependency check failed: $_"
    }

    # Test 3: Configuration
    try {
        $envPath = Join-Path $ProjectRoot ".env"
        if (Test-Path $envPath) {
            $envContent = Get-Content $envPath -Raw
            
            # Check for required keys
            $requiredKeys = @('PROVIDER_TYPE', 'MODEL')
            $missingKeys = @()
            
            foreach ($key in $requiredKeys) {
                if ($envContent -notmatch "$key=") {
                    $missingKeys += $key
                }
            }
            
            if ($missingKeys.Count -eq 0) {
                $results.Configuration = $true
            } else {
                $results.Errors += "Missing required configuration keys: $($missingKeys -join ', ')"
            }
        } else {
            $results.Errors += ".env file not found"
        }
    } catch {
        $results.Errors += "Configuration check failed: $_"
    }

    # Test 4: PM2 Service
    try {
        if (Get-Command pm2 -ErrorAction SilentlyContinue) {
            $pm2List = & pm2 jlist 2>&1 | ConvertFrom-Json
            $service = $pm2List | Where-Object { $_.name -eq 'free-claude-code' }
            
            if ($service) {
                if ($service.pm2_env.status -eq 'online') {
                    $results.PM2Service = $true
                } else {
                    $results.Warnings += "PM2 service exists but is not online (status: $($service.pm2_env.status))"
                }
            } else {
                $results.Warnings += "PM2 service not registered"
            }
        } else {
            $results.Warnings += "PM2 not found"
        }
    } catch {
        $results.Warnings += "PM2 service check failed: $_"
    }

    # Test 5: Server Startup (if PM2 is running)
    if ($results.PM2Service) {
        try {
            Start-Sleep -Seconds 2  # Give server time to start
            
            $response = Invoke-WebRequest -Uri "http://localhost:8082/health" -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            
            if ($response.StatusCode -eq 200) {
                $results.ServerStartup = $true
                $results.APIHealth = $true
            }
        } catch {
            $results.Warnings += "Server health check failed: $_"
        }

        # Test 6: Models Endpoint
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8082/v1/models" -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            
            if ($response.StatusCode -eq 200) {
                $results.ModelsEndpoint = $true
            }
        } catch {
            $results.Warnings += "Models endpoint check failed: $_"
        }
    }

    # Test 7: Claude Code CLI (warning only)
    try {
        $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
        if (-not $claudeCmd) {
            $results.Warnings += "Claude Code CLI not found in PATH. Install from: https://github.com/anthropics/claude-code"
        }
    } catch {
        # Ignore
    }

    # Calculate overall pass/fail
    $results.AllPass = $results.PythonEnvironment -and 
                       $results.Dependencies -and 
                       $results.Configuration -and
                       ($results.APIHealth -or $results.PM2Service)

    return $results
}

function Show-VerificationReport {
    <#
    .SYNOPSIS
        Display verification results in a nice format
    .PARAMETER Results
        Results object from Test-Installation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Results
    )

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Verification Report" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Display test results
    $tests = @(
        @{ Name = "Python Environment"; Pass = $Results.PythonEnvironment },
        @{ Name = "Dependencies"; Pass = $Results.Dependencies },
        @{ Name = "Configuration"; Pass = $Results.Configuration },
        @{ Name = "PM2 Service"; Pass = $Results.PM2Service },
        @{ Name = "Server Startup"; Pass = $Results.ServerStartup },
        @{ Name = "API Health Check"; Pass = $Results.APIHealth },
        @{ Name = "Models Endpoint"; Pass = $Results.ModelsEndpoint }
    )

    foreach ($test in $tests) {
        $icon = if ($test.Pass) { "[✓]" } else { "[✗]" }
        $color = if ($test.Pass) { "Green" } else { "Red" }
        
        Write-Host "$icon " -NoNewline -ForegroundColor $color
        Write-Host $test.Name -ForegroundColor Gray
    }

    # Display warnings
    if ($Results.Warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $Results.Warnings) {
            Write-Host "  [⚠] $warning" -ForegroundColor Yellow
        }
    }

    # Display errors
    if ($Results.Errors.Count -gt 0) {
        Write-Host ""
        Write-Host "Errors:" -ForegroundColor Red
        foreach ($err in $Results.Errors) {
            Write-Host "  [✗] $err" -ForegroundColor Red
        }
    }

    Write-Host ""
    
    if ($Results.AllPass) {
        Write-Host "✓ All critical tests passed!" -ForegroundColor Green
    } else {
        Write-Host "✗ Some tests failed. Please review the errors above." -ForegroundColor Red
    }
    
    Write-Host ""
}

function Invoke-HealthCheck {
    <#
    .SYNOPSIS
        Perform a simple health check on the server
    .PARAMETER Url
        Base URL of the server
    .PARAMETER Timeout
        Timeout in seconds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Url = "http://localhost:8082",
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 5
    )

    try {
        $response = Invoke-RestMethod -Uri "$Url/health" -Method GET -TimeoutSec $Timeout
        return $response.status -eq 'ok'
    } catch {
        return $false
    }
}

Export-ModuleMember -Function Test-Installation, Show-VerificationReport, Invoke-HealthCheck
