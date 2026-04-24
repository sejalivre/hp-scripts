<#
.SYNOPSIS
    Menu de Gerenciamento NextDNS - HP-Scripts
.DESCRIPTION
    Submenu dedicado para instalação, reparo e remoção do NextDNS.
    Documentação: docs.hpinfo.com.br
#>

# Configuração de encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "HP Scripts - Gerenciamento NextDNS"

# ============================================================
# DETECÇÃO ROBUSTA DE CAMINHO
# ============================================================
$NextDNSScriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($NextDNSScriptPath)) {
    if ($MyInvocation.MyCommand.Path) {
        $NextDNSScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
}
$ProjectRoot = $null
if ($NextDNSScriptPath) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $NextDNSScriptPath)
}
if (-not $ProjectRoot) { $ProjectRoot = Get-Location }

$baseUrl = "get.hpinfo.com.br"

# ============================================================
# IMPORTAR MÓDULO UI-UTILS (com fallback remoto e inline)
# ============================================================
$_uiLoaded = $false

# Estágio 1: Tentar caminho local relativo
$uiUtilsPath = Join-Path $ProjectRoot "scripts\ui-utils.ps1"
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
}

function Show-Header {
    Clear-Host
    Show-BoxHeader -Title "GERENCIAMENTO NEXTDNS" -Subtitle "docs.hpinfo.com.br"
}

function Show-NextDNSMenu {
    $toolsBaseUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
    $localBaseUrl = "$toolsBaseUrl/nextdns"
    
    # Lê o ID atual se existir
    $ConfigFile = "$env:ProgramFiles\HPTI\config.txt"
    $CurrentID = "Não configurado"
    if (Test-Path $ConfigFile) {
        $idTemp = Get-Content $ConfigFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($idTemp -and $idTemp -match '^[a-zA-Z0-9]{6}$') {
            $CurrentID = $idTemp
        }
    }

    do {
        Show-Header

        # Mostrar ID atual
        Write-Host "  ┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Gray
        Write-Host "  │  ID Atual: $CurrentID" -ForegroundColor Green -NoNewline
        Write-Host (" " * (50 - $CurrentID.Length)) -NoNewline
        Write-Host "│" -ForegroundColor Gray
        Write-Host "  └──────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
        Write-Host ""
        Show-MenuSeparator -Text "OPÇÕES"
        Show-MenuItem -Number 1 -ID "Install" -Description "Instalação completa" -Color "Green"
        Show-MenuItem -Number 2 -ID "ConfigID" -Description "Configurar ID do NextDNS" -Color "Cyan"
        Show-MenuItem -Number 3 -ID "RestoreDNS" -Description "Voltar ao DNS original" -Color "Cyan"
        Show-MenuItem -Number 4 -ID "Repair" -Description "Corrigir problemas" -Color "Yellow"
        Show-MenuItem -Number 5 -ID "RemoveConfig" -Description "Limpar configurações" -Color "Red"
        Show-MenuItem -Number 6 -ID "StaticDNS" -Description "Configurar DNS estático" -Color "Magenta"
        Write-Host ""
        Write-Host "  [0] Menu Principal" -ForegroundColor DarkGray
        Write-Host ""

        $escolha = Read-MenuKey -Prompt "  Escolha uma opcao"

        switch ($escolha) {
            "1" {
                Write-Host "`n  [🚀] Instalando NextDNS..." -ForegroundColor Green
                try {
                    irm "$localBaseUrl/install.ps1" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao instalar." -ForegroundColor Red
                    Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            "2" {
                Show-Header
                Write-Host "  ══════════════════  CONFIGURAÇÃO DO ID  ═══════════════════════" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  ID Atual: $CurrentID" -ForegroundColor Green
                Write-Host ""
                
                $novoID = Read-Host "  Digite o novo ID (Enter para manter atual)"
                if ($novoID -and $novoID -match '^[a-zA-Z0-9]{6}$') {
                    $HptiDir = "$env:ProgramFiles\HPTI"
                    if (-not (Test-Path $HptiDir)) { 
                        New-Item -ItemType Directory -Path $HptiDir -Force | Out-Null 
                    }
                    $novoID | Out-File -FilePath $ConfigFile -Encoding ASCII -Force
                    Write-Host "`n  [OK] ID atualizado para: $novoID" -ForegroundColor Green
                    $CurrentID = $novoID
                    
                    $reinstalar = Read-Host "  Deseja reinstalar o NextDNS com o novo ID? (S/N)"
                    if ($reinstalar -match '^[sS]') {
                        try {
                            irm "$localBaseUrl/install.ps1" | iex
                        }
                        catch {
                            Write-Host "`n  [❌] ERRO: Falha ao reinstalar." -ForegroundColor Red
                        }
                    }
                }
                elseif ($novoID) {
                    Write-Host "`n  [!] ID inválido! Deve ter 6 caracteres alfanuméricos." -ForegroundColor Yellow
                }
            }
            "3" {
                Write-Host "`n  [🚀] Restaurando DNS Padrão..." -ForegroundColor Cyan
                try {
                    irm "$localBaseUrl/dns_padrão.ps1" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao restaurar DNS." -ForegroundColor Red
                }
            }
            "4" {
                Write-Host "`n  [🚀] Reparando Instalação..." -ForegroundColor Yellow
                try {
                    irm "$localBaseUrl/reparar_nextdns.ps1" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao reparar." -ForegroundColor Red
                }
            }
            "5" {
                Write-Host "`n  [🚀] Removendo Configurações HPTI..." -ForegroundColor Red
                try {
                    irm "$localBaseUrl/remover_hpti.ps1" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao remover." -ForegroundColor Red
                }
            }
            "6" {
                Write-Host "`n  [🚀] Configurando DNS Estático do NextDNS..." -ForegroundColor Magenta
                try {
                    irm "$localBaseUrl/dns_estatico.ps1" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao configurar DNS." -ForegroundColor Red
                }
            }
            "0" {
                Write-Host "`n  Voltando ao Menu Principal..." -ForegroundColor Yellow
                return
            }
            default {
                Write-Host "`n  [!] Opção inválida!" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                continue
            }
        }
        
        if ($escolha -ne "0") {
            Write-Host "`n  Pressione qualquer tecla para continuar..." -ForegroundColor Gray
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

    } while ($true)
}

# Inicia o submenu
Show-NextDNSMenu