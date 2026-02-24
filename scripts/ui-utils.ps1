<#
.SYNOPSIS
    Módulo de Utilidades de UI para HP-Scripts
.DESCRIPTION
    Funções reutilizáveis para desenhar menus com layout moderno e consistente
.NOTES
    Autor: HP-Scripts Team
    Versão: 2.0
    Compatibilidade: PowerShell 5.1+ (Windows 10/11)
#>

# ============================================================
# SISTEMA DE LOG
# ============================================================

# Determinação do caminho de log (executado quando o módulo é carregado)
$script:HPLogPath = $null
$script:HPLogReady = $false

function Initialize-HPLog {
    <#
    .SYNOPSIS
        Inicializa o sistema de log — determina caminho e cria diretório
    #>
    try {
        $primaryDir = Join-Path $env:ProgramFiles 'HPTI'
        $primaryLog = Join-Path $primaryDir 'hpcraft.log'
        
        # Tentar usar o diretório primário
        if (-not (Test-Path $primaryDir)) {
            New-Item -ItemType Directory -Path $primaryDir -Force -ErrorAction Stop | Out-Null
        }
        # Teste de escrita
        $testFile = Join-Path $primaryDir '.write_test'
        [System.IO.File]::WriteAllText($testFile, 'test', [System.Text.Encoding]::UTF8)
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        
        $script:HPLogPath  = $primaryLog
        $script:HPLogReady = $true
    }
    catch {
        # Fallback: usar %TEMP%\HPTI\
        try {
            $fallbackDir = Join-Path $env:TEMP 'HPTI'
            if (-not (Test-Path $fallbackDir)) {
                New-Item -ItemType Directory -Path $fallbackDir -Force -ErrorAction Stop | Out-Null
            }
            $script:HPLogPath  = Join-Path $fallbackDir 'hpcraft.log'
            $script:HPLogReady = $true
        }
        catch {
            $script:HPLogReady = $false
        }
    }
}

function Write-HPLog {
    <#
    .SYNOPSIS
        Registra mensagem no arquivo de log (silencioso — não exibe na tela)
    .PARAMETER Message
        Mensagem a registrar
    .PARAMETER Level
        Nível: INFO (padrão), ERRO, WARN
    #>
    param(
        [string]$Message,
        [ValidateSet('INFO','ERRO','WARN')]
        [string]$Level = 'INFO'
    )

    if (-not $script:HPLogReady) { return }

    try {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $line      = "[$timestamp] [$Level] $Message"
        [System.IO.File]::AppendAllText($script:HPLogPath, $line + "`r`n", [System.Text.Encoding]::UTF8)
    }
    catch {
        # Silencioso — nunca lança exceção para o chamador
    }
}

# Inicializar log ao carregar o módulo
Initialize-HPLog

# ============================================================
# FUNÇÕES DE INFORMAÇÕES DE HARDWARE
# ============================================================

function Get-HardwareInfo {
    <#
    .SYNOPSIS
        Obtém informações de hardware do sistema
    .OUTPUTS
        Hashtable com CPU, RAM, DiskFree e DiskTotal
    #>
    try {
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        if (-not $cpu) { $cpu = "N/A" }

        $ram = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $ramTotal = if ($ram) { [math]::Round($ram.TotalPhysicalMemory / 1GB, 1) } else { 0 }

        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        $diskFree = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 1) } else { 0 }
        $diskTotal = if ($disk) { [math]::Round($disk.Size / 1GB, 1) } else { 0 }

        return @{
            CPU = $cpu
            RAM = $ramTotal
            DiskFree = $diskFree
            DiskTotal = $diskTotal
        }
    }
    catch {
        return $null
    }
}

function Show-HardwareInfo {
    <#
    .SYNOPSIS
        Exibe informações de hardware formatadas dentro da box
    .PARAMETER Width
        Largura interna da box (padrão: 76)
    #>
    param([int]$Width = 76)

    $hw = Get-HardwareInfo
    if ($hw) {
        $cpuShort = if ($hw.CPU.Length -gt 45) { $hw.CPU.Substring(0, 45) + "..." } else { $hw.CPU }
        
        $lineCpu = ("CPU: " + $cpuShort).PadRight($Width)
        $lineRam = ("RAM: " + $hw.RAM + "GB   Disco: " + $hw.DiskFree + "GB / " + $hw.DiskTotal + "GB").PadRight($Width)
        
        Write-Host ("  ║" + $lineCpu + "║") -ForegroundColor DarkGreen
        Write-Host ("  ║" + $lineRam + "║") -ForegroundColor DarkGreen
    }
    else {
        $lineNA = "Hardware info indisponivel".PadRight($Width)
        Write-Host ("  ║" + $lineNA + "║") -ForegroundColor DarkGreen
    }

    # Separador após hardware
    Write-Host ("  ╠" + ("═" * $Width) + "╣") -ForegroundColor DarkGreen
}

# ============================================================
# FUNÇÕES DE DESENHO DE MENUS
# ============================================================

