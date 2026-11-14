# Configurar o Instagram no Windows

O estúdio usa **Facebook Login for Business** e a API Graph do Instagram. Vincule cada conta profissional, Business ou Creator, a uma Página do Facebook. O login ocorre na Meta e o upload vai diretamente do computador à Meta pela API oficial. [Instagram com Facebook Login](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-facebook-login) · [Publicação de conteúdo](https://developers.facebook.com/documentation/instagram-platform/content-publishing)

## Configuração na Meta

1. No [painel de desenvolvedores da Meta](https://developers.facebook.com/apps/), use um aplicativo Business ou um caso de uso com suporte ao **Facebook Login for Business** e à API do Instagram com Facebook Login.
2. Adicione uma configuração de login com token de **usuário**, código de autorização e acesso às Páginas desejadas. Solicite `pages_show_list`, `pages_read_engagement`, `instagram_basic` e `instagram_content_publish`. A pessoa que conecta a conta precisa ter a tarefa `MANAGE` ou `CREATE_CONTENT` na Página. A documentação da Meta prevê permissões de anúncios adicionais para certos acessos concedidos pelo Gerenciador de Negócios. Aplique as permissões exigidas pelo seu tipo de acesso. [Configurar o login](https://developers.facebook.com/documentation/facebook-login/facebook-login-for-business) · [Permissões e tarefas de publicação](https://developers.facebook.com/documentation/instagram-platform/instagram-graph-api/reference/ig-user/media)
3. Para uso próprio em desenvolvimento, inclua o usuário nas funções do aplicativo e valide o acesso às Páginas vinculadas. Para atender contas de terceiros fora das funções e ativos do aplicativo, consulte os requisitos de acesso avançado e análise da Meta. [App Review](https://developers.facebook.com/docs/app-review)
4. No login web, verifique que o endereço de retorno corresponde exatamente a `http://localhost:8000/api/instagram/oauth/callback` no modo de desenvolvimento. Use a validação de redirecionamento do próprio painel da Meta. Se ele exigir HTTPS, use um proxy TLS **local** com certificado confiável pelo navegador, com o mesmo host e porta do endereço cadastrado. Configure `AI_SHORTS_META_REDIRECT_URI` com esse endereço e acesse o estúdio por ele. O proxy precisa manter o cabeçalho `Host` original e evitar logs da query do callback. Mantenha o servidor em loopback. [Fluxo OAuth manual](https://developers.facebook.com/documentation/facebook-login/guides/advanced/manual-flow)
5. Anote o **App ID** e o **ID da configuração de login**. Consulte o **App Secret** no painel da Meta e mantenha-o fora do Git.

## Iniciar e conectar

Depois de rodar o instalador do estúdio, configure o ambiente no PowerShell que iniciará o painel. O segredo digitado fica no ambiente desse processo e de seus filhos. O exemplo usa PowerShell no Windows e evita gravar o valor no histórico do terminal.

```powershell
$env:AI_SHORTS_META_APP_ID = '<App ID numérico>'
$env:AI_SHORTS_META_CONFIG_ID = '<ID numérico da configuração de login>'
$metaSecret = Read-Host 'App Secret da Meta' -AsSecureString
$env:AI_SHORTS_META_APP_SECRET = [System.Net.NetworkCredential]::new('', $metaSecret).Password
$metaSecret.Dispose()
Remove-Variable metaSecret
$env:AI_SHORTS_META_REDIRECT_URI = 'http://localhost:8000/api/instagram/oauth/callback'
$env:AI_SHORTS_META_API_VERSION = 'v27.0'
$env:AI_SHORTS_INSTAGRAM_PUBLISH = '0'
.\scripts\iniciar-fase1.ps1
```

Abra **Instagram → Conectar pela Meta**, autorize as Páginas e escolha até duas contas de destino no estúdio. Repita o login se a segunda conta for administrada por outro usuário do Facebook. Com o envio pausado, é possível conectar contas, preparar rascunhos, conferir prévias e revisar a fila. A versão da Graph API pode ser trocada pela variável de ambiente. [Controle de versões da Meta](https://developers.facebook.com/docs/graph-api/guides/versioning)

O token de Página e o token de usuário de longa duração ficam no **Gerenciador de Credenciais do Windows**, associados ao diretório de dados e ao App ID. O SQLite guarda a fila, as aprovações, os IDs e o histórico. **Renovar acesso** tenta obter novamente o token da Página enquanto o token de usuário estiver válido. Se o acesso de usuário expirar ou for revogado, faça login novamente. O token de Página pode ser invalidado por mudanças de permissões. [Tokens de longa duração](https://developers.facebook.com/documentation/facebook-login/guides/access-tokens/get-long-lived)

## Preparar e agendar um Reel

1. Exporte um corte em 9:16 e selecione **Preparar Reel** no editor ou na página do Instagram. O estúdio usa o FFmpeg para criar uma cópia de publicação com áudio AAC estéreo a 128 kb/s quando há áudio. O arquivo original continua disponível no Clipador. O limite do MP4 é 300 MB e a duração aceita vai de 3 segundos a 15 minutos. [Especificações de Reels](https://developers.facebook.com/documentation/instagram-platform/instagram-graph-api/reference/ig-user/media#reels-specs)
2. Confira a prévia. Escolha a conta e o horário local e preencha a legenda e as hashtags. Confirme que revisou o vídeo, que tem autorização para publicar o vídeo e o áudio e que autoriza a publicação na conta e no horário escolhidos. Selecione **Aprovar e agendar**.
3. Quando estiver pronto para enviar os Reels aprovados, encerre o painel, ajuste `$env:AI_SHORTS_INSTAGRAM_PUBLISH = '1'` e inicie novamente no mesmo terminal. O agendamento roda no computador. Deixe-o ligado, com o painel aberto e acesso à internet.
4. Em **Filas de publicação**, selecione a conta que deseja acompanhar. Falhas temporárias são registradas e o estúdio tenta novamente enquanto o horário ainda estiver dentro da tolerância de 30 minutos. Passado esse período, abra o histórico, reabra o rascunho e autorize um novo horário.
5. Se a Meta deixar o resultado incerto depois do pedido de publicação, selecione **Verificar na Meta** no histórico. O estúdio consulta o status do envio. Ele volta a permitir a reabertura para nova aprovação se a Meta confirmar erro ou expiração. Também é possível conferir o perfil de destino pelo aplicativo oficial.

## Dados e testes

O banco `publicacoes.sqlite3` e as prévias em `instagram/media` ficam na pasta de dados do estúdio. Ao desconectar uma conta, os tokens locais são removidos e os envios pendentes saem da fila. O histórico e as cópias das prévias ficam disponíveis. Para revogar o acesso do aplicativo na Meta, remova-o também das integrações comerciais do Facebook. O estúdio local deve rodar com o perfil do Windows que fez a conexão.

O teste automatizado usa mídia sintética, uma simulação de credenciais e respostas simuladas da Meta. Para rodar no Windows, instale o estúdio e execute na pasta do projeto.

```powershell
. .\scripts\ambiente-fase1.ps1
Push-Location $autoclipRoot
try { & $pythonExe -m pytest -q tests/test_studio_instagram.py } finally { Pop-Location }
```

O primeiro teste com uma conta real requer seu aplicativo da Meta, uma conta profissional configurada e autorização explícita para qualquer Reel de teste.
