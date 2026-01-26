<#
.SYNOPSIS
    Instalador HPTI NextDNS + Flush DNS + Kill Browsers + Agendamento + DDNS
    Versão 1.1 - Com seleção de ID Dinâmico
#>

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

# --- SOLICITAÇÃO DE ID DO CLIENTE ---
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      CONFIGURAÇÃO NEXTDNS HPTI           " -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
$NextDNS_ID = Read-Host "Digite o ID do Cliente NextDNS (ex: 3a495c)"

if ([string]::IsNullOrWhiteSpace($NextDNS_ID)) {
    Write-Error "O ID não pode ser vazio. Cancelando."
    Start-Sleep -Seconds 3
    Exit
}
Write-Host " -> ID Definido: $NextDNS_ID" -ForegroundColor Green
Start-Sleep -Seconds 2

# --- CONFIGURAÇÕES DE INFRAESTRUTURA (URLs Absolutas para evitar 404) ---
$repoBase   = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$dnsBase    = "$repoBase/nextdns"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipExe    = "$tempDir\7z.exe"
$nextDnsZip = "$tempDir\nextdns.7z"
$extractDir = "$tempDir\nextdns_extracted"

# 1. Garante que as pastas existem
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }

# 2. Baixa o motor 7-Zip (se não existir)
if (-not (Test-Path $7zipExe)) {
    Write-Host " -> Preparando motor de extração..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe" -UseBasicParsing
    Copy-Item -Path "$tempDir\7z.txe" -Destination $7zipExe -Force
}

# 3. Baixa o pacote NextDNS do seu repositório
Write-Host " -> Baixando pacote NextDNS..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "$dnsBase/nextdns.7z" -OutFile $nextDnsZip -ErrorAction Stop -UseBasicParsing

# 4. Extração Silenciosa
Write-Host " -> Extraindo ferramentas..." -ForegroundColor Yellow
$argumentos = "x `"$nextDnsZip`" -o`"$extractDir`" -p`"0`" -y"
Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow

# 5. Caminhos dos arquivos extraídos
$InstallerPath = Join-Path $extractDir "NextDNSSetup-3.0.13.exe"
$CertPath      = Join-Path $extractDir "NextDNS.cer"

# --- EXECUÇÃO DA INSTALAÇÃO (COM ID DINÂMICO) ---
if (Test-Path $InstallerPath) {
    Write-Host " -> Instalando NextDNS para o ID: $NextDNS_ID..." -ForegroundColor Cyan
    # Aqui usamos o ID digitado pelo usuário
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=$NextDNS_ID" -Wait
    Write-Host "[OK] Executável instalado." -ForegroundColor Green
} else {
    Write-Error "ERRO: Instalador não encontrado na extração!"
    return
}

# --- INSTALAÇÃO DO CERTIFICADO ---
if (Test-Path $CertPath) {
    Write-Host " -> Instalando certificado de bloqueio..." -ForegroundColor Yellow
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    Write-Host "[OK] Certificado importado." -ForegroundColor Green
}

# --- OCULTAR DO PAINEL DE CONTROLE (SystemComponent) ---
Write-Host " -> Ocultando do Painel de Controle..." -ForegroundColor Gray
Start-Sleep -Seconds 5
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($path in $uninstallPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path | ForEach-Object {
            $displayName = Get-ItemProperty -Path $_.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue
            if ($displayName.DisplayName -like "*NextDNS*") {
                New-ItemProperty -Path $_.PSPath -Name "SystemComponent" -Value 1 -PropertyType DWORD -Force | Out-Null
            }
        }
    }
}

# --- LIMPEZA E FINALIZAÇÃO DE REDE ---
Write-Host " -> Limpando Cache DNS e reiniciando navegadores..." -ForegroundColor Magenta
ipconfig /flushdns | Out-Null

$browsers = @("chrome", "msedge", "firefox", "brave", "opera")
foreach ($b in $browsers) { Stop-Process -Name $b -Force -ErrorAction SilentlyContinue }

# --- AGENDAMENTO DA TAREFA DE REPARO ---
Write-Host " -> Configurando tarefa agendada de reparo..." -ForegroundColor Cyan
$HptiDir = "$env:ProgramFiles\HPTI"
if (!(Test-Path $HptiDir)) { New-Item -ItemType Directory -Path $HptiDir -Force | Out-Null }

$DestScript = Join-Path $HptiDir "reparar_nextdns.ps1"
# Baixa o script de reparo para a pasta permanente
Invoke-WebRequest -Uri "$dnsBase/reparar_nextdns.ps1" -OutFile $DestScript -UseBasicParsing

# PATCH DINÂMICO: Atualiza o ID dentro do script de reparo baixado para o ID atual
if (Test-Path $DestScript) {
    (Get-Content $DestScript).Replace('3a495c', $NextDNS_ID) | Set-Content $DestScript
}

$TaskName = "HPTI_NextDNS_Reparo"
$Action   = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestScript`""
$Trigger1 = New-ScheduledTaskTrigger -AtLogOn
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60) -RepetitionDuration (New-TimeSpan -Days 3650)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($Trigger1, $Trigger2) -Principal $Principal -Settings $Settings -Force | Out-Null

# --- ATUALIZAR IP VINCULADO (DDNS) ---
Write-Host " -> Atualizando IP vinculado no painel NextDNS..." -ForegroundColor Cyan
try {
    # Tenta atualizar usando o ID novo. 
    # Nota: Se o Token (parte final da URL) for diferente para o novo cliente, isso pode falhar.
    $DDNS_URL = "https://link-ip.nextdns.io/$NextDNS_ID/97a2d3980330d01a"
    Invoke-WebRequest -Uri $DDNS_URL -UseBasicParsing | Out-Null
    Write-Host "[OK] IP Vinculado ($NextDNS_ID)." -ForegroundColor Green
} catch {
    Write-Warning "Não foi possível atualizar o IP no painel (Verifique se o Token DDNS é compatível)."
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "   INSTALAÇÃO HPTI CONCLUÍDA COM SUCESSO!  " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "==========================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5
