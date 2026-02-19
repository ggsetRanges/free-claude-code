#requires -Version 5.1

<#
.SYNOPSIS
    Interactive configuration wizard
.DESCRIPTION
    Guides user through configuration and generates .env file
#>

function Get-UserConfiguration {
    <#
    .SYNOPSIS
        Run interactive configuration wizard
    .PARAMETER ProjectRoot
        Root directory of the project
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $config = @{}

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Configuration Wizard" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Provider Selection
    $provider = Show-ProviderSelection
    $config['PROVIDER_TYPE'] = $provider

    # Step 2: Provider-specific configuration
    switch ($provider) {
        'nvidia_nim' {
            $config += Get-NVIDIAConfig -ProjectRoot $ProjectRoot
        }
        'open_router' {
            $config += Get-OpenRouterConfig
        }
        'lmstudio' {
            $config += Get-LMStudioConfig
        }
    }

    # Step 3: Optional features
    Write-Host ""
    Write-Host "Optional Features" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    # Discord/Telegram bot
    if (Read-Confirmation "Enable Discord bot?" -DefaultYes:$false) {
        $config += Get-DiscordConfig
    }

    if (Read-Confirmation "Enable Telegram bot?" -DefaultYes:$false) {
        $config += Get-TelegramConfig
    }

    # Voice transcription
    if (Read-Confirmation "Enable voice note transcription?" -DefaultYes:$false) {
        $config['VOICE_NOTE_ENABLED'] = 'true'
        $config['WHISPER_MODEL'] = 'base'
        $config['WHISPER_DEVICE'] = 'cpu'
        
        $hfToken = Read-Host "Hugging Face token (optional, press Enter to skip)"
        if (-not [string]::IsNullOrWhiteSpace($hfToken)) {
            $config['HF_TOKEN'] = $hfToken
        }
    } else {
        $config['VOICE_NOTE_ENABLED'] = 'false'
    }

    # Step 4: Advanced settings (with defaults)
    Write-Host ""
    if (Read-Confirmation "Configure advanced settings?" -DefaultYes:$false) {
        $config += Get-AdvancedConfig
    } else {
        # Use defaults
        $config['PROVIDER_RATE_LIMIT'] = '40'
        $config['PROVIDER_RATE_WINDOW'] = '60'
        $config['HTTP_READ_TIMEOUT'] = '300'
        $config['HTTP_WRITE_TIMEOUT'] = '10'
        $config['HTTP_CONNECT_TIMEOUT'] = '2'
        $config['CLAUDE_WORKSPACE'] = './agent_workspace'
        $config['MAX_CLI_SESSIONS'] = '10'
        $config['FAST_PREFIX_DETECTION'] = 'true'
        $config['ENABLE_NETWORK_PROBE_MOCK'] = 'true'
        $config['ENABLE_TITLE_GENERATION_SKIP'] = 'true'
        $config['ENABLE_SUGGESTION_MODE_SKIP'] = 'true'
        $config['ENABLE_FILEPATH_EXTRACTION_MOCK'] = 'true'
    }

    # Step 5: Review configuration
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Configuration Summary" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    foreach ($key in ($config.Keys | Sort-Object)) {
        $value = $config[$key]
        # Mask sensitive values
        if ($key -match 'KEY|TOKEN|PASSWORD') {
            $maskedValue = if ($value.Length -gt 8) { 
                $value.Substring(0, 4) + ('*' * ($value.Length - 8)) + $value.Substring($value.Length - 4)
            } else {
                '****'
            }
            Write-Host "  $key = $maskedValue" -ForegroundColor Gray
        } else {
            Write-Host "  $key = $value" -ForegroundColor Gray
        }
    }

    Write-Host ""

    if (-not (Read-Confirmation "Save this configuration?" -DefaultYes:$true)) {
        Write-Host "Configuration cancelled." -ForegroundColor Yellow
        return $null
    }

    return $config
}

