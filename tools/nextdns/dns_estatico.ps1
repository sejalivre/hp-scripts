#requires -RunAsAdministrator
<#
.SYNOPSIS
    Configura DNS Estático do NextDNS nas placas de rede
.DESCRIPTION
    Configura os servidores DNS IPv4 e IPv6 do NextDNS em todas as interfaces de rede ativas.
    Garante que o bloqueio funcione corretamente ao nível da placa de rede.
.NOTES
    Versão: 1.0
    Autor: HP-Scripts
#>

# --- VERIFICAÇÃO DE ADMINISTRADOR ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "       CONFIGURANDO DNS ESTÁTICO DO NEXTDNS               " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# --- CONFIGURAÇÃO DOS SERVIDORES DNS NEXTDNS ---
$NextDNSv4 = @("45.90.28.188", "45.90.30.188")
$NextDNSv6 = @("2a07:a8c0::3a:495c", "2a07:a8c1::3a:495c")

Write-Host "Servidores DNS IPv4: $($NextDNSv4 -join ', ')" -ForegroundColor Gray
Write-Host "Servidores DNS IPv6: $($NextDNSv6 -join ', ')" -ForegroundColor Gray
Write-Host ""

# --- APLICAR DNS NOS ADAPTADORES ---
try {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($adapters.Count -eq 0) {
        Write-Warning "Nenhuma placa de rede ativa encontrada!"
        Start-Sleep -Seconds 3
        Exit
    }

    Write-Host "Placas de rede encontradas: $($adapters.Count)" -ForegroundColor Green
    Write-Host ""

    foreach ($nic in $adapters) {
        Write-Host " -> Configurando: $($nic.Name)" -ForegroundColor Yellow -NoNewline
        
        try {
            # Configurar DNS IPv4
            Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ServerAddresses $NextDNSv4 -ErrorAction Stop
            
            # Configurar DNS IPv6 (ignora erro se IPv6 não disponível)
            Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ServerAddresses $NextDNSv6 -ErrorAction SilentlyContinue
            
            Write-Host " [OK]" -ForegroundColor Green
        }
        catch {
            Write-Host " [FALHA]" -ForegroundColor Red
            Write-Warning "Erro em $($nic.Name): $($_.Exception.Message)"
        }
    }

    Write-Host ""
    Write-Host " -> Limpando cache DNS..." -ForegroundColor Gray
    ipconfig /flushdns | Out-Null
    
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor Green
    Write-Host "   DNS DO NEXTDNS CONFIGURADO COM SUCESSO!                 " -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "===========================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "O bloqueio de DNS agora está ativo nesta máquina." -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "[ERRO] Falha ao configurar DNS: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Start-Sleep -Seconds 3
}

Start-Sleep -Seconds 3
