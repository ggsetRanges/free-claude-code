@echo off
REM Auto-start Claude Proxy Server
echo Starting Claude Proxy Server...
pm2 resurrect
echo.
echo Claude Proxy Status:
pm2 status
echo.
echo Proxy server is running at http://localhost:8082
pause