function Show-ProviderSelection {
    <#
    .SYNOPSIS
        Display provider selection menu
    #>
    [CmdletBinding()]
    param()

    Write-Host "Select AI Provider:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) NVIDIA NIM (Free, 40 req/min)" -ForegroundColor Gray
    Write-Host "  2) OpenRouter (Many models, paid)" -ForegroundColor Gray
    Write-Host "  3) LM Studio (Local, no API key)" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "Choice [1-3]"
        
        switch ($choice) {
            '1' { return 'nvidia_nim' }
            '2' { return 'open_router' }
            '3' { return 'lmstudio' }
            default {
                Write-Host "Please enter 1, 2, or 3" -ForegroundColor Yellow
            }
        }
    } while ($true)
}

function Get-NVIDIAConfig {
    <#
    .SYNOPSIS
        Get NVIDIA NIM configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $config = @{}

    Write-Host ""
    Write-Host "NVIDIA NIM Configuration" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Get your free API key at: https://build.nvidia.com/settings/api-keys" -ForegroundColor Yellow
    Write-Host ""

    do {
        $apiKey = Read-Host "NVIDIA NIM API Key"
        
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Host "API key is required for NVIDIA NIM" -ForegroundColor Red
            continue
        }
        
        if ($apiKey -notmatch '^nvapi-') {
            Write-Host "Warning: NVIDIA API keys usually start with 'nvapi-'" -ForegroundColor Yellow
            if (-not (Read-Confirmation "Continue anyway?" -DefaultYes:$false)) {
                continue
            }
        }
        
        break
    } while ($true)

    $config['NVIDIA_NIM_API_KEY'] = $apiKey

    # Model selection
    Write-Host ""
    Write-Host "Select a model:" -ForegroundColor Cyan
    Write-Host ""

    $modelsFile = Join-Path $ProjectRoot "nvidia_nim_models.json"
    if (Test-Path $modelsFile) {
        $models = Get-Content $modelsFile | ConvertFrom-Json
        $modelList = $models.data | Select-Object -ExpandProperty id

        # Show popular models
        $popularModels = @(
            'stepfun-ai/step-3.5-flash',
            'deepseek-ai/deepseek-v3.1',
            'meta/llama-3.3-70b-instruct',
            'mistralai/mistral-large-3-675b-instruct-2512',
            'moonshotai/kimi-k2.5'
        )

        Write-Host "Popular models:" -ForegroundColor Gray
        for ($i = 0; $i -lt $popularModels.Count; $i++) {
            Write-Host "  $($i + 1)) $($popularModels[$i])" -ForegroundColor Gray
        }
        Write-Host "  6) Enter custom model ID" -ForegroundColor Gray
        Write-Host "  7) View all $($modelList.Count) available models" -ForegroundColor Gray
        Write-Host ""

        do {
            $choice = Read-Host "Choice [1-7]"
            
            if ($choice -match '^\d+$') {
                $choiceNum = [int]$choice
                if ($choiceNum -ge 1 -and $choiceNum -le 5) {
                    $config['MODEL'] = $popularModels[$choiceNum - 1]
                    break
                } elseif ($choiceNum -eq 6) {
                    $customModel = Read-Host "Enter model ID"
                    if ($modelList -contains $customModel) {
                        $config['MODEL'] = $customModel
                        break
                    } else {
                        Write-Host "Warning: Model not in list. Using anyway." -ForegroundColor Yellow
                        $config['MODEL'] = $customModel
                        break
                    }
                } elseif ($choiceNum -eq 7) {
                    Write-Host ""
                    Write-Host "All available models:" -ForegroundColor Cyan
                    $modelList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                    Write-Host ""
                    continue
                }
            }
            
            Write-Host "Please enter a number between 1 and 7" -ForegroundColor Yellow
        } while ($true)
    } else {
        $config['MODEL'] = Read-Host "Model ID [stepfun-ai/step-3.5-flash]"
        if ([string]::IsNullOrWhiteSpace($config['MODEL'])) {
            $config['MODEL'] = 'stepfun-ai/step-3.5-flash'
        }
    }

    return $config
}

