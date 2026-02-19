# ==========================================
# RESTAURAR DNS PADRÃO (DHCP)
# ==========================================
# Este script remove configurações de DNS estático e restaura para DHCP.
# Isso garante que o agente NextDNS possa assumir o controle do DNS.

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " RESTAURANDO DNS PADRÃO (DHCP)                            " -ForegroundColor White
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Definindo placas de rede para Automático (DHCP)..." -ForegroundColor Yellow

try {
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($Adapters.Count -eq 0) {
        Write-Warning "Nenhum adaptador de rede ativo encontrado!"
        Start-Sleep -Seconds 3
        return
    }

    foreach ($nic in $Adapters) {
        Write-Host "    -> Limpando DNS da interface: $($nic.Name)" -ForegroundColor Gray
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "[OK] DNS restaurado para DHCP em $($Adapters.Count) interface(s)." -ForegroundColor Green
    
    Write-Host "Limpando cache DNS..." -ForegroundColor Gray
    ipconfig /flushdns | Out-Null
    Write-Host "[OK] Cache DNS limpo." -ForegroundColor Green
    
}
catch {
    Write-Warning "Erro ao resetar o DNS para DHCP: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "[OK] Operação concluída." -ForegroundColor Green
Start-Sleep -Seconds 2
