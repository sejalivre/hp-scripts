<#
.SYNOPSIS
    Menu de Ferramentas Portáteis - HP Scripts
.DESCRIPTION
    Menu secundário para execução de ferramentas portáteis compactadas em .7z
    Extrai automaticamente para pasta temporária e executa
.NOTES
    Autor: HSA
    Versão: 1.0
#>

# Configuração de encoding e título 
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "HP Scripts - Menu de Ferramentas"

# Forçar TLS 1.2 para compatibilidade com GitHub
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Verificação de Versão do PowerShell (Modernização)
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERRO] Este script requer PowerShell 5.1 ou superior (Windows 10/11)." -ForegroundColor Red
    Write-Host "Versão detectada: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Read-Host "Pressione ENTER para sair"
    exit 1
}

# Caminho base do script - Detecção Robusta
$ScriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptPath)) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $ScriptPath = (Get-Location).Path
    }
}

$ToolsPath = Join-Path (Split-Path -Parent $ScriptPath) "tools"  # Usa ../tools/ da raiz
$TempPath = Join-Path $env:TEMP "HP-Tools"
$BaseUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$7zExe = Join-Path $TempPath "7z.exe"
$7zTxe = Join-Path $ToolsPath "7z.txe"
$7zDll = Join-Path $TempPath "7z.dll"
$7zTxl = Join-Path $ToolsPath "7z.txl"

# ============================================================
# IMPORTAR MÓDULO UI-UTILS
# ============================================================
$uiUtilsPath = Join-Path (Split-Path -Parent $ScriptPath) "scripts\ui-utils.ps1"
if (Test-Path $uiUtilsPath) {
    . $uiUtilsPath
}

function Check-Internet {
    try {
        $test = Test-Connection -ComputerName "google.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        return $test
    }
    catch { return $false }
}

# Função para preparar 7-Zip
# Função para preparar 7-Zip
function Initialize-7Zip {
    # Garante que o diretório temporário existe
    if (-not (Test-Path $TempPath)) {
        New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
    }

    # Verifica e prepara 7z.exe
    if (-not (Test-Path $7zExe)) {
        if (Test-Path $7zTxe) {
            Copy-Item $7zTxe $7zExe -Force
        }
        else {
            # Tenta baixar 7z.txe se não existir localmente
            if (Check-Internet) {
                Write-Host "  -> Baixando dependência 7-Zip..." -ForegroundColor Gray
                try {
                    Invoke-WebRequest -Uri "$BaseUrl/7z.txe" -OutFile $7zExe -UseBasicParsing
                }
                catch { Write-Host "  [ERRO] Falha ao baixar 7z.exe" -ForegroundColor Red }
            }
        }
    }
    
    # Verifica e prepara 7z.dll
    if (-not (Test-Path $7zDll)) {
        if (Test-Path $7zTxl) {
            Copy-Item $7zTxl $7zDll -Force
        }
        # Dll geralmente não é estritamente necessária se usar o exe estático, mas mantendo lógica existente se possível
    }
}

