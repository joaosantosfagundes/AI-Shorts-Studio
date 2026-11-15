$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ambiente-fase1.ps1')

function Assert-ExitCode([string]$Etapa) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Etapa falhou (código $LASTEXITCODE)."
    }
}

function Get-Archive([string]$Url, [string]$Sha256) {
    $archive = Join-Path $downloads ($Url.Split('/')[-1])
    if ((Test-Path -LiteralPath $archive) -and (Get-FileHash -LiteralPath $archive).Hash -eq $Sha256) {
        return $archive
    }

    Write-Host "Baixando $([IO.Path]::GetFileName($archive))"
    $partial = "$archive.partial"
    & curl.exe --fail --silent --show-error --location --retry 2 --output $partial $Url
    Assert-ExitCode 'Download'
    if ((Get-FileHash -LiteralPath $partial).Hash -ne $Sha256) {
        throw "SHA-256 diferente do esperado para $archive."
    }
    Move-Item -LiteralPath $partial -Destination $archive -Force
    return $archive
}

$activePanel = Get-Process autoclip -ErrorAction SilentlyContinue | Where-Object Path -eq $autoClipExe
if ($activePanel) {
    throw 'Encerre o painel local antes de reinstalar. O Windows bloqueia a substituição do executável em uso.'
}

$node = Get-Command node.exe -ErrorAction SilentlyContinue
if (-not $node -or -not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
    throw 'Instale Node.js 20 ou superior com npm e abra outro terminal.'
}
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    throw 'Instale Git para aplicar a correção de compatibilidade do AutoClip.'
}
if ([version]((& $node.Source --version).TrimStart('v')) -lt [version]'20.0') {
    throw 'O build do painel precisa de Node.js 20 ou superior.'
}

$toolsDir = Join-Path $fase1Root 'tools'
$downloads = Join-Path $fase1Root 'downloads'
New-Item -ItemType Directory -Force -Path $toolsDir, $downloads | Out-Null

if (-not (Test-Path -LiteralPath $uvExe)) {
    $archive = Get-Archive 'https://github.com/astral-sh/uv/releases/download/0.13.8/uv-x86_64-pc-windows-msvc.zip' '529e78a9cec6cd7e3e014f7ecd8bda0c113969d4ed0f2efeedb85c30943325b8'
    Expand-Archive -LiteralPath $archive -DestinationPath (Split-Path -Parent $uvExe) -Force
}

if (-not (Test-Path -LiteralPath (Join-Path $ffmpegDir 'ffprobe.exe'))) {
    $archive = Get-Archive 'https://github.com/GyanD/codexffmpeg/releases/download/9.0.2/ffmpeg-9.0.2-full_build.7z' 'f0e46253c70dfe902bac915dfb4224f0cf1b7c6eeab9da2ccc9a5581f9a71b13'
    & tar.exe -xf $archive -C $toolsDir
    Assert-ExitCode 'Extração do FFmpeg'
}

if (-not (Test-Path -LiteralPath $ollamaExe)) {
    $archive = Get-Archive 'https://github.com/ollama/ollama/releases/download/v0.40.16/ollama-windows-amd64.zip' '50fcf5ad54277f2fa5d173ebfc93bcb017adbc0c9ef2314daabc96ca9e6aa64e'
    $ollamaDir = Split-Path -Parent $ollamaExe
    New-Item -ItemType Directory -Force -Path $ollamaDir | Out-Null
    & tar.exe -xf $archive -C $ollamaDir
    Assert-ExitCode 'Extração do Ollama'
}

if (-not (Test-Path -LiteralPath $autoclipRoot)) {
    $commit = '5d0eac36fa615b79dd2104083bf273a96f8d68bb'
    $archive = Get-Archive "https://codeload.github.com/Gutsken/Autoclip/zip/$commit" '33ccd06330828cbc1f36228b61b662ddec94500c2f18573fdff6cef16d2140ad'
    Expand-Archive -LiteralPath $archive -DestinationPath $downloads -Force
    Move-Item -LiteralPath (Join-Path $downloads "Autoclip-$commit") -Destination $autoclipRoot
}

$previousErrorPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    # Restrinja o git apply à cópia instalada do AutoClip.
    $gitScope = @('-C', $autoclipRoot, "--git-dir=$autoclipRoot/.git-patch", "--work-tree=$autoclipRoot")
    $patchNames = @(
        'autoclip-windows-mediapipe.patch',
        'autoclip-performance.patch',
        'autoclip-studio.patch',
        'autoclip-instagram-unified.patch',
        'autoclip-instagram-localdomain.patch',
        'autoclip-instagram-oauth.patch'
    )
    # Os patches seguintes podem substituir o contexto dos anteriores.
    $nextPatch = 0
    for ($index = $patchNames.Count - 1; $index -ge 0; $index--) {
        $patch = Join-Path $PSScriptRoot $patchNames[$index]
        & git.exe @gitScope apply --reverse --check $patch 2>$null
        if ($LASTEXITCODE -eq 0) {
            $nextPatch = $index + 1
            break
        }
    }
    for ($index = $nextPatch; $index -lt $patchNames.Count; $index++) {
        $patchName = $patchNames[$index]
        $patch = Join-Path $PSScriptRoot $patchName
        & git.exe @gitScope apply --check $patch
        Assert-ExitCode "Verificação de $patchName"
        & git.exe @gitScope apply $patch
        Assert-ExitCode "Aplicação de $patchName"
    }
} finally {
    $ErrorActionPreference = $previousErrorPreference
}

if (-not (Test-Path -LiteralPath $pythonExe)) {
    & $uvExe venv --managed-python --python 3.12.16 (Join-Path $fase1Root 'venv')
    Assert-ExitCode 'Criação do ambiente Python'
}

$requirements = Join-Path $PSScriptRoot 'requirements-fase1.txt'
Push-Location -LiteralPath $autoclipRoot
try {
    & $uvExe pip install --python $pythonExe -c $requirements -e '.[dev]'
    Assert-ExitCode 'Instalação das dependências Python'
    & $uvExe pip check --python $pythonExe
    Assert-ExitCode 'Verificação das dependências Python'
} finally {
    Pop-Location
}

Push-Location -LiteralPath (Join-Path $autoclipRoot 'frontend')
try {
    & npm.cmd ci --cache (Join-Path $fase1Root 'cache/npm') --no-audit --no-fund
    Assert-ExitCode 'Instalação das dependências do painel'
    & npm.cmd run build
    Assert-ExitCode 'Build do painel'
} finally {
    Pop-Location
}

$staticRoot = Join-Path $autoclipRoot 'backend/autoclip/static'
$projectRoot = Split-Path -Parent $PSScriptRoot
Copy-Item -LiteralPath (Join-Path $autoclipRoot 'LICENSE') -Destination (Join-Path $staticRoot 'LICENSE-AutoClip.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'licencas/fontes') -Destination $staticRoot -Recurse -Force

& $pythonExe -c "from faster_whisper.utils import download_model; download_model('base')"
Assert-ExitCode 'Download do Whisper base'

$panelData = $env:AUTOCLIP_HOME
try {
    $env:AUTOCLIP_HOME = $faceModelHome
    & $autoClipExe fetch-models
    Assert-ExitCode 'Download do MediaPipe'
} finally {
    $env:AUTOCLIP_HOME = $panelData
}

& $autoClipExe doctor
Assert-ExitCode 'Diagnóstico do AutoClip'
Write-Host 'Instalação concluída. Execute scripts/iniciar-fase1.ps1 para iniciar o painel e preparar o modelo Ollama.'
