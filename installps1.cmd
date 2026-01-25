@echo off
SETLOCAL EnableDelayedExpansion

echo ======================================================
echo   Verificador de Versao do PowerShell (Core)
echo ======================================================

:: 1. Verifica se o Winget esta disponivel
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Winget nao encontrado.
    echo Tentando instalacao via script web alternativo (MSI)...
    powershell -Command "& {iex ((New-Object System.Net.WebClient).DownloadString('https://aka.ms/install-powershell.ps1')) -UseMSI -Quiet}"
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Instalacao via Web concluida.
    ) else (
        echo [ERRO] Falha na instalacao alternativa.
    )
    goto :FINAL
)

:: 2. Se o Winget existe, verifica se o PowerShell 7 ja esta instalado
winget list --id Microsoft.PowerShell --exact >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo [INFO] PowerShell 7 detectado. Verificando atualizacoes...
    winget upgrade --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
    echo [OK] Processo de atualizacao concluido.
) else (
    echo [INFO] PowerShell 7 nao encontrado. Iniciando instalacao via Winget...
    winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
    if %ERRORLEVEL% NEQ 0 (
        echo [ERRO] Erro ao instalar via Winget.
    ) else (
        echo [OK] Instalacao concluida.
    )
)

:FINAL
echo ======================================================


REM certutil -urlcache -f https://get.hpinfo.com.br/installps1.cmd install.cmd && install.cmd


Write-Host "`nPressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")