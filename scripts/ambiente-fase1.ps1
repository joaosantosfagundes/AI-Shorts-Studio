$fase1Root = Join-Path (Split-Path -Parent $PSScriptRoot) '.fase1'
$autoclipRoot = Join-Path $fase1Root 'autoclip'
$uvExe = Join-Path $fase1Root 'tools/uv/uv.exe'
$pythonExe = Join-Path $fase1Root 'venv/Scripts/python.exe'
$autoClipExe = Join-Path $fase1Root 'venv/Scripts/autoclip.exe'
$ffmpegDir = Join-Path $fase1Root 'tools/ffmpeg-9.0.2-full_build/bin'
$ollamaExe = Join-Path $fase1Root 'tools/ollama/ollama.exe'
$env:AUTOCLIP_CUDA_RUNTIME_DIR = Join-Path (Split-Path -Parent $ollamaExe) 'lib/ollama/cuda_v12'
$faceModelHome = Join-Path $fase1Root 'cache/mediapipe'
$faceModelFile = Join-Path $faceModelHome 'models/face_landmarker.task'
$phaseModel = 'qwen2.5:7b'
$ollamaUrl = 'http://127.0.0.1:11434'
$metaLocalHostname = 'localhost.localdomain'
$metaRedirectUri = 'https://{0}:8000/api/instagram/oauth/callback' -f $metaLocalHostname
$metaTlsDir = if ($env:AI_SHORTS_META_TLS_DIR) {
    $env:AI_SHORTS_META_TLS_DIR
} else {
    Join-Path $env:LOCALAPPDATA 'AI Shorts Studio/tls'
}

$env:UV_CACHE_DIR = Join-Path $fase1Root 'cache/uv'
$env:UV_PYTHON_INSTALL_DIR = Join-Path $fase1Root 'tools/python'
$env:UV_LINK_MODE = 'copy'
$env:HF_HOME = Join-Path $fase1Root 'cache/huggingface'
$env:HF_HUB_DISABLE_TELEMETRY = '1'
$env:OLLAMA_MODELS = Join-Path $fase1Root 'cache/ollama'
$env:OLLAMA_HOST = '127.0.0.1:11434'
$env:OLLAMA_NO_CLOUD = '1'
if (-not $env:AI_SHORTS_STORY_VOICES) {
    $env:AI_SHORTS_STORY_VOICES = Join-Path $fase1Root 'cache/piper'
}
$env:PYTHONUTF8 = '1'
if (($env:PATH -split ';') -notcontains $ffmpegDir) {
    $env:PATH = "$ffmpegDir;$env:PATH"
}
$env:AUTOCLIP_HOME = if ($env:AI_SHORTS_STUDIO_DATA) {
    $env:AI_SHORTS_STUDIO_DATA
} else {
    Join-Path $env:LOCALAPPDATA 'AI Shorts Studio/autoclip'
}
