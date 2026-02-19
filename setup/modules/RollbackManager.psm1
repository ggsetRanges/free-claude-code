#requires -Version 5.1

<#
.SYNOPSIS
    Rollback manager for tracking and reversing changes
.DESCRIPTION
    Tracks all changes made during setup and provides rollback capability
#>

$script:RollbackStack = @()

function Register-Change {
    <#
    .SYNOPSIS
        Register a change for potential rollback
    .PARAMETER Action
        Type of action performed
    .PARAMETER Path
        Path affected by the action
    .PARAMETER BackupPath
        Optional backup path for restoration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('CreateFile', 'CreateDir', 'CreateLink', 'ModifyFile', 'StartService')]
        [string]$Action,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupPath = $null
    )

    $change = [PSCustomObject]@{
        Action     = $Action
        Path       = $Path
        BackupPath = $BackupPath
        Timestamp  = Get-Date
    }

    $script:RollbackStack += $change
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Registered change: $Action - $Path" -Level DEBUG
    }
}

function Invoke-Rollback {
    <#
    .SYNOPSIS
        Execute rollback of all registered changes
    #>
    [CmdletBinding()]
    param()

    if ($script:RollbackStack.Count -eq 0) {
        Write-Host "No changes to rollback" -ForegroundColor Yellow
        return
    }

    Write-Host "`nRolling back changes..." -ForegroundColor Yellow
    
    # Process in reverse order
    $changes = $script:RollbackStack | Sort-Object Timestamp -Descending
    
    foreach ($change in $changes) {
        try {
            switch ($change.Action) {
                'CreateFile' {
                    if (Test-Path $change.Path) {
                        Remove-Item -Path $change.Path -Force -ErrorAction Stop
                        Write-Host "  [✓] Removed file: $($change.Path)" -ForegroundColor Gray
                    }
                    
                    if ($change.BackupPath -and (Test-Path $change.BackupPath)) {
                        Move-Item -Path $change.BackupPath -Destination $change.Path -Force -ErrorAction Stop
                        Write-Host "  [✓] Restored backup: $($change.Path)" -ForegroundColor Gray
                    }
                }
                
                'CreateDir' {
                    if (Test-Path $change.Path) {
                        Remove-Item -Path $change.Path -Recurse -Force -ErrorAction Stop
                        Write-Host "  [✓] Removed directory: $($change.Path)" -ForegroundColor Gray
                    }
                }
                
                'CreateLink' {
                    if (Test-Path $change.Path) {
                        Remove-Item -Path $change.Path -Force -ErrorAction Stop
                        Write-Host "  [✓] Removed shortcut: $($change.Path)" -ForegroundColor Gray
                    }
                }
                
                'ModifyFile' {
                    if ($change.BackupPath -and (Test-Path $change.BackupPath)) {
                        Copy-Item -Path $change.BackupPath -Destination $change.Path -Force -ErrorAction Stop
                        Write-Host "  [✓] Restored file: $($change.Path)" -ForegroundColor Gray
                    }
                }
                
                'StartService' {
                    # For PM2 services
                    if (Get-Command pm2 -ErrorAction SilentlyContinue) {
                        & pm2 stop $change.Path 2>&1 | Out-Null
                        & pm2 delete $change.Path 2>&1 | Out-Null
                        Write-Host "  [✓] Stopped service: $($change.Path)" -ForegroundColor Gray
                    }
                }
            }
        } catch {
            Write-Host "  [✗] Failed to rollback $($change.Action): $($change.Path) - $_" -ForegroundColor Red
        }
    }
    
    # Clear the stack
    $script:RollbackStack = @()
    
    Write-Host "Rollback completed`n" -ForegroundColor Yellow
}

function Clear-RollbackStack {
    <#
    .SYNOPSIS
        Clear the rollback stack (after successful completion)
    #>
    [CmdletBinding()]
    param()

    $script:RollbackStack = @()
}

function Get-RollbackStack {
    <#
    .SYNOPSIS
        Get the current rollback stack
    #>
    [CmdletBinding()]
    param()

    return $script:RollbackStack
}

Export-ModuleMember -Function Register-Change, Invoke-Rollback, Clear-RollbackStack, Get-RollbackStack
