param([switch]$SomenteOllama, [switch]$SemNavegador)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ambiente-fase1.ps1')

if (-not (Test-Path -LiteralPath $ollamaExe) -or -not (Test-Path -LiteralPath $autoClipExe)) {
    throw 'Execute scripts/instalar-fase1.ps1 primeiro.'
}

function Get-OllamaModels {
    Invoke-RestMethod -Uri "$ollamaUrl/api/tags" -TimeoutSec 2
}

$ollamaProcess = $null
try {
    try {
        $availableModels = Get-OllamaModels
    } catch {
        $logs = Join-Path $fase1Root 'logs'
        New-Item -ItemType Directory -Force -Path $logs | Out-Null
        $ollamaProcess = Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $logs 'ollama.stdout.log') `
            -RedirectStandardError (Join-Path $logs 'ollama.stderr.log')

        $availableModels = $null
        $deadline = [DateTime]::UtcNow.AddSeconds(30)
        do {
            if ($ollamaProcess.HasExited) {
                break
            }
            try {
                $availableModels = Get-OllamaModels
            } catch {
                Start-Sleep -Milliseconds 500
            }
        } until ($availableModels -or [DateTime]::UtcNow -ge $deadline)
        if (-not $availableModels) {
            throw "O Ollama não respondeu em $ollamaUrl. Consulte $logs/ollama.stderr.log."
        }
    }

    if ($availableModels.models.name -notcontains $phaseModel) {
        & $ollamaExe pull $phaseModel
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao baixar o modelo $phaseModel."
        }
    }

    Write-Host "Ollama disponível em $ollamaUrl com $phaseModel."
    if ($SomenteOllama) {
        if ($ollamaProcess) {
            Write-Host 'Mantenha este terminal aberto enquanto executa o teste. Use Ctrl+C para encerrar.'
            Wait-Process -Id $ollamaProcess.Id
        }
        return
    }

    New-Item -ItemType Directory -Force -Path $env:AUTOCLIP_HOME | Out-Null
    $faceModelDestination = Join-Path $env:AUTOCLIP_HOME 'models/face_landmarker.task'
    if ((Test-Path -LiteralPath $faceModelFile) -and -not (Test-Path -LiteralPath $faceModelDestination)) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $faceModelDestination) | Out-Null
        Copy-Item -LiteralPath $faceModelFile -Destination $faceModelDestination
    }
    $settingsPath = Join-Path $env:AUTOCLIP_HOME 'config.json'
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        $settings = @{
            active_provider = 'ollama'
            providers = @{ ollama = @{ model = $phaseModel; base_url = $ollamaUrl } }
            whisper = @{ model = 'base'; language = 'pt'; compute_type = 'int8'; diarization = $false }
            clips = @{ max_clips = 5 }
            export = @{ ratio = '9:16'; prefer_hardware_encoder = $false }
        } | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText($settingsPath, $settings, [Text.UTF8Encoding]::new($false))
    }

    # O Ollama já foi iniciado com acesso à GPU. O AutoClip usa Whisper na CPU.
    $env:CUDA_VISIBLE_DEVICES = '-1'
    $serveArgs = @('serve', '--host', '127.0.0.1', '--port', '8000')
    if ($SemNavegador) { $serveArgs += '--no-open' }
    & $autoClipExe @serveArgs
    if ($LASTEXITCODE -ne 0) {
        throw "O painel encerrou com código $LASTEXITCODE."
    }
} finally {
    if ($ollamaProcess -and -not $ollamaProcess.HasExited) {
        Stop-Process -Id $ollamaProcess.Id -ErrorAction SilentlyContinue
    }
}
