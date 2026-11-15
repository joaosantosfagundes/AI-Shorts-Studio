param([switch]$Renovar)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ambiente-fase1.ps1')

if (-not (Test-Path -LiteralPath $pythonExe -PathType Leaf)) {
    throw 'Execute scripts/instalar-fase1.ps1 primeiro.'
}

$certificateArgs = @('-m', 'autoclip.instagram.tls', $metaTlsDir)
if ($Renovar) { $certificateArgs += '--renew' }
& $pythonExe @certificateArgs
if ($LASTEXITCODE -ne 0) { throw 'Falha ao preparar o HTTPS local.' }

Write-Host 'Para confiar no certificado no seu perfil do Windows, rode o comando abaixo uma vez.'
$publicCert = (Join-Path $metaTlsDir "$metaLocalHostname.cer").Replace("'", "''")
Write-Host "Import-Certificate -FilePath '$publicCert' -CertStoreLocation 'Cert:\CurrentUser\Root'"
Write-Host 'Depois inicie o painel com scripts/iniciar-fase1.ps1.'