function Get-OpenRouterConfig {
    <#
    .SYNOPSIS
        Get OpenRouter configuration
    #>
    [CmdletBinding()]
    param()

    $config = @{}

    Write-Host ""
    Write-Host "OpenRouter Configuration" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Get your API key at: https://openrouter.ai/keys" -ForegroundColor Yellow
    Write-Host ""

    $apiKey = Read-Host "OpenRouter API Key"
    $config['OPENROUTER_API_KEY'] = $apiKey

    $model = Read-Host "Model ID [anthropic/claude-3.5-sonnet]"
    if ([string]::IsNullOrWhiteSpace($model)) {
        $model = 'anthropic/claude-3.5-sonnet'
    }
    $config['MODEL'] = $model

    return $config
}

function Get-LMStudioConfig {
    <#
    .SYNOPSIS
        Get LM Studio configuration
    #>
    [CmdletBinding()]
    param()

    $config = @{}

    Write-Host ""
    Write-Host "LM Studio Configuration" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Make sure LM Studio is running with a model loaded." -ForegroundColor Yellow
    Write-Host ""

    $baseUrl = Read-Host "LM Studio Base URL [http://localhost:1234/v1]"
    if ([string]::IsNullOrWhiteSpace($baseUrl)) {
        $baseUrl = 'http://localhost:1234/v1'
    }
    $config['LM_STUDIO_BASE_URL'] = $baseUrl

    $model = Read-Host "Model name [local-model]"
    if ([string]::IsNullOrWhiteSpace($model)) {
        $model = 'local-model'
    }
    $config['MODEL'] = $model

    return $config
}

function Get-DiscordConfig {
    <#
    .SYNOPSIS
        Get Discord bot configuration
    #>
    [CmdletBinding()]
    param()

    $config = @{}

    Write-Host ""
    Write-Host "Discord Bot Configuration" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $config['MESSAGING_PLATFORM'] = 'discord'
    $config['DISCORD_BOT_TOKEN'] = Read-Host "Discord Bot Token"
    $config['ALLOWED_DISCORD_CHANNELS'] = Read-Host "Allowed Channel IDs (comma-separated)"

    return $config
}

function Get-TelegramConfig {
    <#
    .SYNOPSIS
        Get Telegram bot configuration
    #>
    [CmdletBinding()]
    param()

    $config = @{}

    Write-Host ""
    Write-Host "Telegram Bot Configuration" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $config['MESSAGING_PLATFORM'] = 'telegram'
    $config['TELEGRAM_BOT_TOKEN'] = Read-Host "Telegram Bot Token"
    $config['ALLOWED_TELEGRAM_USER_ID'] = Read-Host "Allowed User ID"

    return $config
}

function Get-AdvancedConfig {
    <#
    .SYNOPSIS
        Get advanced configuration settings
    #>
    [CmdletBinding()]
    param()

    $config = @{}

    Write-Host ""
    Write-Host "Advanced Settings" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $rateLimit = Read-Host "Provider rate limit (requests/window) [40]"
    $config['PROVIDER_RATE_LIMIT'] = if ([string]::IsNullOrWhiteSpace($rateLimit)) { '40' } else { $rateLimit }

    $rateWindow = Read-Host "Rate limit window (seconds) [60]"
    $config['PROVIDER_RATE_WINDOW'] = if ([string]::IsNullOrWhiteSpace($rateWindow)) { '60' } else { $rateWindow }

    $readTimeout = Read-Host "HTTP read timeout (seconds) [300]"
    $config['HTTP_READ_TIMEOUT'] = if ([string]::IsNullOrWhiteSpace($readTimeout)) { '300' } else { $readTimeout }

    $workspace = Read-Host "Claude workspace directory [./agent_workspace]"
    $config['CLAUDE_WORKSPACE'] = if ([string]::IsNullOrWhiteSpace($workspace)) { './agent_workspace' } else { $workspace }

    # Use defaults for other settings
    $config['HTTP_WRITE_TIMEOUT'] = '10'
    $config['HTTP_CONNECT_TIMEOUT'] = '2'
    $config['MAX_CLI_SESSIONS'] = '10'
    $config['FAST_PREFIX_DETECTION'] = 'true'
    $config['ENABLE_NETWORK_PROBE_MOCK'] = 'true'
    $config['ENABLE_TITLE_GENERATION_SKIP'] = 'true'
    $config['ENABLE_SUGGESTION_MODE_SKIP'] = 'true'
    $config['ENABLE_FILEPATH_EXTRACTION_MOCK'] = 'true'

    return $config
}

