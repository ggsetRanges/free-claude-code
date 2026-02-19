#requires -Version 5.1

<#
.SYNOPSIS
    Centralized logging system for the setup wizard
.DESCRIPTION
    Provides logging to both console and file with timestamps and log levels
#>

$script:LogPath = $null
$script:LogInitialized = $false

function Initialize-Logger {
    <#
    .SYNOPSIS
        Initialize the logging system
    .PARAMETER LogPath
        Path to the log file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    $script:LogPath = $LogPath
    
    # Create log directory if it doesn't exist
    $logDir = Split-Path -Path $LogPath -Parent
    if ($logDir -and -not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Rotate old logs (keep last 5)
    if (Test-Path $LogPath) {
        for ($i = 4; $i -ge 1; $i--) {
            $oldLog = "$LogPath.$i"
            $newLog = "$LogPath.$($i + 1)"
            if (Test-Path $oldLog) {
                Move-Item -Path $oldLog -Destination $newLog -Force
            }
        }
        Move-Item -Path $LogPath -Destination "$LogPath.1" -Force
    }

    # Write header
    $header = @"
================================================================================
Free Claude Code Setup Wizard - Log File
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)
OS: $([System.Environment]::OSVersion.VersionString)
================================================================================

"@
    
    Set-Content -Path $LogPath -Value $header -Encoding UTF8
    $script:LogInitialized = $true
    
    Write-Log "Logger initialized at: $LogPath" -Level INFO
}

function Write-Log {
    <#
    .SYNOPSIS
        Write a log entry
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        Log level (INFO, WARN, ERROR, DEBUG)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )

    if (-not $script:LogInitialized) {
        Write-Warning "Logger not initialized. Call Initialize-Logger first."
        return
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to log file: $_"
    }
}

function Get-LogTail {
    <#
    .SYNOPSIS
        Get the last N lines from the log
    .PARAMETER Lines
        Number of lines to retrieve
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Lines = 20
    )

    if (-not $script:LogInitialized -or -not (Test-Path $script:LogPath)) {
        return @()
    }

    Get-Content -Path $script:LogPath -Tail $Lines
}

function Close-Logger {
    <#
    .SYNOPSIS
        Finalize the log file
    #>
    [CmdletBinding()]
    param()

    if ($script:LogInitialized) {
        $footer = @"

================================================================================
Setup completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================
"@
        Add-Content -Path $script:LogPath -Value $footer -Encoding UTF8
        $script:LogInitialized = $false
    }
}

Export-ModuleMember -Function Initialize-Logger, Write-Log, Get-LogTail, Close-Logger
