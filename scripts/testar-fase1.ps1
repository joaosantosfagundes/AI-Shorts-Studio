$ErrorActionPreference = 'Stop'

# A projeção WinRT do Windows PowerShell dá acesso às vozes pt-BR do sistema.
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

. (Join-Path $PSScriptRoot 'ambiente-fase1.ps1')

$ffmpeg = (Get-Command ffmpeg -CommandType Application | Select-Object -First 1).Source
$ffprobe = (Get-Command ffprobe -CommandType Application | Select-Object -First 1).Source
if (-not (Test-Path -LiteralPath $autoClipExe -PathType Leaf)) {
    throw 'Instale o AutoClip da Fase 1 antes de rodar o teste.'
}

$ollamaUrl = 'http://127.0.0.1:11434'
$installedModels = Invoke-RestMethod -Uri "$ollamaUrl/api/tags" -TimeoutSec 10
if ($phaseModel -notin @($installedModels.models | ForEach-Object { $_.name })) {
    throw "O modelo local $phaseModel ainda precisa ser baixado no Ollama."
}

$testId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$testDir = Join-Path (Join-Path $fase1Root 'teste') $testId
$testHome = Join-Path $testDir 'dados'
New-Item -ItemType Directory -Path $testHome -Force | Out-Null
Write-Host "Resultados deste teste em $testDir"
if (Test-Path -LiteralPath $faceModelFile) {
    $testModels = Join-Path $testHome 'models'
    New-Item -ItemType Directory -Path $testModels -Force | Out-Null
    Copy-Item -LiteralPath $faceModelFile -Destination $testModels
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$wavPath = Join-Path $testDir 'narracao.wav'
$videoPath = Join-Path $testDir 'gravacao-sintetica.mp4'
$narrationPt = @'
A ponte já estava desabando quando percebi que o último carrinho ainda tinha um passageiro. Eu tinha três segundos para puxar a alavanca, mas a alavanca estava do outro lado do mapa. Minha única opção era lançar o gancho por cima do rio. Errei a primeira tentativa e o chão cedeu. Aí o gancho acertou a roda do próprio carrinho. Ele virou no ar, caiu na plataforma e o passageiro saiu ileso. Eu jamais tinha visto uma jogada dessas.

No segundo desafio, todo mundo avisou para não abrir a porta vermelha. Eu fiz o contrário porque ouvi um barulho de gato atrás dela. A sala estava escura, o relógio começou a tocar e a lanterna apagou. Pensei que tinha perdido o jogo, até descobrir que o gato era a chave para sair do labirinto. Ele andou direto até uma saída escondida e eu consegui escapar com um segundo sobrando. Na próxima rodada vou prestar mais atenção nos sons do mapa.
'@

function Write-PortugueseSpeech {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $synthType = [Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media.SpeechSynthesis, ContentType = WindowsRuntime]
    $streamType = [Windows.Media.SpeechSynthesis.SpeechSynthesisStream, Windows.Media.SpeechSynthesis, ContentType = WindowsRuntime]
    $voice = $synthType::AllVoices | Where-Object Language -eq 'pt-BR' | Select-Object -First 1
    if (-not $voice) { throw 'Nenhuma voz pt-BR disponível no Windows.' }

    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    } | Select-Object -First 1

    $synthesizer = New-Object $synthType.FullName
    try {
        $synthesizer.Voice = $voice
        $operation = $synthesizer.SynthesizeTextToStreamAsync($narrationPt)
        $task = $asTask.MakeGenericMethod($streamType).Invoke($null, @($operation))
        $speech = $task.GetAwaiter().GetResult()
        try {
            $readStream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($speech.GetInputStreamAt(0))
            $writeStream = [System.IO.File]::Create($wavPath)
            try { $readStream.CopyTo($writeStream) }
            finally {
                $writeStream.Dispose()
                $readStream.Dispose()
            }
        }
        finally { $speech.Dispose() }
    }
    finally { $synthesizer.Dispose() }
    return $voice.DisplayName
}

