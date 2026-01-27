<#
.SYNOPSIS
    Instalador HPTI NextDNS + Flush DNS + Kill Browsers + Agendamento + DDNS
.DESCRIPTION
    Versão 2.0 - Suporte a ID Dinâmico com Persistência
#>

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "       INSTALADOR NEXTDNS - HP-INFO (HPTI)                " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# --- CONFIGURAÇÃO DO ID NEXTDNS ---
$HptiDir = "$env:ProgramFiles\HPTI"
$ConfigFile = "$HptiDir\config.txt"
$NextDNS_ID = ""

# Tenta ler ID do arquivo de configuração existente
if (Test-Path $ConfigFile) {
    $NextDNS_ID = Get-Content $ConfigFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($NextDNS_ID) {
        Write-Host "[INFO] ID encontrado no arquivo de configuração: $NextDNS_ID" -ForegroundColor Green
        $confirma = Read-Host "Deseja usar este ID? (S/N, Enter=Sim)"
        if ($confirma -and $confirma -notmatch '^[sS]?$') {
            $NextDNS_ID = ""
        }
    }
}

# Se não tem ID válido, solicita ao técnico
if (-not $NextDNS_ID) {
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor Yellow
    Write-Host " CONFIGURAÇÃO DO ID NEXTDNS                               " -ForegroundColor Yellow
    Write-Host "===========================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "O ID NextDNS é necessário para configurar o bloqueio." -ForegroundColor Gray
    Write-Host "Você pode encontrar seu ID em: https://my.nextdns.io" -ForegroundColor Gray
    Write-Host "Exemplo de ID: abc123 (6 caracteres)" -ForegroundColor Gray
    Write-Host ""
    
    do {
        $NextDNS_ID = Read-Host "Digite o ID do NextDNS"
        
        # Validação básica: 6 caracteres alfanuméricos
        if ($NextDNS_ID -match '^[a-zA-Z0-9]{6}$') {
            Write-Host "[OK] ID válido: $NextDNS_ID" -ForegroundColor Green
            break
        }
        else {
            Write-Warning "ID inválido! Deve conter exatamente 6 caracteres alfanuméricos."
            Write-Host "Tente novamente ou pressione Ctrl+C para cancelar." -ForegroundColor Gray
        }
    } while ($true)
    
    # Salva o ID no arquivo de configuração
    if (-not (Test-Path $HptiDir)) { 
        New-Item -ItemType Directory -Path $HptiDir -Force | Out-Null 
    }
    $NextDNS_ID | Out-File -FilePath $ConfigFile -Encoding ASCII -Force
    Write-Host "[OK] ID salvo em: $ConfigFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Iniciando instalação com ID: $NextDNS_ID" -ForegroundColor White
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# --- CONFIGURAÇÕES DE INFRAESTRUTURA (URLs Absolutas para evitar 404) ---
$repoBase = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$dnsBase = "$repoBase/nextdns"
$tempDir = "$env:TEMP\HP-Tools"
$7zipExe = "$tempDir\7z.exe"
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
$CertPath = Join-Path $extractDir "NextDNS.cer"

# --- EXECUÇÃO DA INSTALAÇÃO ---
if (Test-Path $InstallerPath) {
    Write-Host " -> Instalando NextDNS Silenciosamente com ID: $NextDNS_ID..." -ForegroundColor Cyan
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=$NextDNS_ID" -Wait
    Write-Host "[OK] Executável instalado com sucesso." -ForegroundColor Green
}
else {
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

$TaskName = "HPTI_NextDNS_Reparo"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestScript`""
$Trigger1 = New-ScheduledTaskTrigger -AtLogOn
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60) -RepetitionDuration (New-TimeSpan -Days 3650)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($Trigger1, $Trigger2) -Principal $Principal -Settings $Settings -Force | Out-Null

# --- ATUALIZAR IP VINCULADO (DDNS) ---
Write-Host " -> Atualizando IP vinculado no painel NextDNS..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "https://link-ip.nextdns.io/$NextDNS_ID/97a2d3980330d01a" -UseBasicParsing | Out-Null
    Write-Host "[OK] IP vinculado com sucesso (ID: $NextDNS_ID)." -ForegroundColor Green
}
catch {
    Write-Warning "Não foi possível atualizar o IP no painel. Verifique sua conexão."
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "   INSTALAÇÃO HPTI CONCLUÍDA COM SUCESSO!  " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "==========================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5
