$WshShell = New-Object -ComObject WScript.Shell

# Update Desktop shortcut
$Desktop = [System.Environment]::GetFolderPath('Desktop')
$Shortcut = $WshShell.CreateShortcut("$Desktop\Start Claude Proxy.lnk")
$Shortcut.TargetPath = "C:\Users\Administrator\Downloads\free-claude-code\start-with-monitor.bat"
$Shortcut.WorkingDirectory = "C:\Users\Administrator\Downloads\free-claude-code"
$Shortcut.Description = "Start Claude Proxy Server with Live Monitor"
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,13"
$Shortcut.Save()

# Update Startup shortcut
$Shortcut2 = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Claude-Proxy.lnk")
$Shortcut2.TargetPath = "C:\Users\Administrator\Downloads\free-claude-code\start-with-monitor.bat"
$Shortcut2.WorkingDirectory = "C:\Users\Administrator\Downloads\free-claude-code"
$Shortcut2.WindowStyle = 7
$Shortcut2.Description = "Auto-start Claude Proxy Server with Monitor"
$Shortcut2.Save()

Write-Host "Shortcuts updated successfully!" -ForegroundColor Green
Write-Host "Desktop shortcut: Start Claude Proxy (with live monitor)" -ForegroundColor Cyan
Write-Host "Startup shortcut: Auto-starts with monitor on login" -ForegroundColor Cyan
