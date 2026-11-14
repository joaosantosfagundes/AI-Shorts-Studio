# AI Shorts Studio · Clipador IA

## Fase 1 do AI Shorts Studio 2.0

Na gravação investigada, de 2 h 01 min, o SQLite registrou a tarefa como interrompida na transcrição a 5%. O WAV completo já existia. A implementação anterior atingia 5% ao terminar a extração, ainda com a etapa **Prepare** no painel, e decodificava o vídeo para gerar miniaturas sem atualizar a barra. O player usa o vídeo original. A nova preparação extrai o áudio, analisa as pausas e mede o avanço do FFmpeg pela posição na mídia. [Documentação do FFmpeg](https://ffmpeg.org/ffmpeg.html)

- **Progresso e retomada.** A tela mostra o percentual por etapa e a operação atual. A transcrição usa blocos de 120 s com 2 s de sobreposição por lado e salva os blocos completos. A nova tentativa reaproveita WAVs válidos, transcrições concluídas, blocos e outros resultados da mesma tarefa. O worker respeita as configurações gravadas para cada tarefa.
- **Diagnóstico.** Abra **Ver log da tarefa** na tela de progresso. Os registros também ficam em `work/<id>/pipeline.log` dentro da pasta de dados. O FFmpeg tem um limite de 120 s sem avanço e o subprocesso do Whisper tem um limite de 300 s sem atualização. O botão **Tentar novamente** retoma a partir dos arquivos disponíveis. Os limites se aplicam a esses subprocessos. A diarização opcional e a análise de cena usam os mecanismos próprios das bibliotecas.
- **Modo rápido.** Em **Resolução do corte**, escolha **Rápido · 720p** antes de iniciar. A saída 9:16 passa a 720 × 1280, com presets mais rápidos. O padrão continua em 1080p. A exportação manual pode usar o mesmo perfil da tarefa. Pela CLI, use `autoclip clip <arquivo> --fast`.
- **Aceleração.** Com o driver 621.14, o FFmpeg codificou em NVENC a 720 × 1280 e a 1080 × 1920. Se optar pela GPU e o encoder falhar, o render tenta `libx264`. Nas configurações do Whisper, **Automático** tenta CUDA com as bibliotecas CUDA 12 do Ollama portátil já instalado. Se faltarem bibliotecas ou o modelo não couber na GPU, a transcrição continua em CPU. A opção **CPU** é o padrão para as configurações existentes. O processo do Whisper termina antes da seleção e o AutoClip solicita ao Ollama a liberação do modelo após usar o serviço. [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper) · [Ollama](https://docs.ollama.com/faq#how-do-i-keep-a-model-loaded-in-memory-or-make-it-unload-immediately)

### Verificação da atualização no Windows 11

- Em uma cópia do banco e dos intermediários, a gravação de 2 h 01 min reaproveitou o WAV e concluiu a preparação em 1,7 s. O processamento passou de 5%, chegou a 11,64% e respondeu ao cancelamento em menos de um segundo. A nova tentativa retomou no bloco 12 de 61. Os primeiros 11 blocos já estavam no disco. O teste dessa cópia cobriu preparação, transcrição e retomada. O tempo integral de seleção e edição para esse vídeo ainda precisa ser medido.
- O teste com voz sintética em português processou 64,54 s e exportou 31,10 s usando NVENC no perfil rápido. O `ffprobe` confirmou 720 × 1280, H.264 e AAC. O teste também validou os arquivos ASS e SRT. A inferência CUDA do Whisper `base` transcreveu um recorte sintético de 12 s com as bibliotecas locais.
- Pela API do painel, o mesmo vídeo gerou um corte de 720 × 1280 com as opções da tarefa. O teste confirmou os eventos de progresso e de conclusão, a leitura do log e o download do MP4.
- A suíte passou em 300 testes, incluindo a migração de um banco antigo, o cancelamento de processos silenciosos e a exportação por `libx264` após uma falha simulada no NVENC. Foram excluídos 24 casos `golden` ou `e2e` do AutoClip que dependem de mídia própria. Para rodar a mesma seleção, aplique a atualização, carregue o ambiente e use o comando abaixo.

```powershell
. .\scripts\ambiente-fase1.ps1
Push-Location $autoclipRoot
try { & $pythonExe -m pytest -q -m 'not golden and not e2e' } finally { Pop-Location }
```

## Integração com o AutoClip

O teste no Windows 11 x64 usa o AutoClip `0.1.0.dev0`, commit `5d0eac36fa615b79dd2104083bf273a96f8d68bb` do fork Gutsken/Autoclip. O painel existente usa React, TypeScript e Vite. O FastAPI serve o painel compilado, a API e o progresso das tarefas no mesmo endereço. A fila processa um vídeo por vez, grava o histórico em SQLite e guarda arquivos intermediários para reaproveitar etapas concluídas em uma tentativa anterior. Essa arquitetura atende à instalação local da Fase 1 com um único servidor de aplicação. [Revisão do AutoClip](https://github.com/Gutsken/Autoclip/commit/5d0eac36fa615b79dd2104083bf273a96f8d68bb) · [Arquitetura](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/docs/ARCHITECTURE.md)

### O que o código já oferece

- Importação de arquivo local, histórico, progresso por eventos, cancelamento e nova tentativa. O painel expõe quantidade máxima, duração e resolução por tarefa. O painel de revisão permite reproduzir, ajustar início e fim, editar legendas e marcar cortes como aprovados ou rejeitados. [Patch de desempenho](scripts/autoclip-performance.patch)
- Faster-Whisper gera tempos por palavra, inclusive para fala em português. A seleção usa a transcrição em janelas sobrepostas. O LLM retorna índices de palavras, nota e justificativa textual. O código ajusta os limites, elimina sobreposições e ordena os candidatos pela nota até o máximo pedido. Pode encontrar menos cortes do que o máximo configurado. [Transcrição](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/transcribe.py) · [Seleção](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/highlights.py)
- PySceneDetect e MediaPipe ajudam a reenquadrar por cena e por rosto após a seleção. O FFmpeg gera MP4 em H.264/AAC com legendas ASS incorporadas. A prévia no editor busca o vídeo original. [Reenquadramento](https://github.com/Gutsken/Autoclip/tree/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/reframe)

### Lacunas e riscos para o Clipador IA

- A nota e a justificativa atuais são estimativas do LLM com base na fala. A seleção para gameplay precisa combinar sinais de áudio e visuais, detectar reações, explicitar a contribuição de cada sinal e evitar trechos semelhantes mesmo quando aparecem em intervalos distintos. A detecção visual existente é usada no reenquadramento. [Seleção](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/highlights.py) · [Pipeline](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/runner.py)
- Gameplay ainda precisa de critérios de enquadramento que preservem o HUD, avaliação com clipes reais e transições discretas. A localização completa da interface, a confirmação de autorização para material de terceiros e a exportação final condicionada à aprovação pertencem às próximas fases.
- O WAV intermediário de três horas ocupa cerca de 346 MB em disco. Cada bloco de 120 s, incluindo a sobreposição, carrega menos de 8 MB de amostras em `float32`, além da memória usada pelo modelo e suas características. A diarização opcional continua usando o WAV inteiro.
- O AutoClip está em desenvolvimento e a automação do projeto de origem cobre renderização em Windows com Python 3.12. O teste de integração original usa respostas roteirizadas no lugar do LLM e requer vídeo com rosto detectável. A qualidade da seleção e do reenquadramento em gameplay depende de avaliação com gravações representativas. [CI do projeto de origem](https://github.com/artbyjazi/autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/.github/workflows/ci.yml) · [Teste de integração original](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/tests/test_pipeline_e2e.py)

### Dependências e licenças

- **Python 3.11 ou 3.12 x64.** O pacote exige `>=3.11,<3.13`. As dependências incluem FastAPI/Uvicorn, Faster-Whisper/CTranslate2, MediaPipe, PySceneDetect e pysubs2. O teste inicial usa Whisper `base` na CPU para deixar a GPU disponível ao Ollama. O extra de GPU para transcrição exige bibliotecas cuBLAS para CUDA 12 e cuDNN 9. A diarização por WhisperX é opcional, instala PyTorch e requer acesso aos modelos do pyannote. [Dependências Python](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/pyproject.toml)
- **FFmpeg completo e ffprobe.** O filtro `ass`/libass é usado para as legendas e `libx264` fornece codificação H.264 por software. O NVENC depende de um driver compatível com a compilação do FFmpeg. **Node.js 20+ e npm** compilam o painel. [Requisitos do AutoClip](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/README.md#requirements)
- **Ollama para Windows e `qwen2.5:7b`.** O modelo local quantizado ocupa cerca de 4,7 GB para download e usa a licença Apache 2.0. A instalação e o primeiro download de dependências e pesos exigem acesso à internet. A análise usa o serviço local em `127.0.0.1:11434`. [Ollama no Windows](https://docs.ollama.com/windows) · [Modelo e licença](https://ollama.com/library/qwen2.5:7b)
- **Avisos de terceiros.** O AutoClip usa a licença MIT com copyright de Jad Ghazi, 2026. Preserve o `LICENSE` original em cópias do código. As fontes Anton e Inter das legendas e Instrument Serif e Archivo do painel seguem a SIL Open Font License. Preserve os avisos das respectivas famílias ao distribuir os arquivos. [MIT do AutoClip](licencas/AutoClip-MIT.txt) · [Avisos SIL OFL](licencas/fontes)

## Executar no Windows

Abra o PowerShell na pasta do projeto com Git, Node.js 20 ou superior e npm disponíveis. Use os mesmos comandos para instalar ou atualizar. Se houver uma tarefa ativa, aguarde sua conclusão ou cancele antes de fechar o painel. A atualização reaplica os patches ao AutoClip fixado em `.fase1`, reaproveita os downloads locais e adiciona os campos de progresso ao SQLite na primeira inicialização. As configurações existentes continuam na pasta de dados.

```powershell
.\scripts\instalar-fase1.ps1
```

Inicie o Ollama e o painel no mesmo terminal. Mantenha o terminal aberto durante o uso e pressione `Ctrl+C` para encerrar. O painel roda apenas no endereço local porque o AutoClip não tem autenticação. A configuração, o banco SQLite e os vídeos do painel ficam em `$env:LOCALAPPDATA\AI Shorts Studio\autoclip` por padrão, fora da pasta sincronizada pelo OneDrive. Para alterar essa pasta, defina `$env:AI_SHORTS_STUDIO_DATA` antes de iniciar. [Abrir AutoClip](http://127.0.0.1:8000) · [Política de segurança do AutoClip](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/SECURITY.md#running-it-safely)

```powershell
.\scripts\iniciar-fase1.ps1
```

### Teste funcional com vídeo curto

Com o primeiro terminal aberto, rode o teste em um segundo terminal na pasta do projeto. Para executar só o teste sem abrir o painel, inicie o primeiro terminal com `.\scripts\iniciar-fase1.ps1 -SomenteOllama`.

```powershell
.\scripts\testar-fase1.ps1
.\scripts\testar-fase1.ps1 -Rapido -NVENC
```

O teste usa mídia gerada localmente com fala sintética em português brasileiro. Os arquivos de entrada, o MP4 resultante e os logs de cada rodada ficam em `.fase1/teste`. O teste valida H.264/AAC, a resolução escolhida, a transcrição e os arquivos de legenda. `-NVENC` ativa a preferência pela GPU no teste.

Para conferir o painel, importe o vídeo curto gerado ou outro arquivo de sua autoria. Se usar mídia de terceiros, confirme que você tem autorização para o uso pretendido antes de importá-la. Nas configurações gerais, selecione Ollama com `qwen2.5:7b`, Whisper `base`, idioma `pt` e limite de um corte. Inicie a tarefa, abra o resultado, confira a prévia, ajuste os limites e revise a legenda antes de exportar.

### Verificação da instalação original

- A CLI processou 64,54 s de mídia sintética com voz pt-BR Microsoft Maria. O Whisper `base` transcreveu 160 palavras. O Ollama `qwen2.5:7b` escolheu um corte de 21,50 s. O `ffprobe` confirmou MP4 com H.264, AAC e 1080 × 1920. A inspeção de um quadro confirmou legenda em português no vídeo. A saída também inclui SRT. Cada execução do teste salva seu `resultado.json` em `.fase1/teste`.
- O painel compilado respondeu via HTTP. Pela API web, validei importação, conclusão da tarefa, prévia parcial HTTP 206, edição, aprovação e download. A exportação aprovada teve 27,21 s em H.264/AAC, com 1080 × 1920.
- A suíte do AutoClip passou em 294 testes, incluindo renderização real do FFmpeg. A execução excluiu 24 casos marcados como `golden` ou `e2e`.
- O PyAV 19.0.2 falhou na chamada `av.open(..., metadata_errors="ignore")` do Faster-Whisper 1.2.1. O instalador fixa `av==16.1.0`. O MediaPipe também falhou ao abrir o modelo pelo caminho com `Área de Trabalho`. O patch local abre o arquivo pelo Python e passa seus bytes ao MediaPipe. [Dependências fixadas](scripts/requirements-fase1.txt) · [Patch](scripts/autoclip-windows-mediapipe.patch)
- O `qwen3:4b-instruct` devolveu uma lista vazia nesta gravação. O `qwen2.5:7b` selecionou trechos com o prompt original, e o Ollama informou 4,76 GB em VRAM durante a inferência com contexto de 4096 tokens. Whisper e a codificação H.264 ficaram na CPU. Títulos e justificativas saíram em inglês nessa execução, com legendas em português.

### Se o teste falhar

- Se o diagnóstico apontar ausência do filtro `ass`, verifique se o script encontrou a compilação completa do FFmpeg. Se a aceleração de vídeo falhar, use o encoder `libx264`.
- Se o modelo estiver indisponível, confira no primeiro terminal se o Ollama está ativo em `127.0.0.1:11434` e se o download de `qwen2.5:7b` terminou. Se a voz `pt-BR` estiver indisponível, o teste tenta uma voz em inglês e registra o idioma utilizado.
- Se o painel abrir sem a interface, confira a compilação do frontend na instalação. Se uma etapa do teste falhar, consulte os logs da rodada em `.fase1/teste` para localizar a primeira falha.
