$WshShell = New-Object -ComObject WScript.Shell
$Desktop = [System.Environment]::GetFolderPath('Desktop')
$Shortcut = $WshShell.CreateShortcut("$Desktop\Start Claude Proxy.lnk")
$Shortcut.TargetPath = "C:\Users\Administrator\Downloads\free-claude-code\start-claude-proxy.bat"
$Shortcut.WorkingDirectory = "C:\Users\Administrator\Downloads\free-claude-code"
$Shortcut.Description = "Start Claude Proxy Server"
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,13"
$Shortcut.Save()
Write-Host "Desktop shortcut created successfully!" -ForegroundColor Green
