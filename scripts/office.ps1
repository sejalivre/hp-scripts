<#
.SYNOPSIS
    Menu de Gerenciamento Microsoft Office - HPCRAFT
.DESCRIPTION
    Submenu com opções para instalação, reparo e remoção do MS Office
#>

# Verificação de administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    exit
}

# Configuração de encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "HP Scripts - Menu Microsoft Office"

# Detecção do modo de execução
$ScriptRoot = $PSScriptRoot
$IsLocalExecution = $false

if ([string]::IsNullOrEmpty($ScriptRoot)) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = (Get-Location | Select-Object -ExpandProperty Path | Select-Object -First 1)
    }
}

if (Test-Path (Join-Path $ScriptRoot "scripts")) {
    $IsLocalExecution = $true
}
# Fallback para estrutura portable
elseif ($ScriptRoot -like "*portable*") {
    $IsLocalExecution = $true
}

$baseUrl = "get.hpinfo.com.br"
$installUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools/office/install.ps1"

# Identificar o ClickToRun Executable
$ctrPath = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeClickToRun.exe"
if (-not (Test-Path $ctrPath)) {
    $ctrPath = "C:\Program Files (x86)\Common Files\microsoft shared\ClickToRun\OfficeClickToRun.exe"
}

# ============================================================
# IMPORTAR MÓDULO UI-UTILS (com fallback remoto e inline)
# ============================================================
$_uiLoaded = $false

# Estágio 1: Tentar caminho local relativo
$uiUtilsPath = Join-Path $ScriptRoot "ui-utils.ps1"
if (-not (Test-Path $uiUtilsPath) -and $ScriptRoot -like "*scripts*") {
     $uiUtilsPath = Join-Path $ScriptRoot "ui-utils.ps1"
}
elseif (-not (Test-Path $uiUtilsPath)) {
     $uiUtilsPath = Join-Path $ScriptRoot "scripts\ui-utils.ps1"
}

if (Test-Path $uiUtilsPath) {
    try {
        . $uiUtilsPath
        $_uiLoaded = $true
    } catch {}
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
        # Fallback silencioso aqui, o Estágio 3 cuidará da interface básica
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
    function Show-MenuItem {
        param([int]$Number, [string]$ID, [string]$Description, [string]$Color = "DarkGreen", [int]$Width = 76)
        $numStr = $Number.ToString("D2")
        $idPadded = $ID.PadRight(11)
        $descPadded = $Description.PadRight($Width - 19)
        Write-Host ("  [{0}] {1}  {2}" -f $numStr, $idPadded, $descPadded) -ForegroundColor DarkGreen
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
        return Read-Host
    }
}

# stub para Write-HPLog caso não exista
if (-not (Get-Command Write-HPLog -ErrorAction SilentlyContinue)) {
    function Write-HPLog { param($Message, $Level) }
}

# ============================================================
# FUNÇÕES DE AÇÃO
# ============================================================

