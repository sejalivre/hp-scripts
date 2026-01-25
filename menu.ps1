<#
.SYNOPSIS
    Launcher Principal HP-Scripts - Hub de Automação Profissional.
.DESCRIPTION
    Orquestrador dinâmico que utiliza Lazy Loading para ferramentas de TI.
    Versão: 1.3.1 (Correção de Escopo e URL) 
#>

# Configuração de Origem 
$baseUrl = "get.hpinfo.com.br"

# 1. Definição das Ferramentas (Fácil de adicionar novos itens aqui!) 
$ferramentas = @(
    @{ ID = "CHECK"   ; Desc = "Verificações Rápidas e Integridade" ; Path = "check" ; Color = "Yellow" }
    @{ ID = "INFO"    ; Desc = "Coleta de Dados (Hardware/OS)"       ; Path = "info"  ; Color = "Yellow" }
    @{ ID = "REDE"    ; Desc = "Reparo de Rede e Conectividade"      ; Path = "net"   ; Color = "Yellow" }
    @{ ID = "PRINT"   ; Desc = "Módulo de Impressão"                 ; Path = "print" ; Color = "Yellow" }
    @{ ID = "UPDATE"  ; Desc = "Atualizações do Sistema"             ; Path = "update"; Color = "Yellow" }
    @{ ID = "BACKUP"  ; Desc = "Rotina de Backup de Usuário"         ; Path = "backup"; Color = "Yellow" }
    @{ ID = "HORA"    ; Desc = "Sincronizando Horário"               ; Path = "hora"  ; Color = "Yellow" }
    @{ ID = "LIMP"    ; Desc = "Limpeza de Arquivos Temporários"     ; Path = "limp"  ; Color = "Yellow" }
    @{ ID = "ATIV"    ; Desc = "Ativação (get.activated.win)"        ; Path = "https://get.activated.win" ; External = $true }
    @{ ID = "WALL"    ; Desc = "Configurar Wallpaper Padrão"         ; Path = "wallpaper" ; Color = "Magenta" }
    @{ ID = "NEXTDNS" ; Desc = "Gerenciamento NextDNS"               ; Path = "tools/nextdns/nextdns" ; Color = "Yellow" }
)

function Show-MainMenu {
    do {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "             HPCRAFT - HUB DE AUTOMAÇÃO TI                " -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "      Suporte: docs.hpinfo.com.br | v1.3.1                " -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        # 2. Renderização Dinâmica do Menu
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
            # Formatação alinhada: número com 2 espaços, ID com 7 espaços
            Write-Host ("{0,2}. [{1,-7}] {2}" -f $n, $item.ID, $item.Desc)
        }

        Write-Host "----------------------------------------------------------"
        Write-Host "Q. Sair"
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        $escolha = Read-Host "Selecione uma opção"

        if ($escolha -eq "Q" -or $escolha -eq "q") { 
            Write-Host "`nEncerrando..." -ForegroundColor Green
            break 
        }

        # 3. Lógica de Execução Dinâmica com Tratamento de Erro
        $idx = 0  # Inicializa para evitar o erro de [ref]
        if ([int]::TryParse($escolha, [ref]$idx) -and $idx -le $ferramentas.Count -and $idx -gt 0) {
            $selecionada = $ferramentas[$idx - 1]
            $cor = if ($selecionada.Color) { $selecionada.Color } else { "White" }
            
            Write-Host "`n[🚀] Iniciando $($selecionada.ID)..." -ForegroundColor $cor
            
            # Montagem da URL (Trata caminhos externos e internos)
            $finalUrl = if ($selecionada.External) { 
                $selecionada.Path 
            } else { 
                "https://$baseUrl/$($selecionada.Path)" 
            }
            
            try {
                # Download e Execução em memória
                irm $finalUrl | iex
            } catch {
                Write-Host "`n[❌] ERRO: Não foi possível carregar o script." -ForegroundColor Red
                Write-Host "URL: $finalUrl" -ForegroundColor Gray
                Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Warning "Opção '$escolha' inválida! Escolha um número entre 1 e $($ferramentas.Count) ou 'Q'."
            Start-Sleep -Seconds 2
            continue
        }
        
        Write-Host "`nTarefa finalizada. Pressione qualquer tecla para voltar..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    } while ($true)
}

# Inicia o script
Show-MainMenu