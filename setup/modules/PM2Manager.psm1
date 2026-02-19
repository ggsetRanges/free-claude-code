#requires -Version 5.1

<#
.SYNOPSIS
    PM2 service manager for the proxy server
.DESCRIPTION
    Configures PM2 to manage the proxy server as a background service
#>

function New-PM2EcosystemConfig {
    <#
    .SYNOPSIS
        Generate PM2 ecosystem.config.js file
    .PARAMETER Config
        Hashtable of configuration values from .env
    .PARAMETER OutputPath
        Path to write the config file
    .PARAMETER ProjectRoot
        Root directory of the project
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    try {
        # Determine Python executable path
        $pythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
        
        if (-not (Test-Path $pythonExe)) {
            # Fallback to system Python
            $pythonExe = "python"
        }
        
        # Build environment variables object
        $envVars = @()
        foreach ($key in $Config.Keys) {
            $value = $Config[$key] -replace '"', '\"'
            $envVars += "      ${key}: '$value'"
        }
        $envString = $envVars -join ",`n"
        
        # Generate ecosystem config
        $ecosystemConfig = @"
module.exports = {
  apps: [{
    name: 'free-claude-code',
    script: '$($pythonExe -replace '\\', '\\')',
    args: '-m uvicorn server:app --host 0.0.0.0 --port 8082',
    cwd: '$($ProjectRoot -replace '\\', '\\')',
    env: {
$envString
    },
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_memory_restart: '500M',
    watch: false,
    instances: 1,
    exec_mode: 'fork',
    time: true
  }]
};
"@

        Set-Content -Path $OutputPath -Value $ecosystemConfig -Encoding UTF8
        
        if (Get-Command Register-Change -ErrorAction SilentlyContinue) {
            Register-Change -Action CreateFile -Path $OutputPath
        }
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "PM2 ecosystem config created at: $OutputPath" -Level INFO
        }
        
        return $true
    } catch {
        throw "Failed to create PM2 ecosystem config: $_"
    }
}

function Register-PM2Service {
    <#
    .SYNOPSIS
        Register and start the PM2 service
    .PARAMETER ProjectRoot
        Root directory of the project
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    try {
        $ecosystemPath = Join-Path $ProjectRoot "ecosystem.config.js"
        
        if (-not (Test-Path $ecosystemPath)) {
            throw "Ecosystem config not found at: $ecosystemPath"
        }
        
        # Check if PM2 is available
        $pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
        if (-not $pm2) {
            throw "PM2 not found. Please install PM2 first: npm install -g pm2"
        }
        
        Push-Location $ProjectRoot
        
        try {
            # Stop existing instance if running
            & pm2 stop free-claude-code 2>&1 | Out-Null
            & pm2 delete free-claude-code 2>&1 | Out-Null
            
            # Start with ecosystem config
            $output = & pm2 start $ecosystemPath 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "PM2 start failed: $output"
            }
            
            # Save PM2 process list
            & pm2 save 2>&1 | Out-Null
            
            if (Get-Command Register-Change -ErrorAction SilentlyContinue) {
                Register-Change -Action StartService -Path "free-claude-code"
            }
            
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log "PM2 service registered and started" -Level INFO
            }
            
            return $true
        } finally {
            Pop-Location
        }
    } catch {
        throw "Failed to register PM2 service: $_"
    }
}

function Test-PM2Service {
    <#
    .SYNOPSIS
        Check if the PM2 service is running
    #>
    [CmdletBinding()]
    param()

    try {
        $pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
        if (-not $pm2) {
            return $false
        }
        
        $output = & pm2 jlist 2>&1 | ConvertFrom-Json
        
        $service = $output | Where-Object { $_.name -eq 'free-claude-code' }
        
        return ($null -ne $service -and $service.pm2_env.status -eq 'online')
    } catch {
        return $false
    }
}

function Stop-PM2Service {
    <#
    .SYNOPSIS
        Stop the PM2 service
    #>
    [CmdletBinding()]
    param()

    try {
        $pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
        if (-not $pm2) {
            return
        }
        
        & pm2 stop free-claude-code 2>&1 | Out-Null
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "PM2 service stopped" -Level INFO
        }
    } catch {
        Write-Warning "Failed to stop PM2 service: $_"
    }
}

function Start-PM2Service {
    <#
    .SYNOPSIS
        Start the PM2 service
    #>
    [CmdletBinding()]
    param()

    try {
        $pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
        if (-not $pm2) {
            throw "PM2 not found"
        }
        
        & pm2 start free-claude-code 2>&1 | Out-Null
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "PM2 service started" -Level INFO
        }
    } catch {
        throw "Failed to start PM2 service: $_"
    }
}

function Get-PM2Logs {
    <#
    .SYNOPSIS
        Get PM2 service logs
    .PARAMETER Lines
        Number of lines to retrieve
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Lines = 20
    )

    try {
        $pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
        if (-not $pm2) {
            return @()
        }
        
        $output = & pm2 logs free-claude-code --lines $Lines --nostream 2>&1
        return $output
    } catch {
        return @()
    }
}

Export-ModuleMember -Function New-PM2EcosystemConfig, Register-PM2Service, Test-PM2Service, Stop-PM2Service, Start-PM2Service, Get-PM2Logs
