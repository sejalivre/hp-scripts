<#
.SYNOPSIS
    Launcher Principal HP-Scripts - Hub de Automação Profissional.
.DESCRIPTION
    Versão 1.5 - Compatibilidade com Windows 10 antigo (1507+).
.NOTES
    Requer PowerShell 3.0+ (incluído em todas as versões do Windows 10)
#>

# ============================================================
# BLOCO DE COMPATIBILIDADE - Windows 10 Antigo
# ============================================================

# Verificação de Versão do PowerShell
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "[ERRO] Este script requer PowerShell 3.0 ou superior." -ForegroundColor Red
    Write-Host "Versão detectada: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Atualize o PowerShell antes de continuar." -ForegroundColor Gray
    Read-Host "Pressione ENTER para sair"
    exit 1
}

# Configuração de TLS 1.2 (Essencial para HTTPS em Windows 10 1507/1511)
try {
    # Método primário (PowerShell 5.0+)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
catch {
    try {
        # Fallback para versões antigas
        [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    }
    catch {
        Write-Warning "Não foi possível forçar TLS 1.2. Conexões HTTPS podem falhar."
    }
}

# Configuração de Origem 
$baseUrl = "get.hpinfo.com.br"

# 1. Definição das Ferramentas
$ferramentas = @(
    @{ ID = "CHECK"   ; Desc = "Verificações Rápidas e Integridade" ; Path = "check" ; Color = "Yellow" }
    @{ ID = "PERF"    ; Desc = "Análise e Score de Performance"        ; Path = "perf"  ; Color = "Gray" }
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
        Write-Host "      Suporte: docs.hpinfo.com.br | v1.4                  " -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        # 2. Renderização Dinâmica do Menu
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
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

        # 3. Lógica de Execução
        $idx = 0 
        if ([int]::TryParse($escolha, [ref]$idx) -and $idx -le $ferramentas.Count -and $idx -gt 0) {
            $selecionada = $ferramentas[$idx - 1]
            $cor = if ($selecionada.Color) { $selecionada.Color } else { "White" }
            
            Write-Host "`n[🚀] Iniciando $($selecionada.ID)..." -ForegroundColor $cor
            
            # Montagem da URL
            $finalUrl = if ($selecionada.External) { 
                $selecionada.Path 
            }
            else { 
                "https://$baseUrl/$($selecionada.Path)" 
            }
            
            try {
                # --- CORREÇÃO AQUI ---
                # Em vez de 'irm | iex', baixamos para um arquivo temporário e executamos.
                $TempScript = "$env:TEMP\HPTI_Exec_$($selecionada.ID).ps1"
                
                Invoke-WebRequest -Uri $finalUrl -OutFile $TempScript -UseBasicParsing
                
                if (Test-Path $TempScript) {
                    # Executa o arquivo baixado
                    & $TempScript
                    
                    # Remove após execução para manter limpo
                    Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
                }
                else {
                    throw "Arquivo não foi baixado corretamente."
                }
                # ---------------------
            }
            catch {
                Write-Host "`n[❌] ERRO: Falha na execução remota." -ForegroundColor Red
                Write-Host "URL: $finalUrl" -ForegroundColor Gray
                Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Warning "Opção inválida!"
            Start-Sleep -Seconds 1
        }
        
        Write-Host "`nPressione qualquer tecla para voltar..." -ForegroundColor Gray
        
        # Compatibilidade: ReadKey() não funciona em ISE ou sessões remotas
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