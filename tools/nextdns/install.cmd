@echo off
setlocal EnableDelayedExpansion
Title Instalador HPTI - NextDNS (Modo Oculto + Flush)

:: ==========================================
:: 1. VERIFICACAO DE ADMINISTRADOR
:: ==========================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo =====================================================
    echo  ERRO: Este script precisa ser executado como ADMIN.
    echo  Clique com o botao direito e "Executar como Administrador".
    echo =====================================================
    echo.
    pause
    exit
)

:: ==========================================
:: 2. CONFIGURACOES E VARIAVEIS
:: ==========================================
set "INSTALLER_NAME=NextDNSSetup-3.0.13.exe"
set "NEXTDNS_ID=3a495c"
set "INSTALLER_PATH=%~dp0%INSTALLER_NAME%"
:: URL de IP Vinculado (Da sua imagem)
set "LINK_IP_URL=https://link-ip.nextdns.io/3a495c/97a2d3980330d01a"

:: DNS IPv4
set "DNS1=45.90.28.122"
set "DNS2=45.90.30.122"
:: DNS IPv6
set "DNS6_1=2a07:a8c0::3a:495c"
set "DNS6_2=2a07:a8c1::3a:495c"

:: ==========================================
:: 3. INSTALACAO DO AGENTE
:: ==========================================
if exist "%INSTALLER_PATH%" (
    echo [INFO] Iniciando instalacao silenciosa do NextDNS (ID: %NEXTDNS_ID%)...
    start /wait "" "%INSTALLER_PATH%" /S /ID=%NEXTDNS_ID%
    echo [OK] Instalacao concluida.
) else (
    echo [ERRO] O arquivo %INSTALLER_NAME% nao foi encontrado.
    pause
    exit
)

:: ==========================================
:: 4. AGUARDAR REGISTRO (CRUCIAL)
:: ==========================================
echo.
echo [INFO] Aguardando 15 segundos para o Windows criar os registros...
timeout /t 15 /nobreak >nul

:: ==========================================
:: 5. OCULTAR DO ADICIONAR/REMOVER PROGRAMAS
:: ==========================================
echo [INFO] Ocultando NextDNS do Painel de Controle...
set "REG_PATH_1=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
set "REG_PATH_2=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
call :OcultarNextDNS "%REG_PATH_1%"
call :OcultarNextDNS "%REG_PATH_2%"

:: ==========================================
:: 6. INSTALAR CERTIFICADO (OPCIONAL)
:: ==========================================
if exist "%~dp0NextDNS.cer" (
    echo [INFO] Instalando certificado de bloqueio HPTI...
    certutil -addstore -f "Root" "%~dp0NextDNS.cer" >nul
)

:: ==========================================
:: 7. ATUALIZAR IP VINCULADO (NOVO)
:: ==========================================
echo.
echo [INFO] Vinculando IP ao perfil NextDNS...
curl "%LINK_IP_URL%" >nul 2>&1

:: ==========================================
:: 8. CONFIGURACAO DE DNS (REDUNDANCIA)
:: ==========================================
echo [INFO] Configurando DNS nas placas de rede conectadas...
REM for /f "tokens=3,*" %%i in ('netsh interface show interface ^| findstr "Conectad"') do (
REM     set "IFACE_NAME=%%j"
REM     echo    - Configurando interface: "!IFACE_NAME!"
REM     netsh interface ip set dns name="!IFACE_NAME!" static %DNS1% validate=no >nul 2>&1
REM     netsh interface ip add dns name="!IFACE_NAME!" %DNS2% index=2 validate=no >nul 2>&1
REM     netsh interface ipv6 set dns name="!IFACE_NAME!" static %DNS6_1% validate=no >nul 2>&1
REM     netsh interface ipv6 add dns name="!IFACE_NAME!" %DNS6_2% index=2 validate=no >nul 2>&1
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

:: ==========================================
:: 9. AUTOMACAO DE MANUTENCAO
:: ==========================================
echo.
echo [AUTOMACAO] Configurando agendador de tarefas...

:: 9.1 Cria a pasta fixa no C:
if not exist "%ProgramFiles%\HPTI" mkdir "%ProgramFiles%\HPTI"

:: 9.2 Copia o script de reparo
copy /y "%~dp0reparar_nextdns.cmd" "%ProgramFiles%\HPTI\reparar_nextdns.cmd" >nul

:: 9.3 Cria a Tarefa Agendada
schtasks /create /tn "HPTI_NextDNS_Reparo" /tr "\"%ProgramFiles%\HPTI\reparar_nextdns.cmd\"" /sc HOURLY /mo 1 /ru SYSTEM /rl HIGHEST /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [SUCESSO] Tarefa agendada criada.
) else (
    echo [ERRO] Falha ao criar tarefa agendada.
)

:: ==========================================
:: 10. LIMPEZA FINAL
:: ==========================================
echo.
echo [INFO] Limpando Cache DNS e Reiniciando Navegadores...
ipconfig /flushdns

taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
taskkill /F /IM firefox.exe >nul 2>&1
taskkill /F /IM opera.exe >nul 2>&1

echo.
echo [SUCESSO] Processo HPTI finalizado.
echo.
timeout /t 5
exit

:: ==========================================
:: SUB-ROTINAS
:: ==========================================
:OcultarNextDNS
for /f "tokens=*" %%a in ('reg query "%~1" 2^>nul') do (
    reg query "%%a" /v DisplayName 2>nul | find "NextDNS" >nul
    if !errorlevel! equ 0 (
        reg add "%%a" /v SystemComponent /t REG_DWORD /d 1 /f >nul
    )
)
goto :eof