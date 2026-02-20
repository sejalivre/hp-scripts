<#
.SYNOPSIS
    Instalacao de Updates do Windows via PSWindowsUpdate
#>

# Verificacao de administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    exit
}

$ErrorActionPreference = "Continue"

Write-Host "=== INSTALACAO DE UPDATES ===" -ForegroundColor Cyan
Write-Host ""

# Reiniciar servicos
Write-Host "Reiniciando servicos..." -ForegroundColor Yellow
$services = @("wuauserv", "bits", "cryptsvc", "msiserver")

foreach ($svc in $services) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "  $svc OK" -ForegroundColor Green
    }
    catch {
        Write-Host "  $svc ignorado" -ForegroundColor Yellow
    }
}

Write-Host ""

# Instalar PSWindowsUpdate
Write-Host "Verificando PSWindowsUpdate..." -ForegroundColor Yellow
try {
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber
        Write-Host "Modulo instalado!" -ForegroundColor Green
    } else {
        Write-Host "Modulo ja instalado" -ForegroundColor Green
    }
}
catch {
    Write-Host "ERRO ao instalar modulo: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Executar Windows Update
Write-Host "Buscando atualizacoes..." -ForegroundColor Cyan
try {
    Import-Module PSWindowsUpdate
    $updates = Get-WindowsUpdate -MicrosoftUpdate
    
    if ($updates.Count -eq 0) {
        Write-Host "Nenhuma atualizacao disponivel!" -ForegroundColor Green
    } else {
        Write-Host "Encontradas $($updates.Count) atualizacoes" -ForegroundColor Yellow
        Get-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -IgnoreReboot
        Write-Host "Atualizacoes instaladas!" -ForegroundColor Green
    }
}
catch {
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== CONCLUIDO ===" -ForegroundColor Cyan
Read-Host "Pressione ENTER"
