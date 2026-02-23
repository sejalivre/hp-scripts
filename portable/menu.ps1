<#
.SYNOPSIS
    Launcher Principal HP-Scripts - Hub de Automação Profissional.
.DESCRIPTION
    Versão 2.0 - Target: Windows 10/11.
.NOTES
    Requer PowerShell 5.1+ (Windows 10/11)
#>

# ============================================================
# REQUISITOS DE SISTEMA
# ============================================================

# Verificação de Versão do PowerShell
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERRO] Este script requer PowerShell 5.1 ou superior (Windows 10/11)." -ForegroundColor Red
    exit 1
}

# Configuração de TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ============================================================
# LIBERAR POLITICA DE EXECUCAO AUTOMATICAMENTE
# ============================================================
try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned" -or $currentPolicy -eq "Undefined") {
        Write-Host "[INFO] Liberando politica de execucao do PowerShell..." -ForegroundColor Cyan
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($newPolicy -eq "Unrestricted" -or $newPolicy -eq "RemoteSigned" -or $newPolicy -eq "Bypass") {
            Write-Host "[OK] Politica liberada: $newPolicy" -ForegroundColor Green
        }
    }
}
catch {
    # Silenciosamente ignora erros - o usuario pode usar a opcao 16 manualmente
}

# Configuração de Origem
$baseUrl = "get.hpinfo.com.br"

# ============================================================
# DETECÇÃO ROBUSTA DE SCRIPT ROOT
# ============================================================
$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptRoot)) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# ============================================================
# IMPORTAR MÓDULO UI-UTILS (com fallback remoto e inline)
# ============================================================
$_uiLoaded = $false

# Estágio 1: Tentar caminho local relativo
$uiUtilsPath = Join-Path $ScriptRoot "..\scripts\ui-utils.ps1"
if (Test-Path $uiUtilsPath) {
    . $uiUtilsPath
    $_uiLoaded = $true
}

# Estágio 2: Fallback remoto via URL
if (-not $_uiLoaded) {
    try {
        $uiUtilsUrl = "https://$baseUrl/scripts/ui-utils"
        $uiContent = Invoke-RestMethod -Uri $uiUtilsUrl -UseBasicParsing -ErrorAction Stop
        Invoke-Expression $uiContent
        $_uiLoaded = $true
        Write-Host "[INFO] ui-utils carregado remotamente." -ForegroundColor DarkGray
    }
    catch {
        Write-Warning "[AVISO] Falha ao carregar ui-utils remotamente: $($_.Exception.Message)"
    }
}

# Estágio 3: Fallback inline mínimo
if (-not $_uiLoaded) {
    function Show-BoxHeader {
        param([string]$Title, [string]$Subtitle = "", [int]$Width = 76)
        Write-Host ""
        Write-Host ("  === $Title ===" + $(if ($Subtitle) { " | $Subtitle" })) -ForegroundColor Cyan
        Write-Host ""
    }
    function Show-HardwareInfo {
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        $ram = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory
        Write-Host "  CPU: $cpu | RAM: $([math]::Round($ram/1GB,1))GB" -ForegroundColor Gray
        Write-Host ""
    }
    function Show-MenuItem {
        param([int]$Number, [string]$ID, [string]$Description, [string]$Color = "White")
        Write-Host ("  [{0}] {1,-11}  {2}" -f $Number, $ID, $Description) -ForegroundColor $Color
    }
    function Show-MenuSeparator {
        param([string]$Text = "")
        Write-Host ""
        if ($Text) { Write-Host "  --- $Text ---" -ForegroundColor Yellow } else { Write-Host "  ---" -ForegroundColor DarkGray }
        Write-Host ""
    }
    function Show-MenuFooter {
        param([string[]]$Options = @("Q"), [string[]]$Labels = @("Sair"), [string]$HelpURL = "")
        $parts = for ($i = 0; $i -lt $Options.Count; $i++) { "[$($Options[$i])] $($Labels[$i])" }
        Write-Host ("  " + ($parts -join " | ")) -ForegroundColor DarkGray
        Write-Host ""
    }
    function Read-MenuKey {
        param([string]$Prompt = "Selecione uma opcao")
        Write-Host "$Prompt " -NoNewline -ForegroundColor Cyan
        if ($Host.Name -eq 'ConsoleHost') {
            try { $k = [Console]::ReadKey($true); Write-Host $k.KeyChar -ForegroundColor Yellow; return $k.KeyChar.ToString() }
            catch { return Read-Host }
        } else { return Read-Host }
    }
    function Show-HelpMenu {
        param([string]$HelpURL = "https://docs.hpinfo.com.br")
        Clear-Host
        Show-BoxHeader -Title "AJUDA" -Subtitle "Documentação Oficial"
        Write-Host "  Documentacao Online: $HelpURL" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Atalhos Gerais:" -ForegroundColor Yellow
        Write-Host "  [0] Voltar ao menu anterior" -ForegroundColor White
        Write-Host "  [Q] Sair do script atual" -ForegroundColor White
        Write-Host "  [H] Abrir este menu de ajuda" -ForegroundColor White
        Write-Host ""
        $openDocs = Read-MenuKey -Prompt "  Deseja abrir a documentacao no navegador? (S/N)"
        if ($openDocs -match '^[sS]') {
            try { Start-Process $HelpURL; Write-Host "`n  [OK] Documentacao aberta no navegador." -ForegroundColor Green }
            catch { Write-Host "`n  [ERRO] Nao foi possivel abrir a documentacao." -ForegroundColor Red }
        }
        Write-Host "`n  Pressione qualquer tecla para voltar..." -ForegroundColor Gray
        if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
            try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            catch { Read-Host "  Pressione ENTER" }
        } else { Read-Host "  Pressione ENTER" }
    }
}