function New-EnvironmentFile {
    <#
    .SYNOPSIS
        Generate .env file from configuration
    .PARAMETER Config
        Configuration hashtable
    .PARAMETER OutputPath
        Path to write the .env file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        $lines = @()
        $lines += "# Free Claude Code Configuration"
        $lines += "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $lines += ""

        # Group settings
        $groups = @{
            'Provider' = @('PROVIDER_TYPE', 'PROVIDER_RATE_LIMIT', 'PROVIDER_RATE_WINDOW', 'MODEL')
            'HTTP' = @('HTTP_READ_TIMEOUT', 'HTTP_WRITE_TIMEOUT', 'HTTP_CONNECT_TIMEOUT')
            'NVIDIA' = @('NVIDIA_NIM_API_KEY')
            'OpenRouter' = @('OPENROUTER_API_KEY')
            'LMStudio' = @('LM_STUDIO_BASE_URL')
            'Messaging' = @('MESSAGING_PLATFORM', 'MESSAGING_RATE_LIMIT', 'MESSAGING_RATE_WINDOW')
            'Discord' = @('DISCORD_BOT_TOKEN', 'ALLOWED_DISCORD_CHANNELS')
            'Telegram' = @('TELEGRAM_BOT_TOKEN', 'ALLOWED_TELEGRAM_USER_ID')
            'Voice' = @('VOICE_NOTE_ENABLED', 'WHISPER_MODEL', 'WHISPER_DEVICE', 'HF_TOKEN')
            'Agent' = @('CLAUDE_WORKSPACE', 'MAX_CLI_SESSIONS', 'ALLOWED_DIR', 'FAST_PREFIX_DETECTION', 
                        'ENABLE_NETWORK_PROBE_MOCK', 'ENABLE_TITLE_GENERATION_SKIP', 
                        'ENABLE_SUGGESTION_MODE_SKIP', 'ENABLE_FILEPATH_EXTRACTION_MOCK')
        }

        foreach ($groupName in $groups.Keys) {
            $groupKeys = $groups[$groupName]
            $hasValues = $false
            
            foreach ($key in $groupKeys) {
                if ($Config.ContainsKey($key)) {
                    $hasValues = $true
                    break
                }
            }
            
            if ($hasValues) {
                $lines += ""
                $lines += "# $groupName Configuration"
                
                foreach ($key in $groupKeys) {
                    if ($Config.ContainsKey($key)) {
                        $value = $Config[$key]
                        $lines += "$key=`"$value`""
                    }
                }
            }
        }

        $content = $lines -join "`n"
        Set-Content -Path $OutputPath -Value $content -Encoding UTF8 -NoNewline
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Environment file created at: $OutputPath" -Level INFO
        }
        
        return $true
    } catch {
        throw "Failed to create environment file: $_"
    }
}

# Import UI functions if available
if (Get-Command Read-Confirmation -ErrorAction SilentlyContinue) {
    # Already imported
} else {
    function Read-Confirmation {
        param([string]$Prompt, [switch]$DefaultYes)
        $default = if ($DefaultYes) { 'Y' } else { 'n' }
        $response = Read-Host "$Prompt [$default]"
        if ([string]::IsNullOrWhiteSpace($response)) { return $DefaultYes.IsPresent }
        return $response -match '^[Yy]'
    }
}

Export-ModuleMember -Function Get-UserConfiguration, New-EnvironmentFile, Show-ProviderSelection
