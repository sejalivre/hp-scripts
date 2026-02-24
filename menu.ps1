<#
.SYNOPSIS
    Launcher Principal HP-Scripts - Hub de Automação Profissional.
.DESCRIPTION
    Versão 2.0 - Target: Windows 10/11.
.NOTES
    Requer PowerShell 5.1+ (Windows 10/11)
#>

param([switch]$PortableMode)

# ============================================================
# REQUISITOS DE SISTEMA
# ============================================================

# Verificação de Versão do PowerShell
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERRO] Este script requer PowerShell 5.1 ou superior (Windows 10/11)." -ForegroundColor Red
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

# ============================================================
# LIBERAR POLITICA DE EXECUCAO AUTOMATICAMENTE
# ============================================================
try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned" -or $currentPolicy -eq "Undefined") {
        Write-Host "[INFO] Liberando politica de execucao do PowerShell..." -ForegroundColor Yellow
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

# Detecção robusta do diretório do script e modo de execução
$ScriptRoot = $PSScriptRoot
$IsLocalExecution = $false

if ([string]::IsNullOrEmpty($ScriptRoot)) {
    # Fallback 1: Tentar obter do caminho do script atual
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    # Fallback 2: Usar diretório atual
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Verificar se estamos executando de um repositório local (com scripts/)
if ($PortableMode -and (Test-Path (Join-Path $ScriptRoot "scripts"))) {
    $IsLocalExecution = $true
    Write-Host "[INFO] Modo: Execução Local (repositório detectado)" -ForegroundColor DarkGreen
}
else {
    $IsLocalExecution = $false
    Write-Host "[INFO] Modo: Execução Remota (baixando scripts sob demanda)" -ForegroundColor DarkGreen
}

# ============================================================
# IMPORTAR MÓDULO UI-UTILS (com fallback remoto e inline)
# ============================================================
$_uiLoaded = $false
$baseUrl = "get.hpinfo.com.br"

# Estágio 1: Tentar caminho local relativo
$uiUtilsPath = Join-Path $ScriptRoot "scripts\ui-utils.ps1"
$uiUtilsStage = "não carregado"
if (Test-Path $uiUtilsPath) {
    try {
        . $uiUtilsPath
        $_uiLoaded = $true
        $uiUtilsStage = "carregado"
    }
    catch {
        $uiUtilsStage = "falha: $($_.Exception.Message)"
    }
}

# Estágio 2: Fallback remoto via URL
if (-not $_uiLoaded) {
    try {
        $uiUtilsUrl = "https://$baseUrl/scripts/ui-utils"
        $uiContent = Invoke-RestMethod -Uri $uiUtilsUrl -UseBasicParsing -ErrorAction Stop
        Invoke-Expression $uiContent
        $_uiLoaded = $true
        $uiUtilsStage = "carregado remotamente"
        Write-Host "[INFO] ui-utils carregado remotamente." -ForegroundColor DarkGreen
    }
    catch {
        $uiUtilsStage = "falha remota: $($_.Exception.Message)"
        Write-Warning "[AVISO] Falha ao carregar ui-utils remotamente: $($_.Exception.Message)"
    }
}

# Estágio 3: Fallback inline mínimo
if (-not $_uiLoaded) {
    function Show-BoxHeader {
        param([string]$Title, [string]$Subtitle = "", [int]$Width = 76)
        $titlePad  = ($Width - $Title.Length) / 2
        $tLeft     = [math]::Floor($titlePad)
        $tRight    = [math]::Ceiling($titlePad)
        Write-Host ""
        Write-Host ("  ╔" + ("═" * $Width) + "╗") -ForegroundColor DarkGreen
        Write-Host ("  ║" + (" " * $tLeft) + $Title + (" " * $tRight) + "║") -ForegroundColor Green
        if ($Subtitle) {
            $subPad = ($Width - $Subtitle.Length - 4) / 2
            $sLeft = [math]::Floor($subPad)
            $sRight = [math]::Ceiling($subPad)
            Write-Host ("  ║" + (" " * $sLeft) + $Subtitle + (" " * $sRight) + "║") -ForegroundColor DarkGreen
        }
        Write-Host ("  ╚" + ("═" * $Width) + "╝") -ForegroundColor DarkGreen
        Write-Host ""
    }
    function Show-HardwareInfo {
        param([int]$Width = 76)
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        $ram = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory
        Write-Host "  CPU: $cpu | RAM: $([math]::Round($ram/1GB,1))GB" -ForegroundColor DarkGreen
        Write-Host ""
    }
    function Show-MenuItem {
        param([int]$Number, [string]$ID, [string]$Description, [string]$Color = "DarkGreen", [int]$Width = 76)
        $numStr = $Number.ToString("D2")
        $idPadded = $ID.PadRight(11)
        $descWidth = $Width - 19
        $descPadded = $Description.PadRight($descWidth)
        Write-Host ("  [{0}] {1}  {2}" -f $numStr, $idPadded, $descPadded) -ForegroundColor DarkGreen
    }
    function Show-MenuSeparator {
        param([string]$Text = "")
        Write-Host ""
        if ($Text) { Write-Host "  --- $Text ---" -ForegroundColor DarkGreen } else { Write-Host "  ---" -ForegroundColor DarkGreen }
        Write-Host ""
    }
    function Show-MenuFooter {
        param([string[]]$Options = @("Q"), [string[]]$Labels = @("Sair"), [string]$HelpURL = "", [int]$Width = 76)
        $parts = for ($i = 0; $i -lt $Options.Count; $i++) { "[$($Options[$i])] $($Labels[$i])" }
        Write-Host ("  " + ($parts -join " | ")) -ForegroundColor DarkGreen
        Write-Host ""
    }
    function Read-MenuKey {
        param([string]$Prompt = "Selecione uma opcao", [int]$DigitTimeoutMs = 2000)
        Write-Host "$Prompt " -NoNewline -ForegroundColor Green
        if ($Host.Name -eq 'ConsoleHost') {
            try {
                $key = [Console]::ReadKey($true)
                $char = $key.KeyChar
                $buffer = $char.ToString()
                if ([char]::IsDigit($char)) {
                    $deadline = [DateTime]::Now.AddMilliseconds($DigitTimeoutMs)
                    while ([DateTime]::Now -lt $deadline -and $buffer.Length -lt 2) {
                        if ([Console]::KeyAvailable) {
                            $k2 = [Console]::ReadKey($true)
                            if ([char]::IsDigit($k2.KeyChar)) {
                                $buffer += $k2.KeyChar.ToString()
                                $deadline = [DateTime]::Now.AddMilliseconds($DigitTimeoutMs)
                            }
                            else { break }
                        }
                        Start-Sleep -Milliseconds 15
                    }
                }
                Write-Host $buffer -ForegroundColor Green
                return $buffer
            }
            catch { return Read-Host $Prompt }
        } else { return Read-Host $Prompt }
    }
    function Show-HelpMenu {
        param([string]$HelpURL = "https://docs.hpinfo.com.br")
        Clear-Host
        Show-BoxHeader -Title "AJUDA" -Subtitle "Documentação Oficial"
        Write-Host "  Documentacao Online: $HelpURL" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Atalhos Gerais:" -ForegroundColor Green
        Write-Host "  [0] Voltar ao menu anterior" -ForegroundColor DarkGreen
        Write-Host "  [Q] Sair do script atual" -ForegroundColor DarkGreen
        Write-Host "  [H] Abrir este menu de ajuda" -ForegroundColor DarkGreen
        Write-Host ""
        $openDocs = Read-MenuKey -Prompt "  Deseja abrir a documentacao no navegador? (S/N)"
        if ($openDocs -match '^[sS]') {
            try { Start-Process $HelpURL; Write-Host "`n  Documentacao aberta no navegador." -ForegroundColor Green }
            catch { Write-Host "`n  [ERRO] Nao foi possivel abrir a documentacao." -ForegroundColor Red }
        }
        Write-Host "`n  Pressione qualquer tecla para voltar..." -ForegroundColor DarkGreen
        if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
            try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
            catch { Read-Host "  Pressione ENTER" }
        } else { Read-Host "  Pressione ENTER" }
    }
    # Stub de logging para fallback
    function Write-HPLog {
        param([string]$Message, [string]$Level = 'INFO')
        # Silencioso no fallback
    }
    $uiUtilsStage = "fallback inline"
}