function Write-EnglishSpeech {
    $narrationEn = @'
The bridge was already falling apart when I noticed a passenger still sitting in the last mine cart. I had three seconds to pull the lever, but the lever was on the other side of the map. My only option was to fire a grappling hook over the river. I missed my first shot and the ground gave way. Then the hook caught the wheel of the cart itself. It flipped in the air, landed on the platform, and the passenger walked away without a scratch. I had never seen that trick work before.

In the second challenge, everyone warned me against opening the red door. I did it anyway because I heard a cat on the other side. The room was dark, the clock started ringing, and my flashlight went out. I thought I had lost the game until I realized that the cat knew the way out of the maze. It walked straight to a hidden exit and I escaped with one second left on the clock. Next round I am going to pay much closer attention to the sounds of the map.
'@
    Add-Type -AssemblyName System.Speech
    $speaker = New-Object System.Speech.Synthesis.SpeechSynthesizer
    try {
        $englishVoice = $speaker.GetInstalledVoices() | Where-Object {
            $_.Enabled -and $_.VoiceInfo.Culture.TwoLetterISOLanguageName -eq 'en'
        } | Select-Object -First 1
        if (-not $englishVoice) { throw 'Nenhuma voz de teste em inglês disponível no Windows.' }
        $speaker.SelectVoice($englishVoice.VoiceInfo.Name)
        $speaker.SetOutputToWaveFile($wavPath)
        $speaker.Speak($narrationEn)
    }
    finally { $speaker.Dispose() }
    return $englishVoice.VoiceInfo.Name
}

function Invoke-LoggedNative {
    param([string] $Executable, [string[]] $ArgumentList, [string] $LogPath)
    # O Windows PowerShell trata stderr de processos nativos como ErrorRecord.
    $ErrorActionPreference = 'Continue'
    & $Executable @ArgumentList 2>&1 | ForEach-Object { $_.ToString() } | Tee-Object -FilePath $LogPath | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Falha de $Executable (código $LASTEXITCODE). Veja $LogPath" }
}

function Read-VideoProbe([string] $Path, [string] $ProbePath) {
    $probeJson = & $ffprobe -v error -show_streams -show_format -of json $Path
    if ($LASTEXITCODE -ne 0) { throw "O FFprobe não conseguiu ler $Path" }
    $json = $probeJson -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($ProbePath, $json, $utf8)
    return ($json | ConvertFrom-Json)
}

$language = 'pt'
try { $voiceName = Write-PortugueseSpeech }
catch {
    Write-Warning "A voz pt-BR falhou ($($_.Exception.Message)). Tentando a narração em inglês."
    $language = 'en'
    $voiceName = Write-EnglishSpeech
}
Write-Host "Narração sintética em $language com $voiceName"

Invoke-LoggedNative -Executable $ffmpeg -LogPath (Join-Path $testDir 'geracao.log') -ArgumentList @(
    '-hide_banner', '-loglevel', 'error', '-nostdin', '-f', 'lavfi', '-i',
    'testsrc2=size=640x360:rate=24', '-i', $wavPath, '-af', 'apad=pad_dur=2',
    '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
    '-shortest', '-movflags', '+faststart', $videoPath
)
$sourceProbe = Read-VideoProbe $videoPath (Join-Path $testDir 'entrada.ffprobe.json')
if ([double]::Parse($sourceProbe.format.duration, [cultureinfo]::InvariantCulture) -lt 40) {
    throw 'A gravação sintética precisa ter pelo menos 40 segundos.'
}

$testConfig = @{
    active_provider = 'ollama'
    providers = @{ ollama = @{ model = $phaseModel; base_url = $ollamaUrl } }
    whisper = @{ model = 'base'; compute_type = 'int8'; language = $language; diarization = $false }
    clips = @{ max_clips = 1; min_duration_s = 12; max_duration_s = 40 }
    export = @{ ratio = '9:16'; caption_style = 'clean_lower'; prefer_hardware_encoder = $false; write_srt = $true }
}
[System.IO.File]::WriteAllText((Join-Path $testHome 'config.json'), ($testConfig | ConvertTo-Json -Depth 8), $utf8)

