@echo off
:: ================================================================
::  HPCRAFT - Versao Portatil (Pendrive)
::  Inicializador do Menu Principal
:: ================================================================
title HPCRAFT - Hub de Automacao TI (Portatil)
color 0A

:: Verifica se esta rodando como administrador 
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [AVISO] Este script precisa ser executado como Administrador!
    echo.
    echo Clique com o botao direito e selecione "Executar como administrador"
    echo.
    pause
    exit /b 1
)

:: Define o diretorio do script como diretorio de trabalho
cd /d "%~dp0"

:: Verifica se o PowerShell existe
where powershell.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] PowerShell nao encontrado!
    pause
    exit /b 1
)

:: Executa o menu principal
echo.
echo [*] Iniciando HPCRAFT - Versao Portatil...
echo.

:: Verifica se o arquivo menu.ps1 existe
if not exist "%~dp0menu.ps1" (
    echo [ERRO] O arquivo menu.ps1 nao foi encontrado!
    echo Cerifique-se de que o INICIAR.cmd e o menu.ps1 estao na mesma pasta.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0menu.ps1"

pause