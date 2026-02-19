# Free Claude Code - Setup Guide

Complete guide for installing and configuring the Free Claude Code proxy server.

## Table of Contents

- [Quick Start](#quick-start)
- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [FAQ](#faq)

---

## Quick Start

### Automated Installation (Recommended)

1. **Download the repository**
   ```bash
   git clone https://github.com/rishiskhare/free-claude-code.git
   cd free-claude-code
   ```

2. **Run the installer**
   - **Windows**: Double-click `INSTALL.bat` or run:
     ```powershell
     .\setup\Setup-Wizard.ps1
     ```

3. **Follow the wizard**
   - Select your AI provider (NVIDIA NIM, OpenRouter, or LM Studio)
   - Enter your API key (if required)
   - Choose a model
   - Configure optional features

4. **Done!** The server will start automatically.

---

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Windows 10/11 (64-bit) |
| **RAM** | 4 GB minimum, 8 GB recommended |
| **Disk Space** | 2 GB free space |
| **Internet** | Required for NVIDIA NIM and OpenRouter |

### Required Software

The setup wizard will automatically install these if missing:

- **Python 3.14+** - Runtime for the proxy server
- **Node.js 18+** - Required for PM2 process manager
- **uv** - Python package manager
- **PM2** - Process manager for background service
- **fzf** - Fuzzy finder for model selection

### Optional Software

- **Claude Code CLI** - For terminal usage
- **VSCode** - For VSCode extension integration

---

## Installation Methods

### Method 1: Automated Wizard (Recommended)

**Full Interactive Installation:**
```powershell
.\setup\Setup-Wizard.ps1
```

**Silent Installation (with existing .env):**
```powershell
.\setup\Setup-Wizard.ps1 -Silent
```

**Skip Specific Steps:**
```powershell
# Skip shortcuts
.\setup\Setup-Wizard.ps1 -SkipShortcuts

# Skip validation
.\setup\Setup-Wizard.ps1 -SkipValidation

# Skip PM2 setup
.\setup\Setup-Wizard.ps1 -SkipPM2
```

**Repair Mode:**
```powershell
.\setup\Setup-Wizard.ps1 -Mode repair
```

### Method 2: Manual Installation

If you prefer manual setup or the wizard fails:

1. **Install Prerequisites**
   ```powershell
   # Install Python 3.14+
   # Download from: https://www.python.org/downloads/
   
   # Install Node.js
   # Download from: https://nodejs.org/
   
   # Install uv
   pip install uv
   
   # Install PM2
   npm install -g pm2
   
   # Install fzf
   # Download from: https://github.com/junegunn/fzf/releases
   ```

2. **Setup Python Environment**
   ```powershell
   cd free-claude-code
   uv sync
   ```

3. **Configure Environment**
   ```powershell
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Start Server**
   ```powershell
   pm2 start "uv run uvicorn server:app --host 0.0.0.0 --port 8082" --name "free-claude-code"
   ```

---

## Configuration

### Provider Setup

#### NVIDIA NIM (Free, Recommended)

1. Get API key: https://build.nvidia.com/settings/api-keys
2. Configure:
   ```env
   PROVIDER_TYPE=nvidia_nim
   NVIDIA_NIM_API_KEY=nvapi-your-key-here
   MODEL=stepfun-ai/step-3.5-flash
   ```

**Popular Models:**
- `stepfun-ai/step-3.5-flash` - Fast, balanced
- `deepseek-ai/deepseek-v3.1` - High quality
- `meta/llama-3.3-70b-instruct` - Strong reasoning
- `moonshotai/kimi-k2.5` - Long context

#### OpenRouter (Paid)

1. Get API key: https://openrouter.ai/keys
2. Configure:
   ```env
   PROVIDER_TYPE=open_router
   OPENROUTER_API_KEY=sk-or-your-key-here
   MODEL=anthropic/claude-3.5-sonnet
   ```

#### LM Studio (Local)

1. Install LM Studio: https://lmstudio.ai/
2. Load a model and start the server
3. Configure:
   ```env
   PROVIDER_TYPE=lmstudio
   LM_STUDIO_BASE_URL=http://localhost:1234/v1
   MODEL=local-model
   ```

### VSCode Extension Setup

1. Install the Claude Code extension
2. Open VSCode Settings (Ctrl+,)
3. Search for `claude-code.environmentVariables`
4. Add:
   ```json
   "claude-code.environmentVariables": [
     { "name": "ANTHROPIC_BASE_URL", "value": "http://localhost:8082" },
     { "name": "ANTHROPIC_AUTH_TOKEN", "value": "freecc" }
   ]
   ```
5. Reload VSCode

**Use Specific Model:**
```json
{ "name": "ANTHROPIC_AUTH_TOKEN", "value": "freecc:moonshotai/kimi-k2.5" }
```

### Optional Features

#### Discord Bot

```env
MESSAGING_PLATFORM=discord
DISCORD_BOT_TOKEN=your-bot-token
ALLOWED_DISCORD_CHANNELS=channel-id-1,channel-id-2
```

#### Telegram Bot

```env
MESSAGING_PLATFORM=telegram
TELEGRAM_BOT_TOKEN=your-bot-token
ALLOWED_TELEGRAM_USER_ID=your-user-id
```

#### Voice Transcription

```env
VOICE_NOTE_ENABLED=true
WHISPER_MODEL=base
WHISPER_DEVICE=cpu
HF_TOKEN=your-huggingface-token  # Optional
```

---

## Troubleshooting

### Common Issues

#### 1. PowerShell Execution Policy Error

**Error:** "cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

#### 2. Port 8082 Already in Use

**Error:** "Address already in use"

**Solution:**
```powershell
# Find process using port 8082
netstat -ano | findstr :8082

# Kill the process (replace PID)
taskkill /PID <PID> /F

# Or change port in .env
# Add: PORT=8083
```

#### 3. Python Not Found After Installation

**Solution:**
```powershell
# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Or restart PowerShell
```

#### 4. PM2 Service Won't Start

**Check logs:**
```powershell
pm2 logs free-claude-code
```

**Common fixes:**
```powershell
# Restart service
pm2 restart free-claude-code

# Delete and recreate
pm2 delete free-claude-code
pm2 start ecosystem.config.js

# Check Python path in ecosystem.config.js
```

#### 5. API Key Invalid

**NVIDIA NIM:**
- Keys start with `nvapi-`
- Get new key: https://build.nvidia.com/settings/api-keys
- Check for typos

**OpenRouter:**
- Keys start with `sk-or-`
- Verify at: https://openrouter.ai/keys

#### 6. Model Not Found

**Solution:**
```powershell
# List available models
curl http://localhost:8082/v1/models

# Check nvidia_nim_models.json for valid model IDs
```

#### 7. VSCode Extension Not Connecting

**Checklist:**
1. Server running? `pm2 list`
2. Port accessible? `curl http://localhost:8082/health`
3. Environment variables set correctly?
4. VSCode reloaded after config change?

**Test connection:**
```powershell
curl http://localhost:8082/v1/models -H "Authorization: Bearer freecc"
```

### Getting Help

1. **Check logs:**
   ```powershell
   # Setup log
   type setup.log
   
   # Server logs
   pm2 logs free-claude-code
   ```

2. **Verify installation:**
   ```powershell
   .\setup\Setup-Wizard.ps1 -Mode repair -SkipValidation:$false
   ```

3. **Report issues:**
   - GitHub: https://github.com/rishiskhare/free-claude-code/issues
   - Include: OS version, error message, setup.log

---

## Advanced Usage

### Command-Line Options

```powershell
# Full help
.\setup\Setup-Wizard.ps1 -ShowHelp

# Repair installation
.\setup\Setup-Wizard.ps1 -Mode repair

# Update installation
.\setup\Setup-Wizard.ps1 -Mode update

# Force reinstall
.\setup\Setup-Wizard.ps1 -Force

# Custom log path
.\setup\Setup-Wizard.ps1 -LogPath "C:\logs\setup.log"
```

### PM2 Management

```powershell
# List all services
pm2 list

# View logs
pm2 logs free-claude-code

# Restart service
pm2 restart free-claude-code

# Stop service
pm2 stop free-claude-code

# Start service
pm2 start free-claude-code

# Monitor resources
pm2 monit

# Save configuration
pm2 save

# Setup auto-start on boot
pm2 startup
```

### Manual Server Start

```powershell
# Without PM2
cd free-claude-code
uv run uvicorn server:app --host 0.0.0.0 --port 8082

# With custom port
uv run uvicorn server:app --host 0.0.0.0 --port 8083

# With reload (development)
uv run uvicorn server:app --host 0.0.0.0 --port 8082 --reload
```

### Environment Variables

All settings can be configured in `.env`:

```env
# Provider Configuration
PROVIDER_TYPE=nvidia_nim
PROVIDER_RATE_LIMIT=40
PROVIDER_RATE_WINDOW=60

# HTTP Timeouts
HTTP_READ_TIMEOUT=300
HTTP_WRITE_TIMEOUT=10
HTTP_CONNECT_TIMEOUT=2

# Server Configuration
HOST=0.0.0.0
PORT=8082

# Agent Configuration
CLAUDE_WORKSPACE=./agent_workspace
MAX_CLI_SESSIONS=10
ALLOWED_DIR=/path/to/allowed/directory

# Optimization Flags
FAST_PREFIX_DETECTION=true
ENABLE_NETWORK_PROBE_MOCK=true
ENABLE_TITLE_GENERATION_SKIP=true
ENABLE_SUGGESTION_MODE_SKIP=true
ENABLE_FILEPATH_EXTRACTION_MOCK=true
```

### Multiple Instances

Run multiple instances with different ports:

```powershell
# Instance 1 (port 8082)
pm2 start ecosystem.config.js --name "claude-nvidia"

# Instance 2 (port 8083)
# Edit ecosystem.config.js to use port 8083
pm2 start ecosystem.config.js --name "claude-openrouter"
```

---

## FAQ

### General

**Q: Is this really free?**  
A: Yes! NVIDIA NIM provides 40 free requests per minute. OpenRouter has free models too.

**Q: Do I need an Anthropic API key?**  
A: No! That's the whole point - you use NVIDIA NIM, OpenRouter, or LM Studio instead.

**Q: Can I use this with the official Claude Code?**  
A: Yes! Just point it to `http://localhost:8082` instead of Anthropic's API.

**Q: Does this work on Mac/Linux?**  
A: The setup wizard is Windows-only, but you can manually install on Mac/Linux.

### Performance

**Q: Which model is fastest?**  
A: `stepfun-ai/step-3.5-flash` is very fast. `deepseek-v3.1` is slower but higher quality.

**Q: Can I use multiple models?**  
A: Yes! Change the `MODEL` in `.env` and restart: `pm2 restart free-claude-code`

**Q: What's the rate limit?**  
A: NVIDIA NIM: 40 req/min. OpenRouter: varies by model. LM Studio: unlimited.

### Troubleshooting

**Q: Setup wizard fails to install Python**  
A: Download manually from python.org and run wizard again with `-SkipPrereqs`

**Q: Server starts but VSCode can't connect**  
A: Check firewall settings. Try `curl http://localhost:8082/health`

**Q: How do I update?**  
A: Run `.\setup\Setup-Wizard.ps1 -Mode update`

**Q: How do I uninstall?**  
A: Run `.\UNINSTALL.ps1`

### Advanced

**Q: Can I run this on a remote server?**  
A: Yes! Change `HOST=0.0.0.0` in `.env` and configure firewall.

**Q: Can I use a custom model?**  
A: Yes! Set `MODEL=your-model-id` in `.env`

**Q: How do I enable HTTPS?**  
A: Use a reverse proxy like nginx or Caddy.

---

## Support

- **Documentation**: README.md, SETUP_GUIDE.md
- **Issues**: https://github.com/rishiskhare/free-claude-code/issues
- **Logs**: `setup.log`, `pm2 logs free-claude-code`

---

## Next Steps

After successful installation:

1. ✅ Test the API: `curl http://localhost:8082/v1/models`
2. ✅ Configure VSCode extension
3. ✅ Try the CLI: `claude-free`
4. ✅ Read the main README.md for usage examples
5. ✅ Join the community and share feedback!

---

**Happy coding with free Claude! 🚀**
