# AI Shorts Studio · Clipador IA

## Fase 1 — auditoria e instalação

O teste no Windows 11 x64 usa o AutoClip `0.1.0.dev0`, commit `5d0eac36fa615b79dd2104083bf273a96f8d68bb` do fork Gutsken/Autoclip. O painel existente usa React, TypeScript e Vite. O FastAPI serve o painel compilado, a API e o progresso das tarefas no mesmo endereço. A fila processa um vídeo por vez, grava o histórico em SQLite e guarda arquivos intermediários para reaproveitar etapas concluídas em uma tentativa anterior. Essa arquitetura atende à instalação local da Fase 1 com um único servidor de aplicação. [Revisão do AutoClip](https://github.com/Gutsken/Autoclip/commit/5d0eac36fa615b79dd2104083bf273a96f8d68bb) · [Arquitetura](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/docs/ARCHITECTURE.md)

### O que o código já oferece

- Importação de arquivo local, histórico, progresso por eventos, cancelamento e nova tentativa. O painel expõe quantidade máxima, duração e idioma por tarefa. A fila tem uma limitação nesses controles, descrita abaixo. O painel de revisão permite reproduzir, ajustar início e fim, editar legendas e marcar cortes como aprovados ou rejeitados. [API de tarefas](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/api/jobs.py) · [Painel](https://github.com/Gutsken/Autoclip/tree/5d0eac36fa615b79dd2104083bf273a96f8d68bb/frontend)
- Faster-Whisper gera tempos por palavra, inclusive para fala em português. A seleção usa a transcrição em janelas sobrepostas. O LLM retorna índices de palavras, nota e justificativa textual. O código ajusta os limites, elimina sobreposições e ordena os candidatos pela nota até o máximo pedido. Pode encontrar menos cortes do que o máximo configurado. [Transcrição](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/transcribe.py) · [Seleção](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/highlights.py)
- PySceneDetect e MediaPipe ajudam a reenquadrar por cena e por rosto após a seleção. O FFmpeg gera MP4 vertical de 1080 × 1920 com H.264, AAC e legendas ASS incorporadas ao quadro. O render inicial também alimenta a prévia no painel. [Reenquadramento](https://github.com/Gutsken/Autoclip/tree/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/reframe) · [Exportação](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/export.py)

### Lacunas e riscos para o Clipador IA

- A nota e a justificativa atuais são estimativas do LLM com base na fala. A seleção para gameplay precisa combinar sinais de áudio e visuais, detectar reações, explicitar a contribuição de cada sinal e evitar trechos semelhantes mesmo quando aparecem em intervalos distintos. A detecção visual existente é usada no reenquadramento. [Seleção](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/highlights.py) · [Pipeline](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/runner.py)
- Gameplay ainda precisa de critérios de enquadramento que preservem o HUD, avaliação com clipes reais, transições discretas e perfil de teste em 720 × 1280. O fluxo do produto também precisa de interface em português, confirmação explícita de autorização para material de terceiros e exportação final condicionada à aprovação. O roteiro desta fase usa um arquivo local produzido para o teste. [Exportação](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/export.py) · [Pipeline](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/runner.py)
- Gravações de duas a três horas precisam de teste de memória, disco, tempo e recuperação no hardware de destino. Na etapa de transcrição, o Faster-Whisper decodifica o áudio completo para a memória. Um WAV de três horas a 16 kHz, mono, PCM de 16 bits ocupa cerca de 346 MB em disco. O decodificador ainda cria uma representação de 32 bits antes de extrair as características para a transcrição. [Preparação de mídia](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/prepare.py) · [Decodificação do Faster-Whisper](https://github.com/SYSTRAN/faster-whisper/blob/master/faster_whisper/audio.py#L23-L68)
- O AutoClip está em desenvolvimento e a automação do projeto de origem cobre renderização em Windows com Python 3.12. O teste de integração original usa respostas roteirizadas no lugar do LLM e requer vídeo com rosto detectável. A qualidade da seleção e do reenquadramento em gameplay depende de avaliação com gravações representativas. [CI do projeto de origem](https://github.com/artbyjazi/autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/.github/workflows/ci.yml) · [Teste de integração original](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/tests/test_pipeline_e2e.py)
- A API registra as configurações individuais no SQLite. A fila web instancia o pipeline sem repassá-las, então ele lê as configurações globais. No teste web, o pedido de um corte retornou dois. Enquanto esse fluxo estiver em avaliação, ajuste a quantidade e a duração na tela de configurações gerais antes de iniciar a tarefa. A correção proposta é usar a configuração persistida da tarefa no worker, com fallback para registros antigos. [API de tarefas](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/api/jobs.py#L49-L69) · [Fila](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/jobs/queue.py#L136-L141) · [Pipeline](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/backend/autoclip/pipeline/runner.py#L107-L122)

### Dependências e licenças

- **Python 3.11 ou 3.12 x64.** O pacote exige `>=3.11,<3.13`. As dependências incluem FastAPI/Uvicorn, Faster-Whisper/CTranslate2, MediaPipe, PySceneDetect e pysubs2. O teste inicial usa Whisper `base` na CPU para deixar a GPU disponível ao Ollama. O extra de GPU para transcrição exige bibliotecas cuBLAS para CUDA 12 e cuDNN 9. A diarização por WhisperX é opcional, instala PyTorch e requer acesso aos modelos do pyannote. [Dependências Python](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/pyproject.toml)
- **FFmpeg completo e ffprobe.** O filtro `ass`/libass é usado para as legendas e `libx264` fornece codificação H.264 por software. O NVENC depende de um driver compatível com a compilação do FFmpeg. **Node.js 20+ e npm** compilam o painel. [Requisitos do AutoClip](https://github.com/Gutsken/Autoclip/blob/5d0eac36fa615b79dd2104083bf273a96f8d68bb/README.md#requirements)
- **Ollama para Windows e `qwen2.5:7b`.** O modelo local quantizado ocupa cerca de 4,7 GB para download e usa a licença Apache 2.0. A instalação e o primeiro download de dependências e pesos exigem acesso à internet. A análise usa o serviço local em `127.0.0.1:11434`. [Ollama no Windows](https://docs.ollama.com/windows) · [Modelo e licença](https://ollama.com/library/qwen2.5:7b)
- **Avisos de terceiros.** O AutoClip usa a licença MIT com copyright de Jad Ghazi, 2026. Preserve o `LICENSE` original em cópias do código. As fontes Anton e Inter das legendas e Instrument Serif e Archivo do painel seguem a SIL Open Font License. Preserve os avisos das respectivas famílias ao distribuir os arquivos. [MIT do AutoClip](licencas/AutoClip-MIT.txt) · [Avisos SIL OFL](licencas/fontes)

## Executar no Windows

Abra o PowerShell na pasta do projeto com Git, Node.js 20 ou superior e npm disponíveis. A instalação usa a pasta `.fase1` para manter o ambiente local ao projeto. Rode uma vez e aguarde a conclusão do diagnóstico do AutoClip. Encerre o painel antes de reinstalar para liberar o executável no Windows.

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
```

O teste usa mídia gerada localmente com fala sintética em português brasileiro. Os arquivos de entrada, o MP4 resultante e os logs de cada rodada ficam em `.fase1/teste`. O resultado esperado é uma transcrição com tempos por palavra, um corte escolhido pelo Ollama e um MP4 de 1080 × 1920 em H.264/AAC com legendas sincronizadas. A mídia sintética serve para validar a integração. A qualidade editorial dos cortes, o HUD e o desempenho em gravações longas exigem testes próprios.

Para conferir o painel, importe o vídeo curto gerado ou outro arquivo de sua autoria. Se usar mídia de terceiros, confirme que você tem autorização para o uso pretendido antes de importá-la. Nas configurações gerais, selecione Ollama com `qwen2.5:7b`, Whisper `base`, idioma `pt` e limite de um corte. Inicie a tarefa, abra o resultado, confira a prévia, ajuste os limites e revise a legenda antes de exportar.

### Resultado observado no Windows 11

- A CLI processou 64,54 s de mídia sintética com voz pt-BR Microsoft Maria. O Whisper `base` transcreveu 160 palavras. O Ollama `qwen2.5:7b` escolheu um corte de 21,50 s. O `ffprobe` confirmou MP4 com H.264, AAC e 1080 × 1920. A inspeção de um quadro confirmou legenda em português no vídeo. A saída também inclui SRT. Cada execução do teste salva seu `resultado.json` em `.fase1/teste`.
- O painel compilado respondeu via HTTP. Pela API web, validei importação, conclusão da tarefa, prévia parcial HTTP 206, edição, aprovação e download. A exportação aprovada teve 27,21 s em H.264/AAC, com 1080 × 1920.
- A suíte do AutoClip passou em 294 testes, incluindo renderização real do FFmpeg. A execução excluiu 24 casos marcados como `golden` ou `e2e`.
- O PyAV 19.0.2 falhou na chamada `av.open(..., metadata_errors="ignore")` do Faster-Whisper 1.2.1. O instalador fixa `av==16.1.0`. O MediaPipe também falhou ao abrir o modelo pelo caminho com `Área de Trabalho`. O patch local abre o arquivo pelo Python e passa seus bytes ao MediaPipe. [Dependências fixadas](scripts/requirements-fase1.txt) · [Patch](scripts/autoclip-windows-mediapipe.patch)
- O `qwen3:4b-instruct` devolveu uma lista vazia nesta gravação. O `qwen2.5:7b` selecionou trechos com o prompt original, e o Ollama informou 4,76 GB em VRAM durante a inferência com contexto de 4096 tokens. Whisper e a codificação H.264 ficaram na CPU. Títulos e justificativas saíram em inglês nessa execução, com legendas em português.

### Se o teste falhar

- Se o diagnóstico apontar ausência do filtro `ass`, verifique se o script encontrou a compilação completa do FFmpeg. Se a aceleração de vídeo falhar, use o encoder `libx264`.
- Se o modelo estiver indisponível, confira no primeiro terminal se o Ollama está ativo em `127.0.0.1:11434` e se o download de `qwen2.5:7b` terminou. Se a voz `pt-BR` estiver indisponível, o teste tenta uma voz em inglês e registra o idioma utilizado.
- Se o painel abrir sem a interface, confira a compilação do frontend na instalação. Se uma etapa do teste falhar, consulte os logs da rodada em `.fase1/teste` para localizar a primeira falha.
