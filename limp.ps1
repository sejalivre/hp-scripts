# limp.ps1 - Limpeza Profunda e Otimização de Cache
# Executar como Administrador

$ErrorActionPreference = "SilentlyContinue"

function Get-FolderSize($Path) {
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return if ($size) { $size } else { 0 }
    }
    return 0
}

Write-Host "=== INICIANDO LIMPEZA PROFUNDA ===" -ForegroundColor Cyan

# 1. Fechar Aplicativos Comuns
Write-Host "Encerrando processos ativos..." -ForegroundColor Yellow
$processos = @("winword", "excel", "powerpnt", "outlook", "chrome", "msedge", "firefox", "brave", "acrord32", "explorer")
foreach ($p in $processos) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Inicializar contador de espaço
$espacoAntes = (Get-PSDrive C).Free
$tamanhoInicialTemp = (Get-FolderSize "$env:TEMP") + (Get-FolderSize "C:\Windows\Temp")

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

# 3. Parar Serviços e Limpar Cache de Atualização (Baseado no seu update.ps1)
Write-Host "Limpando cache do Windows Update..." -ForegroundColor Yellow
$servicos = @("wuauserv", "bits", "cryptsvc")
[cite_start]foreach ($s in $servicos) { Stop-Service $s -Force } [cite: 1]

[cite_start]$updateFolders = @("C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2") [cite: 1]
foreach ($folder in $updateFolders) {
    Remove-Item -Path "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
}

[cite_start]foreach ($s in $servicos) { Start-Service $s } [cite: 1]
 
# 4. Limpeza de Cache de Navegadores (Mantendo Senhas e Favoritos)
Write-Host "Limpando cache de navegadores..." -ForegroundColor Yellow
# Chrome / Edge (Chromium)
$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
)
foreach ($path in $browserCaches) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Limpeza de Pontos Adicionais Úteis
Write-Host "Limpando lixeira e otimização de entrega..." -ForegroundColor Yellow
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
# Arquivos de Otimização de Entrega (Windows Update)
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
Write-Host "=======================================" -ForegroundColor Cyan

# Reiniciar o Explorer para o usuário
Start-Process explorer.exe


Write-Host "`nPressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")