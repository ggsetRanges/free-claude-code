$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Claude-Proxy.lnk")
$Shortcut.TargetPath = "C:\Users\Administrator\Downloads\free-claude-code\start-claude-proxy.bat"
$Shortcut.WorkingDirectory = "C:\Users\Administrator\Downloads\free-claude-code"
$Shortcut.WindowStyle = 7
$Shortcut.Description = "Auto-start Claude Proxy Server"
$Shortcut.Save()
Write-Host "Startup shortcut created successfully!" -ForegroundColor Green
Write-Host "The proxy will now start automatically when you log in to Windows." -ForegroundColor Cyan
