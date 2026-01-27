@echo off
SETLOCAL EnableDelayedExpansion

echo ======================================================
echo   INSTALADOR/ATUALIZADOR DE POWERSHELL
echo   HP-Scripts - Verificacao e Instalacao Automatica
echo ======================================================
echo.

:: ============================================================
:: ETAPA 1: Verificar se PowerShell existe
:: ============================================================
echo [1/5] Verificando se PowerShell esta instalado...

where powershell.exe >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] PowerShell nao encontrado no sistema!
    echo [INFO] Sera necessario instalar o PowerShell.
    set PS_MISSING=1
) else (
    echo [OK] PowerShell encontrado.
    set PS_MISSING=0
)
echo.

:: ============================================================
:: ETAPA 2: Verificar versao do PowerShell (se existir)
:: ============================================================
if %PS_MISSING%==0 (
    echo [2/5] Verificando versao do PowerShell...
    
    for /f "tokens=*" %%i in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.Major"') do set PS_VERSION=%%i
    
    echo [INFO] Versao do PowerShell detectada: %PS_VERSION%
    
    if %PS_VERSION% LSS 5 (
        echo [AVISO] Versao antiga detectada (menor que 5.1)
        echo [INFO] Recomenda-se atualizar para PowerShell 7+
        set NEEDS_UPDATE=1
    ) else (
        echo [OK] Versao compativel (5.1+)
        set NEEDS_UPDATE=0
    )
) else (
    echo [2/5] Pulando verificacao de versao (PowerShell nao instalado)
    set NEEDS_UPDATE=1
)
echo.

:: ============================================================
:: ETAPA 3: Verificar se Winget esta disponivel
:: ============================================================
echo [3/5] Verificando disponibilidade do Winget...

where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Winget nao encontrado.
    echo [INFO] Tentando metodo alternativo (instalacao via MSI)...
    set USE_WINGET=0
) else (
    echo [OK] Winget disponivel.
    set USE_WINGET=1
)
echo.

:: ============================================================
:: ETAPA 4: Instalar ou Atualizar PowerShell
:: ============================================================
echo [4/5] Processando instalacao/atualizacao...

if %USE_WINGET%==1 (
    :: Metodo 1: Usando Winget (preferencial)
    echo [INFO] Usando Winget para gerenciar PowerShell 7...
    
    winget list --id Microsoft.PowerShell --exact >nul 2>nul
    
    if %ERRORLEVEL% EQU 0 (
        echo [INFO] PowerShell 7 ja instalado. Verificando atualizacoes...
        winget upgrade --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
        
        if %ERRORLEVEL% EQU 0 (
            echo [OK] PowerShell 7 atualizado com sucesso.
        ) else (
            echo [INFO] Nenhuma atualizacao disponivel ou ja esta na versao mais recente.
        )
    ) else (
        echo [INFO] PowerShell 7 nao encontrado. Instalando...
        winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
        
        if %ERRORLEVEL% EQU 0 (
            echo [OK] PowerShell 7 instalado com sucesso.
        ) else (
            echo [ERRO] Falha ao instalar PowerShell 7 via Winget.
            set USE_WINGET=0
            goto :FALLBACK_METHOD
        )
    )
) else (
    :FALLBACK_METHOD
    :: Metodo 2: Instalacao via script web (fallback)
    echo [INFO] Usando metodo alternativo (download direto da Microsoft)...
    
    if %PS_MISSING%==1 (
        echo [ERRO] PowerShell nao esta instalado e Winget nao esta disponivel.
        echo [INFO] Por favor, instale o PowerShell manualmente:
        echo        https://aka.ms/powershell-release?tag=stable
        goto :ERROR_EXIT
    )
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& {try {Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://aka.ms/install-powershell.ps1')); Install-PowerShell -UseMSI -Quiet} catch {Write-Host '[ERRO] Falha no download/instalacao'; exit 1}}"
    
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Instalacao via script web concluida.
    ) else (
        echo [ERRO] Falha na instalacao alternativa.
        echo [INFO] Tente instalar manualmente: https://aka.ms/powershell-release?tag=stable
        goto :ERROR_EXIT
    )
)
echo.

:: ============================================================
:: ETAPA 5: Verificacao Final
:: ============================================================
echo [5/5] Verificacao final...

where pwsh.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] PowerShell 7 (pwsh.exe) detectado no sistema.
    
    for /f "tokens=*" %%i in ('pwsh -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') do set PWSH_VERSION=%%i
    echo [INFO] Versao instalada: PowerShell %PWSH_VERSION%
) else (
    echo [INFO] PowerShell 7 nao detectado no PATH (pode requerer reinicio).
)

echo.
echo ======================================================
echo   PROCESSO CONCLUIDO
echo ======================================================
echo.
echo [IMPORTANTE] Se esta foi a primeira instalacao:
echo   - Reinicie o terminal ou computador
echo   - Use 'pwsh' para abrir PowerShell 7
echo.
echo Para executar o menu principal:
echo   irm get.hpinfo.com.br/menu ^| iex
echo.
echo ======================================================

pause
exit /b 0

:ERROR_EXIT
echo.
echo ======================================================
echo   ERRO: Instalacao nao concluida
echo ======================================================
pause
exit /b 1
