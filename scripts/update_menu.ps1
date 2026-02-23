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

# Função para captura de tecla instantânea (sem ENTER)
function Read-MenuKey {
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
        return Read-Host $Prompt
    }
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ===============================================" -ForegroundColor Cyan
    Write-Host "  GERENCIAMENTO WINDOWS UPDATE" -ForegroundColor Cyan
    Write-Host "  ===============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-UpdateMenu {
    do {
        Show-Header
        
        Write-Host "  [1] Restaura Update - Diagnostica e repara" -ForegroundColor Yellow
        Write-Host "  [2] Instala Update  - Instala atualizacoes" -ForegroundColor Green
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