# Função para extrair e executar ferramenta
# Função para extrair e executar ferramenta
function Start-Tool {
    param(
        [string]$ArchiveName,
        [string]$ExeName,
        [string]$Password = "0"
    )
    
    # Define caminhos
    $localArchive = Join-Path $ToolsPath $ArchiveName
    $tempArchive = Join-Path $TempPath $ArchiveName
    $archiveToUse = $null
    
    # 1. Verifica se existe na pasta tools (Original)
    if (Test-Path $localArchive) {
        $archiveToUse = $localArchive
    }
    # 2. Se não, verifica se já foi baixado no temp
    elseif (Test-Path $tempArchive) {
        $archiveToUse = $tempArchive
    }
    # 3. Se não, tenta baixar
    else {
        Write-Host "`n  [AVISO] Ferramenta não encontrada localmente: $ArchiveName" -ForegroundColor Yellow
        if (Check-Internet) {
            Write-Host "  -> Tentando baixar de: $BaseUrl/$ArchiveName" -ForegroundColor Cyan
            try {
                if (-not (Test-Path $TempPath)) { New-Item -ItemType Directory -Path $TempPath -Force | Out-Null }
                Invoke-WebRequest -Uri "$BaseUrl/$ArchiveName" -OutFile $tempArchive -UseBasicParsing
                if (Test-Path $tempArchive) {
                    $archiveToUse = $tempArchive
                    Write-Host "  [OK] Download concluído." -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  [FALHA] Erro no download: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  [ERRO] Sem internet para baixar a ferramenta." -ForegroundColor Red
        }
    }

    if (-not $archiveToUse) {
        Write-Host "  [ERRO] Impossível executar $ArchiveName" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    Initialize-7Zip
    
    Write-Host "`n  Extraindo $ArchiveName..." -ForegroundColor Cyan
    
    # Criar pasta temp se não existir
    if (-not (Test-Path $TempPath)) {
        New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
    }
    
    # Extrair arquivo
    if (Test-Path $7zExe) {
        $extractArgs = "x `"$archiveToUse`" -o`"$TempPath`" -y -p$Password"
        Start-Process -FilePath $7zExe -ArgumentList $extractArgs -Wait -WindowStyle Hidden
    }
    else {
        Write-Host "  [ERRO] 7z.exe não encontrado." -ForegroundColor Red
        return
    }
    
    # Executar programa
    # Executar programa
    # Procura recursivamente pelo executável, pois alguns arquivos extraem em subpastas
    $exePath = $null
    $potentialExes = Get-ChildItem -Path $TempPath -Filter $ExeName -Recurse -ErrorAction SilentlyContinue
    
    if ($potentialExes) {
        # Pega o primeiro encontrado (caso haja duplicatas, geralmente o primeiro é o correto ou único)
        $exeFile = $potentialExes | Select-Object -First 1
        $exePath = $exeFile.FullName
        $workDir = $exeFile.DirectoryName
        
        Write-Host "  Executando $ExeName..." -ForegroundColor Green
        try {
            Start-Process -FilePath $exePath -WorkingDirectory $workDir
        }
        catch {
            Write-Host "  [ERRO] Falha ao iniciar o processo: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  [ERRO] Executável não encontrado após extração: $ExeName" -ForegroundColor Red
        Write-Host "  Verifique se o arquivo foi baixado corretamente." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

# Funções Read-MenuKey e Show-BoxHeader estão disponíveis no ui-utils.ps1

# Função para limpar cabeçalho
function Show-Header {
    Clear-Host
    Show-BoxHeader -Title "MENU DE FERRAMENTAS PORTÁTEIS" -Subtitle "HP Scripts v1.0"
}

# Menu Principal
function Show-MainMenu {
    Show-Header
    Write-Host "  ┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Gray
    Write-Host "  │  [1] Diagnóstico de Hardware         [5] Gerenciamento Disco │" -ForegroundColor White
    Write-Host "  │  [2] Otimização do Sistema           [6] Ferramentas de Rede │" -ForegroundColor White
    Write-Host "  │  [3] Senha e Usuários                [7] Boot e Recuperação  │" -ForegroundColor White
    Write-Host "  │  [4] Utilitários Diversos            [0] Menu Principal      │" -ForegroundColor White
    Write-Host "  └──────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
    Write-Host ""
}

# Submenu - Diagnóstico de Hardware
function Show-DiagnosticoMenu {
    Show-Header
    Show-MenuSeparator -Text "DIAGNÓSTICO DE HARDWARE"
    Show-MenuItem -Number 1 -ID "CPU-Z" -Description "Informações detalhadas do processador"
    Show-MenuItem -Number 2 -ID "AIDA64" -Description "Diagnóstico completo do sistema"
    Show-MenuItem -Number 3 -ID "CoreTemp" -Description "Monitor de temperatura da CPU"
    Show-MenuItem -Number 4 -ID "CrystalDisk" -Description "Saúde do disco rígido/SSD"
    Show-MenuItem -Number 5 -ID "SSDLife" -Description "Vida útil de SSDs"
    Show-MenuItem -Number 6 -ID "BatteryInfo" -Description "Informações da bateria"
    Show-MenuItem -Number 7 -ID "KBTutility" -Description "Teste de teclado"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "cpuz_All.7z" "cpuz_All.exe" }
        "2" { Start-Tool "ad.7z" "ad.exe" }
        "3" { Start-Tool "CoreTemp.7z" "Core Temp.exe" }
        "4" { Start-Tool "CrystalDiskInfo.7z" "DiskInfo64.exe" }
        "5" { Start-Tool "ssdlife.7z" "SSDLife.exe" }
        "6" { Start-Tool "BatteryInfoView.7z" "BatteryInfoView.exe" }
        "7" { Start-Tool "KBTutility.7z" "KBTutility.exe" }
        "0" { return }
    }
    Show-DiagnosticoMenu
}

# Submenu - Otimização
function Show-OtimizacaoMenu {
    Show-Header
    Show-MenuSeparator -Text "OTIMIZAÇÃO DO SISTEMA"
    Show-MenuItem -Number 1 -ID "Optimizer" -Description "Otimização completa do Windows"
    Show-MenuItem -Number 2 -ID "Winaero" -Description "Personalização avançada"
    Show-MenuItem -Number 3 -ID "Autoruns" -Description "Gerenciar inicialização"
    Show-MenuItem -Number 4 -ID "LastActivity" -Description "Últimas atividades do sistema"
    Show-MenuItem -Number 5 -ID "WUB" -Description "Bloquear Windows Update"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "Optimizer-16.7.7z" "Optimizer-16.7.exe" }
        "2" { Start-Tool "WinaeroTweaker.7z" "WinaeroTweaker.exe" }
        "3" { Start-Tool "Autoruns.7z" "Autoruns64.exe" }
        "4" { Start-Tool "LastActivityView.7z" "LastActivityView.exe" }
        "5" { Start-Tool "WindowsUpdateBlocker.7z" "Wub.exe" }
        "0" { return }
    }
    Show-OtimizacaoMenu
}

# Submenu - Senha e Usuários
function Show-SenhaMenu {
    Show-Header
    Show-MenuSeparator -Text "SENHA E USUÁRIOS"
    Show-MenuItem -Number 1 -ID "PassReset" -Description "Resetar senha de usuário"
    Show-MenuItem -Number 2 -ID "ActivePass" -Description "Alterar senha ativa"
    Show-MenuItem -Number 3 -ID "AdminReset" -Description "Resetar senha admin"
    Show-MenuItem -Number 4 -ID "Daossoft" -Description "Ferramenta Daosoft"
    Show-MenuItem -Number 5 -ID "OOUserMgr" -Description "Gerenciador de usuários"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "PasswordReset.7z" "PasswordReset.exe" }
        "2" { Start-Tool "ActivePasswordChanger.7z" "PasswordChanger.exe" }
        "3" { Start-Tool "AdminPasswordResetter.7z" "AdminPasswordResetter.exe" }
        "4" { Start-Tool "DaossoftWindowsPassword.7z" "DaossoftWindowsPassword.exe" }
        "5" { Start-Tool "OOUserManager.7z" "ooum64.exe" }
        "0" { return }
    }
    Show-SenhaMenu
}

