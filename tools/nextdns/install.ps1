<#
.SYNOPSIS
    Instalador HPTI NextDNS + Flush DNS + Kill Browsers + Agendamento
#>

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

# --- CONFIGURAÇÕES DE INFRAESTRUTURA (Padrão HP-Scripts) ---
$repoBase   = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipExe    = "$tempDir\7z.exe"
$nextDnsZip = "$tempDir\nextdns.7z"
$extractDir = "$tempDir\nextdns_extracted"

# 1. Garante que as pastas existem
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }

# 2. Baixa o motor 7-Zip (se não existir) [cite: 66, 67]
if (-not (Test-Path $7zipExe)) {
    Write-Host " -> Preparando motor de extração..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe"
    Copy-Item -Path "$tempDir\7z.txe" -Destination $7zipExe -Force
}

# 3. Baixa o pacote de ferramentas NextDNS [cite: 68]
Write-Host " -> Baixando pacote NextDNS..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "$repoBase/nextdns.7z" -OutFile $nextDnsZip

# 4. Extrai o conteúdo [cite: 69]
Write-Host " -> Extraindo ferramentas..." -ForegroundColor Yellow
$argumentos = "x `"$nextDnsZip`" -o`"$extractDir`" -p`"0`" -y"
Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow

# 5. Redefine o caminho do instalador para a pasta extraída
$InstallerPath = Join-Path $extractDir "NextDNSSetup-3.0.13.exe"
$CertPath      = Join-Path $extractDir "NextDNS.cer"

# --- VARIÁVEIS GERAIS ---
$NextDNS_ID = "3a495c"
$InstallerName = "NextDNSSetup-3.0.13.exe"
$InstallerPath = Join-Path $PSScriptRoot $InstallerName
$DNS_IPv4 = @("45.90.28.122", "45.90.30.122")
$DNS_IPv6 = @("2a07:a8c0::3a:495c", "2a07:a8c1::3a:495c")
$All_DNS = $DNS_IPv4 + $DNS_IPv6

# --- 1. INSTALAÇÃO DO EXECUTÁVEL ---
if (Test-Path $InstallerPath) {
    Write-Host "Instalando NextDNS..." -ForegroundColor Yellow
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=$NextDNS_ID" -PassThru -Wait
} else {
    Write-Error "Arquivo $InstallerName nao encontrado!"
    Pause; Exit
}

# --- 2. INSTALAÇÃO DO CERTIFICADO (Novo) ---
$CertPath = Join-Path $PSScriptRoot "NextDNS.cer"
if (Test-Path $CertPath) {
    Write-Host "Instalando certificado de bloqueio..." -ForegroundColor Yellow
    try {
        Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    } catch {
        Write-Warning "Falha ao instalar certificado. O bloqueio funcionará, mas sem a tela personalizada."
    }
}

# --- 3. DNS NAS PLACAS ---
<# Write-Host "Configurando IPs DNS..." -ForegroundColor Yellow
try {
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($nic in $Adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ServerAddresses $All_DNS -ErrorAction SilentlyContinue
    }
} catch {}
#>
# --- 4. AGUARDAR E OCULTAR DO PAINEL ---
Write-Host "Aguardando registro e ocultando..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
$uninstallPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")

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

# --- 5. LIMPEZA FINAL (FLUSH E KILL) ---
Write-Host "Limpando Cache DNS e Reiniciando Navegadores..." -ForegroundColor Magenta

# Limpa cache do Windows
Invoke-Expression -Command "ipconfig /flushdns"

# Fecha navegadores forçadamente
Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "firefox" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "opera" -Force -ErrorAction SilentlyContinue

Write-Host "`n[SUCESSO] NextDNS Ativo e Oculto." -ForegroundColor Green

# --- 6. BLOCO DE AUTOMAÇÃO DE MANUTENÇÃO (HPTI) ---
Write-Host "`n[AUTOMAÇÃO] Configurando reparo automático..." -ForegroundColor Cyan

# 6.1. Define e Cria a Pasta Permanente (C:\Program Files\HPTI)
$HptiDir = "$env:ProgramFiles\HPTI"
if (!(Test-Path $HptiDir)) {
    New-Item -ItemType Directory -Path $HptiDir -Force | Out-Null
}

# 6.2. Copia o script de reparo para o local seguro
$SourceScript = Join-Path $PSScriptRoot "reparar_nextdns.ps1"
$DestScript   = Join-Path $HptiDir "reparar_nextdns.ps1"

if (Test-Path $SourceScript) {
    Copy-Item -Path $SourceScript -Destination $DestScript -Force
    Write-Host " -> Script de reparo copiado para: $DestScript" -ForegroundColor Gray
} else {
    Write-Warning "AVISO: O arquivo 'reparar_nextdns.ps1' não foi encontrado na pasta do instalador. O agendamento pode falhar."
}




# 6.3. DEFINIÇÃO DA TAREFA (O que faltava)
$TaskName = "HPTI_NextDNS_Reparo"
$Action   = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestScript`""

# Gatilhos: Ao Logar e A cada 1 hora (Duração de 10 anos)
$Trigger1 = New-ScheduledTaskTrigger -AtLogOn
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60) -RepetitionDuration (New-TimeSpan -Days 3650)

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Registra a tarefa
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($Trigger1, $Trigger2) -Principal $Principal -Settings $Settings -Force | Out-Null

# --- ATUALIZAR IP VINCULADO (DDNS) ---
Write-Host "Atualizando IP vinculado no painel..." -ForegroundColor Cyan
try {
    # O parametro -UseBasicParsing garante compatibilidade com Windows antigos
    # O | Out-Null esconde o output para não sujar a tela
    Invoke-WebRequest -Uri "https://link-ip.nextdns.io/3a495c/97a2d3980330d01a" -UseBasicParsing | Out-Null
    Write-Host "[OK] IP atualizado no NextDNS." -ForegroundColor Green
} catch {
    Write-Warning "Não foi possível atualizar o IP vinculado (Sem internet?)."
}

Write-Host "[SUCESSO] Agendador configurado. O sistema será verificado a cada 60 minutos." -ForegroundColor Green

Start-Sleep -Seconds 5