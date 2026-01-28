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

# Configurar tratamento de erros
$ErrorActionPreference = "Continue"
$errosEncontrados = 0

Write-Host "`n=== INICIANDO LIMPEZA PROFUNDA ===" -ForegroundColor Cyan

# 1. Encerrar processos comuns
Write-Host "Encerrando processos ativos..." -ForegroundColor Yellow
$processos = @(
    "winword", "excel", "powerpnt", "outlook",
    "chrome", "msedge", "firefox", "brave",
    "acrord32", "explorer"
)
foreach ($p in $processos) {
    try {
        Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorar erros ao encerrar processos
    }
}
Start-Sleep -Seconds 2

# Espaço antes
try {
    $espacoAntes = (Get-PSDrive C -ErrorAction Stop).Free
}
catch {
    Write-Host "Aviso: Não foi possível calcular espaço inicial" -ForegroundColor Yellow
    $espacoAntes = 0
}

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
    try {
        # Expandir wildcards para verificar se existem arquivos
        $itens = Get-Item $caminho -ErrorAction SilentlyContinue
        if ($itens) {
            Remove-Item $caminho -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Continuar mesmo se houver erro
        $errosEncontrados++
    }
}

# 3. Windows Update
Write-Host "Limpando cache do Windows Update..." -ForegroundColor Yellow
$servicos = "wuauserv", "bits", "cryptsvc"
foreach ($s in $servicos) {
    try {
        $servico = Get-Service $s -ErrorAction SilentlyContinue
        if ($servico -and $servico.Status -ne "Stopped") {
            Stop-Service $s -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }
    }
    catch {
        Write-Host "Aviso: Não foi possível parar o serviço $s" -ForegroundColor Yellow
        $errosEncontrados++
    }
}

$updateFolders = "C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2"
foreach ($folder in $updateFolders) {
    try {
        if (Test-Path $folder) {
            $itens = Get-ChildItem "$folder\*" -ErrorAction SilentlyContinue
            if ($itens) {
                Remove-Item "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Host "Aviso: Não foi possível limpar $folder" -ForegroundColor Yellow
        $errosEncontrados++
    }
}

foreach ($s in $servicos) {
    try {
        $servico = Get-Service $s -ErrorAction SilentlyContinue
        if ($servico -and $servico.Status -eq "Stopped") {
            Start-Service $s -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Ignorar erros ao reiniciar serviços
    }
}

# 4. Cache de navegadores
Write-Host "Limpando cache de navegadores..." -ForegroundColor Yellow
$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
)
foreach ($path in $browserCaches) {
    try {
        $itens = Get-Item $path -ErrorAction SilentlyContinue
        if ($itens) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Continuar mesmo se houver erro
        $errosEncontrados++
    }
}

# 5. Lixeira e Delivery Optimization
Write-Host "Limpando lixeira e otimização de entrega..." -ForegroundColor Yellow

# Clear-RecycleBin só existe no PowerShell 5.0+
if ($PSVersionTable.PSVersion.Major -ge 5) {
    try {
        Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Aviso: Não foi possível limpar a lixeira" -ForegroundColor Yellow
    }
}
else {
    # Fallback para versões antigas usando COM
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        $recycleBin.Items() | ForEach-Object { 
            try {
                Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue 
            }
            catch {
                # Ignorar erros individuais
            }
        }
    }
    catch {
        Write-Host "Aviso: Não foi possível limpar a lixeira" -ForegroundColor Yellow
    }
}

$doPath = "C:\Windows\SoftwareDistribution\DeliveryOptimization"
try {
    if (Test-Path $doPath) {
        $itens = Get-ChildItem "$doPath\*" -ErrorAction SilentlyContinue
        if ($itens) {
            Remove-Item "$doPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Host "Aviso: Não foi possível limpar Delivery Optimization" -ForegroundColor Yellow
}

# 6. Estatísticas finais
try {
    $espacoDepois = (Get-PSDrive C -ErrorAction Stop).Free
    $totalLimpoMB = [math]::Round(($espacoDepois - $espacoAntes) / 1MB, 2)
}
catch {
    Write-Host "Aviso: Não foi possível calcular espaço recuperado" -ForegroundColor Yellow
    $totalLimpoMB = "N/A"
}

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "LIMPEZA CONCLUÍDA!" -ForegroundColor Green
if ($totalLimpoMB -ne "N/A") {
    Write-Host "Espaço recuperado: $totalLimpoMB MB" -ForegroundColor White
}
if ($errosEncontrados -gt 0) {
    Write-Host "Avisos: $errosEncontrados itens não puderam ser limpos" -ForegroundColor Yellow
}
Write-Host "=======================================" -ForegroundColor Cyan

# Restaurar Explorer
try {
    Start-Process explorer.exe -ErrorAction SilentlyContinue
}
catch {
    Write-Host "Aviso: Não foi possível reiniciar o Explorer" -ForegroundColor Yellow
}