# Submenu - Utilitários
function Show-UtilitariosMenu {
    Show-Header
    Show-MenuSeparator -Text "UTILITÁRIOS DIVERSOS"
    Show-MenuItem -Number 1 -ID "Notepad++" -Description "Editor de texto avançado"
    Show-MenuItem -Number 2 -ID "UltraISO" -Description "Editor/Criador de ISOs"
    Show-MenuItem -Number 3 -ID "Unlocker" -Description "Desbloquear arquivos em uso"
    Show-MenuItem -Number 4 -ID "TakeOwner" -Description "Assumir propriedade"
    Show-MenuItem -Number 5 -ID "Revo" -Description "Desinstalar programas"
    Show-MenuItem -Number 6 -ID "Screenshot" -Description "Captura de tela"
    Show-MenuItem -Number 7 -ID "USBShow" -Description "Recuperar arquivos USB"
    Show-MenuItem -Number 8 -ID "Firewall" -Description "Bloquear no firewall"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "Notepad++.7z" "notepad++.exe" }
        "2" { Start-Tool "UltraISO.7z" "UltraISO.exe" }
        "3" { Start-Tool "Unlocker.7z" "Unlocker.exe" }
        "4" { Start-Tool "TakeOwnershipPro.7z" "TakeOwnershipPro.exe" }
        "5" { Start-Tool "RevoUninstaller.7z" "RevoUnin.exe" }
        "6" { Start-Tool "screenshot.7z" "Screenshot.exe" }
        "7" { Start-Tool "usbshow.7z" "usbshow.exe" }
        "8" { Start-Tool "BloqueadordeFirewall.7z" "Firewall App Blocker.exe" }
        "0" { return }
    }
    Show-UtilitariosMenu
}

