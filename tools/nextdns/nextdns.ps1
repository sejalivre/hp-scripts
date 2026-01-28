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

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║            🌐  GERENCIAMENTO NEXTDNS  🌐                     ║" -ForegroundColor Cyan
    Write-Host "  ║                docs.hpinfo.com.br                            ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-NextDNSMenu {
    $localBaseUrl = "get.hpinfo.com.br/tools/nextdns"
    
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
        Write-Host "  ══════════════════════  OPÇÕES  ═══════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Instalar NextDNS     - Instalação completa" -ForegroundColor Green
        Write-Host "  [2] Ver/Alterar ID       - Configurar ID do NextDNS" -ForegroundColor Cyan
        Write-Host "  [3] Restaurar DNS Padrão - Voltar ao DNS original" -ForegroundColor Cyan
        Write-Host "  [4] Reparar Instalação   - Corrigir problemas" -ForegroundColor Yellow
        Write-Host "  [5] Remover Config HPTI  - Limpar configurações" -ForegroundColor Red
        Write-Host ""
        Write-Host "  [0] Menu Principal" -ForegroundColor DarkGray
        Write-Host ""
        
        $escolha = Read-Host "  Escolha uma opção"

        switch ($escolha) {
            "1" {
                Write-Host "`n  [🚀] Instalando NextDNS..." -ForegroundColor Green
                try {
                    irm "https://$localBaseUrl/install" | iex
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
                            irm "https://$localBaseUrl/install" | iex
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
                    irm "https://$localBaseUrl/dns_padrão" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao restaurar DNS." -ForegroundColor Red
                }
            }
            "4" {
                Write-Host "`n  [🚀] Reparando Instalação..." -ForegroundColor Yellow
                try {
                    irm "https://$localBaseUrl/reparar_nextdns" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao reparar." -ForegroundColor Red
                }
            }
            "5" {
                Write-Host "`n  [🚀] Removendo Configurações HPTI..." -ForegroundColor Red
                try {
                    irm "https://$localBaseUrl/remover_hpti" | iex
                }
                catch {
                    Write-Host "`n  [❌] ERRO: Falha ao remover." -ForegroundColor Red
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