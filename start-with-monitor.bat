@echo off
REM Start Claude Proxy with Live Monitor
title Starting Claude Proxy Server
echo Starting Claude Proxy Server with Live Monitor...
echo.

REM Add npm to PATH
set PATH=%APPDATA%\npm;%PATH%

REM Start or resurrect the proxy
echo [1/2] Starting proxy server...
pm2 resurrect
if %errorlevel% neq 0 (
    echo Failed to start with resurrect, trying fresh start...
    cd /d "%~dp0"
    pm2 start ecosystem.config.js
)

echo.
echo [2/2] Waiting for server to initialize...
timeout /t 3 /nobreak >nul

REM Open monitor in a new window
echo.
echo Opening live monitor window...
start "Claude Proxy Monitor" "%~dp0monitor-proxy.bat"

echo.
echo Monitor window opened! Check the new window for live status.
echo.
timeout /t 3 /nobreak >nul
exit
