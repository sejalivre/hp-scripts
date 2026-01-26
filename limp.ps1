# ==========================================================
# HP Scripts - LIMP.ps1
# Limpeza Profunda e Otimização de Cache
# Executar como Administrador
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"

# ---------------- PERF (ANTES) ----------------
irm https://get.hpinfo.com.br/perf | iex

Write-Host "`n=== INICIANDO LIMPEZA PROFUNDA ===" -ForegroundColor Cyan

# ---------------- FUNÇÕES ----------------
function Remove-Safe {
    param($Path)
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------------- 1. ENCERRAR PROCESSOS ----------------
Write-Host "Encerrando processos ativos..." -ForegroundColor Yellow
$processos = @(
    "winword","excel","powerpnt","outlook",
    "chrome","msedge","firefox","brave",
    "acrord32","explorer"
)

foreach ($p in $processos) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 2

# ---------------- ESPAÇO ANTES ----------------
$espacoAntes = (Get-PSDrive C).Free

# ---------------- 2. TEMP / PREFETCH ----------------
Write-Host "Limpando arquivos temporários e Prefetch..." -ForegroundColor Yellow

$pastasLimpar = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*",
    "C:\Windows\Prefetch\*",
    "$env:APPDATA\Microsoft\Windows\Recent\*",
    "C:\Windows\Logs\*"
)

foreach ($caminho in $pastasLimpar) {
    Remove-Safe $caminho
}

# Thumbcache (tratamento especial)
$ThumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
if (Test-Path $ThumbPath) {
    Get-ChildItem $ThumbPath -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# ---------------- 3. WINDOWS UPDATE ----------------
Write-Host "Limpando cache do Windows Update..." -ForegroundColor Yellow

$servicos = @("wuauserv", "bits", "cryptsvc")

foreach ($s in $servicos) {
    Stop-Service $s -Force -ErrorAction SilentlyContinue
}

$updateFolders = @(
    "C:\Windows\SoftwareDistribution",
    "C:\Windows\System32\catroot2"
)

foreach ($folder in $updateFolders) {
    Remove-Safe "$folder\*"
}

foreach ($s in $servicos) {
    Start-Service $s -ErrorAction SilentlyContinue
}

# ---------------- 4. CACHE DE NAVEGADORES ----------------
Write-Host "Limpando cache de navegadores..." -ForegroundColor Yellow

$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
)

foreach ($path in $browserCaches) {
    Remove-Safe $path
}

# ---------------- 5. LIXEIRA / DELIVERY OPT ----------------
Write-Host "Limpando lixeira e otimização de entrega..." -ForegroundColor Yellow

Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
Remove-Safe "C:\Windows\SoftwareDistribution\DeliveryOptimization\*"

# ---------------- ESPAÇO DEPOIS ----------------
$espacoDepois = (Get-PSDrive C).Free
$totalLimpoMB = [math]::Round(($espacoDepois - $espacoAntes) / 1MB, 2)

# ---------------- RESULTADO  ----------------
Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "LIMPEZA CONCLUÍDA!" -ForegroundColor Green

if ($totalLimpoMB -gt 0) {
    Write-Host "Espaço recuperado: $totalLimpoMB MB" -ForegroundColor White
} else {
    Write-Host "O sistema já estava limpo." -ForegroundColor White
}

Write-Host "=======================================" -ForegroundColor Cyan

# ---------------- PERF (DEPOIS) ----------------
irm https://get.hpinfo.com.br/perf | iex -AfterClean

# ---------------- EXPLORER ----------------
Start-Process explorer.exe
