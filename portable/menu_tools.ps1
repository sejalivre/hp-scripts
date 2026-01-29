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

# Caminho base do script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsPath = Join-Path (Split-Path -Parent $ScriptPath) "tools"  # Usa ../tools/ da raiz
$TempPath = Join-Path $env:TEMP "hsati"
$7zExe = Join-Path $ToolsPath "7z.exe"
$7zTxe = Join-Path $ToolsPath "7z.txe"
$7zDll = Join-Path $ToolsPath "7z.dll"
$7zTxl = Join-Path $ToolsPath "7z.txl"

# Função para preparar 7-Zip
function Initialize-7Zip {
    if (-not (Test-Path $7zExe)) {
        if (Test-Path $7zTxe) {
            Copy-Item $7zTxe $7zExe -Force
        }
    }
    if (-not (Test-Path $7zDll)) {
        if (Test-Path $7zTxl) {
            Copy-Item $7zTxl $7zDll -Force
        }
    }
}

# Função para extrair e executar ferramenta
function Start-Tool {
    param(
        [string]$ArchiveName,
        [string]$ExeName,
        [string]$Password = "0"
    )
    
    $archivePath = Join-Path $ToolsPath $ArchiveName
    
    if (-not (Test-Path $archivePath)) {
        Write-Host "`n  [ERRO] Arquivo não encontrado: $ArchiveName" -ForegroundColor Red
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
    $extractArgs = "x `"$archivePath`" -o`"$TempPath`" -y -p$Password"
    Start-Process -FilePath $7zExe -ArgumentList $extractArgs -Wait -WindowStyle Hidden
    
    # Executar programa
    $exePath = Join-Path $TempPath $ExeName
    if (Test-Path $exePath) {
        Write-Host "  Executando $ExeName..." -ForegroundColor Green
        Start-Process -FilePath $exePath -WorkingDirectory $TempPath
    }
    else {
        Write-Host "  [ERRO] Executável não encontrado: $ExeName" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

# Função para limpar cabeçalho
function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║           🔧  MENU DE FERRAMENTAS PORTÁTEIS  🔧              ║" -ForegroundColor Cyan
    Write-Host "  ║                    HP Scripts v1.0                           ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
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
    Write-Host "  ══════════════════  DIAGNÓSTICO DE HARDWARE  ══════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] CPU-Z              - Informações detalhadas do processador" -ForegroundColor White
    Write-Host "  [2] ad                 - Diagnóstico completo do sistema" -ForegroundColor White
    Write-Host "  [3] Core Temp          - Monitor de temperatura da CPU" -ForegroundColor White
    Write-Host "  [4] CrystalDiskInfo    - Saúde do disco rígido/SSD" -ForegroundColor White
    Write-Host "  [5] SSD Life           - Vida útil de SSDs" -ForegroundColor White
    Write-Host "  [6] BatteryInfoView    - Informações da bateria" -ForegroundColor White
    Write-Host "  [7] Teste de Teclado   - Verificar teclas" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
    Write-Host "  ══════════════════  OTIMIZAÇÃO DO SISTEMA  ═══════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Optimizer          - Otimização completa do Windows" -ForegroundColor White
    Write-Host "  [2] Winaero Tweaker    - Personalização avançada" -ForegroundColor White
    Write-Host "  [3] Autoruns           - Gerenciar inicialização" -ForegroundColor White
    Write-Host "  [4] LastActivityView   - Últimas atividades do sistema" -ForegroundColor White
    Write-Host "  [5] Bloqueador Update  - Bloquear Windows Update" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
    Write-Host "  ═════════════════════  SENHA E USUÁRIOS  ══════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Password Reset     - Resetar senha de usuário" -ForegroundColor White
    Write-Host "  [2] Active Password    - Alterar senha ativa" -ForegroundColor White
    Write-Host "  [3] Admin Resetter     - Resetar senha admin" -ForegroundColor White
    Write-Host "  [4] Daosoft Password   - Ferramenta Daosoft" -ForegroundColor White
    Write-Host "  [5] OO UserManager     - Gerenciador de usuários" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
    Write-Host "  ═══════════════════  UTILITÁRIOS DIVERSOS  ════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Notepad++          - Editor de texto avançado" -ForegroundColor White
    Write-Host "  [2] UltraISO           - Editor/Criador de ISOs" -ForegroundColor White
    Write-Host "  [3] Unlocker           - Desbloquear arquivos em uso" -ForegroundColor White
    Write-Host "  [4] TakeOwnership Pro  - Assumir propriedade" -ForegroundColor White
    Write-Host "  [5] Revo Uninstaller   - Desinstalar programas" -ForegroundColor White
    Write-Host "  [6] Screenshot         - Captura de tela" -ForegroundColor White
    Write-Host "  [7] USB Show           - Recuperar arquivos USB" -ForegroundColor White
    Write-Host "  [8] Bloq. Firewall     - Bloquear no firewall" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
    Write-Host "  ════════════════════  GERENCIAMENTO DISCO  ════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] WizTree            - Analisar espaço em disco" -ForegroundColor White
    Write-Host "  [2] Disk Defrag        - Desfragmentar disco" -ForegroundColor White
    Write-Host "  [3] ChkDsk GUI         - Verificar disco (interface)" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
    Write-Host "  ═══════════════════  FERRAMENTAS DE REDE  ═════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Advanced IP Scanner  - Escanear rede local" -ForegroundColor White
    Write-Host "  [2] Mudar MAC            - Alterar endereço MAC" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
    Write-Host "  ═════════════════════  BOOT E RECUPERAÇÃO  ════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] NTBOOTAutoFix      - Reparar boot do Windows" -ForegroundColor White
    Write-Host "  [2] BOOTICE            - Editor de boot avançado" -ForegroundColor White
    Write-Host "  [3] BCD/EFI Edit       - Editar configuração BCD" -ForegroundColor White
    Write-Host "  [4] QEMU Simple Boot   - Testar boot de ISO" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Voltar" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
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
        $mainChoice = Read-Host "  Escolha uma categoria"
        
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
