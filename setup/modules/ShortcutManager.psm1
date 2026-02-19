#requires -Version 5.1

<#
.SYNOPSIS
    Shortcut manager for creating desktop and startup shortcuts
.DESCRIPTION
    Creates Windows shortcuts for easy access to the proxy server
#>

function New-DesktopShortcut {
    <#
    .SYNOPSIS
        Create a desktop shortcut
    .PARAMETER Target
        Target executable or script
    .PARAMETER ShortcutName
        Name of the shortcut (without .lnk)
    .PARAMETER WorkingDirectory
        Working directory for the shortcut
    .PARAMETER Description
        Shortcut description
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,
        
        [Parameter(Mandatory = $true)]
        [string]$ShortcutName,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Free Claude Code Proxy Server"
    )

    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Desktop = [Environment]::GetFolderPath('Desktop')
        $ShortcutPath = Join-Path $Desktop "$ShortcutName.lnk"
        
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $Target
        
        if ($WorkingDirectory) {
            $Shortcut.WorkingDirectory = $WorkingDirectory
        } else {
            $Shortcut.WorkingDirectory = Split-Path $Target -Parent
        }
        
        $Shortcut.Description = $Description
        $Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,13"
        $Shortcut.Save()
        
        if (Get-Command Register-Change -ErrorAction SilentlyContinue) {
            Register-Change -Action CreateLink -Path $ShortcutPath
        }
        
        return $ShortcutPath
    } catch {
        throw "Failed to create desktop shortcut: $_"
    }
}

function New-StartupShortcut {
    <#
    .SYNOPSIS
        Create a startup shortcut (auto-start on login)
    .PARAMETER Target
        Target executable or script
    .PARAMETER ShortcutName
        Name of the shortcut (without .lnk)
    .PARAMETER WorkingDirectory
        Working directory for the shortcut
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,
        
        [Parameter(Mandatory = $true)]
        [string]$ShortcutName,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = ""
    )

    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        $ShortcutPath = Join-Path $Startup "$ShortcutName.lnk"
        
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $Target
        
        if ($WorkingDirectory) {
            $Shortcut.WorkingDirectory = $WorkingDirectory
        } else {
            $Shortcut.WorkingDirectory = Split-Path $Target -Parent
        }
        
        $Shortcut.Description = "Auto-start Free Claude Code Proxy"
        $Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,13"
        $Shortcut.WindowStyle = 7  # Minimized
        $Shortcut.Save()
        
        if (Get-Command Register-Change -ErrorAction SilentlyContinue) {
            Register-Change -Action CreateLink -Path $ShortcutPath
        }
        
        return $ShortcutPath
    } catch {
        throw "Failed to create startup shortcut: $_"
    }
}

function New-StartMenuFolder {
    <#
    .SYNOPSIS
        Create a Start Menu folder with shortcuts
    .PARAMETER FolderName
        Name of the folder to create
    .PARAMETER Shortcuts
        Hashtable of shortcuts to create (Name = Target)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Shortcuts = @{}
    )

    try {
        $StartMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
        $FolderPath = Join-Path $StartMenu $FolderName
        
        if (-not (Test-Path $FolderPath)) {
            New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
            
            if (Get-Command Register-Change -ErrorAction SilentlyContinue) {
                Register-Change -Action CreateDir -Path $FolderPath
            }
        }
        
        $WshShell = New-Object -ComObject WScript.Shell
        
        foreach ($name in $Shortcuts.Keys) {
            $target = $Shortcuts[$name]
            $shortcutPath = Join-Path $FolderPath "$name.lnk"
            
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $target
            $Shortcut.WorkingDirectory = Split-Path $target -Parent
            $Shortcut.Save()
            
            if (Get-Command Register-Change -ErrorAction SilentlyContinue) {
                Register-Change -Action CreateLink -Path $shortcutPath
            }
        }
        
        return $FolderPath
    } catch {
        throw "Failed to create Start Menu folder: $_"
    }
}

function Test-ShortcutExists {
    <#
    .SYNOPSIS
        Check if a shortcut exists
    .PARAMETER ShortcutName
        Name of the shortcut to check
    .PARAMETER Location
        Location to check (Desktop, Startup, StartMenu)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Desktop', 'Startup', 'StartMenu')]
        [string]$Location
    )

    $path = switch ($Location) {
        'Desktop' { Join-Path ([Environment]::GetFolderPath('Desktop')) "$ShortcutName.lnk" }
        'Startup' { Join-Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" "$ShortcutName.lnk" }
        'StartMenu' { Join-Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" "$ShortcutName.lnk" }
    }

    return Test-Path $path
}

Export-ModuleMember -Function New-DesktopShortcut, New-StartupShortcut, New-StartMenuFolder, Test-ShortcutExists
