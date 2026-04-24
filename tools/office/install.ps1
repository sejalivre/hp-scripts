<#
.SYNOPSIS
    Script de Instalação do Microsoft Office via URL Customizada - HPCRAFT
.DESCRIPTION
    Realiza o download e execução do instalador do Office a partir de um link fornecido.
#>

param(
    [string]$DownloadUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365AppsBasicRetail&platform=x64&language=pt-br&version=O16GA"
)

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

# Configuração de encoding para caracteres especiais
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "       INSTALADOR MICROSOFT OFFICE - HP-SCRIPTS            " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    Write-Host " [ERRO] Nenhuma URL de download fornecida." -ForegroundColor Red
    Start-Sleep -Seconds 3
    Exit
}

$tempDir = "$env:TEMP\HP-Tools"
$setupExe = Join-Path $tempDir "OfficeSetup.exe"

# 1. Garante que a pasta temporária existe
if (-not (Test-Path $tempDir)) { 
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null 
}

# 2. Download do Instalador
try {
    Write-Host " -> Baixando instalador do Office..." -ForegroundColor Yellow
    Write-Host " -> URL: $DownloadUrl" -ForegroundColor Gray
    
    # Remove arquivo antigo se existir
    if (Test-Path $setupExe) { Remove-Item $setupExe -Force }
    
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $setupExe -UseBasicParsing -ErrorAction Stop
    
    Write-Host " [OK] Download concluído." -ForegroundColor Green
}
catch {
    Write-Host " [ERRO] Falha ao baixar o instalador: $($_.Exception.Message)" -ForegroundColor Red
    Start-Sleep -Seconds 5
    Exit
}

# 3. Execução da Instalação
if (Test-Path $setupExe) {
    Write-Host " -> Iniciando instalação..." -ForegroundColor Cyan
    Write-Host " [NOTA] O Office será instalado em segundo plano." -ForegroundColor Gray
    Write-Host " [NOTA] Acompanhe o progresso pela janela oficial do Office." -ForegroundColor Gray
    
    try {
        Start-Process -FilePath $setupExe -Wait -ErrorAction Stop
        Write-Host " [OK] O instalador foi finalizado." -ForegroundColor Green
    }
    catch {
        Write-Host " [ERRO] Falha ao executar o instalador: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Cleanup
    Write-Host " -> Limpando arquivos temporários..." -ForegroundColor Gray
    Remove-Item $setupExe -Force -ErrorAction SilentlyContinue
}
else {
    Write-Host " [ERRO] Instalador não encontrado após o download." -ForegroundColor Red
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "       PROCESSO DE INSTALAÇÃO FINALIZADO                   " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "===========================================================" -ForegroundColor Cyan
Start-Sleep -Seconds 3
