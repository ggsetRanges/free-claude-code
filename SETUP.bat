@echo off
REM ========================================================================
REM   Free Claude Code - One-Click Setup
REM   Double-click this file to install everything automatically!
REM ========================================================================

title Free Claude Code - Setup Wizard

echo.
echo  ========================================================================
echo    FREE CLAUDE CODE - AUTOMATED SETUP
echo  ========================================================================
echo.
echo  This wizard will automatically:
echo    - Install all prerequisites (Python, Node.js, PM2, etc.)
echo    - Configure your AI provider
echo    - Set up the proxy server
echo    - Create desktop shortcuts
echo.
echo  Press any key to start, or close this window to cancel...
echo.
pause >nul

REM Check for PowerShell
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: PowerShell not found!
    echo  Please install PowerShell to continue.
    echo.
    pause
    exit /b 1
)

REM Launch the setup wizard
echo.
echo  Starting setup wizard...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0setup\Setup-Wizard.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo  ========================================================================
    echo    SETUP COMPLETE!
    echo  ========================================================================
    echo.
    echo  Your proxy server is now running at: http://localhost:8082
    echo.
    echo  Next steps:
    echo    1. Configure VSCode extension (see README.md)
    echo    2. Test: curl http://localhost:8082/v1/models
    echo    3. Manage server: pm2 list / pm2 logs free-claude-code
    echo.
) else (
    echo.
    echo  ========================================================================
    echo    SETUP FAILED
    echo  ========================================================================
    echo.
    echo  Check setup.log for details.
    echo.
)

pause