function Show-BoxHeader {
    <#
    .SYNOPSIS
        Desenha cabeçalho com título centralizado (abre a box)
    .PARAMETER Title
        Título do menu
    .PARAMETER Subtitle
        Subtítulo opcional (ex: versão, docs)
    .PARAMETER Width
        Largura da box (padrão: 76)
    #>
    param(
        [string]$Title,
        [string]$Subtitle = "",
        [int]$Width = 76
    )

    $titlePad  = ($Width - $Title.Length) / 2
    $tLeft     = [math]::Floor($titlePad)
    $tRight    = [math]::Ceiling($titlePad)

    Write-Host ""
    # Linha superior
    Write-Host ("  ╔" + ("═" * $Width) + "╗") -ForegroundColor DarkGreen

    # Linha do título (brilhante)
    Write-Host ("  ║" + (" " * $tLeft) + $Title + (" " * $tRight) + "║") -ForegroundColor Green

    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        $subPad  = ($Width - $Subtitle.Length) / 2
        $sLeft   = [math]::Floor($subPad)
        $sRight  = [math]::Ceiling($subPad)
        Write-Host ("  ║" + (" " * $sLeft) + $Subtitle + (" " * $sRight) + "║") -ForegroundColor DarkGreen
    }

    # Separador (box continua aberta para hardware e itens)
    Write-Host ("  ╠" + ("═" * $Width) + "╣") -ForegroundColor DarkGreen
}

function Show-MenuItem {
    <#
    .SYNOPSIS
        Renderiza item de menu com numeração alinhada dentro da box
    .PARAMETER Number
        Número da opção
    .PARAMETER ID
        ID/Shortname da ferramenta (alinhado à esquerda, 11 chars)
    .PARAMETER Description
        Descrição da ferramenta
    .PARAMETER Color
        Parâmetro mantido para compatibilidade (ignorado - usa tema Matrix)
    .PARAMETER Width
        Largura interna da box (padrão: 76)
    #>
    param(
        [int]$Number,
        [string]$ID,
        [string]$Description,
        [string]$Color = "DarkGreen",   # mantido por retrocompatibilidade
        [int]$Width = 76
    )

    $numStr    = $Number.ToString("D2")        # zero-pad: "01", "10", "16"
    $idPadded  = $ID.PadRight(11)
    # Conteúdo interno: "  [NN] ID(11)  Desc" preenchido até Width
    # Cálculo: 2 espaços + 1[ + 2NN + 1] + 1 espaço + 11ID + 2 espaços + desc = 19 + desc
    $descWidth = $Width - 19
    $descPadded = $Description.PadRight($descWidth)
    $inner     = "  [{0}] {1}  {2}" -f $numStr, $idPadded, $descPadded
    
    # Número em Green (brilhante), resto em DarkGreen
    Write-Host "  ║" -ForegroundColor DarkGreen -NoNewline
    Write-Host "  [" -ForegroundColor DarkGreen -NoNewline
    Write-Host $numStr  -ForegroundColor Green      -NoNewline
    Write-Host "] {0}  {1}" -f $idPadded, $descPadded -ForegroundColor DarkGreen -NoNewline
    Write-Host "║"      -ForegroundColor DarkGreen
}

function Show-MenuSeparator {
    <#
    .SYNOPSIS
        Exibe linha separadora com texto (usado em submenus)
    .PARAMETER Text
        Texto do separador
    #>
    param(
        [string]$Text = ""
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        Write-Host "  " + ("─" * 76) -ForegroundColor DarkGreen
    }
    else {
        $textLen    = $Text.Length + 4
        $dashCount  = (76 - $textLen) / 2
        $leftDashes = [math]::Floor($dashCount)
        $rightDashes= [math]::Ceiling($dashCount)
        Write-Host ("  " + ("─" * $leftDashes) + " $Text " + ("─" * $rightDashes)) -ForegroundColor DarkGreen
    }
    Write-Host ""
}

function Show-MenuFooter {
    <#
    .SYNOPSIS
        Exibe rodapé com opções de navegação e fecha a box
    .PARAMETER Options
        Array de opções para exibir (ex: @("Q", "H"))
    .PARAMETER Labels
        Array de labels para cada opção (ex: @("Sair", "Ajuda"))
    .PARAMETER HelpURL
        URL para abrir com a opção H
    .PARAMETER Width
        Largura interna da box (padrão: 76)
    #>
    param(
        [string[]]$Options  = @("Q"),
        [string[]]$Labels   = @("Sair"),
        [string]$HelpURL    = "https://docs.hpinfo.com.br",
        [int]$Width         = 76
    )

    # Construir texto do footer
    $parts = @()
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $parts += "[$($Options[$i])] $($Labels[$i])"
    }
    $footerText = $parts -join "  |  "

    # Centralizar dentro de $Width
    $pad   = ($Width - $footerText.Length) / 2
    $lPad  = [math]::Floor($pad)
    $rPad  = [math]::Ceiling($pad)

    # Separador antes do footer
    Write-Host ("  ╠" + ("═" * $Width) + "╣") -ForegroundColor DarkGreen

    # Linha do footer
    Write-Host ("  ║" + (" " * $lPad) + $footerText + (" " * $rPad) + "║") -ForegroundColor DarkGreen

    # Fechamento da box
    Write-Host ("  ╚" + ("═" * $Width) + "╝") -ForegroundColor DarkGreen
    Write-Host ""
}

