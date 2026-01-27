# limp.ps1 - Limpeza Profunda e Otimização de Cache
# Executar como Administrador
# Requer: PowerShell 3.0+ (Windows 8+)

# Verifica versão do PowerShell
$requiredVersion = 3
if ($PSVersionTable.PSVersion.Major -lt $requiredVersion) {
    Write-Host "ERRO: Este script requer PowerShell $requiredVersion.0 ou superior!" -ForegroundColor Red
    Write-Host "Versão atual: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit
}

$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n=== INICIANDO LIMPEZA PROFUNDA ===" -ForegroundColor Cyan

# 1. Encerrar processos comuns
Write-Host "Encerrando processos ativos..." -ForegroundColor Yellow
$processos = @(
    "winword", "excel", "powerpnt", "outlook",
    "chrome", "msedge", "firefox", "brave",
    "acrord32", "explorer"
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
$servicos = "wuauserv", "bits", "cryptsvc"
foreach ($s in $servicos) {
    Get-Service $s -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne "Stopped" } | Stop-Service -Force
}

$updateFolders = "C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2"
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

# Clear-RecycleBin só existe no PowerShell 5.0+
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
}
else {
    # Fallback para versões antigas usando COM
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        $recycleBin.Items() | ForEach-Object { 
            Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue 
        }
    }
    catch {
        Write-Host "Aviso: Não foi possível limpar a lixeira" -ForegroundColor Yellow
    }
}

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

# Restaurar Explorer
Start-Process explorer.exe
