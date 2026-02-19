@echo off
title Claude Proxy Monitor
color 0A
mode con: cols=80 lines=30

REM Add npm to PATH
set PATH=%APPDATA%\npm;%PATH%

:MONITOR
cls
echo ================================================================================
echo                     CLAUDE PROXY SERVER MONITOR
echo ================================================================================
echo.
echo [%date% %time%]
echo.

REM Check if PM2 process is running
echo [1/4] Checking PM2 Process...
pm2 list | findstr /C:"claude-proxy" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] PM2 process found
) else (
    echo [ERROR] PM2 process not found!
    echo.
    echo Starting proxy server...
    pm2 resurrect
    timeout /t 3 /nobreak >nul
)
echo.

REM Check if port 8082 is listening
echo [2/4] Checking Port 8082...
netstat -ano | findstr ":8082" | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Port 8082 is listening
) else (
    echo [WARNING] Port 8082 not listening yet...
)
echo.

REM Test API endpoint
echo [3/4] Testing API Endpoint...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8082/v1/models' -TimeoutSec 5 -UseBasicParsing; if ($response.StatusCode -eq 200) { Write-Host '[OK] API responding (Status 200)' -ForegroundColor Green } else { Write-Host '[WARNING] API returned status:' $response.StatusCode -ForegroundColor Yellow } } catch { Write-Host '[ERROR] API not responding:' $_.Exception.Message -ForegroundColor Red }"
echo.

REM Show PM2 status
echo [4/4] PM2 Status:
echo --------------------------------------------------------------------------------
pm2 status
echo --------------------------------------------------------------------------------
echo.

REM Show server logs (last 5 lines)
echo Recent Server Logs:
echo --------------------------------------------------------------------------------
pm2 logs claude-proxy --lines 5 --nostream 2>nul
echo --------------------------------------------------------------------------------
echo.

REM Final status
echo ================================================================================
netstat -ano | findstr ":8082" | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8082/v1/models' -TimeoutSec 2 -UseBasicParsing; if ($response.StatusCode -eq 200) { Write-Host '  STATUS: READY FOR VSCODE CLAUDE CODE!' -ForegroundColor Green -BackgroundColor Black; Write-Host '  Server: http://localhost:8082' -ForegroundColor Cyan } } catch { Write-Host '  STATUS: Starting up, please wait...' -ForegroundColor Yellow }"
) else (
    echo   STATUS: Server not ready yet...
)
echo ================================================================================
echo.
echo Press Ctrl+C to exit monitor, or wait for auto-refresh in 10 seconds...
echo.

timeout /t 10 /nobreak >nul
goto MONITOR
