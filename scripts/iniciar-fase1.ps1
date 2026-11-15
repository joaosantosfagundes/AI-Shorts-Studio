param([switch]$SomenteOllama, [switch]$SemNavegador, [switch]$SemBaixarModelo)

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

    $missingDefault = $availableModels.models.name -notcontains $phaseModel
    if ($missingDefault -and -not $SemBaixarModelo) {
        & $ollamaExe pull $phaseModel
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao baixar o modelo $phaseModel."
        }
    }

    if ($missingDefault -and $SemBaixarModelo) {
        Write-Host "Ollama disponível em $ollamaUrl. Use um modelo já instalado."
    } else {
        Write-Host "Ollama disponível em $ollamaUrl com $phaseModel."
    }
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
            whisper = @{ model = 'base'; device = 'cpu'; language = 'pt'; compute_type = 'int8'; diarization = $false }
            clips = @{ max_clips = 5 }
            export = @{ ratio = '9:16'; resolution = '1080p'; prefer_hardware_encoder = $true }
        } | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText($settingsPath, $settings, [Text.UTF8Encoding]::new($false))
    }

    $serveArgs = @('serve', '--host', '127.0.0.1', '--port', '8000')
    if ((-not $env:AI_SHORTS_META_REDIRECT_URI) -or ($env:AI_SHORTS_META_REDIRECT_URI -in @(
        'https://localhost:8000/api/instagram/oauth/callback',
        'http://localhost:8000/api/instagram/oauth/callback'
    ))) {
        $env:AI_SHORTS_META_REDIRECT_URI = $metaRedirectUri
    }
    $metaTlsBundle = Join-Path $metaTlsDir "$metaLocalHostname-server.pem"
    if (Test-Path -LiteralPath $metaTlsBundle -PathType Leaf) {
        $serveArgs += @('--ssl-certfile', $metaTlsBundle)
        $resolved = @()
        try {
            $resolved = @([Net.Dns]::GetHostAddresses($metaLocalHostname).IPAddressToString)
        } catch {
            # O Clipador pode abrir pelo nome localhost enquanto o alias está pendente.
        }
        if (($resolved -contains '127.0.0.1') -and -not ($resolved | Where-Object { $_ -ne '127.0.0.1' })) {
            $serveArgs += @('--browser-host', $metaLocalHostname)
        } else {
            Write-Warning "$metaLocalHostname precisa apontar para 127.0.0.1. Edite o arquivo hosts conforme docs/instagram-meta.md."
        }
    } else {
        $previousTlsBundle = Join-Path $metaTlsDir 'localhost-server.pem'
        if (Test-Path -LiteralPath $previousTlsBundle -PathType Leaf) {
            $serveArgs += @('--ssl-certfile', $previousTlsBundle)
            Write-Warning 'Para usar o Instagram, prepare o certificado de localhost.localdomain com scripts/preparar-https-instagram.ps1.'
        }
    }
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
