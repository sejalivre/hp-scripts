<#
.SYNOPSIS
    HP-Scripts .NET v1.0 - Reparo e Instalação de .NET Framework e Runtimes
.DESCRIPTION
    Script para gerenciar versões do .NET Framework, habilitar recursos legados
    e instalar runtimes modernos (.NET 6, 8).
.NOTES
    Autor: HP-Scripts Team
    Versão: 1.0
    Compatibilidade: PowerShell 5.1+ (Windows 10/11)
    Requer: Execução como Administrador
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CONFIGURAÇÕES E FUNÇÕES AUXILIARES
# ============================================================

# Cores para output
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"

# Detecta diretório do script
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $ScriptDir) { $ScriptDir = Get-Location }

# ============================================================
# IMPORTAR MÓDULO UI-UTILS (com fallback remoto e inline)
# ============================================================
$_uiLoaded = $false
$baseUrl = "get.hpinfo.com.br"

# Estágio 1: Tentar caminho local relativo
$uiUtilsPath = Join-Path $ScriptDir "ui-utils.ps1"
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
    }
    catch {
        Write-Warning "[AVISO] Falha ao carregar ui-utils remotamente."
    }
}

# Estágio 3: Fallback inline mínimo
if (-not $_uiLoaded) {
    function Show-BoxHeader { param([string]$Title, [string]$Subtitle = "") Write-Host "`n=== $Title ===" -ForegroundColor Cyan }
    function Show-MenuItem { param([int]$Number, [string]$ID, [string]$Description) Write-Host "  [$Number] $ID - $Description" }
    function Show-MenuSeparator { param([string]$Text = "") Write-Host "`n--- $Text ---" -ForegroundColor Yellow }
    function Show-MenuFooter { Write-Host "" }
    function Read-MenuKey { param([string]$Prompt = "Opção") Write-Host "$Prompt: " -NoNewline; return Read-Host }
}

function Write-Status {
    param([string]$Message, [string]$Status, [string]$Color = "White")
    $icon = switch ($Status) { "SUCESSO" { "✅" }; "AVISO" { "⚠️" }; "ERRO" { "❌" }; "INFO" { "ℹ️" }; default { "➡️" } }
    Write-Host "$icon $Message" -ForegroundColor $Color
}

# ============================================================
# FUNÇÕES DE REPARO E INSTALAÇÃO
# ============================================================

function Repair-NetFramework {
    Write-HPLog -Message "Iniciando reparo de .NET Framework via DISM" -Level INFO
    Write-Status "Reparando imagem do Windows (.NET Framework) com DISM..." "INFO" $ColorInfo
    
    try {
        dism /Online /Cleanup-Image /RestoreHealth
        Write-Status "Reparo DISM concluído com sucesso!" "SUCESSO" $ColorSuccess
    }
    catch {
        Write-Status "Erro ao executar DISM: $($_.Exception.Message)" "ERRO" $ColorError
    }
}

function Enable-NetFx3 {
    Write-HPLog -Message "Tentando habilitar .NET 3.5" -Level INFO
    Write-Status "Habilitando .NET Framework 3.5 (requer Internet)..." "INFO" $ColorInfo
    
    try {
        dism /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess
        if ($LASTEXITCODE -eq 0) {
            Write-Status ".NET Framework 3.5 habilitado com sucesso!" "SUCESSO" $ColorSuccess
        } else {
            Write-Status "Falha ao habilitar .NET 3.5. Código de erro: $LASTEXITCODE" "ERRO" $ColorError
            Write-Status "Verifique se há conexão com a Internet ou use uma mídia do Windows." "AVISO" $ColorWarning
        }
    }
    catch {
        Write-Status "Erro: $($_.Exception.Message)" "ERRO" $ColorError
    }
}

function Install-ModernNet {
    param([string]$Version)
    
    Write-HPLog -Message "Instalando .NET $Version via winget" -Level INFO
    Write-Status "Verificando winget..." "INFO" $ColorInfo
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Status "Winget não encontrado. Instale-o primeiro via 'INSTALLPS1'." "ERRO" $ColorError
        return
    }

    $packageId = if ($Version -eq "6") { "Microsoft.DotNet.DesktopRuntime.6" } else { "Microsoft.DotNet.DesktopRuntime.8" }
    
    Write-Status "Instalando .NET $Version Desktop Runtime ($packageId)..." "INFO" $ColorInfo
    winget install --id $packageId --silent --accept-package-agreements --accept-source-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status ".NET $Version instalado com sucesso!" "SUCESSO" $ColorSuccess
    } else {
        Write-Status "Falha na instalação via winget. Código: $LASTEXITCODE" "ERRO" $ColorError
    }
}

function Launch-NetRepairTool {
    Write-HPLog -Message "Lançando Microsoft .NET Repair Tool" -Level INFO
    $url = "https://download.microsoft.com/download/2/B/D/2BDE5453-7E17-4910-BD9A-C102D38FD955/NetFxRepairTool.exe"
    $tempPath = Join-Path $env:TEMP "NetFxRepairTool.exe"
    
    Write-Status "Baixando Microsoft .NET Framework Repair Tool..." "INFO" $ColorInfo
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing
        if (Test-Path $tempPath) {
            Write-Status "Iniciando ferramenta..." "SUCESSO" $ColorSuccess
            Start-Process $tempPath -Wait
            Remove-Item $tempPath -Force
        }
    }
    catch {
        Write-Status "Falha ao baixar ferramenta: $($_.Exception.Message)" "ERRO" $ColorError
    }
}

# ============================================================
# MENU DO SCRIPT
# ============================================================

do {
    Clear-Host
    Show-BoxHeader -Title "REPARO E INSTALAÇÃO .NET" -Subtitle "HPCRAFT v1.0"
    
    Show-MenuSeparator -Text "REPARO E RECURSOS"
    Show-MenuItem -Number 1 -ID "REPARO"    -Description "Reparar .NET Framework (DISM)"
    Show-MenuItem -Number 2 -ID "NET35"     -Description "Habilitar .NET 3.5 (Legado)"
    Show-MenuItem -Number 3 -ID "MS-TOOL"   -Description "Ferramenta de Reparo Oficial MS"
    
    Show-MenuSeparator -Text "RUNTIMES MODERNOS"
    Show-MenuItem -Number 4 -ID "NET6"      -Description "Instalar .NET 6.0 Desktop Runtime"
    Show-MenuItem -Number 5 -ID "NET8"      -Description "Instalar .NET 8.0 Desktop Runtime"
    
    Show-MenuFooter -Options @("0", "Q") -Labels @("Menu Principal", "Sair")
    
    $choice = Read-MenuKey -Prompt "Selecione uma opção"
    
    switch ($choice) {
        "1" { Repair-NetFramework; Read-Host "`nPressione ENTER para continuar" }
        "2" { Enable-NetFx3; Read-Host "`nPressione ENTER para continuar" }
        "3" { Launch-NetRepairTool; Read-Host "`nPressione ENTER para continuar" }
        "4" { Install-ModernNet -Version "6"; Read-Host "`nPressione ENTER para continuar" }
        "5" { Install-ModernNet -Version "8"; Read-Host "`nPressione ENTER para continuar" }
        "0" { return }
        "Q" { exit }
        "q" { exit }
    }
} while ($true)
