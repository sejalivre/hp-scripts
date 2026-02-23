<#
.SYNOPSIS
    Menu de Gerenciamento do Windows Update - HPCRAFT
.DESCRIPTION
    Submenu com opcoes para restaurar ou instalar updates
#>

# Verificacao de administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    exit
}

# Configuracao de encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "HP Scripts - Menu Windows Update"

# Deteccao do modo de execucao
$ScriptRoot = $PSScriptRoot
$IsLocalExecution = $false

if ([string]::IsNullOrEmpty($ScriptRoot)) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

if (Test-Path (Join-Path $ScriptRoot "scripts")) {
    $IsLocalExecution = $true
}

$baseUrl = "get.hpinfo.com.br"

# ============================================================
# IMPORTAR MÓDULO UI-UTILS (com fallback remoto e inline)
# ============================================================
$_uiLoaded = $false

# Estágio 1: Tentar caminho local relativo
$uiUtilsPath = Join-Path $ScriptRoot "ui-utils.ps1"
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
    Show-BoxHeader -Title "GERENCIAMENTO WINDOWS UPDATE"
}

function Show-UpdateMenu {
    do {
        Show-Header

        Show-MenuItem -Number 1 -ID "Restore" -Description "Diagnostica e repara Windows Update" -Color "Yellow"
        Show-MenuItem -Number 2 -ID "Install" -Description "Instala atualizações" -Color "Green"
        Write-Host ""
        Write-Host "  [0] Menu Principal" -ForegroundColor DarkGray
        Write-Host ""

        $escolha = Read-MenuKey -Prompt "  Escolha uma opcao"

        switch ($escolha) {
            "1" {
                Write-Host "`n  Iniciando Restauracao..." -ForegroundColor Yellow
                try {
                    if ($IsLocalExecution) {
                        $scriptPath = Join-Path $ScriptRoot "scripts/update_repair.ps1"
                        if (Test-Path $scriptPath) {
                            & $scriptPath
                        } else {
                            Write-Host "Script nao encontrado" -ForegroundColor Red
                        }
                    } else {
                        irm "https://$baseUrl/scripts/update_repair" | iex
                    }
                }
                catch {
                    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            "2" {
                Write-Host "`n  Iniciando Instalacao..." -ForegroundColor Green
                try {
                    if ($IsLocalExecution) {
                        $scriptPath = Join-Path $ScriptRoot "scripts/update_install.ps1"
                        if (Test-Path $scriptPath) {
                            & $scriptPath
                        } else {
                            Write-Host "Script nao encontrado" -ForegroundColor Red
                        }
                    } else {
                        irm "https://$baseUrl/scripts/update_install" | iex
                    }
                }
                catch {
                    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            "0" {
                return
            }
            default {
                Write-Host "Opcao invalida!" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
        
        if ($escolha -ne "0") {
            Write-Host "`nPressione ENTER para continuar..." -ForegroundColor Gray
            Read-Host
        }

    } while ($true)
}

Show-UpdateMenu
