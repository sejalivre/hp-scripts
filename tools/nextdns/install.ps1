# install.ps1 - Instalador HPTI NextDNS
# Versão Final Consolidada (Bypass 404)

$ErrorActionPreference = "SilentlyContinue"

# --- CONFIGURAÇÕES DE INFRAESTRUTURA ---
# Link direto para a pasta tools onde ficam os binários
$repoBase   = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$dnsBase    = "$repoBase/nextdns"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipExe    = "$tempDir\7z.exe"
$nextDnsZip = "$tempDir\nextdns.7z"
$extractDir = "$tempDir\nextdns_extracted"

# 1. Garante pastas [cite: 66, 69]
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }

# 2. Motor de Extração (Baixa o 7z.txe e renomeia para .exe) 
if (-not (Test-Path $7zipExe)) {
    Write-Host " -> Preparando motor de extração..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe"
    Copy-Item -Path "$tempDir\7z.txe" -Destination $7zipExe -Force
}

# 3. Baixa o pacote NextDNS (Certifique-se que o arquivo está em tools/nextdns/nextdns.7z) 
Write-Host " -> Baixando pacote NextDNS..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "$dnsBase/nextdns.7z" -OutFile $nextDnsZip -ErrorAction Stop
} catch {
    Write-Error "ERRO 404: O arquivo nextdns.7z não foi encontrado no GitHub!"
    Write-Host "Verifique se ele está em: hp-scripts/tools/nextdns/nextdns.7z" -ForegroundColor Red
    return
}

# 4. Extração [cite: 69]
Write-Host " -> Extraindo ferramentas..." -ForegroundColor Yellow
$argumentos = "x `"$nextDnsZip`" -o`"$extractDir`" -p`"0`" -y"
Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow

# 5. Execução do Instalador Extraído [cite: 70]
$InstallerPath = Join-Path $extractDir "NextDNSSetup-3.0.13.exe"
if (Test-Path $InstallerPath) {
    Write-Host " -> Instalando NextDNS..." -ForegroundColor Cyan
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/ID=3a495c" -Wait
    Write-Host "[OK] Instalado com sucesso." -ForegroundColor Green
} else {
    Write-Error "Arquivo instalador não encontrado dentro do .7z!"
}
