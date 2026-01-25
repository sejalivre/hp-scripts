<#
.SYNOPSIS
    Menu de Gerenciamento NextDNS - HP-Scripts
.DESCRIPTION
    Submenu dedicado para instalação, reparo e remoção do NextDNS.
    Padronizado com a arquitetura do menu principal v1.3.1.
    Documentação: docs.hpinfo.com.br
#>

function Show-NextDNSMenu {
    # --- ESCUDO DE ESCOPO ---
    # Movemos as variáveis para DENTRO da função. 
    # Assim elas são locais e não sobrescrevem o menu principal.
    
    $localBaseUrl = "get.hpinfo.com.br/tools/nextdns"

    $tools = @(
        @{ ID = "INSTALL" ; Desc = "Instalar NextDNS (Completo)"     ; Path = "install"         ; Color = "Green" }
        @{ ID = "RESET"   ; Desc = "Restaurar DNS Padrão"            ; Path = "dns_padrão"      ; Color = "Cyan" }
        @{ ID = "REPAIR"  ; Desc = "Reparar Instalação"              ; Path = "reparar_nextdns" ; Color = "Yellow" }
        @{ ID = "REMOVE"  ; Desc = "Remover Configurações HPTI"      ; Path = "remover_hpti"    ; Color = "Red" }
    )
    # ------------------------

    do {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "             GERENCIAMENTO NEXTDNS - HP-INFO              " -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "      Suporte: docs.hpinfo.com.br | Módulo DNS            " -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        # Renderização Dinâmica do Menu
        for ($i = 0; $i -lt $tools.Count; $i++) {
            $n = $i + 1
            $item = $tools[$i]
            Write-Host ("{0,2}. [{1,-7}] {2}" -f $n, $item.ID, $item.Desc)
        }

        Write-Host "----------------------------------------------------------"
        Write-Host "V. Voltar ao Menu Principal"
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        $escolha = Read-Host "Selecione uma opção"

        if ($escolha -in "V", "v", "Q", "q") { 
            Write-Host "`nVoltando..." -ForegroundColor Gray
            break 
        }

        $idx = 0 
        if ([int]::TryParse($escolha, [ref]$idx) -and $idx -le $tools.Count -and $idx -gt 0) {
            $selecionada = $tools[$idx - 1]
            $cor = if ($selecionada.Color) { $selecionada.Color } else { "White" }
            
            Write-Host "`n[🚀] Executando: $($selecionada.Desc)..." -ForegroundColor $cor
            
            # Montagem da  URL usando a variável LOCAL
            $finalUrl = "https://$localBaseUrl/$($selecionada.Path)" 
            
            try {
                irm $finalUrl | iex
            } catch {
                Write-Host "`n[❌] ERRO: Falha ao carregar o módulo." -ForegroundColor Red
                Write-Host "URL Tentada: $finalUrl" -ForegroundColor Gray
                Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Warning "Opção '$escolha' inválida! Escolha um número entre 1 e $($tools.Count) ou 'V'."
            Start-Sleep -Seconds 1.5
            continue
        }
        
        Write-Host "`nTarefa finalizada. Pressione qualquer tecla..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    } while ($true)
}

# Inicia o submenu
Show-NextDNSMenu