function Show-BoxFooter {
    <#
    .SYNOPSIS
        Desenha fechamento da box (para uso em submenus que não usam Show-MenuFooter)
    .PARAMETER Width
        Largura da box (padrão: 76)
    #>
    param([int]$Width = 76)

    Write-Host ("  ╚" + ("═" * $Width) + "╝") -ForegroundColor DarkGreen
    Write-Host ""
}

# ============================================================
# FUNÇÕES DE NAVEGAÇÃO
# ============================================================

function Read-MenuKey {
    <#
    .SYNOPSIS
        Captura tecla com buffer de timeout para números de 2+ dígitos
    .PARAMETER Prompt
        Texto do prompt
    .PARAMETER DigitTimeoutMs
        Timeout em ms para acumular dígitos (padrão: 500)
    .OUTPUTS
        String digitada (caractere ou número acumulado)
    #>
    param(
        [string]$Prompt       = "Selecione uma opcao",
        [int]$DigitTimeoutMs  = 2000
    )

    Write-Host ""
    Write-Host "  $Prompt: " -NoNewline -ForegroundColor Green

    if ($Host.Name -eq 'ConsoleHost') {
        try {
            # Lê o primeiro caractere (bloqueante)
            $key    = [Console]::ReadKey($true)
            $char   = $key.KeyChar
            $buffer = $char.ToString()

            # Se for um dígito, aguarda mais dígitos com timeout
            if ([char]::IsDigit($char)) {
                $deadline = [DateTime]::Now.AddMilliseconds($DigitTimeoutMs)
                $maxDigits = 2  # Limitar a 2 dígitos (para 01-99)

                while ([DateTime]::Now -lt $deadline -and $buffer.Length -lt $maxDigits) {
                    if ([Console]::KeyAvailable) {
                        $k2 = [Console]::ReadKey($true)
                        if ([char]::IsDigit($k2.KeyChar)) {
                            $buffer  += $k2.KeyChar.ToString()
                            # Reset deadline a cada novo dígito recebido
                            $deadline = [DateTime]::Now.AddMilliseconds($DigitTimeoutMs)
                        }
                        else {
                            # Tecla não-dígito: descarta e para
                            break
                        }
                    }
                    Start-Sleep -Milliseconds 15
                }
            }

            # Eco do que foi digitado
            Write-Host $buffer -ForegroundColor Green
            Write-HPLog -Message "Usuario digitou: '$buffer'" -Level INFO
            return $buffer
        }
        catch {
            $result = Read-Host $Prompt
            Write-HPLog -Message "Usuario digitou (fallback): '$result'" -Level INFO
            return $result
        }
    }
    else {
        $result = Read-Host $Prompt
        Write-HPLog -Message "Usuario digitou (Read-Host): '$result'" -Level INFO
        return $result
    }
}

function Show-HelpMenu {
    <#
    .SYNOPSIS
        Exibe menu de ajuda
    .PARAMETER HelpURL
        URL da documentação
    #>
    param(
        [string]$HelpURL = "https://docs.hpinfo.com.br"
    )

    Clear-Host
    Show-BoxHeader -Title "AJUDA" -Subtitle "Documentação Oficial"

    # Linhas dentro da box
    $lines = @(
        "Documentacao Online: $HelpURL",
        "",
        "Atalhos Gerais:",
        "[0] Voltar ao menu anterior",
        "[Q] Sair do script atual",
        "[H] Abrir este menu de ajuda"
    )
    foreach ($l in $lines) {
        $inner = ("  " + $l).PadRight(76)
        Write-Host ("  ║" + $inner + "║") -ForegroundColor DarkGreen
    }

    Show-MenuFooter -Options @("S","N") -Labels @("Abrir docs","Voltar")
    
    $openDocs = Read-MenuKey -Prompt "Deseja abrir a documentação no navegador? (S/N)"
    if ($openDocs -match '^[sS]') {
        try {
            Start-Process $HelpURL
            Write-Host "  Documentacao aberta no navegador." -ForegroundColor Green
            Write-HPLog -Message "Documentacao aberta: $HelpURL" -Level INFO
        }
        catch {
            Write-Host "  [ERRO] Nao foi possivel abrir a documentacao." -ForegroundColor Red
            Write-HPLog -Message "ERRO ao abrir docs: $($_.Exception.Message)" -Level ERRO
        }
    }

    Write-Host "`n  Pressione qualquer tecla para voltar..." -ForegroundColor DarkGreen
    if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
        catch { Read-Host "  Pressione ENTER" }
    }
    else {
        Read-Host "  Pressione ENTER"
    }
}
