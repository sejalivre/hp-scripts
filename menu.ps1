# Arquivo: menu.ps1
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   HP-SCRIPTS - CENTRAL DE SUPORTE        " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Exibir Informacoes do PC (info.ps1)"
Write-Host "2. Reparar Conexao de Rede (net.ps1)"
Write-Host "3. Gerenciar Impressoras (print.ps1)"
Write-Host "4. Atualizar Sistema/Drivers (update.ps1)"
Write-Host "5. Realizar Backup (backup.ps1)"
Write-Host "Q. Sair"
Write-Host ""

$escolha = Read-Host "Digite o numero da opcao"

# URL Base para facilitar manutencao
$baseUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main"

Switch ($escolha) {
    "1" {
        Write-Host "Carregando Info..." -ForegroundColor Yellow
        irm "$baseUrl/info.ps1" | iex
    }
    "2" {
        Write-Host "Iniciando reparo de rede..." -ForegroundColor Yellow
        irm "$baseUrl/net.ps1" | iex
    }
    "3" {
        Write-Host "Carregando modulo de impressao..." -ForegroundColor Yellow
        irm "$baseUrl/print.ps1" | iex
    }
    "4" {
        Write-Host "Iniciando atualizacoes..." -ForegroundColor Yellow
        irm "$baseUrl/update.ps1" | iex
    }
    "5" {
        Write-Host "Iniciando backup..." -ForegroundColor Yellow
        irm "$baseUrl/backup.ps1" | iex
    }
    "Q" {
        Write-Host "Saindo..."
        Exit
    }
    Default {
        Write-Host "Opcao Invalida." -ForegroundColor Red
    }
}