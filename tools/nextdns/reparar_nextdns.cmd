@echo off
setlocal EnableDelayedExpansion
Title Manutencao HPTI - NextDNS Repair (Robust Mode)

:: --- 1. VERIFICACAO DE ADMIN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Precisa de Admin.
    pause
    
)

:: --- CONFIGS ---
set "DNS1=45.90.28.122"
set "DNS2=45.90.30.122"
set "DNS6_1=2a07:a8c0::3a:495c"
set "DNS6_2=2a07:a8c1::3a:495c"

echo === INICIANDO REPARO E CHECKUP HPTI (V2) ===
echo.

:: --- 2. LOCALIZAR O NOME REAL DO SERVICO ---
echo [CHECK] Identificando o servico NextDNS no sistema...

set "SERVICE_NAME="
:: Usa WMIC para buscar qualquer servico que tenha 'NextDNS' no nome visivel
for /f "tokens=2 delims==" %%A in ('wmic service where "DisplayName like '%%NextDNS%%'" get Name /value 2^>nul ^| find "="') do set "SERVICE_NAME=%%A"

:: Se nao achou pelo DisplayName, tenta achar pelo Name direto
if "!SERVICE_NAME!"=="" (
    sc query "NextDNS" >nul 2>&1
    if !errorlevel! equ 0 set "SERVICE_NAME=NextDNS"
)

if "!SERVICE_NAME!"=="" (
    echo [ERRO CRITICO] O servico NextDNS nao foi encontrado instalado!
    echo Sugestao: Rode o instalador novamente.
) else (
    echo [INFO] Servico identificado como ID: "!SERVICE_NAME!"
    
    :: --- 3. VERIFICAR STATUS E INICIAR ---
    sc query "!SERVICE_NAME!" | find /i "RUNNING" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [CORRECAO] O servico estava parado. Iniciando...
        net start "!SERVICE_NAME!" >nul 2>&1
        if !errorlevel! equ 0 (
            echo    - [SUCESSO] Servico iniciado.
        ) else (
            echo    - [FALHA] Nao foi possivel iniciar o servico.
        )
    ) else (
        echo [OK] O servico ja esta rodando.
    )
)

:: --- 4. REFORCAR DNS (Blindagem) ---
echo.
echo [CHECK] Reforcando DNS nas placas de rede...
REM for /f "tokens=3,*" %%i in ('netsh interface show interface ^| findstr "Conectad"') do (
REM     set "IFACE_NAME=%%j"
    
    :: IPv4
REM     netsh interface ip set dns name="!IFACE_NAME!" static %DNS1% validate=no >nul 2>&1
REM     netsh interface ip add dns name="!IFACE_NAME!" %DNS2% index=2 validate=no >nul 2>&1
    
    :: IPv6
REM     netsh interface ipv6 set dns name="!IFACE_NAME!" static %DNS6_1% validate=no >nul 2>&1
REM     netsh interface ipv6 add dns name="!IFACE_NAME!" %DNS6_2% index=2 validate=no >nul 2>&1
    
REM    echo    - DNS validado em: "!IFACE_NAME!"
REM )

:: ==========================================
:: 8. GARANTIR REDE LIMPA (DHCP)
:: ==========================================
REM Em vez de chumbar IP, vamos deixar automatico para o Agente NextDNS assumir.
REM Isso garante que o HOSTNAME apareca nos logs.

echo [INFO] Definindo placas de rede para Automatico (DHCP)...
for /f "tokens=3,*" %%i in ('netsh interface show interface ^| findstr "Conectad"') do (
    set "IFACE_NAME=%%j"
    echo    - Limpando DNS da interface: "!IFACE_NAME!"
    netsh interface ip set dns name="!IFACE_NAME!" source=dhcp >nul 2>&1
    netsh interface ipv6 set dns name="!IFACE_NAME!" source=dhcp >nul 2>&1
)

:: --- 5. VERIFICAR OCULTACAO (REGISTRO) ---
echo.
echo [CHECK] Verificando ocultacao no registro...

set "REG_PATH_1=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
set "REG_PATH_2=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

call :CheckAndFixHide "%REG_PATH_1%"
call :CheckAndFixHide "%REG_PATH_2%"

:: --- 6. LIMPEZA ---
echo.
echo [MANUTENCAO] Limpando cache DNS...
ipconfig /flushdns >nul

echo.
echo === PROCESSO FINALIZADO ===
timeout /t 3 >nul


:: --- ATUALIZAR IP VINCULADO ---
echo.
echo [MANUTENCAO] Atualizando IP no NextDNS...
curl "https://link-ip.nextdns.io/3a495c/97a2d3980330d01a" >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] IP Sincronizado.
) else (
    REM Fallback para Windows antigos que nao tem curl, usando powershell
    powershell -Command "Invoke-WebRequest 'https://link-ip.nextdns.io/3a495c/97a2d3980330d01a' -UseBasicParsing" >nul 2>&1
)


:: --- INSTALAR CERTIFICADO (OPCIONAL) ---
if exist "%~dp0NextDNS.cer" (
    echo [INFO] Instalando certificado de bloqueio HPTI...
    certutil -addstore -f "Root" "%~dp0NextDNS.cer" >nul
)

:: SUB-ROTINA
:CheckAndFixHide
for /f "tokens=*" %%a in ('reg query "%~1" 2^>nul') do (
    reg query "%%a" /v DisplayName 2>nul | find "NextDNS" >nul
    if !errorlevel! equ 0 (
        reg query "%%a" /v SystemComponent 2>nul | find "0x1" >nul
        if !errorlevel! neq 0 (
            echo [CORRECAO] Ocultando NextDNS em %%a...
            reg add "%%a" /v SystemComponent /t REG_DWORD /d 1 /f >nul
        ) else (
             echo [OK] Ocultacao validada.
        )
    )
)
goto :eof