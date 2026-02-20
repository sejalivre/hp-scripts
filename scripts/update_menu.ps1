<#
.SYNOPSIS
    Menu de Gerenciamento Windows Update - HP-Scripts
.DESCRIPTION
    Submenu dedicado para restauração e instalação do Windows Update.
    Documentação: docs.hpinfo.com.br
#>

# Configuração de encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "HP Scripts - Gerenciamento Windows Update"

# Detecção robusta do diretório do script e modo de execução
$ScriptRoot = $PSScriptRoot

if ([string]::IsNullOrEmpty($ScriptRoot)) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Verificar se estamos executando de um repositório local (com scripts/)
$IsLocalExecution = $false
if (Test-Path (Join-Path $ScriptRoot "scripts")) {
    $IsLocalExecution = $true
}

# URL base para downloads remotos
$baseUrl = "get.hpinfo.com.br"

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║           🔄  GERENCIAMENTO WINDOWS UPDATE  🔄               ║" -ForegroundColor Cyan
    Write-Host "  ║                docs.hpinfo.com.br                            ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-LocalOrRemoteScript {
    param(
        [string]$ScriptName
    )
    
    if ($IsLocalExecution) {
        $scriptPath = Join-Path $ScriptRoot "scripts\$ScriptName"
        if (Test-Path $scriptPath) {
            & $scriptPath
        }
        else {
            Write-Host "`n  [❌] ERRO: Script local não encontrado: $scriptPath" -ForegroundColor Red
        }
    }
    else {
        $finalUrl = "https://$baseUrl/scripts/$ScriptName"
        $TempScript = Join-Path $env:TEMP "HPTI_$ScriptName"
        try {
            Write-Host "`n  [INFO] Baixando script remoto..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $finalUrl -OutFile $TempScript -UseBasicParsing
            if (Test-Path $TempScript) {
                & $TempScript
                Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host "`n  [❌] ERRO: Falha ao baixar script remoto." -ForegroundColor Red
            Write-Host "  URL: $finalUrl" -ForegroundColor Gray
            Write-Host "  Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
}

function Show-UpdateMenu {
    do {
        Show-Header
        Write-Host "  ┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Gray
        Write-Host "  │  [1] Restaura Update   - Diagnosticar e reparar componentes  │" -ForegroundColor White
        Write-Host "  │  [2] Instala Update   - Baixar e instalar atualizações    │" -ForegroundColor White
        Write-Host "  └──────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host ""
        
        $escolha = Read-Host "  Escolha uma opção"

        switch ($escolha) {
            "1" {
                Write-Host "`n  [🚀] Iniciando Restauração do Windows Update..." -ForegroundColor Yellow
                Invoke-LocalOrRemoteScript -ScriptName "update_repair.ps1"
            }
            "2" {
                Write-Host "`n  [🚀] Iniciando Instalação de Atualizações..." -ForegroundColor Green
                Invoke-LocalOrRemoteScript -ScriptName "update_install.ps1"
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
Show-UpdateMenu