function Install-Office {
    param([string]$DownloadUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365AppsBasicRetail&platform=x64&language=pt-br&version=O16GA")
    Write-Host "`n  [INFO] Iniciando instalação do Office..." -ForegroundColor Yellow
    
    # Determinar script de instalação
    $localInstallScript = ""
    
    # Lista de locais para procurar o instalador local
    $pathsToTry = @()
    if ($ScriptRoot) {
        try {
            $pathsToTry += Join-Path $ScriptRoot "tools\office\install.ps1"
            $parent = Split-Path $ScriptRoot -Parent
            if ($parent) {
                $pathsToTry += Join-Path $parent "tools\office\install.ps1"
            }
        } catch {}
    }
    
    foreach ($path in $pathsToTry) {
        if (Test-Path $path) {
            $localInstallScript = $path
            break
        }
    }

    $tempScript = Join-Path $env:TEMP "install_office.ps1"
    $scriptToExecute = ""

    if ($localInstallScript) {
        $scriptToExecute = $localInstallScript
        Write-Host "  [INFO] Usando script de instalação local." -ForegroundColor DarkGreen
    }
    else {
        try {
            Write-Host "  [INFO] Baixando script de instalação remoto..." -ForegroundColor DarkGreen
            Invoke-WebRequest -Uri $installUrl -OutFile $tempScript -UseBasicParsing -ErrorAction Stop
            $scriptToExecute = $tempScript
        }
        catch {
            Write-Host "  [ERRO] Falha ao baixar o instalador: $($_.Exception.Message)" -ForegroundColor Red
            Write-HPLog -Message "ERRO no download do Office: $($_.Exception.Message)" -Level ERRO
            return
        }
    }

    if (Test-Path $scriptToExecute) {
        Write-Host "  [INFO] Executando instalador..." -ForegroundColor Green
        try {
            & $scriptToExecute -DownloadUrl $DownloadUrl
            Write-HPLog -Message "Script de instalação do Office executado com sucesso." -Level INFO
        }
        catch {
            Write-Host "  [ERRO] Falha ao executar o instalador: $($_.Exception.Message)" -ForegroundColor Red
            Write-HPLog -Message "ERRO na execução do instalador do Office: $($_.Exception.Message)" -Level ERRO
        }
        finally {
            if ($scriptToExecute -eq $tempScript) {
                Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Repair-Office {
    Write-Host "`n  [INFO] Iniciando reparo do Office..." -ForegroundColor Yellow
    
    # 1. Limpar Cache
    $cachePath = "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache"
    if (Test-Path $cachePath) {
        Write-Host "  [INFO] Limpando cache do Office..." -ForegroundColor DarkGreen
        try {
            # Tentar encerrar processos do office antes
            $processos = @("winword", "excel", "powerpnt", "outlook", "onenote")
            foreach ($p in $processos) {
                Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 1
            Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cache limpo." -ForegroundColor Green
        }
        catch {
            Write-Host "  [AVISO] Não foi possível limpar todo o cache." -ForegroundColor Yellow
        }
    }

    # 2. Executar Quick Repair
    if (Test-Path $ctrPath) {
        Write-Host "  [INFO] Iniciando Reparo Rápido nativo..." -ForegroundColor DarkGreen
        try {
            Start-Process -FilePath $ctrPath -ArgumentList "scenario=Repair RepairType=QuickRepair platform=x64 culture=pt-br DisplayLevel=True" -Wait
            Write-Host "  [OK] Processo de reparo concluído." -ForegroundColor Green
            Write-HPLog -Message "Reparo rápido do Office executado." -Level INFO
        }
        catch {
            Write-Host "  [ERRO] Falha ao iniciar Reparo Rápido: $($_.Exception.Message)" -ForegroundColor Red
            Write-HPLog -Message "ERRO no reparo do Office: $($_.Exception.Message)" -Level ERRO
        }
    }
    else {
        Write-Host "  [ERRO] OfficeClickToRun.exe não encontrado." -ForegroundColor Red
    }
}

function Remove-Office {
    Write-Host "`n  [AVISO] VOCÊ ESTÁ PRESTES A REMOVER O MICROSOFT OFFICE COMPLETAMENTE!" -ForegroundColor Red
    Write-Host "  Esta ação não pode ser desfeita." -ForegroundColor Red
    
    Write-Host ""
    Write-Host "  Deseja continuar com a remoção? (S/N): " -NoNewline -ForegroundColor Yellow
    $confirma = Read-Host
    
    if ($confirma -ne "S" -and $confirma -ne "s") {
        Write-Host "  [INFO] Operação cancelada pelo usuário." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    if (Test-Path $ctrPath) {
        Write-Host "  [INFO] Iniciando desinstalação..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath $ctrPath -ArgumentList "scenario=Uninstall platform=x64 culture=pt-br DisplayLevel=True" -Wait
            Write-Host "  [OK] Processo de desinstalação concluído." -ForegroundColor Green
            Write-HPLog -Message "Desinstalação do Office executada." -Level INFO
        }
        catch {
            Write-Host "  [ERRO] Falha ao iniciar desinstalação: $($_.Exception.Message)" -ForegroundColor Red
            Write-HPLog -Message "ERRO na desinstalação do Office: $($_.Exception.Message)" -Level ERRO
        }
    }
    else {
        Write-Host "  [ERRO] OfficeClickToRun.exe não encontrado." -ForegroundColor Red
    }
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

function Show-OfficeMenu {
    do {
        Clear-Host
        Show-BoxHeader -Title "GERENCIAMENTO OFFICE" -Subtitle "Instalação e Manutenção"
        
        # Verificar Status
        $isInstalled = Test-Path $ctrPath
        $statusStr = if ($isInstalled) { "Instalado" } else { "Não detectado" }
        
        Show-MenuItem -Number 1 -ID "INSTALAR" -Description "Baixar e Instalar Microsoft Office"
        Show-MenuItem -Number 2 -ID "REPARAR"  -Description "Reparo Rápido e Limpeza de Cache"
        Show-MenuItem -Number 3 -ID "REMOVER"  -Description "Desinstalação Completa (Confirmação)"
        Show-MenuItem -Number 4 -ID "BUSINESS" -Description "Instalar Office 365 Business (Via Link)"
        
        Write-Host ""
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGreen
        Write-Host ""

        $escolha = Read-MenuKey -Prompt "  Selecione uma opção"

        switch ($escolha) {
            "1" { Install-Office }
            "2" { Repair-Office }
            "3" { Remove-Office }
            "4" { 
                Write-Host ""
                $url = Read-Host "  Digite a URL do instalador do Office 365 Business"
                if (-not [string]::IsNullOrWhiteSpace($url)) {
                    Install-Office -DownloadUrl $url
                } else {
                    Write-Host "  [AVISO] URL inválida." -ForegroundColor Yellow
                }
            }
            "0" { return }
            "Q" { exit }
            "q" { exit }
        }
        
        if ($escolha -ne "0") {
            Write-Host "`n  Pressione ENTER para continuar..." -ForegroundColor DarkGreen
            Read-Host
        }
    } while ($true)
}

Show-OfficeMenu
