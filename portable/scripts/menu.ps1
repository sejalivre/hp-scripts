<#
.SYNOPSIS
    HPCRAFT - Menu Portátil (Pendrive)
.DESCRIPTION
    Versão offline que executa scripts diretamente do pendrive.
    Não requer conexão com internet.
.NOTES
    Versão Portátil 1.0
#>

# ============================================================
# CONFIGURAÇÃO DO DIRETÓRIO BASE (PORTÁTIL)
# ============================================================

# Detecta automaticamente o diretório onde o script está
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PortableRoot = Split-Path -Parent $ScriptDir

# Configuração de TLS 1.2 (caso precise de conexão eventual)
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
catch {
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    }
    catch {}
}

# Definição das Ferramentas
$ferramentas = @(
    @{ ID = "CHECK"      ; Desc = "Verificações Rápidas e Integridade" ; Script = "check.ps1" ; Color = "Yellow" }
    @{ ID = "SFC"        ; Desc = "Diagnóstico e Reparação Completa"   ; Script = "sfc.ps1"   ; Color = "Red" }
    @{ ID = "WINFORGE"   ; Desc = "Instalação e Otimização do Sistema" ; Script = "winforge.ps1" ; Color = "Magenta" }
    @{ ID = "LIMP"       ; Desc = "Limpeza de Arquivos Temporários"    ; Script = "limp.ps1"  ; Color = "Yellow" }
    @{ ID = "UPDATE"     ; Desc = "Atualizações do Sistema"            ; Script = "update.ps1"; Color = "Yellow" }
    @{ ID = "HORA"       ; Desc = "Sincronizando Horário"              ; Script = "hora.ps1"  ; Color = "Yellow" }
    @{ ID = "REDE"       ; Desc = "Reparo de Rede e Conectividade"     ; Script = "net.ps1"   ; Color = "Yellow" }
    @{ ID = "PRINT"      ; Desc = "Módulo de Impressão"                ; Script = "print.ps1" ; Color = "Yellow" }
    @{ ID = "BACKUP"     ; Desc = "Rotina de Backup de Usuário"        ; Script = "backup.ps1"; Color = "Yellow" }
    @{ ID = "WALL"       ; Desc = "Configurar Wallpaper Padrão"        ; Script = "wallpaper.ps1" ; Color = "Magenta" }
)

function Show-MainMenu {
    do {
        Clear-Host
        Write-Host "===========================================================" -ForegroundColor Cyan
        Write-Host "       HPCRAFT - HUB DE AUTOMAÇÃO TI (PORTÁTIL)            " -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "  [PENDRIVE] Executando de: $PortableRoot" -ForegroundColor DarkGray
        Write-Host "  Suporte: docs.hpinfo.com.br | v1.0 Portable              " -ForegroundColor Gray
        Write-Host "===========================================================" -ForegroundColor Cyan
        
        # Renderização do Menu  
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
            Write-Host ("{0,2}. [{1,-11}] {2}" -f $n, $item.ID, $item.Desc)
        }

        Write-Host "----------------------------------------------------------"
        Write-Host "Q. Sair"
        Write-Host "===========================================================" -ForegroundColor Cyan
        
        $escolha = Read-Host "Selecione uma opção"

        if ($escolha -eq "Q" -or $escolha -eq "q") { 
            Write-Host "`nEncerrando..." -ForegroundColor Green
            break 
        }

        # Lógica de Execução
        $idx = 0 
        if ([int]::TryParse($escolha, [ref]$idx) -and $idx -le $ferramentas.Count -and $idx -gt 0) {
            $selecionada = $ferramentas[$idx - 1]
            $cor = if ($selecionada.Color) { $selecionada.Color } else { "White" }
            
            Write-Host "`n[🚀] Iniciando $($selecionada.ID)..." -ForegroundColor $cor
            
            $scriptPath = Join-Path $ScriptDir $selecionada.Script
            
            if (Test-Path $scriptPath) {
                try {
                    # Executar script local
                    & $scriptPath
                }
                catch {
                    Write-Host "`n[❌] ERRO: Falha na execução." -ForegroundColor Red
                    Write-Host "Script: $scriptPath" -ForegroundColor Gray
                    Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Host "`n[❌] ERRO: Script não encontrado!" -ForegroundColor Red
                Write-Host "Caminho: $scriptPath" -ForegroundColor Gray
            }
        }
        else {
            Write-Warning "Opção inválida!"
            Start-Sleep -Seconds 1
        }
        
        Write-Host "`nPressione qualquer tecla para voltar..." -ForegroundColor Gray
        
        if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
            try {
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            catch {
                Read-Host "Pressione ENTER para continuar"
            }
        }
        else {
            Read-Host "Pressione ENTER para continuar"
        }

    } while ($true)
}

Show-MainMenu