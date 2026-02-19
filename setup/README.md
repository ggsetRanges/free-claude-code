# Setup Wizard - Internal Structure

This directory contains the automated setup wizard for Free Claude Code.

## Files

- **`Setup-Wizard.ps1`** - Main orchestrator script
- **`modules/`** - PowerShell modules (10 files)
- **`assets/`** - ASCII art logo
- **`backups/`** - Temporary backup storage during installation

## Usage

Users should run `SETUP.bat` from the root directory, not these files directly.

## For Developers

To modify the setup wizard:

1. Edit modules in `modules/` directory
2. Test with: `.\Setup-Wizard.ps1 -SkipValidation`
3. Check logs in `../setup.log`

## Modules

| Module | Purpose |
|--------|---------|
| Logger.psm1 | Logging system |
| ProgressDisplay.psm1 | Retro UI |
| UIModules.psm1 | UI components |
| RollbackManager.psm1 | Change tracking |
| PrerequisiteChecker.psm1 | Dependency installation |
| ConfigWizard.psm1 | Configuration wizard |
| ShortcutManager.psm1 | Shortcut creation |
| PM2Manager.psm1 | PM2 service setup |
| Validator.psm1 | Post-install checks |