# 1. Definição das Ferramentas
$ferramentas = @(
    @{ ID = "CHECK"      ; Desc = "Verificações Rápidas e Integridade" ; Path = "../scripts/check" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "REPAIR"     ; Desc = "Reparo Automático do Sistema"       ; Path = "../scripts/repair" ; Color = "Magenta" ; IsLocalScript = $true }
    @{ ID = "SFC"        ; Desc = "Diagnóstico e Reparação Completa"   ; Path = "../scripts/sfc"   ; Color = "Red" ; IsLocalScript = $true }
    @{ ID = "INSTALLPS1" ; Desc = "Instalar/Atualizar PowerShell"   ; Path = "installps1.cmd" ; Color = "Cyan" ; IsCmd = $true }
    @{ ID = "WINFORGE"   ; Desc = "Instalação e Otimização do Sistema" ; Path = "../scripts/winforge" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "LIMP"       ; Desc = "Limpeza de Arquivos Temporários"     ; Path = "../scripts/limp"  ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "UPDATE"     ; Desc = "Atualizações do Sistema"             ; Path = "../scripts/update_menu"; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "HORA"       ; Desc = "Sincronizando Horário"               ; Path = "../scripts/hora"  ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "REDE"       ; Desc = "Reparo de Rede e Conectividade"      ; Path = "../scripts/net"   ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "PRINT"      ; Desc = "Módulo de Impressão"                 ; Path = "../scripts/print" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "BACKUP"     ; Desc = "Rotina de Backup de Usuário"         ; Path = "../scripts/backup"; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "ATIV"       ; Desc = "Ativação (get.activated.win)"        ; Path = "https://get.activated.win" ; External = $true }
    @{ ID = "WALL"       ; Desc = "Configurar Wallpaper Padrão"         ; Path = "../scripts/wallpaper" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "NEXTDNS"    ; Desc = "Gerenciamento NextDNS"               ; Path = "../tools/nextdns/nextdns.ps1" ; Color = "Yellow" ; IsLocal = $true }
    @{ ID = "TOOLS"      ; Desc = "Menu de Ferramentas Portáteis"       ; Path = "menu_tools.ps1" ; Color = "Green" ; IsLocal = $true }
    @{ ID = "POLICY"     ; Desc = "Liberar Política de Execução"        ; Path = "SetExecutionPolicy" ; Color = "Magenta" ; IsFunction = $true }
)

