@echo off
SETLOCAL EnableDelayedExpansion

echo ======================================================
echo   Verificador de Versao do PowerShell (Core)
echo ======================================================

:: Verifica se o Winget esta disponivel
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Winget nao encontrado. Certifique-se de que a Loja Windows esta atualizada.
    echo Tentando instalacao via script web alternativo...
    powershell -Command "& {iex ((New-Object System.Net.WebClient).DownloadString('https://aka.ms/install-powershell.ps1')) -UseMSI -Quiet}"
    pause
    exit /b
)

:: Verifica se o PowerShell 7 ja esta instalado
winget list --id Microsoft.PowerShell --exact >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo [INFO] PowerShell 7 detectado. Verificando atualizacoes...
    winget upgrade --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
    echo [OK] Processo de atualizacao concluido.
) else (
    echo [INFO] PowerShell 7 nao encontrado. Iniciando instalacao...
    winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
    echo [OK] Instalacao concluida.
)

echo ======================================================
echo Operacao finalizada!
pause