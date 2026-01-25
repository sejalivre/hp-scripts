<#
.SYNOPSIS
    Script de Manutenção e Autocorreção HPTI - NextDNS (Versão Auto-Reparável)
.DESCRIPTION
    1. Verifica e baixa dependências (7zip, Certificado, Instalador) se faltarem.
    2. Verifica se o serviço NextDNS está rodando. Se não, tenta reinstalar/iniciar.
    3. Reseta placas para DHCP (permite que o Agente NextDNS assuma).
    4. Garante que o NextDNS esteja oculto no Painel de Controle.
    5. Atualiza o IP vinculado (DDNS).
#>

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

# --- CONFIGURAÇÕES DE INFRAESTRUTURA (Baseado no Install) ---
$repoBase      = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir       = "$env:TEMP\HP-Tools"
$7zipExe       = "$tempDir\7z.exe"
$extractDir    = "$tempDir\nextdns_extracted"
$HptiDir       = "$env:ProgramFiles\HPTI"
$CertPath      = Join-Path $HptiDir "NextDNS.cer"
$NextDNS_ID    = "3a495c"
$InstallerName = "NextDNSSetup-3.0.13.exe"
$InstallerPath = Join-Path $HptiDir $InstallerName

# Garante que as pastas de trabalho existem
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }

Write-Host "--- INICIANDO VERIFICAÇÃO DE SAÚDE HPTI ---" -ForegroundColor Cyan

# --- 1. DOWNLOAD DE DEPENDÊNCIAS (Modelo Install) ---
if (-not (Test-Path $7zipExe)) {
    Write-Host " -> Recuperando motor de extração..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe" -UseBasicParsing
    Copy-Item -Path "$tempDir\7z.txe" -Destination $7zipExe -Force
}

# Se o Certificado ou Instalador sumiram da pasta HPTI, baixa o pacote novamente
if (-not (Test-Path $CertPath) -or -not (Test-Path $InstallerPath)) {
    Write-Host " -> Recuperando arquivos base do repositório..." -ForegroundColor Yellow
    $nextDnsZip = "$tempDir\nextdns.7z"
    Invoke-WebRequest -Uri "$repoBase/nextdns.7z" -OutFile $nextDnsZip -UseBasicParsing
    
    # Extrai para a pasta temporária
    $argumentos = "x `"$nextDnsZip`" -o`"$extractDir`" -p`"0`" -y"
    Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow
    
    # Move para a pasta permanente HPTI
    Copy-Item -Path "$extractDir\NextDNS.cer" -Destination $CertPath -Force
    Copy-Item -Path "$extractDir\$InstallerName" -Destination $InstallerPath -Force
}

# --- 2. VERIFICAR SERVIÇO ---
$Service = Get-Service | Where-Object { $_.DisplayName -like "*NextDNS*" -or $_.Name -like "*NextDNS*" } | Select-Object -First 1

if ($Service) {
    if ($Service.Status -ne "Running") {
        Write-Host "[CORREÇÃO] Iniciando serviço NextDNS..." -ForegroundColor Yellow
        Start-Service -InputObject $Service
    } else {
        Write-Host "[OK] Serviço NextDNS rodando." -ForegroundColor Green
    }
} else {
    Write-Warning "[ALERTA] Serviço não encontrado. Tentando reinstalação silenciosa..."
    if (Test-Path $InstallerPath) {
        Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=$NextDNS_ID" -Wait
    }
}

# --- 3. CONFIGURAÇÃO DE REDE (DHCP/AUTO) ---
Write-Host " -> Validando placas de rede (DHCP)..." -ForegroundColor Gray
try {
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($nic in $Adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] DNS em modo Automático." -ForegroundColor Green
} catch {
    Write-Warning "Falha ao resetar DNS."
}

# --- 4. INSTALAR CERTIFICADO ---
if (Test-Path $CertPath) {
    Write-Host " -> Verificando certificado..." -ForegroundColor Gray
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
}

# --- 5. GARANTIR OCULTAÇÃO NO PAINEL ---
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

# --- 6. ATUALIZAR IP (DDNS) ---
try {
    Invoke-WebRequest -Uri "https://link-ip.nextdns.io/3a495c/97a2d3980330d01a" -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Host "[OK] IP vinculado atualizado." -ForegroundColor Green
} catch {
    Write-Warning "Não foi possível atualizar o IP (Sem conexão?)."
}

# --- 7. LIMPEZA FINAL ---
Invoke-Expression -Command "ipconfig /flushdns"
Write-Host "--- VERIFICAÇÃO CONCLUÍDA ---" -ForegroundColor White
Start-Sleep -Seconds 3
