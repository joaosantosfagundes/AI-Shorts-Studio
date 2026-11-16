param([switch]$Kokoro)

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

if ($Kokoro) {
    $kokoroDir = (New-Item -ItemType Directory -Force -Path $env:AI_SHORTS_STORY_KOKORO).FullName
    $export = 'https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/468588286ebb2dd77c25b9771e5d165896538cce'
    $original = 'https://huggingface.co/hexgrad/Kokoro-82M/resolve/4a34baf21f785e7cd08e41a290dffeb1fd0b66b7'
    $assets = @(
        @("$export/onnx/model_quantized.onnx", 'model_quantized.onnx', 'FBAE9257E1E05FFC727E951EF9B9C98418E6D79F1C9B6B13BD59F5C9028A1478'),
        @("$export/voices/pf_dora.bin", 'pf_dora.bin', '3DA7B5B2D91847EBF5646F57631AF6ECECAE3C29A89CD300F06EDF9AA6CFE9EE'),
        @("$export/voices/pm_alex.bin", 'pm_alex.bin', '0175C753F59C54E7FD5A995BEDEF0C5FF2FB67E0043DD3DCB2AE74EC2ACBEB2A'),
        @("$export/voices/pm_santa.bin", 'pm_santa.bin', '8B012DB3185778AFE2E45A62CBAD69DB73021774FE68DDA634BCC748A982EEDE'),
        @("$original/config.json", 'config.json', '5ABB01E2403B072BF03D04FDE160443E209D7A0DAD49A423BE15196B9B43C17F')
    )
    foreach ($asset in $assets) {
        $target = Join-Path $kokoroDir $asset[1]
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if ((Get-FileHash -LiteralPath $target).Hash -ne $asset[2]) {
                throw "O arquivo existente $target tem outra versão. Use outro diretório em AI_SHORTS_STORY_KOKORO."
            }
            continue
        }
        $download = "$target.part"
        & curl.exe --fail --silent --show-error --location --max-time 600 --continue-at - --output $download $asset[0]
        if ($LASTEXITCODE -ne 0) {
            throw "A transferência de $($asset[1]) foi interrompida. Rode este script novamente para retomar."
        }
        if ((Get-FileHash -LiteralPath $download).Hash -ne $asset[2]) {
            throw "SHA-256 incorreto em $download. Mova esse arquivo para outro nome antes de tentar novamente."
        }
        Move-Item -LiteralPath $download -Destination $target
    }
    Write-Host 'Kokoro pt-BR pronto com Dora, Alex e Santa. Pesos sob Apache 2.0.'
    Write-Host 'Ficha do modelo em https://huggingface.co/hexgrad/Kokoro-82M'
}
