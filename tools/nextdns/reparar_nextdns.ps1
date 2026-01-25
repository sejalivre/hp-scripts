# reparar_nextdns.ps1 - Manutenção e Auto-Recuperação HPTI
# Versão: 1.3.0 | Foco: Restauração Completa de Binários

Write-Host "--- INICIANDO VERIFICAÇÃO DE SAÚDE HPTI ---" -ForegroundColor Cyan

# --- CONFIGURAÇÕES DE INFRAESTRUTURA (URLs Absolutas) ---
$repoBase   = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$dnsBase    = "$repoBase/nextdns"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipExe    = "$tempDir\7z.exe"
$nextDnsZip = "$tempDir\nextdns.7z"
$extractDir = "$tempDir\nextdns_extracted"

# --- 1. VERIFICAÇÃO DO SERVIÇO (AUTO-REINSTALAÇÃO SE NECESSÁRIO) ---
$svc = Get-Service -Name "NextDNS" -ErrorAction SilentlyContinue
if ($null -eq $svc) {
    Write-Warning "[ALERTA] Serviço NextDNS não encontrado. Iniciando Recuperação de Binários..."
    
    # Garante pastas para o processo de recuperação [cite: 66]
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
    if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }

    # Baixa motor de extração se necessário [cite: 67]
    if (-not (Test-Path $7zipExe)) {
        Write-Host " -> Preparando motor de extração..." -ForegroundColor Gray
        Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe" -UseBasicParsing
        Copy-Item -Path "$tempDir\7z.txe" -Destination $7zipExe -Force
    }

    # Baixa e Extrai o pacote completo [cite: 68, 69]
    Write-Host " -> Baixando e Extraindo pacote de reparo..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "$dnsBase/nextdns.7z" -OutFile $nextDnsZip -UseBasicParsing
    $argumentos = "x `"$nextDnsZip`" -o`"$extractDir`" -p`"0`" -y"
    Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow

    # Executa a reinstalação silenciosa [cite: 70]
    $InstallerPath = Join-Path $extractDir "NextDNSSetup-3.0.13.exe"
    if (Test-Path $InstallerPath) {
        Write-Host " -> Restaurando serviço NextDNS..." -ForegroundColor Cyan
        Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=3a495c" -Wait
    }
} elseif ($svc.Status -ne "Running") {
    Write-Host " -> Iniciando serviço NextDNS que estava parado..." -ForegroundColor Yellow
    Start-Service -Name "NextDNS"
}

# --- 2. MANUTENÇÃO DE REDE (DHCP) ---
Write-Host " -> Garantindo DHCP nas placas de rede..." -ForegroundColor Gray
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($nic in $adapters) {
    Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
}

# --- 3. RE-APLICAÇÃO DO CERTIFICADO ---
$CertPath = Join-Path $extractDir "NextDNS.cer" # Usa o que foi extraído ou baixa se sumiu
if (-not (Test-Path $CertPath)) {
    Invoke-WebRequest -Uri "$dnsBase/NextDNS.cer" -OutFile $CertPath -UseBasicParsing
}
$certStore = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*NextDNS*" }
if (-not $certStore) {
    Write-Host " -> Restaurando certificado ausente..." -ForegroundColor Yellow
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
}

# --- 4. VERIFICAÇÃO DE OCULTAÇÃO (STEALTH) ---
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

# --- 5. SINCRONIZAÇÃO FINAL ---
try {
    Invoke-WebRequest -Uri "https://link-ip.nextdns.io/3a495c/97a2d3980330d01a" -UseBasicParsing | Out-Null
} catch {}
ipconfig /flushdns | Out-Null

Write-Host "--- VERIFICAÇÃO CONCLUÍDA ---" -ForegroundColor Green
