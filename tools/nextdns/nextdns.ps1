# tools/nextdns/nextdns.ps1
# Menu de Gerenciamento NextDNS - HP-Scripts

function Show-NextDNSMenu {
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
        "1" { 
            Write-Host "Iniciando Instalação..." -ForegroundColor Yellow
            & "$PSScriptRoot\install.ps1" 
        }
        "2" { 
            Write-Host "Restaurando DNS..." -ForegroundColor Yellow
            & "$PSScriptRoot\dns_padrão.ps1" 
        }
        "3" { 
            Write-Host "Reparando..." -ForegroundColor Yellow
            & "$PSScriptRoot\reparar_nextdns.ps1" 
        }
        "4" { 
            Write-Host "Removendo HPTI..." -ForegroundColor Yellow
            & "$PSScriptRoot\remover_hpti.ps1" 
        }
        "5" { return }
        default { Write-Warning "Opção Inválida!"; Start-Sleep -Seconds 2; Show-NextDNSMenu }
    }
}

Show-NextDNSMenu