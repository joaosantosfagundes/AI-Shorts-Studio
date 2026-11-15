$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ambiente-fase1.ps1')

if (-not (Test-Path -LiteralPath $pythonExe -PathType Leaf)) {
    throw 'Execute scripts/instalar-fase1.ps1 primeiro.'
}

$constraints = Join-Path $PSScriptRoot 'requirements-fase1.txt'
& $uvExe pip install --python $pythonExe --only-binary ':all:' -c $constraints 'piper-tts==1.8.0' 'pathvalidate==3.3.1'
if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao instalar o Piper no ambiente do Studio.'
}

$voiceDir = (New-Item -ItemType Directory -Force -Path $env:AI_SHORTS_STORY_VOICES).FullName
$voiceBase = 'https://huggingface.co/rhasspy/piper-voices/resolve/cf910fb59f1d79ab3b625a63993a108751c6c25d/pt/pt_BR/cadu/medium'
$files = @(
    @{ Source = 'pt_BR-cadu-medium.onnx.json'; File = 'pt_BR-cadu-medium.onnx.json'; Sha256 = '9FA837B7C1237EA5978BCD7BE38C130798E8FAA064F754873BB4CE5FC498BD88' },
    @{ Source = 'MODEL_CARD'; File = 'pt_BR-cadu-medium.MODEL_CARD'; Sha256 = 'CCD97B4369F50E6FBA3A4FB730643EF2675F87B43C5D22298404C58F8204A375' },
    @{ Source = 'pt_BR-cadu-medium.onnx'; File = 'pt_BR-cadu-medium.onnx'; Sha256 = 'D5A662E3F606D5A49DD29BA9CE90C304AE45DD9543F8B0C773BCB0DE282499DE' }
)
foreach ($entry in $files) {
    $destination = Join-Path $voiceDir $entry.File
    if (Test-Path -LiteralPath $destination) {
        if ((Get-FileHash -LiteralPath $destination).Hash -ne $entry.Sha256) {
            throw "O arquivo existente $destination pertence a outra versão. Escolha outro diretório em AI_SHORTS_STORY_VOICES."
        }
        continue
    }
    $partial = Join-Path $voiceDir ($entry.File + '.' + [guid]::NewGuid().ToString('N') + '.part')
    try {
        $url = "$voiceBase/$($entry.Source)"
        & curl.exe --fail --silent --show-error --location --retry 2 --max-time 180 --output $partial $url
        if ($LASTEXITCODE -ne 0 -or (Get-FileHash -LiteralPath $partial).Hash -ne $entry.Sha256) {
            throw "Não foi possível verificar $($entry.Source)."
        }
        Move-Item -LiteralPath $partial -Destination $destination
    } finally {
        if (Test-Path -LiteralPath $partial -PathType Leaf) {
            Remove-Item -LiteralPath $partial
        }
    }
}
Write-Host "Voz Cadu (pt-BR) pronta em $voiceDir."
