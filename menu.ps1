<#
.SYNOPSIS
    Launcher Principal HP-Scripts - Hub de Automação Profissional.
.DESCRIPTION
    Orquestrador que utiliza Lazy Loading para executar ferramentas de TI via get.hpinfo.com.br.
#>

# Configuração de Origem (CDN/GitHub)
$baseUrl = "https://get.hpinfo.com.br"

function Show-MainMenu {
    do {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "             HPCRAFT - HUB DE AUTOMAÇÃO TI                " -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "      Suporte: docs.hpinfo.com.br | v1.2.1                " -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        Write-Host "1. [INFO]      Coleta de Dados (Hardware/OS)"
        Write-Host "2. [REDE]      Reparo de Rede e Conectividade"
        Write-Host "3. [PRINT]     Módulo de Impressão"
        Write-Host "4. [UPDATE]    Atualizações do Sistema"
        Write-Host "5. [BACKUP]    Rotina de Backup de Usuário"
        Write-Host "6. [HORA]      Sincronização de Horário"
        Write-Host "7. [LIMPEZA]   Limpeza de Arquivos Temporários"
        Write-Host "8. [ATIVADOR]  Ativação de Sistema (get.activated.win)"
        Write-Host "9. [WALLPAPER] Configurar Wallpaper Padrão"
        Write-Host "10.[NEXTDNS]   Gerenciamento e Reparo NextDNS"
        Write-Host "----------------------------------------------------------"
        Write-Host "Q. Sair"
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        $escolha = Read-Host "Selecione uma opção"

        switch ($escolha) {
            "1" { Write-Host "`nCarregando Info..." -ForegroundColor Yellow; irm "$baseUrl/info" | iex }
            "2" { Write-Host "`nIniciando reparo de rede..." -ForegroundColor Yellow; irm "$baseUrl/net" | iex }
            "3" { Write-Host "`nCarregando módulo de impressão..." -ForegroundColor Yellow; irm "$baseUrl/print" | iex }
            "4" { Write-Host "`nIniciando atualizações..." -ForegroundColor Yellow; irm "$baseUrl/update" | iex }
            "5" { Write-Host "`nIniciando backup..." -ForegroundColor Yellow; irm "$baseUrl/backup" | iex }
            "6" { Write-Host "`nSincronizando horário..." -ForegroundColor Yellow; irm "$baseUrl/hora" | iex }
            "7" { Write-Host "`nIniciando limpeza..." -ForegroundColor Yellow; irm "$baseUrl/limp" | iex }
            "8" { Write-Host "`nIniciando ativador..." -ForegroundColor Cyan; irm "https://get.activated.win" | iex }
            "9" { Write-Host "`nConfigurando Wallpaper..." -ForegroundColor Magenta; irm "$baseUrl/wallpaper" | iex }
            "10" { Write-Host "`nCarregando Menu NextDNS..." -ForegroundColor Yellow; irm "$baseUrl/nextdns" | iex }
            "Q" { Write-Host "`nEncerrando..." -ForegroundColor Green; break }
            Default { Write-Warning "Opção inválida!" ; Start-Sleep -Seconds 1 }
        }
        
        if ($escolha -ne "Q") { 
            Write-Host "`nTarefa finalizada. Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }

    } while ($escolha -ne "Q")
}

# Execução
Show-MainMenu
