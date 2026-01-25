# tools/nextdns/nextdns.ps1
# Menu de Gerenciamento NextDNS - HP-Scripts

$baseUrl = "get.hpinfo.com.br/tools/nextdns"

function Show-NextDNSMenu {
    do {
        Clear-Host
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "       GERENCIAMENTO NEXTDNS - HP-INFO    " -ForegroundColor White -BackgroundColor Blue
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "1. Instalar NextDNS (Completo)"
        Write-Host "2. Restaurar DNS Padrão"
        Write-Host "3. Reparar Instalação"
        Write-Host "4. Remover Configurações HPTI"
        Write-Host "5. Voltar ao Menu Principal"
        Write-Host "==========================================" -ForegroundColor Cyan
        
        $escolha = Read-Host "Escolha uma opção"

        switch ($escolha) {
            "1" { Write-Host "Iniciando Instalação..." -ForegroundColor Yellow; irm "$baseUrl/install" | iex }
            "2" { Write-Host "Restaurando DNS..." -ForegroundColor Yellow; irm "$baseUrl/dns_padrão" | iex }
            "3" { Write-Host "Reparando..." -ForegroundColor Yellow; irm "$baseUrl/reparar_nextdns" | iex }
            "4" { Write-Host "Removendo HPTI..." -ForegroundColor Yellow; irm "$baseUrl/remover_hpti" | iex }
            "5" { return }
            default { Write-Warning "Opção Inválida!"; Start-Sleep -Seconds 2 }
        }
    } while ($escolha -ne "5")
}

Show-NextDNSMenu
