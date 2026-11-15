# Histórias IA

O gerador produz MP4 vertical 9:16 de 15, 30, 45 ou 60 segundos. Ele usa o Ollama para o roteiro, Piper para narrar em pt-BR, camadas PNG originais para a arte e FFmpeg para codificar o vídeo. A saída do MVP é 720 × 1280, H.264 a 24 fps e áudio AAC. [Saída estruturada do Ollama](https://docs.ollama.com/capabilities/structured-outputs) · [Piper](https://github.com/OHF-Voice/piper1-gpl)

## Atualize e inicie no Windows

Encerre o Studio se estiver aberto. Use a pasta do projeto e, se usa a integração com o Instagram, o mesmo PowerShell em que as credenciais já estão configuradas.

~~~powershell
.\scripts\instalar-fase1.ps1
.\scripts\preparar-voz-historias.ps1
$env:AI_SHORTS_INSTAGRAM_PUBLISH = '0'
.\scripts\iniciar-fase1.ps1 -SemBaixarModelo
~~~

O segundo script instala o Piper 1.8.0 e a dependência pathvalidate no ambiente Python do Studio. Ele baixa a voz **Cadu** (63 MB), confere os hashes e mantém a ficha do modelo. O pacote e a voz somam aproximadamente 100 MB. A voz fica por padrão em `.fase1\cache\piper`. Outros pares de arquivos pt-BR `.onnx` e `.onnx.json` compatíveis podem ficar nessa pasta ou no diretório definido por `AI_SHORTS_STORY_VOICES`. Confira a ficha e a licença de cada voz antes de adicionar. [Ficha da voz Cadu](https://huggingface.co/rhasspy/piper-voices/blob/cf910fb59f1d79ab3b625a63993a108751c6c25d/pt/pt_BR/cadu/medium/MODEL_CARD) · [Licenças das vozes Piper](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/COMMERCIAL_USE.md)

A aba lista os modelos compatíveis já instalados no Ollama local. Escolha `qwen3:4b-instruct` para o primeiro vídeo. `qwen2.5:7b` também é aceito. A opção `-SemBaixarModelo` inicia o Studio com o que já está instalado. Se a aba indicar ausência de modelo ou voz, o roteiro ou o áudio, respectivamente, precisam desse serviço antes de prosseguir. [API de geração do Ollama](https://docs.ollama.com/api/generate)

## Crie e revise

1. Abra **Histórias IA** e escreva uma ideia original. Escolha gênero, duração, narrador e modelo. Clique em **Gerar roteiro**.
2. No **Editor de roteiro**, revise personagens, cenários, narração, diálogos, ações e final. A ficha visual conserva o personagem entre cenas. **Variar visual** troca a cor da ficha selecionada. Ajuste também a espécie, cor e acessório se quiser. Para mudar o vídeo de uma cena, escolha o movimento, a expressão, o objeto e o enquadramento nos controles da cena.
3. Use **Regenerar cena** para pedir outra versão de uma cena. Salve e use **Gerar prévia da narração** para ouvir a voz no ritmo escolhido. Se o áudio ultrapassar a duração disponível, encurte as falas, ajuste a velocidade ou escolha uma duração maior.
4. Clique em **Aprovar roteiro** e depois **Produzir vídeo**. A produção mostra a etapa que está executando e o avanço medido do desenho e do FFmpeg. **Cancelar geração** interrompe a tarefa. **Retomar produção** reaproveita imagens e frases completas em cache e volta a executar a etapa que precisar de arquivos.
5. No resultado, reproduza e baixe o MP4 ou o SRT. Uma nova renderização ganha um identificador próprio e deixa os MP4 anteriores disponíveis.

## Prepare um Reel

Clique em **Preparar Reel** no vídeo. O Studio abre a aba Instagram com a exportação selecionada. Use **Preparar prévia** e escolha a conta de destino. Se `@clipshistoricos` estiver autorizada, o editor oferece um botão para selecioná-la. A revisão, a confirmação dos direitos e a autorização de envio continuam obrigatórias antes de colocar um Reel na fila. Com `AI_SHORTS_INSTAGRAM_PUBLISH=0`, a fila fica pausada. [Guia da integração Instagram](instagram-meta.md)

## Arquivos, recursos e limites

- O banco `stories\historias.sqlite3` guarda projetos, roteiros, aprovações, estados e exportações na pasta de dados do Studio. Dentro de `stories`, `projects` contém as versões de áudio, legendas e MP4. `cache` contém as referências PNG, fundos e frases sintetizadas.
- O Clipador e Histórias IA usam o mesmo recurso de produção no processo do Studio. O Ollama recebe a ordem para descarregar o modelo ao terminar o roteiro. O Piper, o desenho das camadas e o encoder libx264 usam CPU. O render grava e lê quadros em disco. O consumo depende da duração e da cena.
- A biblioteca oferece cinco personagens com cores e acessórios configuráveis e cinco opções de cenário. Os movimentos são transformações simples de camadas, como piscar, acenar, inclinar a cabeça e pular. A legenda por frase usa os tempos medidos do áudio. O seletor por palavra fica indisponível até haver alinhamento confiável.
- A Fase A usa a biblioteca desenhada localmente. O ComfyUI pode rodar em um ambiente separado no Windows. A avaliação de modelos, licenças e consumo com 8 GB de VRAM pertence à Fase C. [Requisitos do ComfyUI](https://docs.comfy.org/installation/system_requirements)

## Testes

Execute a suíte de Histórias IA e Instagram com o ambiente instalado. Os testes automatizados simulam respostas do Ollama e falas do Piper. O FFmpeg gera e inspeciona um MP4 real com esse áudio de teste.

O teste real no Windows gerou **Lume e a Estrela Caída** com `qwen3:4b-instruct` e a voz Cadu. O FFprobe mediu 15,00 s, 720 × 1280 em 9:16, H.264 a 24 fps e AAC. A legenda apareceu no quadro do MP4 reproduzido no Chrome. **Preparar Reel** abriu a revisão local, com a publicação pausada. Uma segunda renderização manteve a primeira versão disponível.

~~~powershell
. .\scripts\ambiente-fase1.ps1
Push-Location $autoclipRoot
try {
    & $pythonExe -m pytest -q tests/test_studio_stories.py tests/test_studio_instagram.py
} finally {
    Pop-Location
}
~~~

Para repetir a produção com os serviços reais, selecione 15 segundos, Qwen 4B e Cadu. Gere e aprove um roteiro curto, produza o vídeo e baixe o MP4. Para inspecioná-lo no PowerShell do projeto, use o arquivo baixado no último argumento.

~~~powershell
. .\scripts\ambiente-fase1.ps1
ffprobe -v error -show_entries 'stream=codec_name,width,height,display_aspect_ratio,r_frame_rate:format=duration' -of json 'C:\caminho\historia.mp4'
~~~
