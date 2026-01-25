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