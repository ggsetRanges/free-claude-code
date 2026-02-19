@echo off
REM Auto-start Claude Proxy Server
echo Starting Claude Proxy Server...

REM Add npm global packages to PATH
set PATH=%APPDATA%\npm;%PATH%

REM Start the proxy using PM2
pm2 resurrect

echo.
echo Claude Proxy Status:
pm2 status

echo.
echo Proxy server is running at http://localhost:8082
echo.
echo You can close this window - the proxy runs in the background.
timeout /t 5 /nobreak >nul
exit
