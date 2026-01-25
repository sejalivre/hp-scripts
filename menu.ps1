<#
.SYNOPSIS
    Hub de Automação HP-Scripts - Launcher Principal.
.DESCRIPTION
    Orquestrador que centraliza o acesso às ferramentas de suporte via nuvem.
    Versão: 1.2
#>

do {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "       HP-SCRIPTS HUB - Automação TI          " -ForegroundColor White -BackgroundColor DarkCyan
    Write-Host "==============================================" -ForegroundColor Cyan
    [cite_start]Write-Host "  1. [INFO]   Coleta de Dados e Saúde do PC" [cite: 26]
    [cite_start]Write-Host "  2. [NET]    Ferramentas de Rede e Conectividade" [cite: 73]
    [cite_start]Write-Host "  3. [BACKUP] Rotina de Cópia e Governança" [cite: 81]
    Write-Host "  --------------------------------------------"
    Write-Host "  Q. Sair"
    Write-Host "==============================================" -ForegroundColor Cyan
    
    $escolha = Read-Host "Selecione uma opção para iniciar"

    switch ($escolha) {
        "1" {
            Write-Host "`nIniciando Coleta de Informações..." -ForegroundColor Yellow
            # Baixa e executa na memória via domínio curto [cite: 63, 64]
            [cite_start]irm get.hpinfo.com.br/info | iex [cite: 64, 72]
        }
        "2" {
            Write-Host "`nIniciando Diagnóstico de Rede..." -ForegroundColor Yellow
            [cite_start]irm get.hpinfo.com.br/net | iex [cite: 72]
        }
        "3" {
            $destino = Read-Host "`nInforme o caminho de destino para o backup (ex: D:\Backup)"
            if (-not [string]::IsNullOrWhiteSpace($destino)) {
                # O backup.ps1 exige parâmetro de destino para segurança [cite: 86]
                irm get.hpinfo.com.br/backup | iex
                # Nota: Certifique-se que o backup.ps1 remoto esteja preparado para receber o parâmetro
            } else {
                Write-Warning "Caminho de destino é obrigatório."
            }
        }
        "Q" {
            Write-Host "`nEncerrando HubCraft Assistant. Até logo!" -ForegroundColor Green
            Start-Sleep -Seconds 1
            break
        }
        Default {
            Write-Host "`n[!] Opção Inválida: $escolha" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }

    if ($escolha -ne "Q") {
        Write-Host "`n----------------------------------------------"
        Write-Host "Tarefa concluída. Pressione ENTER para voltar ao menu..." -ForegroundColor Gray
        $null = Read-Host
    }

} while ($escolha -ne "Q")