# Log de inicialização
Write-HPLog -Message "=== HPCraft iniciado ===" -Level INFO
Write-HPLog -Message "Modo de execucao: $(if ($IsLocalExecution) {'Local'} else {'Remoto'})" -Level INFO
Write-HPLog -Message "ui-utils: $uiUtilsStage" -Level INFO

# 1. Definição das Ferramentas (sem cores individuais - tudo usa tema Matrix)
$ferramentas = @(
    @{ ID = "CHECK"      ; Desc = "Verificações Rápidas e Integridade" ; Path = "scripts/check" ; IsLocalScript = $true }
    @{ ID = "REPAIR"     ; Desc = "Reparo Automático do Sistema"       ; Path = "scripts/repair" ; IsLocalScript = $true }
    @{ ID = "SFC"        ; Desc = "Diagnóstico e Reparação Completa"   ; Path = "scripts/sfc"   ; IsLocalScript = $true }
    @{ ID = "INSTALLPS1" ; Desc = "Instalar/Atualizar PowerShell"   ; Path = "installps1.cmd" ; IsCmd = $true }
    @{ ID = "WINFORGE"   ; Desc = "Instalação e Otimização do Sistema" ; Path = "scripts/winforge" ; IsLocalScript = $true }
    @{ ID = "LIMP"       ; Desc = "Limpeza de Arquivos Temporários"     ; Path = "scripts/limp"  ; IsLocalScript = $true }
    @{ ID = "UPDATE"     ; Desc = "Atualizações do Sistema"             ; Path = "scripts/update_menu"; IsLocalScript = $true }
    @{ ID = "HORA"       ; Desc = "Sincronizando Horário"               ; Path = "scripts/hora"  ; IsLocalScript = $true }
    @{ ID = "REDE"       ; Desc = "Reparo de Rede e Conectividade"      ; Path = "scripts/net"   ; IsLocalScript = $true }
    @{ ID = "PRINT"      ; Desc = "Módulo de Impressão"                 ; Path = "scripts/print" ; IsLocalScript = $true }
    @{ ID = "BACKUP"     ; Desc = "Rotina de Backup de Usuário"         ; Path = "scripts/backup"; IsLocalScript = $true }
    @{ ID = "ATIV"       ; Desc = "Ativação (get.activated.win)"        ; Path = "https://get.activated.win" ; External = $true }
    @{ ID = "WALL"       ; Desc = "Configurar Wallpaper Padrão"         ; Path = "scripts/wallpaper" ; IsLocalScript = $true }
    @{ ID = "NEXTDNS"    ; Desc = "Gerenciamento NextDNS"               ; Path = "tools/nextdns/nextdns" ; IsLocal = $true }
    @{ ID = "TOOLS"      ; Desc = "Menu de Ferramentas Portáteis"       ; Path = "menu_tools" ; IsLocal = $true }
    @{ ID = "POLICY"     ; Desc = "Liberar Política de Execução"        ; Path = "SetExecutionPolicy" ; IsFunction = $true }
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
        Write-Host "[INFO] Tentando alterar para Unrestricted..." -ForegroundColor Yellow

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction Stop

        $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
        Write-Host "[OK] Política alterada com sucesso para: $newPolicy" -ForegroundColor Green
        Write-Host "[INFO] Comando executado: $command" -ForegroundColor DarkGreen
        Write-HPLog -Message "Politica de execucao alterada para: $newPolicy" -Level INFO
    }
    catch {
        Write-Host "[AVISO] Não foi possível alterar automaticamente." -ForegroundColor Yellow
        Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
        Write-HPLog -Message "ERRO ao alterar politica: $($_.Exception.Message)" -Level ERRO

        Write-Host "`n[INFO] Copiando comando para área de transferência..." -ForegroundColor Yellow

        try {
            Set-Clipboard -Value $command
            Write-Host "[OK] Comando copiado: $command" -ForegroundColor Green
            Write-Host "[INFO] Cole no PowerShell com CTRL+V e execute como Administrador" -ForegroundColor Yellow
        }
        catch {
            Write-Host "[INFO] Comando para copiar manualmente:" -ForegroundColor Yellow
            Write-Host $command -ForegroundColor Green
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
        Show-BoxHeader -Title "HPCRAFT v2" -Subtitle "Windows Optimization Tool"

        # Exibir informações de hardware
        Show-HardwareInfo

        # Renderização Dinâmica do Menu
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
            Show-MenuItem -Number $n -ID $item.ID -Description $item.Desc
        }

        Show-MenuFooter -Options @("Q", "H") -Labels @("Sair", "Ajuda")

        $escolha = Read-MenuKey -Prompt "Selecione uma opcao" -DigitTimeoutMs 2000
        Write-HPLog -Message "Opcao selecionada: '$escolha'" -Level INFO

        if ($escolha -eq "Q" -or $escolha -eq "q") {
            Write-Host "`nEncerrando..." -ForegroundColor Green
            Write-HPLog -Message "Encerrando HPCraft (opcao Q)" -Level INFO
            break
        }

        if ($escolha -eq "H" -or $escolha -eq "h") {
            Write-HPLog -Message "Menu Ajuda aberto" -Level INFO
            Show-HelpMenu -HelpURL "https://docs.hpinfo.com.br"
            continue
        }

        # 3. Lógica de Execução
        $idx = 0 
        if ([int]::TryParse($escolha, [ref]$idx) -and $idx -le $ferramentas.Count -and $idx -gt 0) {
            $selecionada = $ferramentas[$idx - 1]
            
            Write-Host "`n  Iniciando $($selecionada.ID)..." -ForegroundColor Green
            Write-HPLog -Message "Iniciando modulo: $($selecionada.ID)" -Level INFO
            
            # Verificar se é um arquivo .cmd (batch)
            if ($selecionada.IsCmd) {
                # Para arquivos .cmd, baixar e executar via cmd.exe
                $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                $TempCmd = "$env:TEMP\HPTI_Exec_$($selecionada.ID).cmd"
                
                try {
                    Write-Host "  [INFO] Baixando instalador..." -ForegroundColor Yellow
                    Invoke-WebRequest -Uri $finalUrl -OutFile $TempCmd -UseBasicParsing
                    
                    if (Test-Path $TempCmd) {
                        Write-Host "  [INFO] Executando instalador..." -ForegroundColor Yellow
                        # Executar o .cmd e aguardar conclusão
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$TempCmd`"" -Wait -NoNewWindow
                        
                        # Remove após execução
                        Remove-Item $TempCmd -Force -ErrorAction SilentlyContinue
                        Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                    }
                    else {
                        throw "Arquivo não foi baixado corretamente."
                    }
                }
                catch {
                    Write-Host "`n  [ERRO] Falha ao executar instalador." -ForegroundColor Red
                    Write-Host "  URL: $finalUrl" -ForegroundColor DarkGreen
                    Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
                    Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                }
            }
            elseif ($selecionada.IsLocalScript) {
                # Para scripts PowerShell locais (dentro de ./scripts/)
                if ($IsLocalExecution) {
                    # Modo local: executar arquivo do disco 
                    $scriptPath = Join-Path $ScriptRoot "$($selecionada.Path).ps1"
                    if (Test-Path $scriptPath) {
                        try {
                            & $scriptPath
                            Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                        }
                        catch {
                            Write-Host "`n  [ERRO] Erro durante execucao do modulo." -ForegroundColor Red
                            Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
                            Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                        }
                    }
                    else {
                        Write-Host "`n  [ERRO] Script local não encontrado: $scriptPath" -ForegroundColor Red
                        Write-HPLog -Message "ERRO: Script local nao encontrado: $scriptPath" -Level ERRO
                    }
                }
                else {
                    # Modo remoto: baixar e executar
                    $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                    $TempScript = Join-Path $env:TEMP "HPTI_$($selecionada.ID).ps1"
                    try {
                        Write-Host "  [INFO] Baixando script remoto..." -ForegroundColor Yellow
                        Invoke-WebRequest -Uri $finalUrl -OutFile $TempScript -UseBasicParsing
                        if (Test-Path $TempScript) {
                            & $TempScript
                            Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
                            Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                        }
                    }
                    catch {
                        Write-Host "`n  [ERRO] Falha ao baixar script remoto." -ForegroundColor Red
                        Write-Host "  URL: $finalUrl" -ForegroundColor DarkGreen
                        Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
                        Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                    }
                }
            }
            elseif ($selecionada.IsLocal) {
                # Para scripts locais (como  menu_tools.ps1)
                if ($IsLocalExecution) {
                    # Modo local: executar arquivo do disco
                    $scriptPath = Join-Path $ScriptRoot "$($selecionada.Path).ps1"
                    if (Test-Path $scriptPath) {
                        try {
                            & $scriptPath
                            Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                        }
                        catch {
                            Write-Host "`n  [ERRO] Erro durante execucao do modulo." -ForegroundColor Red
                            Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
                            Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                        }
                    }
                    else {
                        Write-Host "`n  [ERRO] Script local não encontrado: $($selecionada.Path)" -ForegroundColor Red
                        Write-HPLog -Message "ERRO: Script local nao encontrado: $($selecionada.Path)" -Level ERRO
                    }
                }
                else {
                    # Modo remoto: baixar e executar
                    $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                    $TempScript = Join-Path $env:TEMP "HPTI_$($selecionada.ID).ps1"
                    try {
                        Write-Host "  [INFO] Baixando script remoto..." -ForegroundColor Yellow
                        Invoke-WebRequest -Uri $finalUrl -OutFile $TempScript -UseBasicParsing
                        if (Test-Path $TempScript) {
                            & $TempScript
                            Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
                            Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                        }
                    }
                    catch {
                        Write-Host "`n  [ERRO] Falha ao baixar script remoto." -ForegroundColor Red
                        Write-Host "  URL: $finalUrl" -ForegroundColor DarkGreen
                        Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
                        Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                    }
                }
            }
            elseif ($selecionada.IsFunction) {
                # Para funções internas (não requerem download)
                switch ($selecionada.Path) {
                    "SetExecutionPolicy" { 
                        try {
                            Set-ExecutionPolicy-Unrestricted 
                            Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                        }
                        catch {
                            Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                        }
                    }
                    default { 
                        Write-Warning "Função desconhecida: $($selecionada.Path)" 
                        Write-HPLog -Message "Funcao desconhecida: $($selecionada.Path)" -Level WARN
                    }
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
                    Write-HPLog -Message "Modulo $($selecionada.ID) concluido com sucesso" -Level INFO
                }
                catch {
                    Write-Host "`n  [ERRO] Falha na execução remota." -ForegroundColor Red
                    Write-Host "  URL: $finalUrl" -ForegroundColor DarkGreen
                    Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGreen
                    Write-HPLog -Message "ERRO em $($selecionada.ID): $($_.Exception.Message)" -Level ERRO
                }
            }
        }
        else {
            Write-Warning "Opção inválida!"
            Write-HPLog -Message "Opcao invalida: '$escolha'" -Level WARN
            Start-Sleep -Seconds 1
        }
        
        Write-Host "`n  Pressione qualquer tecla para voltar..." -ForegroundColor DarkGreen
        
        # Compatibilidade: ReadKey() não funciona em ISE ou sessões remotas
        if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
            try {
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            catch {
                Read-Host "  Pressione ENTER para continuar"
            }
        }
        else {
            Read-Host "  Pressione ENTER para continuar"
        }

    } while ($true)
}

Show-MainMenu
