# limp.ps1 - Limpeza Profunda e Otimização de Cache
# Executar como Administrador

$ErrorActionPreference = "SilentlyContinue"

# ===============================
# PERF - ANTES DA LIMPEZA
# ===============================
$env:HPINFO_PERF_STAGE = "BEFORE"
irm https://get.hpinfo.com.br/perf | iex

Write-Host "`n=== INICIANDO LIMPEZA PROFUNDA ===" -ForegroundColor Cyan

# 1. Encerrar processos comuns
Write-Host "Encerrando processos ativos..." -ForegroundColor Yellow
$processos = @(
    "winword","excel","powerpnt","outlook",
    "chrome","msedge","firefox","brave",
    "acrord32","explorer"
)
foreach ($p in $processos) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force
}
Start-Sleep -Seconds 2

# Espaço antes
$espacoAntes = (Get-PSDrive C).Free

# 2. Limpeza de temporários
Write-Host "Limpando arquivos temporários e Prefetch..." -ForegroundColor Yellow
$pastasLimpar = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*",
    "C:\Windows\Prefetch\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
    "$env:APPDATA\Microsoft\Windows\Recent\*",
    "C:\Windows\Logs\*"
)

foreach ($caminho in $pastasLimpar) {
    if (Test-Path $caminho) {
        Remove-Item $caminho -Recurse -Force
    }
}

# 3. Windows Update
Write-Host "Limpando cache do Windows Update..." -ForegroundColor Yellow
$servicos = "wuauserv","bits","cryptsvc"
foreach ($s in $servicos) {
    Get-Service $s -ErrorAction SilentlyContinue | Where-Object {$_.Status -ne "Stopped"} | Stop-Service -Force
}

$updateFolders = "C:\Windows\SoftwareDistribution","C:\Windows\System32\catroot2"
foreach ($folder in $updateFolders) {
    if (Test-Path $folder) {
        Remove-Item "$folder\*" -Recurse -Force
    }
}

foreach ($s in $servicos) {
    Get-Service $s -ErrorAction SilentlyContinue | Start-Service
}

# 4. Cache de navegadores
Write-Host "Limpando cache de navegadores..." -ForegroundColor Yellow
$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
)
foreach ($path in $browserCaches) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
    }
}

# 5.  Lixeira e Delivery Optimization
Write-Host "Limpando lixeira e otimização de entrega..." -ForegroundColor Yellow
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue

$doPath = "C:\Windows\SoftwareDistribution\DeliveryOptimization"
if (Test-Path $doPath) {
    Remove-Item "$doPath\*" -Recurse -Force
}

# 6. Estatísticas finais
$espacoDepois = (Get-PSDrive C).Free
$totalLimpoMB = [math]::Round(($espacoDepois - $espacoAntes) / 1MB, 2)

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "LIMPEZA CONCLUÍDA!" -ForegroundColor Green
Write-Host "Espaço recuperado: $totalLimpoMB MB" -ForegroundColor White
Write-Host "=======================================" -ForegroundColor Cyan

# ===============================
# PERF - DEPOIS DA LIMPEZA
# ===============================
$env:HPINFO_PERF_STAGE = "AFTER"
irm https://get.hpinfo.com.br/perf | iex

# Restaurar Explorer
Start-Process explorer.exe
