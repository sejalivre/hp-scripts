# reparar_nextdns.ps1 - Manutenção Automática HPTI
# Versão: 1.2.0 | Foco: Zero Dependência Local

Write-Host "--- INICIANDO VERIFICAÇÃO DE SAÚDE HPTI ---" -ForegroundColor Cyan

# --- CONFIGURAÇÕES DE INFRAESTRUTURA ---
$repoBase = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$dnsBase  = "$repoBase/nextdns"
$tempDir  = "$env:TEMP\HP-Tools"
$CertPath = "$tempDir\NextDNS.cer"

# 1. Verificação do Serviço
$svc = Get-Service -Name "NextDNS" -ErrorAction SilentlyContinue
if ($null -eq $svc) {
    Write-Warning "[ALERTA] O serviço NextDNS não foi encontrado."
    Write-Host " -> Tentando restaurar via instalador silencioso..." -ForegroundColor Yellow
    # Aqui ele chama o seu instalador da web para corrigir o serviço
    irm "get.hpinfo.com.br/nextdns/install" | iex
} elseif ($svc.Status -ne "Running") {
    Write-Host " -> Iniciando serviço NextDNS parado..." -ForegroundColor Yellow
    Start-Service -Name "NextDNS"
}

# 2. Restauração do Certificado (Sem usar PSScriptRoot)
if (-not (Test-Path $CertPath)) {
    Write-Host " -> Baixando certificado para verificação..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "$dnsBase/NextDNS.cer" -OutFile $CertPath -UseBasicParsing
}

if (Test-Path $CertPath) {
    $certStore = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*NextDNS*" }
    if (-not $certStore) {
        Write-Host " -> Reinstalando certificado ausente..." -ForegroundColor Yellow
        Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    }
}

# 3. Limpando Placas de Rede (DHCP)
Write-Host " -> Definindo placas de rede para Automático (DHCP)..." -ForegroundColor Gray
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($nic in $adapters) {
    Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
}

# 4. Validação de Ocultação
Write-Host " -> Validando ocultação do programa..." -ForegroundColor Gray
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

# 5. DDNS e Flush
Write-Host " -> Atualizando IP e Limpando Cache..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "https://link-ip.nextdns.io/3a495c/97a2d3980330d01a" -UseBasicParsing | Out-Null
} catch {}
ipconfig /flushdns | Out-Null

Write-Host "--- VERIFICAÇÃO CONCLUÍDA ---" -ForegroundColor Green