$previousAutoClipHome = $env:AUTOCLIP_HOME
$previousCudaVisibleDevices = $env:CUDA_VISIBLE_DEVICES
$previousHuggingFaceOffline = $env:HF_HUB_OFFLINE
try {
    $env:AUTOCLIP_HOME = $testHome
    $env:CUDA_VISIBLE_DEVICES = '-1'
    $env:HF_HUB_OFFLINE = '1'
    Invoke-LoggedNative -Executable $autoClipExe -LogPath (Join-Path $testDir 'pipeline.log') -ArgumentList @('clip', $videoPath)
    Invoke-LoggedNative -Executable $autoClipExe -LogPath (Join-Path $testDir 'tarefas.log') -ArgumentList @('jobs')
}
finally {
    $env:AUTOCLIP_HOME = $previousAutoClipHome
    $env:CUDA_VISIBLE_DEVICES = $previousCudaVisibleDevices
    $env:HF_HUB_OFFLINE = $previousHuggingFaceOffline
}

$transcriptFiles = @(Get-ChildItem -LiteralPath (Join-Path $testHome 'work') -Recurse -File -Filter 'transcript.json')
if ($transcriptFiles.Count -ne 1) { throw 'Era esperado um arquivo de transcrição do Faster-Whisper.' }
$transcript = Get-Content -LiteralPath $transcriptFiles[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $transcript.words -or $transcript.language -ne $language) {
    throw "Transcrição vazia ou em idioma diferente do configurado ($language)."
}

$clips = @(Get-ChildItem -LiteralPath (Join-Path $testHome 'exports') -Recurse -File -Filter '*.mp4')
if ($clips.Count -ne 1) { throw "O teste esperava um MP4. Foram encontrados $($clips.Count)." }
$clip = $clips[0]
$result = Read-VideoProbe $clip.FullName (Join-Path $testDir 'saida.ffprobe.json')
$video = @($result.streams | Where-Object codec_type -eq 'video')
$audio = @($result.streams | Where-Object codec_type -eq 'audio')
if ($video.Count -ne 1 -or $video[0].codec_name -ne 'h264' -or
    $video[0].width -ne 1080 -or $video[0].height -ne 1920 -or
    $audio.Count -ne 1 -or $audio[0].codec_name -ne 'aac' -or
    'mp4' -notin ($result.format.format_name -split ',')) {
    throw 'A saída deveria ser um MP4 de 1080 × 1920 com vídeo H.264 e áudio AAC.'
}

$srtPath = [System.IO.Path]::ChangeExtension($clip.FullName, 'srt')
$assFiles = @(Get-ChildItem -LiteralPath (Join-Path $testHome 'work') -Recurse -File -Filter 'captions.ass')
if (-not (Test-Path -LiteralPath $srtPath -PathType Leaf) -or
    -not (Select-String -LiteralPath $srtPath -SimpleMatch '-->' -Quiet) -or
    $assFiles.Count -ne 1 -or
    -not (Select-String -LiteralPath $assFiles[0].FullName -Pattern '^Dialogue:' -Quiet)) {
    throw 'A exportação não produziu arquivos de legendas com eventos temporizados.'
}

$summary = [ordered]@{
    modelo_ollama = $phaseModel
    voz_windows = $voiceName
    idioma = $language
    palavras_transcritas = $transcript.words.Count
    entrada = $videoPath
    entrada_segundos = $sourceProbe.format.duration
    saida = $clip.FullName
    saida_segundos = $result.format.duration
    video = 'h264 1080x1920'
    audio = 'aac'
    legenda = $srtPath
}
$summaryJson = $summary | ConvertTo-Json
[System.IO.File]::WriteAllText((Join-Path $testDir 'resultado.json'), $summaryJson, $utf8)
$summaryJson | Write-Output
