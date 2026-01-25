@echo off
setlocal EnableDelayedExpansion
Title HPTI - Reverter para Google DNS e Limpar

:: --- 1. VERIFICACAO DE ADMIN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Precisa de Admin.
    pause
    exit
)

echo === INICIANDO REMOCAO TOTAL HPTI ===
echo.

:: --- 1. REMOVER AGENDAMENTO ---
echo [1/5] Removendo tarefa agendada...
schtasks /delete /tn "HPTI_NextDNS_Reparo" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo    - Tarefa removida.
) else (
    echo    - Tarefa nao encontrada ou ja removida.
)

:: --- 2. DESINSTALAR SERVICO ---
echo.
echo [2/5] Removendo NextDNS...

:: Tenta rodar o desinstalador oficial silencioso
if exist "%ProgramFiles%\NextDNS\NextDNSSetup.exe" (
    echo    - Executando desinstalador oficial...
    "%ProgramFiles%\NextDNS\NextDNSSetup.exe" /S /REMOVE
    timeout /t 5 >nul
) else (
    echo    - Desinstalador nao achado. Forcando remocao manual...
    
    :: Descobre o nome do servico (NextDNS ou NextDNS Agent)
    set "SVC_NAME="
    sc query "NextDNS Agent" >nul 2>&1
    if !errorlevel! equ 0 set "SVC_NAME=NextDNS Agent"
    
    if "!SVC_NAME!"=="" (
        sc query "NextDNS" >nul 2>&1
        if !errorlevel! equ 0 set "SVC_NAME=NextDNS"
    )

    if not "!SVC_NAME!"=="" (
        net stop "!SVC_NAME!" >nul 2>&1
        sc delete "!SVC_NAME!" >nul 2>&1
        echo    - Servico "!SVC_NAME!" deletado na forca bruta.
    ) else (
        echo    - Nenhum servico encontrado.
    )
)

:: --- 3. LIMPAR ARQUIVOS ---
echo.
echo [3/5] Limpando arquivos...
if exist "%ProgramFiles%\HPTI" (
    rmdir /s /q "%ProgramFiles%\HPTI"
    echo    - Pasta HPTI deletada.
)
if exist "%ProgramFiles%\NextDNS" (
    rmdir /s /q "%ProgramFiles%\NextDNS"
)

:: --- 4. DNS DO GOOGLE ---
echo.
echo [4/5] Configurando DNS Google (8.8.8.8)...

for /f "tokens=3,*" %%i in ('netsh interface show interface ^| findstr "Conectad"') do (
    set "IFACE_NAME=%%j"
    
    REM Configura Primario 8.8.8.8
    netsh interface ip set dns name="!IFACE_NAME!" static 8.8.8.8 validate=no >nul 2>&1
    
    REM Configura Secundario 8.8.4.4
    netsh interface ip add dns name="!IFACE_NAME!" 8.8.4.4 index=2 validate=no >nul 2>&1
    
    echo    - Aplicado em: "!IFACE_NAME!"
)

:: --- 5. FLUSH ---
echo.
echo [5/5] Limpando Cache...
ipconfig /flushdns >nul

echo.
echo [CONCLUIDO] O computador esta livre do bloqueio.
timeout /t 5
exit