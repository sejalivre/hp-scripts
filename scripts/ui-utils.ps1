<#
.SYNOPSIS
    Módulo de Utilidades de UI para HP-Scripts
.DESCRIPTION
    Funções reutilizáveis para desenhar menus com layout moderno e consistente
.NOTES
    Autor: HP-Scripts Team
    Versão: 1.0
    Compatibilidade: PowerShell 5.1+ (Windows 10/11)
#>

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
        Exibe informações de hardware formatadas em uma linha
    #>
    $hw = Get-HardwareInfo
    if ($hw) {
        $cpuShort = if ($hw.CPU.Length -gt 35) { $hw.CPU.Substring(0, 35) + "..." } else { $hw.CPU }
        Write-Host "  🖥️  CPU: $cpuShort" -ForegroundColor Gray
        Write-Host "  💾 RAM: $($hw.RAM)GB | Disco: $($hw.DiskFree)GB/$($hw.DiskTotal)GB" -ForegroundColor Gray
        Write-Host ""
    }
}

# ============================================================
# FUNÇÕES DE DESENHO DE MENUS
# ============================================================

function Show-BoxHeader {
    <#
    .SYNOPSIS
        Desenha cabeçalho com título centralizado
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

    $padding = ($Width - $Title.Length) / 2
    $leftPad = [math]::Floor($padding)
    $rightPad = [math]::Ceiling($padding)

    Write-Host ""
    Write-Host ("  ╔" + ("═" * $Width) + "╗") -ForegroundColor Cyan

    if ([string]::IsNullOrWhiteSpace($Subtitle)) {
        # Apenas título
        Write-Host ("  ║" + (" " * $leftPad) + $Title + (" " * $rightPad) + "║") -ForegroundColor Cyan
    }
    else {
        # Título + Subtítulo
        $subPadding = ($Width - $Subtitle.Length) / 2
        $subLeftPad = [math]::Floor($subPadding)
        $subRightPad = [math]::Ceiling($subPadding)

        Write-Host ("  ║" + (" " * $leftPad) + $Title + (" " * $rightPad) + "║") -ForegroundColor Cyan
        Write-Host ("  ║" + (" " * $subLeftPad) + $Subtitle + (" " * $subRightPad) + "║") -ForegroundColor DarkCyan
    }

    Write-Host ("  ╚" + ("═" * $Width) + "╝") -ForegroundColor Cyan
    Write-Host ""
}

function Show-BoxFooter {
    <#
    .SYNOPSIS
        Desenha fechamento da box
    .PARAMETER Width
        Largura da box (padrão: 76)
    #>
    param([int]$Width = 76)

    Write-Host ""
    Write-Host ("  ╚" + ("═" * $Width) + "╝") -ForegroundColor Cyan
    Write-Host ""
}

function Show-MenuItem {
    <#
    .SYNOPSIS
        Renderiza item de menu com numeração alinhada
    .PARAMETER Number
        Número da opção
    .PARAMETER ID
        ID/Shortname da ferramenta (alinhado à esquerda, 11 chars)
    .PARAMETER Description
        Descrição da ferramenta
    .PARAMETER Color
        Cor do texto (padrão: White)
    #>
    param(
        [int]$Number,
        [string]$ID,
        [string]$Description,
        [string]$Color = "White"
    )

    $idPadded = $ID.PadRight(11)
    Write-Host ("  [{0}] {1}  {2}" -f $Number, $idPadded, $Description) -ForegroundColor $Color
}

function Show-MenuSeparator {
    <#
    .SYNOPSIS
        Exibe linha separadora com texto
    .PARAMETER Text
        Texto do separador
    #>
    param(
        [string]$Text = ""
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        Write-Host "  " + ("─" * 76) -ForegroundColor DarkGray
    }
    else {
        $textLen = $Text.Length + 4
        $dashCount = (76 - $textLen) / 2
        $leftDashes = [math]::Floor($dashCount)
        $rightDashes = [math]::Ceiling($dashCount)

        Write-Host ("  " + ("─" * $leftDashes) + " $Text " + ("─" * $rightDashes)) -ForegroundColor Yellow
    }
    Write-Host ""
}

function Show-MenuFooter {
    <#
    .SYNOPSIS
        Exibe rodapé com opções de navegação
    .PARAMETER Options
        Array de opções para exibir (ex: @("Q", "H"))
    .PARAMETER Labels
        Array de labels para cada opção (ex: @("Sair", "Ajuda"))
    .PARAMETER HelpURL
        URL para abrir com a opção H
    #>
    param(
        [string[]]$Options = @("Q"),
        [string[]]$Labels = @("Sair"),
        [string]$HelpURL = "https://docs.hpinfo.com.br"
    )

    $footerParts = @()
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $footerParts += "[$($Options[$i])] $($Labels[$i])"
    }

    $footerText = $footerParts -join " | "
    $padding = (76 - $footerText.Length) / 2
    $leftPad = [math]::Floor($padding)
    $rightPad = [math]::Ceiling($padding)

    Write-Host ("  " + (" " * $leftPad) + $footerText + (" " * $rightPad)) -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================
# FUNÇÕES DE NAVEGAÇÃO
# ============================================================

function Read-MenuKey {
    <#
    .SYNOPSIS
        Captura tecla instantânea (sem ENTER) no ConsoleHost
    .PARAMETER Prompt
        Texto do prompt
    .OUTPUTS
        Caractere digitado
    #>
    param(
        [string]$Prompt = "Selecione uma opcao"
    )

    Write-Host "$Prompt " -NoNewline -ForegroundColor Cyan

    # Tenta usar ReadKey para resposta instantânea
    if ($Host.Name -eq 'ConsoleHost') {
        try {
            $key = [Console]::ReadKey($true)
            $char = $key.KeyChar.ToString()
            Write-Host $char -ForegroundColor Yellow
            return $char
        }
        catch {
            return Read-Host $Prompt
        }
    }
    else {
        return Read-Host $prompt
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

    Write-Host "  📚 Documentação Online: $HelpURL" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Atalhos Gerais:" -ForegroundColor Yellow
    Write-Host "  [0] Voltar ao menu anterior" -ForegroundColor White
    Write-Host "  [Q] Sair do script atual" -ForegroundColor White
    Write-Host "  [H] Abrir este menu de ajuda" -ForegroundColor White
    Write-Host ""

    $openDocs = Read-MenuKey -Prompt "  Deseja abrir a documentação no navegador? (S/N)"
    if ($openDocs -match '^[sS]') {
        try {
            Start-Process $HelpURL
            Write-Host "`n  [OK] Documentação aberta no navegador." -ForegroundColor Green
        }
        catch {
            Write-Host "`n  [ERRO] Não foi possível abrir a documentação." -ForegroundColor Red
            Write-Host "  URL: $HelpURL" -ForegroundColor Gray
        }
    }

    Write-Host "`n  Pressione qualquer tecla para voltar..." -ForegroundColor Gray
    if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
        try {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        catch {
            Read-Host "  Pressione ENTER"
        }
    }
    else {
        Read-Host "  Pressione ENTER"
    }
}
