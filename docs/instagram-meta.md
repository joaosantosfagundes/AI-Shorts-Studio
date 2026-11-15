# Configurar o Instagram no AI Shorts Studio

O Studio usa a **Instagram API with Unified Login**. Cada conta profissional do Instagram precisa estar em um portfólio empresarial da Meta, e o aplicativo precisa pertencer a um portfólio. As contas podem ser compartilhadas na mesma sessão se a Meta as oferecer juntas. Você também pode conectar cada conta em uma sessão separada. O fluxo aceita conta profissional Business ou Creator e dispensa Páginas do Facebook. [Visão geral do Unified Login](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login)

## 1. Prepare o endereço HTTPS no Windows

A configuração usa a Redirect URL que a Meta aceitou para este projeto.

```text
https://localhost.localdomain:8000/api/instagram/oauth/callback
```

No PowerShell **como administrador**, abra o arquivo de resolução local:

```powershell
notepad.exe "$env:SystemRoot\System32\drivers\etc\hosts"
```

Adicione a linha abaixo ao final e salve no mesmo arquivo. Se o nome já estiver listado, deixe uma única entrada para `127.0.0.1`.

```text
127.0.0.1 localhost.localdomain
```

O comando abaixo deve retornar `127.0.0.1`. [Resolução local pelo arquivo hosts](https://learn.microsoft.com/windows/powertoys/hosts-file-editor)

```powershell
[System.Net.Dns]::GetHostAddresses('localhost.localdomain').IPAddressToString
```

Encerre o painel e volte ao PowerShell do seu usuário. Atualize o Studio e gere o certificado:

```powershell
.\scripts\instalar-fase1.ps1
.\scripts\preparar-https-instagram.ps1
```

O segundo script cria o certificado para `localhost.localdomain` e imprime o comando de importação para você executar, após conferir o arquivo e a impressão digital SHA-256 exibida. Com o diretório padrão, o comando é:

```powershell
$cert = Join-Path $env:LOCALAPPDATA 'AI Shorts Studio\tls\localhost.localdomain.cer'
Import-Certificate -FilePath $cert -CertStoreLocation 'Cert:\CurrentUser\Root'
```

Importe somente o arquivo público `.cer`. Se você usa `AI_SHORTS_META_TLS_DIR`, execute o comando de importação exibido pelo script para o seu diretório. Para trocar um certificado vencido, rode `.\scripts\preparar-https-instagram.ps1 -Renovar`, importe o novo certificado público e reinicie o painel. O Studio abre em `https://localhost.localdomain:8000` e escuta em `127.0.0.1:8000`. [Import-Certificate no Windows](https://learn.microsoft.com/powershell/module/pki/import-certificate)

Use no Studio a mesma Redirect URL salva em **API setup with Unified login → Configure your app → Redirect URL**. A Meta exige correspondência exata de esquema, nome, porta e caminho. [Requisitos e URL de login da Meta](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/get-started#login-button)

## 2. Confira a configuração e copie os IDs

No [Meta for Developers](https://developers.facebook.com/apps/), abra o app **AI Shorts Studio**.

| Valor | Onde encontrar |
| --- | --- |
| Meta App ID | **App settings → Basic → App ID** |
| Meta App Secret | **App settings → Basic → App Secret → Show** |
| Meta Login Configuration ID | **Use cases → Manage messaging & content on Instagram → Customize → API setup with Unified login → Configure your app**. Selecione a configuração **Instagram Login Compatible** e copie o valor de `config_id` do campo **Login URL**. O mesmo ID aparece em **Facebook Login for Business → Configurations**. |
| Redirect URI | Na mesma área **Configure your app**, use o campo **Redirect URL**. Cole a URI HTTPS completa da etapa anterior. |
| Versão da Graph API | O Studio usa `v27.0` por padrão. Configure `AI_SHORTS_META_API_VERSION` se precisar usar outra versão compatível. |

Use o App ID e o segredo do **app Meta**. A configuração precisa emitir um **System-user access token (SUAT)**. Confira o tipo e a validade na prévia da configuração. [Configurações de login](https://developers.facebook.com/documentation/facebook-login/facebook-login-for-business#create-a-configuration) · [Onde fica o App Secret](https://developers.facebook.com/docs/graph-api/guides/secure-requests/#generate-the-proof) · [Versões da API](https://developers.facebook.com/docs/graph-api/guides/versioning)

- O Studio precisa de `instagram_basic` para reconhecer a conta e `instagram_content_publish` para publicar. A configuração padrão desse caso de uso também exige `instagram_manage_messages`. Mantenha o que o painel marcar como obrigatório. A permissão `business_management` só é necessária para usar **Renovar acesso** pela API.
- No modo **Development**, use perfis profissionais reais com função no app. Em **Generate access tokens → Add account**, convide os perfis como **Instagram Tester**. Em cada perfil, aceite em **Instagram na web → Settings → Website permissions → Apps and websites → Tester Invites**. Para contas externas sem função no app, a Meta exige **Live**, **Advanced Access** e **App Review**.
- O roteiro geral de configuração da Meta inclui webhooks HTTPS, por exemplo, para mensagens e comentários. O Studio consulta o status de cada Reel pela API e roda localmente. Se o painel exigir webhooks para concluir a configuração ou a revisão do caso de uso, essa etapa é feita à parte.

[Permissões e revisão](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/permissions) · [Contas de teste e configuração de webhooks](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/get-started)

## 3. Abra o Studio e conecte as duas contas

Use a sessão do PowerShell em que suas credenciais da Meta já estão definidas. Para migrar apenas o endereço e manter a publicação pausada, rode:

```powershell
$env:AI_SHORTS_META_REDIRECT_URI = 'https://localhost.localdomain:8000/api/instagram/oauth/callback'
$env:AI_SHORTS_INSTAGRAM_PUBLISH = '0'
.\scripts\iniciar-fase1.ps1
```

Com o Studio aberto, confira a resolução e o certificado em outro terminal. A resposta deve incluir `status = ok`.

```powershell
Invoke-RestMethod 'https://localhost.localdomain:8000/api/health'
```

Para a configuração inicial em uma nova sessão, use o bloco completo abaixo. Digite o segredo apenas no prompt do terminal.

```powershell
$env:AI_SHORTS_META_APP_ID = '<Meta App ID>'
$env:AI_SHORTS_META_CONFIG_ID = '<Login Configuration ID>'
$metaSecret = Read-Host 'App Secret da Meta' -AsSecureString
$env:AI_SHORTS_META_APP_SECRET = [System.Net.NetworkCredential]::new('', $metaSecret).Password
$metaSecret.Dispose()
Remove-Variable metaSecret
$env:AI_SHORTS_META_REDIRECT_URI = 'https://localhost.localdomain:8000/api/instagram/oauth/callback'
$env:AI_SHORTS_META_API_VERSION = 'v27.0'
$env:AI_SHORTS_INSTAGRAM_PUBLISH = '0'
.\scripts\iniciar-fase1.ps1
```

1. Abra **Instagram → Conectar Instagram** em `https://localhost.localdomain:8000` para iniciar o login no mesmo endereço do callback.
2. Na tela oficial da Meta, escolha entrar com Instagram. Selecione o portfólio empresarial e a conta profissional que deseja compartilhar.
3. Ao voltar ao Studio, marque o `@` correto e selecione **Conectar contas selecionadas**. Se a Meta oferecer as duas contas na mesma sessão, você pode selecionar ambas.
4. Para autorizar a segunda conta em outra sessão, repita o processo com o outro perfil do Instagram. Confira os dois nomes e o status **Autorizada** no Studio.
5. Para atualizar uma conta, use **Renovar acesso** se o botão estiver disponível. A API de gerenciamento exige um token válido com `business_management`. Se o acesso venceu, foi revogado ou não permite renovação, use **Reconectar pelo Instagram** na linha da conta.

O código de autorização é trocado no backend. O Studio usa o SUAT para identificar o portfólio e as contas atribuídas pela Meta. Os tokens ficam no Gerenciador de Credenciais do Windows, separados por conta. O SQLite guarda identificadores, estado, agendamentos e histórico. Ao desconectar uma conta, o Studio remove o acesso local dela e tira os envios pendentes da fila. A revogação no portfólio da Meta pode afetar as duas contas quando elas compartilham a mesma autorização. [Autenticação e validade do SUAT](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/authentication) · [Gerenciamento dos tokens](https://developers.facebook.com/documentation/facebook-login/facebook-login-for-business#bisu-token-api)

Se houver contas do fluxo anterior, reconecte-as antes de publicar. O Studio associa rascunhos, fila e histórico ao ID do Instagram devolvido pela Meta. Se uma configuração nova devolver outro ID, os registros antigos ficam vinculados ao ID original. Para publicar pela conta nova, prepare e aprove um novo rascunho.

### Diagnostique uma tentativa de conexão

Depois de atualizar o Studio, reinicie-o na sessão PowerShell que já tem as credenciais e mantenha `AI_SHORTS_INSTAGRAM_PUBLISH=0`. Clique novamente em **Conectar Instagram** para obter um código novo. O Studio envia a mesma `redirect_uri` no diálogo da Meta e na troca do código por token. Para um teste com uma conta profissional que já aceitou o convite de testadora, mantenha o app em **Development**. [Guia de Unified Login](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/get-started) · [OAuth 2.0, seção 4.1.3](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.1.3)

| Etapa no log | Requisição | O que conferir na Meta se falhar |
| --- | --- | --- |
| `troca-codigo` | `GET /oauth/access_token` | Confirme que a Redirect URL é idêntica à do Studio e que o App ID e o App Secret pertencem ao mesmo app que a configuração selecionada. |
| `portfolio` | `GET /me` com `client_business_id` | Confirme a configuração **Instagram Login Compatible**, o tipo **System-user access token** e o vínculo da conta com o portfólio selecionado. |
| `inspecao-token` | `GET /debug_token` | Confira o app associado ao token e as permissões `instagram_basic` e `instagram_content_publish` na configuração de login e no consentimento. |
| `contas` | `GET /me/assigned_instagram_accounts` | Confira se a conta profissional foi compartilhada com o app no portfólio selecionado. |

As falhas da API ficam no terminal e no arquivo `instagram\oauth.log` do diretório de dados. Cada registro inclui a etapa, o método, o endpoint com a versão, o status HTTP, o código e o subcódigo da Meta, a referência e um resumo seguro quando esses dados estiverem disponíveis. Para localizar a última linha no PowerShell, use o comando abaixo. [Erros da Graph API](https://developers.facebook.com/docs/graph-api/guides/error-handling) · [Inspeção de tokens](https://developers.facebook.com/docs/graph-api/reference/debug_token/)

```powershell
$studioData = if ($env:AI_SHORTS_STUDIO_DATA) { $env:AI_SHORTS_STUDIO_DATA } else { Join-Path $env:LOCALAPPDATA 'AI Shorts Studio\autoclip' }
Get-Content -LiteralPath (Join-Path $studioData 'instagram\oauth.log') -Tail 1
```

Compartilhe somente essa linha de diagnóstico. O resumo omite a URL completa do callback, os parâmetros das requisições, os códigos de autorização, o segredo e os tokens. `transporte=WinError-10054` indica que a conexão do Studio com a Meta foi encerrada antes de obter uma resposta HTTP. Um `WinError 10054` no `asyncio` durante o fechamento de um socket do servidor local também pode vir de uma conexão do navegador encerrada abruptamente. Consulte o registro da tentativa para verificar se houve uma resposta da Graph API. [Códigos do Winsock](https://learn.microsoft.com/windows/win32/winsock/windows-sockets-error-codes-2)

## 4. Teste a prévia e depois a publicação autorizada

1. No Clipador, exporte um corte em 9:16. Abra **Preparar Reel** no editor ou na página do Instagram. Revise o MP4 local, selecione a conta, escreva a legenda e as hashtags e escolha um horário futuro. O Studio aceita MP4 vertical de 3 segundos a 15 minutos e até 300 MB. [Especificações de Reels](https://developers.facebook.com/documentation/instagram-platform/instagram-graph-api/reference/ig-user/media#reels-specs)
2. Confira as três confirmações, incluindo direitos de uso do vídeo e do áudio e autorização de publicação na conta e no horário escolhidos. Clique em **Aprovar e agendar**. Com `AI_SHORTS_INSTAGRAM_PUBLISH=0`, valide a conta de destino e o horário na fila sem enviar o vídeo.
3. Para testar um envio real, escolha um Reel de sua autoria, revise as filas das duas contas e autorize explicitamente o envio. Encerre o painel. Na mesma sessão PowerShell, ajuste `$env:AI_SHORTS_INSTAGRAM_PUBLISH = '1'` e rode `.\scripts\iniciar-fase1.ps1`. Mantenha o computador ligado, o Studio aberto e a internet disponível até o resultado aparecer no histórico.
4. O Studio usa a API oficial para enviar o MP4 diretamente do computador à Meta. Caso o resultado fique incerto, use **Verificar na Meta** no histórico ou confira o perfil de destino. Se perdeu o horário por mais de 30 minutos, reabra o rascunho e aprove um novo agendamento. [Publicação e envio direto de Reels](https://developers.facebook.com/documentation/instagram-platform/content-publishing)

## Testes automatizados

Os testes usam tokens fictícios, respostas simuladas da Meta e mídia sintética. Para executar no Windows com o ambiente instalado, rode:

```powershell
. .\scripts\ambiente-fase1.ps1
Push-Location $autoclipRoot
try { & $pythonExe -m pytest -q tests/test_studio_instagram.py } finally { Pop-Location }
```
