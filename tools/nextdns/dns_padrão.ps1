# ==========================================
# 8. GARANTIR REDE LIMPA (DHCP)
# ==========================================
# Em vez de chumbar IP, vamos deixar automatico para o Agente NextDNS assumir.
# Isso garante que o HOSTNAME apareca nos logs.

Write-Host "Definindo placas de rede para Automático (DHCP)..." -ForegroundColor Yellow

try {
    # Pega apenas adaptadores conectados (Status = Up)
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

    foreach ($nic in $Adapters) {
        Write-Host "    - Limpando DNS da interface: $($nic.Name)" -ForegroundColor Gray
        
        # O parâmetro -ResetServerAddresses remove qualquer DNS estático (IPv4 e IPv6)
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
} catch {
    Write-Warning "Não foi possível resetar o DNS para DHCP: $_"
}