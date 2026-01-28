# ==========================================
# RESTAURAR DNS PADRÃO (DHCP)
# ==========================================
# Este script remove configurações de DNS estático e restaura para DHCP.
# Isso garante que o agente NextDNS possa assumir o controle do DNS.

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " RESTAURANDO DNS PADRÃO (DHCP)                            " -ForegroundColor White
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Definindo placas de rede para Automático (DHCP)..." -ForegroundColor Yellow

try {
    # Pega apenas adaptadores conectados (Status = Up)
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($Adapters.Count -eq 0) {
        Write-Warning "Nenhum adaptador de rede ativo encontrado!"
        Start-Sleep -Seconds 3
        return
    }

    foreach ($nic in $Adapters) {
        Write-Host "    -> Limpando DNS da interface: $($nic.Name)" -ForegroundColor Gray
        
        # O parâmetro -ResetServerAddresses remove qualquer DNS estático (IPv4 e IPv6)
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "[OK] DNS restaurado para DHCP em $($Adapters.Count) interface(s)." -ForegroundColor Green
    
    # Limpa cache DNS
    Write-Host "Limpando cache DNS..." -ForegroundColor Gray
    ipconfig /flushdns | Out-Null
    Write-Host "[OK] Cache DNS limpo." -ForegroundColor Green
    
}
catch {
    Write-Warning "Erro ao resetar o DNS para DHCP: $_"
}

Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")