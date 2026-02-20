#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Menu de Gerenciamento do Windows Update - HPCRAFT
.DESCRIPTION
    Submenu com opções para restaurar ou instalar updates
#>

# Configuração de encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "HP Scripts - Menu Windows Update"

# Detecção do modo de execução
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

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║         🔄  GERENCIAMENTO WINDOWS UPDATE  🔄                 ║" -ForegroundColor Cyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-UpdateMenu {
    do {
        Show-Header
        
        Write-Host "  ══════════════════════  OPÇÕES  ═══════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Restaura Update  - Diagnostica e repara o Windows Update" -ForegroundColor Yellow
        Write-Host "  [2] Instala Update   - Instala atualizações via PSWindowsUpdate" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [0] Menu Principal" -ForegroundColor DarkGray
        Write-Host ""
        
        $escolha = Read-Host "  Escolha uma opção"

        switch ($escolha) {
            "1" {
                Write-Host "`n  [🚀] Iniciando Restauração do Windows Update..." -ForegroundColor Yellow
                try {
                    if ($IsLocalExecution) {
                        $scriptPath = Join-Path $ScriptRoot "scripts/update_repair.ps1"
                        if (Test-Path $scriptPath) {
                            & $scriptPath
                        } else {
                            Write-Host "`n  [❌] Script não encontrado: $scriptPath" -ForegroundColor Red
                        }
                    } else {
                        irm "https://$baseUrl/scripts/update_repair" | iex
                    }
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao executar." -ForegroundColor Red
                    Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            "2" {
                Write-Host "`n  [🚀] Iniciando Instalação de Updates..." -ForegroundColor Green
                try {
                    if ($IsLocalExecution) {
                        $scriptPath = Join-Path $ScriptRoot "scripts/update_install.ps1"
                        if (Test-Path $scriptPath) {
                            & $scriptPath
                        } else {
                            Write-Host "`n  [❌] Script não encontrado: $scriptPath" -ForegroundColor Red
                        }
                    } else {
                        irm "https://$baseUrl/scripts/update_install" | iex
                    }
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao executar." -ForegroundColor Red
                    Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            "0" {
                Write-Host "`n  Voltando ao Menu Principal..." -ForegroundColor Yellow
                return
            }
            default {
                Write-Host "`n  [!] Opção inválida!" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
        
        if ($escolha -ne "0") {
            Write-Host "`n  Pressione qualquer tecla para continuar..." -ForegroundColor Gray
            if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
                try {
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                catch {
                    Read-Host "Pressione ENTER"
                }
            } else {
                Read-Host "Pressione ENTER"
            }
        }

    } while ($true)
}

Show-UpdateMenu
