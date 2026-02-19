@echo off
REM Free Claude Code - Setup Wizard Launcher
REM This batch file launches the PowerShell setup wizard

echo.
echo ========================================================================
echo   Free Claude Code - Setup Wizard
echo ========================================================================
echo.
echo Starting setup wizard...
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found!
    echo Please install PowerShell to run this setup wizard.
    pause
    exit /b 1
)

REM Run the setup wizard
powershell -ExecutionPolicy Bypass -File "%~dp0setup\Setup-Wizard.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Setup failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Setup completed successfully!
echo.
pause