# Submenu - Disco
function Show-DiscoMenu {
    Show-Header
    Show-MenuSeparator -Text "GERENCIAMENTO DISCO"
    Show-MenuItem -Number 1 -ID "WizTree" -Description "Analisar espaço em disco"
    Show-MenuItem -Number 2 -ID "DiskDefrag" -Description "Desfragmentar disco"
    Show-MenuItem -Number 3 -ID "ChkDskGUI" -Description "Verificar disco (interface)"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "wiztree.7z" "WizTree64.exe" }
        "2" { Start-Tool "DiskDefrag.7z" "DiskDefrag.exe" }
        "3" { Start-Tool "ChkDskGui.7z" "ChkDskGui.exe" }
        "0" { return }
    }
    Show-DiscoMenu
}

# Submenu - Rede
function Show-RedeMenu {
    Show-Header
    Show-MenuSeparator -Text "FERRAMENTAS DE REDE"
    Show-MenuItem -Number 1 -ID "AdvIPScan" -Description "Escanear rede local"
    Show-MenuItem -Number 2 -ID "ChangeMAC" -Description "Alterar endereço MAC"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "advancedipscanner.7z" "advanced_ip_scanner.exe" }
        "2" { Start-Tool "MudarMAC.7z" "TMAC_Manager.exe" }
        "0" { return }
    }
    Show-RedeMenu
}

# Submenu - Boot e Recuperação
function Show-BootMenu {
    Show-Header
    Show-MenuSeparator -Text "BOOT E RECUPERAÇÃO"
    Show-MenuItem -Number 1 -ID "NTBOOTFix" -Description "Reparar boot do Windows"
    Show-MenuItem -Number 2 -ID "BOOTICE" -Description "Editor de boot avançado"
    Show-MenuItem -Number 3 -ID "BCDEdit" -Description "Editar configuração BCD"
    Show-MenuItem -Number 4 -ID "QemuBoot" -Description "Testar boot de ISO"
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-MenuKey -Prompt "  Escolha uma opcao"
    switch ($choice) {
        "1" { Start-Tool "NTBOOTAutoFix.7z" "NTBOOTautofix.exe" }
        "2" { Start-Tool "BOOTICEx64.7z" "BOOTICEx64.exe" }
        "3" { Start-Tool "BCD_UFI_EDIT.7z" "BCDEDIT.exe" }
        "4" { Start-Tool "QemuSimpleBoot.7z" "QemuSimpleBoot.exe" }
        "0" { return }
    }
    Show-BootMenu
}

# Loop principal
function Main {
    do {
        Show-MainMenu
        $mainChoice = Read-MenuKey -Prompt "  Escolha uma categoria"
        
        switch ($mainChoice) {
            "1" { Show-DiagnosticoMenu }
            "2" { Show-OtimizacaoMenu }
            "3" { Show-SenhaMenu }
            "4" { Show-UtilitariosMenu }
            "5" { Show-DiscoMenu }
            "6" { Show-RedeMenu }
            "7" { Show-BootMenu }
            "0" { 
                Write-Host "`n  Voltando ao Menu Principal..." -ForegroundColor Yellow
                return 
            }
        }
    } while ($true)
}

# Executar menu
Main
