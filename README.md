<div align="center">

# Free Claude Code

> **Enhanced Fork** of [Alishahryar1/free-claude-code](https://github.com/Alishahryar1/free-claude-code)  
> This fork adds **simplified automated setup**, **enhanced Windows support**, and **improved installation guidelines** — open for all!

### Use Claude Code CLI & VSCode — for free. No Anthropic API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Python 3.14](https://img.shields.io/badge/python-3.14-3776ab.svg?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/downloads/)
[![uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json&style=for-the-badge)](https://github.com/astral-sh/uv)
[![Tested with Pytest](https://img.shields.io/badge/testing-Pytest-00c0ff.svg?style=for-the-badge)](https://github.com/Alishahryar1/free-claude-code/actions/workflows/tests.yml)
[![Type checking: Ty](https://img.shields.io/badge/type%20checking-ty-ffcc00.svg?style=for-the-badge)](https://pypi.org/project/ty/)
[![Code style: Ruff](https://img.shields.io/badge/code%20formatting-ruff-f5a623.svg?style=for-the-badge)](https://github.com/astral-sh/ruff)
[![Logging: Loguru](https://img.shields.io/badge/logging-loguru-4ecdc4.svg?style=for-the-badge)](https://github.com/Delgan/loguru)

A lightweight proxy server that translates Claude Code's Anthropic API calls into **NVIDIA NIM**, **OpenRouter**, or **LM Studio** format.  
Get **40 free requests/min** on NVIDIA NIM, access **hundreds of models** on OpenRouter, or run **fully local** with LM Studio.

[Features](#features) · [Quick Start](#quick-start) · [How It Works](#how-it-works) · [Discord Bot](#discord-bot) · [Configuration](#configuration) · [Contributing](#contributing)

---

</div>

<div align="center">
  <img src="pic.png" alt="Free Claude Code in action" width="700">
  <p><em>Claude Code running via NVIDIA NIM — completely free</em></p>
</div>

## 🎯 What's New in This Fork

This enhanced fork builds upon the original project with significant improvements:

| Enhancement | Description |
|-------------|-------------|
| **🚀 Automated Setup Wizard** | One-click Windows installer with interactive PowerShell wizard |
| **📦 Prerequisite Auto-Install** | Automatically installs Python, Node.js, uv, PM2, and fzf |
| **🔧 Smart Configuration** | Interactive configuration wizard with validation |
| **🎨 Enhanced UI** | Retro-styled terminal UI with progress tracking |
| **🔄 Rollback Support** | Automatic backup and rollback on installation failure |
| **🖥️ Desktop Shortcuts** | Auto-generated shortcuts for easy access |
| **📝 Comprehensive Docs** | Detailed setup guide and troubleshooting documentation |
| **✅ Validation System** | Post-install validation ensures everything works |
| **🛠️ Repair Mode** | Built-in repair functionality for fixing issues |
| **🗑️ Clean Uninstall** | Complete uninstallation script with cleanup |

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Zero Cost** | 40 req/min free on NVIDIA NIM. Free models on OpenRouter. Fully local with LM Studio |
| **Drop-in Replacement** | Set 2 env vars — no modifications to Claude Code CLI or VSCode extension needed |
| **3 Providers** | NVIDIA NIM, OpenRouter (hundreds of models), LM Studio (local & offline) |
| **Thinking Token Support** | Parses `<think>` tags and `reasoning_content` into native Claude thinking blocks |
| **Heuristic Tool Parser** | Models outputting tool calls as text are auto-parsed into structured tool use |
| **Request Optimization** | 5 categories of trivial API calls intercepted locally — saves quota and latency |
| **Discord Bot** | Remote autonomous coding with tree-based threading, session persistence, and live progress (Telegram also supported) |
| **Smart Rate Limiting** | Proactive rolling-window throttle + reactive 429 exponential backoff across all providers |
| **Subagent Control** | Task tool interception forces `run_in_background=False` — no runaway subagents |
| **Extensible** | Clean `BaseProvider` and `MessagingPlatform` ABCs — add new providers or platforms easily |

## 🚀 Quick Start

### 🪟 Automated Setup (Windows - Recommended)

**The easiest way to get started on Windows:**

1. **Download the repository**
   ```bash
   git clone https://github.com/rishiskhare/free-claude-code.git
   cd free-claude-code
   ```

2. **Run the one-click installer**
   - **Double-click [`SETUP.bat`](SETUP.bat)** ← That's it!
   - Or run in PowerShell: `.\setup\Setup-Wizard.ps1`

3. **Follow the interactive wizard**
   - The wizard will automatically install all prerequisites (Python, Node.js, uv, PM2, fzf)
   - Select your AI provider (NVIDIA NIM, OpenRouter, or LM Studio)
   - Enter your API key (get free NVIDIA key at [build.nvidia.com/settings/api-keys](https://build.nvidia.com/settings/api-keys))
   - Choose your preferred model
   - Configure optional features (Discord/Telegram bots, voice transcription)

4. **Done!** The server starts automatically and runs in the background.

**What the wizard does:**
- ✅ Installs all prerequisites automatically
- ✅ Creates Python virtual environment
- ✅ Generates [`.env`](.env.example) configuration
- ✅ Sets up PM2 background service
- ✅ Creates desktop shortcuts
- ✅ Validates installation

**Troubleshooting?** See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed help.

---

### 📋 Manual Setup (All Platforms)

If you prefer manual installation or are on Mac/Linux:

#### Step 1: Install the prerequisites

You need these before starting:

| What | Where to get it |
| --- | --- |
| NVIDIA API key (free) | [build.nvidia.com/settings/api-keys](https://build.nvidia.com/settings/api-keys) |
| Claude Code CLI | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
| uv (Python package runner) | [github.com/astral-sh/uv](https://github.com/astral-sh/uv) |
| PM2 (keeps the proxy running) | `npm install -g pm2` |
| fzf (fuzzy model picker) | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |


#### Step 2: Clone the repo and add your API key

```bash
git clone https://github.com/rishiskhare/free-claude-code.git
cd free-claude-code
cp .env.example .env
```

Now open [`.env`](.env.example) and set the `NVIDIA_NIM_API_KEY` value:

```dotenv
NVIDIA_NIM_API_KEY="nvapi-paste-your-key-here"
```

You only need to change that one key to get started.

> **Want to use a different provider?** See [Providers](#providers) for OpenRouter (hundreds of models) or LM Studio (fully local).

#### Step 3: Start the proxy server

```bash
pm2 start "uv run uvicorn server:app --host 0.0.0.0 --port 8082" --name "claude-proxy"
```

That's it - the proxy is now running in the background. You can close this terminal and it keeps going. Use these commands to manage it:

| Command | What it does |
| --- | --- |
| `pm2 logs claude-proxy` | See server logs (useful for troubleshooting) |
| `pm2 stop claude-proxy` | Stop the proxy |
| `pm2 restart claude-proxy` | Restart it (e.g., after editing `.env`) |
| `pm2 list` | Check if the proxy is running |

#### Step 4: Launch Claude Code

#### Option A: Terminal (CLI)

Add this alias to your `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
alias claude-free='/full/path/to/free-claude-code/claude-free'
```

Replace the path with where you cloned the repo (e.g., `/Users/yourname/Downloads/free-claude-code/`), then reload your shell:

```bash
source ~/.zshrc # or: source ~/.bashrc
```

Now you can run it from any directory:

```bash
claude-free
```

You'll see a searchable list of every available model. Pick one and go. Just type a few letters to filter (e.g., type "kimi" to find Kimi K2.5 instantly).

#### Option B: VSCode Extension

If you use the [Claude Code VSCode extension](https://marketplace.visualstudio.com/items?itemName=anthropics.claude-code), you can point it at the proxy too:

1. Open VSCode Settings (`Cmd + ,` on macOS, `Ctrl + ,` on Linux/Windows).
2. Search for `claude-code.environmentVariables`.
3. Click **Edit in settings.json** and add:

```json
"claude-code.environmentVariables": [
  { "name": "ANTHROPIC_BASE_URL", "value": "http://localhost:8082" },
  { "name": "ANTHROPIC_AUTH_TOKEN", "value": "freecc" }
]
```

4. Reload the extension (or restart VSCode).
5. **If you see the login screen** ("How do you want to log in?"): Click **Anthropic Console**, then authorize. The extension will start working. You may be redirected to buy credits in the browser - ignore that; the extension already works.

That's it - the Claude Code panel in VSCode now uses NVIDIA NIM for free. To switch back to Anthropic, remove or comment out the block above and reload.

> **Tip:** To use a specific model from VSCode, set the token to `freecc:model-id` (e.g., `"freecc:moonshotai/kimi-k2.5"`). Otherwise it uses the `MODEL` value from your [`.env`](.env.example).

## 🎨 Model-Specific Aliases (Optional)

You can also create aliases that skip the picker and go straight into a specific model. Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias claude-kimi='ANTHROPIC_BASE_URL="http://localhost:8082" ANTHROPIC_AUTH_TOKEN="freecc:moonshotai/kimi-k2.5" claude'
```

Swap out the model ID after `freecc:` to use any model. Then run `source ~/.zshrc` (or `source ~/.bashrc`).

---

## 🔧 Configuration

### Providers

#### NVIDIA NIM (Free, Recommended)

Get 40 free requests per minute with NVIDIA NIM:

1. Get your free API key: [build.nvidia.com/settings/api-keys](https://build.nvidia.com/settings/api-keys)
2. Add to [`.env`](.env.example):
   ```env
   PROVIDER_TYPE=nvidia_nim
   NVIDIA_NIM_API_KEY=nvapi-your-key-here
   MODEL=stepfun-ai/step-3.5-flash
   ```

**Popular Models:**
- `stepfun-ai/step-3.5-flash` - Fast, balanced performance
- `deepseek-ai/deepseek-v3.1` - High quality reasoning
- `meta/llama-3.3-70b-instruct` - Strong reasoning capabilities
- `moonshotai/kimi-k2.5` - Long context (200K+ tokens)

#### OpenRouter (Paid)

Access hundreds of models through OpenRouter:

1. Get API key: [openrouter.ai/keys](https://openrouter.ai/keys)
2. Configure in [`.env`](.env.example):
   ```env
   PROVIDER_TYPE=open_router
   OPENROUTER_API_KEY=sk-or-your-key-here
   MODEL=anthropic/claude-3.5-sonnet
   ```

#### LM Studio (Local)

Run completely offline with local models:

1. Install LM Studio: [lmstudio.ai](https://lmstudio.ai/)
2. Load a model and start the local server
3. Configure in [`.env`](.env.example):
   ```env
   PROVIDER_TYPE=lmstudio
   LM_STUDIO_BASE_URL=http://localhost:1234/v1
   MODEL=local-model
   ```

### Optional Features

#### Discord Bot

Enable remote autonomous coding via Discord:

```env
MESSAGING_PLATFORM=discord
DISCORD_BOT_TOKEN=your-bot-token
ALLOWED_DISCORD_CHANNELS=channel-id-1,channel-id-2
```

#### Telegram Bot

Enable remote autonomous coding via Telegram:

```env
MESSAGING_PLATFORM=telegram
TELEGRAM_BOT_TOKEN=your-bot-token
ALLOWED_TELEGRAM_USER_ID=your-user-id
```

#### Voice Transcription

Enable voice note transcription with Whisper:

```env
VOICE_NOTE_ENABLED=true
WHISPER_MODEL=base
WHISPER_DEVICE=cpu
HF_TOKEN=your-huggingface-token  # Optional
```

Install voice dependencies:
```bash
uv sync --extra voice
```

---

## 🤖 How It Works

```
┌─────────────────┐
│  Claude Code    │  (CLI or VSCode Extension)
│  CLI / VSCode   │
└────────┬────────┘
         │ Anthropic API format
         │ (with ANTHROPIC_BASE_URL override)
         ▼
┌─────────────────────────────────────────┐
│  Free Claude Code Proxy (this project)  │
│  ┌─────────────────────────────────┐   │
│  │  FastAPI Server (port 8082)     │   │
│  │  • Request optimization         │   │
│  │  • Tool call parsing            │   │
│  │  • Thinking token support       │   │
│  │  • Rate limiting                │   │
│  └────────────┬────────────────────┘   │
└───────────────┼─────────────────────────┘
                │ Provider-specific format
                ▼
    ┌───────────┴───────────┐
    │                       │
┌───▼────┐  ┌──────▼─────┐  ┌────▼─────┐
│ NVIDIA │  │ OpenRouter │  │LM Studio │
│  NIM   │  │            │  │ (Local)  │
└────────┘  └────────────┘  └──────────┘
```

The proxy intercepts Claude Code's API calls and:
1. **Optimizes requests** - Skips trivial calls (network probes, title generation, etc.)
2. **Translates format** - Converts Anthropic API format to provider-specific format
3. **Parses responses** - Extracts thinking tokens and tool calls
4. **Manages rate limits** - Implements smart throttling and backoff
5. **Returns results** - Sends back responses in Anthropic format

---

## 🤝 Discord Bot

Run Claude Code remotely through Discord with full autonomous capabilities:

### Features

- **Tree-based Threading** - Conversations organized in threads
- **Session Persistence** - Resume conversations after restarts
- **Live Progress Updates** - Real-time status updates
- **Voice Note Support** - Send voice messages (transcribed with Whisper)
- **Multi-user Support** - Restrict access to specific channels
- **Transcript Export** - Download conversation history

### Setup

1. Create a Discord bot at [discord.com/developers/applications](https://discord.com/developers/applications)
2. Enable these intents: Message Content, Guild Messages
3. Add bot to your server
4. Configure in [`.env`](.env.example):
   ```env
   MESSAGING_PLATFORM=discord
   DISCORD_BOT_TOKEN=your-bot-token
   ALLOWED_DISCORD_CHANNELS=channel-id-1,channel-id-2
   ```
5. Restart the server: `pm2 restart claude-proxy`

### Usage

- **Start conversation**: Mention the bot in any allowed channel
- **Continue**: Reply to bot messages to continue the conversation
- **Voice notes**: Send voice messages (requires voice transcription enabled)
- **Export**: Use `/transcript` command to download conversation history

---

## 📁 Project Structure

```
free-claude-code/
├── api/                      # FastAPI application
│   ├── app.py               # Main application factory
│   ├── routes.py            # API endpoints
│   ├── dependencies.py      # Dependency injection
│   ├── detection.py         # Request type detection
│   ├── optimization_handlers.py  # Request optimizations
│   └── models/              # Pydantic models
├── providers/               # Provider implementations
│   ├── base.py             # Base provider interface
│   ├── nvidia_nim/         # NVIDIA NIM provider
│   ├── open_router/        # OpenRouter provider
│   ├── lmstudio/           # LM Studio provider
│   └── common/             # Shared utilities
├── messaging/              # Messaging platform integrations
│   ├── platforms/          # Discord, Telegram implementations
│   ├── handler.py          # Message handling logic
│   ├── trees/              # Conversation tree management
│   └── rendering/          # Markdown rendering
├── cli/                    # CLI session management
│   ├── manager.py          # Session manager
│   └── process_registry.py # Process tracking
├── config/                 # Configuration
│   ├── settings.py         # Settings management
│   └── logging_config.py   # Logging setup
├── setup/                  # Windows setup wizard
│   ├── Setup-Wizard.ps1    # Main wizard script
│   └── modules/            # PowerShell modules
├── tests/                  # Comprehensive test suite
├── server.py               # Entry point
├── .env.example            # Configuration template
├── ecosystem.config.js     # PM2 configuration
├── pyproject.toml          # Python dependencies
└── README.md               # This file
```

---

## 🧪 Development

### Running Tests

```bash
# Run all tests
uv run pytest

# Run with coverage
uv run pytest --cov=. --cov-report=html

# Run specific test file
uv run pytest tests/api/test_routes.py

# Run with verbose output
uv run pytest -v
```

### Code Quality

```bash
# Format code
uv run ruff format .

# Lint code
uv run ruff check .

# Type checking
uv run ty .
```

### Development Server

```bash
# Run with auto-reload
uv run uvicorn server:app --host 0.0.0.0 --port 8082 --reload

# Run with debug logging
uv run uvicorn server:app --host 0.0.0.0 --port 8082 --log-level debug
```

---

## 🛠️ Troubleshooting

### Common Issues

#### Port 8082 Already in Use

```bash
# Windows
netstat -ano | findstr :8082
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8082 | xargs kill -9
```

#### API Key Invalid

- NVIDIA NIM keys start with `nvapi-`
- OpenRouter keys start with `sk-or-`
- Check for typos and trailing spaces

#### VSCode Extension Not Connecting

1. Verify server is running: `pm2 list`
2. Test connection: `curl http://localhost:8082/health`
3. Check VSCode settings are correct
4. Reload VSCode window

#### Model Not Found

```bash
# List available models
curl http://localhost:8082/v1/models

# Check nvidia_nim_models.json for valid model IDs
```

For more troubleshooting help, see [SETUP_GUIDE.md](SETUP_GUIDE.md).

---

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Comprehensive setup and configuration guide
- **[setup/README.md](setup/README.md)** - Setup wizard internal documentation
- **[.env.example](.env.example)** - Configuration template with all options
- **[LICENSE](LICENSE)** - MIT License details

---

## 🤝 Contributing

Contributions are welcome! This is an open fork designed to be accessible to everyone.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Run tests**: `uv run pytest`
5. **Format code**: `uv run ruff format .`
6. **Commit changes**: `git commit -m 'Add amazing feature'`
7. **Push to branch**: `git push origin feature/amazing-feature`
8. **Open a Pull Request**

### Areas for Contribution

- 🌐 **Mac/Linux Setup Wizard** - Port the Windows wizard to other platforms
- 🔌 **New Providers** - Add support for more AI providers
- 💬 **Messaging Platforms** - Add Slack, WhatsApp, etc.
- 📖 **Documentation** - Improve guides and add tutorials
- 🐛 **Bug Fixes** - Fix issues and improve stability
- ✨ **Features** - Add new capabilities

### Code Style

- Follow PEP 8 for Python code
- Use type hints
- Write tests for new features
- Update documentation

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Ali Khokhar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **Original Project**: [Alishahryar1/free-claude-code](https://github.com/Alishahryar1/free-claude-code) - The foundation this fork builds upon
- **Anthropic**: For creating Claude and the Claude Code CLI
- **NVIDIA**: For providing free NIM API access
- **Community Contributors**: Everyone who has contributed to making this project better

---

## 🔗 Links

- **Original Repository**: [github.com/Alishahryar1/free-claude-code](https://github.com/Alishahryar1/free-claude-code)
- **This Fork**: [github.com/rishiskhare/free-claude-code](https://github.com/rishiskhare/free-claude-code)
- **Claude Code CLI**: [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code)
- **NVIDIA NIM**: [build.nvidia.com](https://build.nvidia.com)
- **OpenRouter**: [openrouter.ai](https://openrouter.ai)
- **LM Studio**: [lmstudio.ai](https://lmstudio.ai)

---

## ⭐ Star History

If you find this project useful, please consider giving it a star! ⭐

---

## 📞 Support

- **Issues**: [github.com/rishiskhare/free-claude-code/issues](https://github.com/rishiskhare/free-claude-code/issues)
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed help

---

<div align="center">

**Made with ❤️ by the community**

**Happy coding with free Claude! 🚀**

</div>
