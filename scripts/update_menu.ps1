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
        Write-Host ("  === $Title ===" + $(if ($Subtitle) { " | $Subtitle" })) -ForegroundColor Green
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
        Write-Host "  [{0}] {1}  {2}" -f $numStr, $idPadded, $descPadded -ForegroundColor DarkGreen
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
}

function Show-Header {
    Clear-Host
    Show-BoxHeader -Title "GERENCIAMENTO WINDOWS UPDATE"
}

function Show-UpdateMenu {
    do {
        Show-Header

        Show-MenuItem -Number 1 -ID "Restore" -Description "Diagnostica e repara Windows Update"
        Show-MenuItem -Number 2 -ID "Install" -Description "Instala atualizações"
        Write-Host ""
        Write-Host "  [0] Menu Principal" -ForegroundColor DarkGreen
        Write-Host ""

        $escolha = Read-MenuKey -Prompt "  Escolha uma opcao"

        switch ($escolha) {
            "1" {
                Write-Host "`n  Iniciando Restauracao..." -ForegroundColor Green
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
            Write-Host "`nPressione ENTER para continuar..." -ForegroundColor DarkGreen
            Read-Host
        }

    } while ($true)
}

Show-UpdateMenu
