<#
.SYNOPSIS
    Instalador HPTI NextDNS - Versão Final Consolidada
#>

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

# --- CONFIGURAÇÕES DE INFRAESTRUTURA (URLs Absolutas para Web) ---

$dnsBase    = "get.hpinfo.com.br/tools/nextdns"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipExe    = "$tempDir\7z.exe"
$nextDnsZip = "$tempDir\nextdns.7z"
$extractDir = "$tempDir\nextdns_extracted"

# 1. Garante que as pastas existem
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }

# 2. Baixa o motor 7-Zip (Essencial para extração)
if (-not (Test-Path $7zipExe)) {
    Write-Host " -> Preparando motor de extração..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe"
    Copy-Item -Path "$tempDir\7z.txe" -Destination $7zipExe -Force
}

# 3. Baixa o pacote NextDNS do seu repositório
Write-Host " -> Baixando pacote NextDNS..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "$dnsBase/nextdns.7z" -OutFile $nextDnsZip -ErrorAction Stop

# 4. Extração Silenciosa
Write-Host " -> Extraindo ferramentas..." -ForegroundColor Yellow
$argumentos = "x `"$nextDnsZip`" -o`"$extractDir`" -p`"0`" -y"
Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow

# 5. Caminhos dos arquivos extraídos
$InstallerPath = Join-Path $extractDir "NextDNSSetup-3.0.13.exe"
$CertPath      = Join-Path $extractDir "NextDNS.cer"

# --- EXECUÇÃO DA INSTALAÇÃO ---
if (Test-Path $InstallerPath) {
    Write-Host " -> Instalando NextDNS..." -ForegroundColor Cyan
    # Instalação silenciosa com seu ID de configuração
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=3a495c" -Wait
    Write-Host "[OK] NextDNS instalado." -ForegroundColor Green
} else {
    Write-Error "ERRO: Arquivo NextDNSSetup-3.0.13.exe nao encontrado na extração!"
    return
}

# --- INSTALAÇÃO DO CERTIFICADO ---
if (Test-Path $CertPath) {
    Write-Host " -> Instalando certificado de bloqueio..." -ForegroundColor Yellow
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
}

# --- OCULTAR DO PAINEL DE CONTROLE ---
Write-Host " -> Ocultando do sistema..." -ForegroundColor Gray
Start-Sleep -Seconds 5
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

# --- LIMPEZA E FINALIZAÇÃO ---
Write-Host " -> Limpando Cache DNS..." -ForegroundColor Magenta
ipconfig /flushdns | Out-Null

# Fecha navegadores para aplicar o DNS
$browsers = @("chrome", "msedge", "firefox", "opera")
foreach ($b in $browsers) { Stop-Process -Name $b -Force -ErrorAction SilentlyContinue }

# --- AGENDAMENTO DE REPARO ---
$HptiDir = "$env:ProgramFiles\HPTI"
if (!(Test-Path $HptiDir)) { New-Item -ItemType Directory -Path $HptiDir -Force | Out-Null }

$DestScript = Join-Path $HptiDir "reparar_nextdns.ps1"
# Baixa o script de reparo direto do GitHub para a pasta final
Invoke-WebRequest -Uri "$dnsBase/reparar_nextdns.ps1" -OutFile $DestScript

# Cria a tarefa agendada
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestScript`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "HPTI_NextDNS_Reparo" -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null

Write-Host "`n[SUCESSO] NextDNS Ativo, Oculto e Agendado!" -ForegroundColor Green
Start-Sleep -Seconds 5
