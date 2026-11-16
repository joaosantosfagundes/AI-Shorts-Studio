# Histórias IA

O gerador produz MP4 vertical 9:16 de 15, 30, 45 ou 60 segundos, com 720 × 1280, H.264 a 24 fps e áudio AAC. O Ollama gera o roteiro. O Kokoro e o Piper sintetizam a narração em pt-BR. O Cartoon 3D é o padrão dos novos projetos e o editor também oferece Cartoon 2D. [Saída estruturada do Ollama](https://docs.ollama.com/capabilities/structured-outputs)

## Atualize e inicie no Windows

Encerre o Studio se estiver aberto. Use a pasta do projeto e, se usa a integração com o Instagram, o mesmo PowerShell em que as credenciais já estão configuradas.

~~~powershell
git pull --ff-only origin main
.\scripts\instalar-fase1.ps1
.\scripts\preparar-voz-historias.ps1 -Kokoro
$env:AI_SHORTS_INSTAGRAM_PUBLISH = '0'
.\scripts\iniciar-fase1.ps1 -SemBaixarModelo
~~~

O segundo script mantém a voz **Cadu** (Piper 1.8.0, modelo de 63 MB) e, com `-Kokoro`, verifica e instala o modelo ONNX quantizado e suas três vozes. Os arquivos Kokoro somam cerca de 94 MB e ficam em `.fase1\cache\kokoro`. Use `AI_SHORTS_STORY_KOKORO` para outro diretório. Os arquivos já verificados são reaproveitados. [Modelo Kokoro](https://huggingface.co/hexgrad/Kokoro-82M) · [Conversão ONNX fixada](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/tree/468588286ebb2dd77c25b9771e5d165896538cce)

A aba lista os modelos compatíveis já instalados no Ollama local. Escolha `qwen3:4b-instruct` para o primeiro vídeo. `qwen2.5:7b` também é aceito. A opção `-SemBaixarModelo` inicia o Studio com o que já está instalado. Se a aba indicar ausência de modelo ou voz, o roteiro ou o áudio, respectivamente, precisam desse serviço antes de prosseguir. [API de geração do Ollama](https://docs.ollama.com/api/generate)

## Crie e revise

1. Abra **Histórias IA** e escreva uma ideia original. Escolha gênero, duração, estilo, narrador e modelo. Use **Ouvir voz** para comparar a mesma frase. Clique em **Gerar roteiro**.
2. No **Editor de roteiro**, revise a narração e a composição de cada cena. Escolha elenco, cenário, luz, expressão, gesto, objeto, enquadramento, posição e direção do olhar. Use a ficha visual para conferir a aparência. Uma pendência assinala um elemento que precisa de uma escolha antes da renderização.
3. Use **Regenerar cena** para pedir outra versão de uma cena. Salve e use **Gerar prévia da narração** para ouvir a voz no ritmo escolhido. Se o áudio ultrapassar a duração disponível, encurte as falas, ajuste a velocidade ou escolha uma duração maior.
4. Clique em **Aprovar roteiro** e depois **Produzir vídeo**. A produção mostra a etapa que está executando e o avanço medido do desenho e do FFmpeg. **Cancelar geração** interrompe a tarefa. **Retomar produção** reaproveita as frases em cache e recria os quadros.
5. No resultado, reproduza e baixe o MP4 ou o SRT. Uma nova renderização ganha um identificador próprio e deixa os MP4 anteriores disponíveis.

## Crie uma série e um final interativo

1. Aprove o episódio e use **Iniciar série com esta história**. O estilo, os modelos, as cores e os acessórios do elenco ficam fixos para os episódios seguintes.
2. Em **Notas e final interativo**, registre o resumo, os acontecimentos e os mistérios. Para incluir a votação, preencha a pergunta e os dois planos. Salve e produza o vídeo. O Studio reserva de 4 a 8 segundos para exibir as opções ao fim da narração. Se precisar de mais espaço, encurte a fala ou aumente a duração do vídeo.
3. Selecione manualmente o resultado e salve. Use **Criar episódio seguinte** e **Gerar roteiro**. O Ollama recebe o plano escolhido, o final e a memória dos quatro episódios mais recentes. Revise se o novo roteiro seguiu o plano. A série guarda cada episódio com suas notas e reaproveita as mesmas fichas de personagens.

Uma mudança no texto do final interativo exige uma nova renderização. Os MP4 exportados continuam na biblioteca. Depois que a continuação foi criada, o resultado e os planos daquele episódio ficam registrados.

## Prepare um Reel

Clique em **Preparar Reel** no vídeo. O Studio abre a aba Instagram com a exportação selecionada. Use **Preparar prévia** e escolha a conta de destino. Se `@clipshistoricos` estiver autorizada, o editor oferece um botão para selecioná-la. A revisão, a confirmação dos direitos e a autorização de envio continuam obrigatórias antes de colocar um Reel na fila. Com `AI_SHORTS_INSTAGRAM_PUBLISH=0`, a fila fica pausada. [Guia da integração Instagram](instagram-meta.md)

## Vozes e licenças

- **Kokoro 82M ONNX** oferece Dora, Alex e Santa com fonemização `pt-br`. A ficha original identifica uma voz feminina e duas masculinas. O modelo e a conversão ONNX usam Apache 2.0. A mesma frase de comparação é usada em todos os motores. Velocidade e pausas estão disponíveis, e o motor usado aparece abaixo da prévia da narração. [Vozes brasileiras do Kokoro](https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md#brazilian-portuguese) · [Licença dos pesos](https://huggingface.co/hexgrad/Kokoro-82M)
- **Piper** mantém Cadu como voz de reserva para falha ou indisponibilidade do Kokoro. Sua revisão fixa usa a cadeia de treinamento CC0 listada pelo mantenedor. Jeff também consta na lista, e Faber tem uma cadeia de treino com atribuição. Confira a ficha da versão exata de qualquer voz externa. [Ficha da voz Cadu](https://huggingface.co/rhasspy/piper-voices/blob/cf910fb59f1d79ab3b625a63993a108751c6c25d/pt/pt_BR/cadu/medium/MODEL_CARD) · [Licenças das vozes Piper](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/COMMERCIAL_USE.md)
- A licença pública do **Coqui XTTS v2** limita os pesos e os áudios a uso não comercial. O Studio usa o Kokoro no lugar desse modelo para projetos possivelmente monetizados. O gênero orienta o roteiro e a expressão visual. O controle de voz ajusta a velocidade. [Licença do XTTS v2](https://huggingface.co/coqui/XTTS-v2/blob/main/LICENSE.txt)
- O **RHVoice** usa síntese paramétrica e oferece a voz brasileira Letícia-F123 sob CC BY-SA 4.0. Foi avaliado pela documentação. O **MMS TTS** da Meta oferece um modelo identificado como português geral e os pesos usam CC BY-NC 4.0. [Documentação do RHVoice](https://github.com/RHVoice/RHVoice/blob/master/doc/en/index.md) · [Licença da Letícia-F123](https://github.com/RHVoice/RHVoice/blob/master/doc/en/License.md#letícia-f123) · [Ficha do MMS TTS](https://huggingface.co/facebook/mms-tts-por)

## Arquivos, recursos e limites

- O banco `stories\historias.sqlite3` guarda projetos, roteiros, aprovações, séries, escolhas, estados e exportações na pasta de dados do Studio. Dentro de `stories`, `projects` contém as versões de áudio, legendas e MP4. `cache` contém as referências PNG, fundos e frases sintetizadas.
- O Clipador e Histórias IA usam o mesmo recurso de produção no processo do Studio. O Ollama recebe a ordem para descarregar o modelo ao terminar o roteiro. O Kokoro, o Piper, o desenho das camadas 2D e o encoder libx264 usam CPU. O render grava e lê quadros em disco. O consumo depende da duração e da cena.
- A biblioteca 3D usa malhas originais para cachorro, gato, coelho, coruja, robô e estrela com rosto. Os cenários são quarto, jardim, bosque, oficina e rua. O Studio renderiza perspectiva, iluminação e profundidade em OpenGL 3.3 com ModernGL. Os quadros 3D são amostrados a 24 fps e incluem piscar, gestos de cabeça e pata, passos, deslocamento, expressões, olhares e câmera. O Blender Eevee é compatível com a classe de GPU, mas adicionar o Blender portátil exigiria um download de aproximadamente 380 MB. [ModernGL](https://moderngl.readthedocs.io/en/latest/topics/context.html) · [Blender 4.5 LTS](https://www.blender.org/releases/4-5/)
- O Cartoon 2D usa as camadas PNG da biblioteca anterior. Projetos antigos mantêm o estilo salvo. Os tempos das legendas por frase vêm dos arquivos PCM da voz efetivamente usada. A exibição por palavra depende de alinhamento confiável. As vozes integradas têm velocidade e pausas ajustadas pela pontuação, com interpretação emocional dependente da voz escolhida.

## Testes

Execute a suíte de Histórias IA e Instagram com o ambiente instalado. Os testes automatizados cobrem migração de projetos 2D, reaproveitamento de áudio, falhas visuais, votação e continuidade. O FFmpeg gera e inspeciona um MP4 real com áudio de teste.

No Windows 11 com uma RTX 3060, o protótipo de 5 s com Pingo e uma estrela levou 4,46 s. A história de 15 s com `qwen3:4b-instruct` levou 15,14 s para gerar o roteiro e 18,28 s para produzir o MP4 com Dora. O roteiro precisou de ajuste de posição e olhar no editor. O FFprobe mediu 15,00 s, 720 × 1280, H.264 a 24 fps e AAC.

No teste da série, o vídeo exibiu Plano A e Plano B nos seis segundos finais. A renderização com as falas reaproveitadas levou 12,38 s. Após o registro manual do Plano B, o Ollama escreveu a continuação em 13,37 s, seguindo as pegadas e usando as fichas visuais do primeiro episódio.

O Chrome reproduziu os MP4 originais e a cópia preparada na revisão do Reel. A revisão foi validada com a publicação pausada.

A frase de comparação levou, em CPU, 4,77 s com Dora, 4,80 s com Alex, 4,83 s com Santa e 3,04 s com Cadu. Na verificação por transcrição local com Whisper base, apareceram divergências em palavras como “olhou”, “havia ninguém” e “sussurrou”. A transcrição indica pontos para revisar de ouvido.

~~~powershell
. .\scripts\ambiente-fase1.ps1
$env:AI_SHORTS_INSTAGRAM_PUBLISH = '0'
Push-Location $autoclipRoot
try {
    & $pythonExe -m pytest -q tests/test_studio_stories.py tests/test_studio_instagram.py
} finally {
    Pop-Location
}
~~~

Para repetir a produção com os serviços reais, selecione 15 segundos, Cartoon 3D, Qwen 4B e Dora. Gere e aprove um roteiro curto, produza o vídeo e baixe o MP4. Para inspecioná-lo no PowerShell do projeto, use o arquivo baixado no último argumento.

~~~powershell
. .\scripts\ambiente-fase1.ps1
ffprobe -v error -show_entries 'stream=codec_name,width,height,display_aspect_ratio,r_frame_rate:format=duration' -of json 'C:\caminho\historia.mp4'
~~~