function Set-ExecutionPolicy-Unrestricted {
    $command = "Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force"

    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser

        if ($currentPolicy -eq "Unrestricted" -or $currentPolicy -eq "RemoteSigned" -or $currentPolicy -eq "Bypass") {
            Write-Host "[OK] Política de execução já está liberada: $currentPolicy" -ForegroundColor Green
            return
        }

        Write-Host "[INFO] Política atual: $currentPolicy" -ForegroundColor Yellow
        Write-Host "[INFO] Tentando alterar para Unrestricted..." -ForegroundColor Cyan

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction Stop

        $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
        Write-Host "[OK] Política alterada com sucesso para: $newPolicy" -ForegroundColor Green
        Write-Host "[INFO] Comando executado: $command" -ForegroundColor Gray
    }
    catch {
        Write-Host "[AVISO] Não foi possível alterar automaticamente." -ForegroundColor Yellow
        Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host "`n[INFO] Copiando comando para área de transferência..." -ForegroundColor Cyan

        try {
            Set-Clipboard -Value $command
            Write-Host "[OK] Comando copiado: $command" -ForegroundColor Green
            Write-Host "[INFO] Cole no PowerShell com CTRL+V e execute como Administrador" -ForegroundColor Yellow
        }
        catch {
            Write-Host "[INFO] Comando para copiar manualmente:" -ForegroundColor Cyan
            Write-Host $command -ForegroundColor White
        }
    }
}

# Funções Read-MenuKey e Get-HardwareInfo estão disponíveis no ui-utils.ps1

function Show-MatrixEffect {
    param([int]$DurationSeconds = 2)

    # Caracteres para o efeito matrix
    $chars = "0123456789ABCDEF"
    $width = $Host.UI.RawUI.WindowSize.Width
    $height = $Host.UI.RawUI.WindowSize.Height

    # Salvar cor original
    $originalColor = $Host.UI.RawUI.ForegroundColor
    $originalBg = $Host.UI.RawUI.BackgroundColor

    # Fundo preto
    $Host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host

    $startTime = Get-Date

    while (((Get-Date) - $startTime).TotalSeconds -lt $DurationSeconds) {
        # Posicionar cursor em local aleatório
        $x = Get-Random -Minimum 0 -Maximum $width
        $y = Get-Random -Minimum 0 -Maximum ($height - 5)

        # Mover cursor
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($x, $y)

        # Escolher caractere aleatório
        $char = $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]

        # Cor verde com variação de intensidade
        $greenShades = @("DarkGreen", "Green", "DarkGreen")
        $color = $greenShades[(Get-Random -Minimum 0 -Maximum $greenShades.Length)]

        Write-Host $char -ForegroundColor $color -NoNewline

        # Pequeno delay para criar efeito de "chuva"
        Start-Sleep -Milliseconds 10
    }

    # Restaurar cores originais
    $Host.UI.RawUI.ForegroundColor = $originalColor
    $Host.UI.RawUI.BackgroundColor = $originalBg
    Clear-Host
}

# Executar efeito Matrix antes de carregar o menu
Show-MatrixEffect -DurationSeconds 2

# Iniciar menu principal
function Show-MainMenu {
    do {
        Clear-Host
        Show-BoxHeader -Title "HPCRAFT v2" -Subtitle "Windows Optimization Tool (PORTABLE)"

        # Exibir informações de hardware
        Show-HardwareInfo

        # Renderização Dinâmica do Menu
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
            $color = if ($item.Color) { $item.Color } else { "White" }
            Show-MenuItem -Number $n -ID $item.ID -Description $item.Desc -Color $color
        }

        Show-MenuFooter -Options @("Q", "H") -Labels @("Sair", "Ajuda")

        $escolha = Read-MenuKey -Prompt "Selecione uma opcao"

        if ($escolha -eq "Q" -or $escolha -eq "q") {
            Write-Host "`nEncerrando..." -ForegroundColor Green
            break
        }

        if ($escolha -eq "H" -or $escolha -eq "h") {
            Show-HelpMenu -HelpURL "https://docs.hpinfo.com.br"
            continue
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
                $scriptPath = Join-Path $ScriptRoot "$($selecionada.Path).ps1"
                if (Test-Path $scriptPath) {
                    & $scriptPath
                }
                else {
                    Write-Host "`n[❌] ERRO: Script local não encontrado: $scriptPath" -ForegroundColor Red
                }
            }
            elseif ($selecionada.IsLocal) {
                # Para scripts locais
                $scriptPath = Join-Path $ScriptRoot $selecionada.Path
                if (Test-Path $scriptPath) {
                    & $scriptPath
                }
                else {
                    Write-Host "`n[❌] ERRO: Script local não encontrado: $($selecionada.Path)" -ForegroundColor Red
                }
            }
            elseif ($selecionada.IsFunction) {
                # Para funções internas (não requerem download)
                switch ($selecionada.Path) {
                    "SetExecutionPolicy" { Set-ExecutionPolicy-Unrestricted }
                    default { Write-Warning "Função desconhecida: $($selecionada.Path)" }
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