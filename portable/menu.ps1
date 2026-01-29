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
    @{ ID = "CHECK"      ; Desc = "Verificações Rápidas e Integridade" ; Path = "../scripts/check" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "SFC"        ; Desc = "Diagnóstico e Reparação Completa"   ; Path = "../scripts/sfc"   ; Color = "Red" ; IsLocalScript = $true }
    @{ ID = "INSTALLPS1" ; Desc = "Instalar/Atualizar PowerShell"   ; Path = "installps1.cmd" ; Color = "Cyan" ; IsCmd = $true }
    @{ ID = "WINFORGE"   ; Desc = "Instalação e Otimização do Sistema" ; Path = "../scripts/winforge" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "LIMP"       ; Desc = "Limpeza de Arquivos Temporários"     ; Path = "../scripts/limp"  ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "UPDATE"     ; Desc = "Atualizações do Sistema"             ; Path = "../scripts/update"; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "HORA"       ; Desc = "Sincronizando Horário"               ; Path = "../scripts/hora"  ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "REDE"       ; Desc = "Reparo de Rede e Conectividade"      ; Path = "../scripts/net"   ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "PRINT"      ; Desc = "Módulo de Impressão"                 ; Path = "../scripts/print" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "BACKUP"     ; Desc = "Rotina de Backup de Usuário"         ; Path = "../scripts/backup"; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "ATIV"       ; Desc = "Ativação (get.activated.win)"        ; Path = "https://get.activated.win" ; External = $true }
    @{ ID = "WALL"       ; Desc = "Configurar Wallpaper Padrão"         ; Path = "../scripts/wallpaper" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "NEXTDNS"    ; Desc = "Gerenciamento NextDNS"               ; Path = "../tools/nextdns/nextdns.ps1" ; Color = "Yellow" ; IsLocal = $true }
    @{ ID = "TOOLS"      ; Desc = "Menu de Ferramentas Portáteis"       ; Path = "menu_tools.ps1" ; Color = "Green" ; IsLocal = $true }
)

function Show-MainMenu {
    do {
        Clear-Host
        Write-Host ""
        Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║       🚀  HPCRAFT PORTABLE - HUB DE AUTOMAÇÃO TI  🚀         ║" -ForegroundColor Cyan
        Write-Host "  ║         Suporte: docs.hpinfo.com.br | v1.5 Portable          ║" -ForegroundColor DarkCyan
        Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        # 2. Renderização Dinâmica do Menu  
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
            Write-Host ("  {0,2}. [{1,-11}] {2}" -f $n, $item.ID, $item.Desc) -ForegroundColor White
        }

        Write-Host ""
        Write-Host "  [Q] Sair" -ForegroundColor DarkGray
        Write-Host ""
        
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
            
            # Verificar se é um arquivo .cmd (batch)
            if ($selecionada.IsCmd) {
                # Para arquivos .cmd, baixar e executar via cmd.exe
                $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                $TempCmd = "$env:TEMP\HPTI_Exec_$($selecionada.ID).cmd"
                
                try {
                    Write-Host "[INFO] Baixando instalador..." -ForegroundColor Gray
                    Invoke-WebRequest -Uri $finalUrl -OutFile $TempCmd -UseBasicParsing
                    
                    if (Test-Path $TempCmd) {
                        Write-Host "[INFO] Executando instalador..." -ForegroundColor Gray
                        # Executar o .cmd e aguardar conclusão
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$TempCmd`"" -Wait -NoNewWindow
                        
                        # Remove após execução
                        Remove-Item $TempCmd -Force -ErrorAction SilentlyContinue
                    }
                    else {
                        throw "Arquivo não foi baixado corretamente."
                    }
                }
                catch {
                    Write-Host "`n[❌] ERRO: Falha ao executar instalador." -ForegroundColor Red
                    Write-Host "URL: $finalUrl" -ForegroundColor Gray
                    Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            elseif ($selecionada.IsLocalScript) {
                # Para scripts PowerShell locais (dentro de ../scripts/)
                $scriptPath = Join-Path $PSScriptRoot "$($selecionada.Path).ps1"
                if (Test-Path $scriptPath) {
                    & $scriptPath
                }
                else {
                    Write-Host "`n[❌] ERRO: Script local não encontrado: $scriptPath" -ForegroundColor Red
                }
            }
            elseif ($selecionada.IsLocal) {
                # Para scripts locais
                $scriptPath = Join-Path $PSScriptRoot $selecionada.Path
                if (Test-Path $scriptPath) {
                    & $scriptPath
                }
                else {
                    Write-Host "`n[❌] ERRO: Script local não encontrado: $($selecionada.Path)" -ForegroundColor Red
                }
            }
            else {
                # Montagem da URL para scripts PowerShell
                $finalUrl = if ($selecionada.External) { 
                    $selecionada.Path 
                }
                else { 
                    "https://$baseUrl/$($selecionada.Path)" 
                }
                
                try {
                    # Baixar e executar o script
                    $scriptContent = Invoke-RestMethod -Uri $finalUrl -UseBasicParsing
                    
                    # Executar o conteúdo diretamente
                    Invoke-Expression $scriptContent
                }
                catch {
                    Write-Host "`n[❌] ERRO: Falha na execução remota." -ForegroundColor Red
                    Write-Host "URL: $finalUrl" -ForegroundColor Gray
                    Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
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