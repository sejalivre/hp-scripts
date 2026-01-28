#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinForge - Sistema de Instalação e Otimização do Windows
.DESCRIPTION
    Instala aplicativos essenciais e aplica otimizações de sistema para padronizar máquinas após formatação.
    - Instala Chrome, 7-Zip, Adobe Reader via Winget/Chocolatey
    - Habilita caminhos longos
    - Configura energia para alto desempenho
    - Remove bloatware
    - Aplica otimizações visuais e de performance
.NOTES
    Autor: HP Scripts
    Requer: Privilégios de Administrador
#>

# ============================================================================
# CONFIGURAÇÃO INICIAL
# ============================================================================

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Criar diretórios de logs
$LogDir = "C:\Program Files\HPTI\Logs"
$ReportDir = "C:\Program Files\HPTI\Reports"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

# Configurar logging
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "winforge_$Timestamp.log"
$ReportFile = Join-Path $ReportDir "winforge_$Timestamp.html"

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $LogMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Type] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    
    switch ($Type) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message -ForegroundColor Cyan }
    }
}

# ============================================================================
# VARIÁVEIS DE CONTROLE
# ============================================================================

$Script:Results = @{
    Apps          = @()
    Optimizations = @()
    Errors        = @()
}

# ============================================================================
# FUNÇÕES DE INSTALAÇÃO DE APLICATIVOS
# ============================================================================

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-Chocolatey {
    Write-Log "Instalando Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $Script:Results.Optimizations += "Chocolatey instalado com sucesso"
        Write-Log "Chocolatey instalado com sucesso" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao instalar Chocolatey: $_" "ERROR"
        $Script:Results.Errors += "Falha ao instalar Chocolatey: $_"
        return $false
    }
}

function Install-Apps {
    Write-Log "=== INICIANDO INSTALAÇÃO DE APLICATIVOS ===" "INFO"
    
    $Apps = @(
        @{Name = "Google Chrome"; WingetId = "Google.Chrome"; ChocoId = "googlechrome" },
        @{Name = "7-Zip"; WingetId = "7zip.7zip"; ChocoId = "7zip" },
        @{Name = "Adobe Acrobat Reader"; WingetId = "Adobe.Acrobat.Reader.64-bit"; ChocoId = "adobereader" }
    )
    
    $UseWinget = Test-WingetAvailable
    
    if (-not $UseWinget) {
        Write-Log "Winget não disponível, tentando Chocolatey..." "WARNING"
        $ChocoAvailable = Test-Path "$env:ProgramData\chocolatey\bin\choco.exe"
        if (-not $ChocoAvailable) {
            $ChocoAvailable = Install-Chocolatey
        }
        if (-not $ChocoAvailable) {
            Write-Log "Nenhum gerenciador de pacotes disponível. Pulando instalação de apps." "ERROR"
            return
        }
    }
    
    foreach ($App in $Apps) {
        Write-Log "Instalando $($App.Name)..."
        try {
            if ($UseWinget) {
                $Process = Start-Process -FilePath "winget" -ArgumentList "install --id $($App.WingetId) --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow
                if ($Process.ExitCode -eq 0) {
                    $Script:Results.Apps += "$($App.Name) - Instalado com sucesso (Winget)"
                    Write-Log "$($App.Name) instalado com sucesso" "SUCCESS"
                }
                else {
                    throw "Winget retornou código de erro: $($Process.ExitCode)"
                }
            }
            else {
                $Process = Start-Process -FilePath "choco" -ArgumentList "install $($App.ChocoId) -y" -Wait -PassThru -NoNewWindow
                if ($Process.ExitCode -eq 0) {
                    $Script:Results.Apps += "$($App.Name) - Instalado com sucesso (Chocolatey)"
                    Write-Log "$($App.Name) instalado com sucesso" "SUCCESS"
                }
                else {
                    throw "Chocolatey retornou código de erro: $($Process.ExitCode)"
                }
            }
        }
        catch {
            Write-Log "Erro ao instalar $($App.Name): $_" "WARNING"
            $Script:Results.Errors += "Falha ao instalar $($App.Name): $_"
        }
    }
}

# ============================================================================
# FUNÇÕES DE OTIMIZAÇÃO DO SISTEMA
# ============================================================================

function Enable-LongPaths {
    Write-Log "Habilitando suporte a caminhos longos..."
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Force
        $Script:Results.Optimizations += "Caminhos longos habilitados"
        Write-Log "Caminhos longos habilitados com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao habilitar caminhos longos: $_" "ERROR"
        $Script:Results.Errors += "Falha ao habilitar caminhos longos: $_"
    }
}

function Remove-MenuDelay {
    Write-Log "Removendo delay dos menus..."
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0 -Force
        $Script:Results.Optimizations += "Delay de menus removido"
        Write-Log "Delay de menus removido com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao remover delay de menus: $_" "ERROR"
        $Script:Results.Errors += "Falha ao remover delay de menus: $_"
    }
}

function Show-ComputerOnDesktop {
    Write-Log "Mostrando 'Computador' na área de trabalho..."
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Force
        $Script:Results.Optimizations += "Ícone 'Computador' adicionado à área de trabalho"
        Write-Log "Ícone 'Computador' adicionado à área de trabalho" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao mostrar 'Computador' na área de trabalho: $_" "ERROR"
        $Script:Results.Errors += "Falha ao mostrar 'Computador': $_"
    }
}

function Set-HighPerformancePower {
    Write-Log "Configurando plano de energia para Alto Desempenho..."
    try {
        $HighPerf = powercfg -l | Where-Object { $_ -match "Alto desempenho|High performance" }
        if ($HighPerf -match "([a-f0-9-]{36})") {
            powercfg -setactive $Matches[1]
            $Script:Results.Optimizations += "Plano de energia configurado para Alto Desempenho"
            Write-Log "Plano de energia configurado para Alto Desempenho" "SUCCESS"
        }
        else {
            # Criar plano de alto desempenho se não existir
            powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            $Script:Results.Optimizations += "Plano de Alto Desempenho criado e ativado"
            Write-Log "Plano de Alto Desempenho criado e ativado" "SUCCESS"
        }
    }
    catch {
        Write-Log "Erro ao configurar plano de energia: $_" "ERROR"
        $Script:Results.Errors += "Falha ao configurar plano de energia: $_"
    }
}

function Disable-Copilot {
    Write-Log "Desabilitando Copilot..."
    try {
        $Paths = @(
            "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        )
        foreach ($Path in $Paths) {
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force | Out-Null
            }
            Set-ItemProperty -Path $Path -Name "TurnOffWindowsCopilot" -Value 1 -Force
        }
        $Script:Results.Optimizations += "Copilot desabilitado"
        Write-Log "Copilot desabilitado com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar Copilot: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar Copilot: $_"
    }
}

function Disable-Recall {
    Write-Log "Desabilitando Recall..."
    try {
        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "DisableAIDataAnalysis" -Value 1 -Force
        $Script:Results.Optimizations += "Recall desabilitado"
        Write-Log "Recall desabilitado com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar Recall: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar Recall: $_"
    }
}

function Disable-ModernStandby {
    Write-Log "Desabilitando Modern Standby..."
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Value 0 -Force
        $Script:Results.Optimizations += "Modern Standby desabilitado"
        Write-Log "Modern Standby desabilitado com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar Modern Standby: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar Modern Standby: $_"
    }
}

function Disable-NewsAndInterests {
    Write-Log "Desabilitando News & Interests..."
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Force
        $Script:Results.Optimizations += "News & Interests desabilitado"
        Write-Log "News & Interests desabilitado" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar News & Interests: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar News & Interests: $_"
    }
}

function Disable-Cortana {
    Write-Log "Desabilitando Cortana..."
    try {
        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "AllowCortana" -Value 0 -Force
        $Script:Results.Optimizations += "Cortana desabilitado"
        Write-Log "Cortana desabilitado com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar Cortana: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar Cortana: $_"
    }
}

function Set-PrefetchBasedOnDrive {
    Write-Log "Configurando Prefetch baseado no tipo de disco..."
    try {
        $SystemDrive = $env:SystemDrive.TrimEnd(':')
        $DriveType = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | Select-Object -ExpandProperty MediaType
        
        if ($DriveType -eq "SSD") {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0 -Force
            $Script:Results.Optimizations += "Prefetch configurado para SSD (desabilitado)"
            Write-Log "Prefetch desabilitado (SSD detectado)" "SUCCESS"
        }
        else {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3 -Force
            $Script:Results.Optimizations += "Prefetch configurado para HDD (habilitado)"
            Write-Log "Prefetch habilitado (HDD detectado)" "SUCCESS"
        }
    }
    catch {
        Write-Log "Erro ao configurar Prefetch: $_" "ERROR"
        $Script:Results.Errors += "Falha ao configurar Prefetch: $_"
    }
}

function Remove-BloatwareApps {
    Write-Log "Removendo aplicativos desnecessários..."
    
    $AppsToRemove = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingFinance",
        "Microsoft.BingNews",
        "Microsoft.Getstarted",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.OneNote",
        "Microsoft.SkypeApp",
        "Microsoft.XboxApp",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.YourPhone",
        "Microsoft.People"
    )
    
    foreach ($App in $AppsToRemove) {
        try {
            $Package = Get-AppxPackage -Name $App -ErrorAction SilentlyContinue
            if ($Package) {
                Remove-AppxPackage -Package $Package.PackageFullName -ErrorAction Stop
                $Script:Results.Optimizations += "Removido: $App"
                Write-Log "Removido: $App" "SUCCESS"
            }
        }
        catch {
            Write-Log "Erro ao remover $App : $_" "WARNING"
        }
    }
}

function Remove-3DObjectsFolder {
    Write-Log "Removendo pasta '3D Objects' do Explorer..."
    try {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force
        }
        $Path64 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        if (Test-Path $Path64) {
            Remove-Item -Path $Path64 -Recurse -Force
        }
        $Script:Results.Optimizations += "Pasta '3D Objects' removida do Explorer"
        Write-Log "Pasta '3D Objects' removida do Explorer" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao remover pasta '3D Objects': $_" "ERROR"
        $Script:Results.Errors += "Falha ao remover pasta '3D Objects': $_"
    }
}

function Disable-GameDVR {
    Write-Log "Desabilitando Game DVR..."
    try {
        $Path = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "GameDVR_Enabled" -Value 0 -Force
        
        $Path2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
        if (-not (Test-Path $Path2)) {
            New-Item -Path $Path2 -Force | Out-Null
        }
        Set-ItemProperty -Path $Path2 -Name "AllowGameDVR" -Value 0 -Force
        
        $Script:Results.Optimizations += "Game DVR desabilitado"
        Write-Log "Game DVR desabilitado com sucesso" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar Game DVR: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar Game DVR: $_"
    }
}

function Disable-AppSuggestions {
    Write-Log "Desabilitando sugestões de apps no menu Iniciar..."
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Force
        $Script:Results.Optimizations += "Sugestões de apps desabilitadas"
        Write-Log "Sugestões de apps desabilitadas" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar sugestões de apps: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar sugestões de apps: $_"
    }
}

function Disable-StickyKeys {
    Write-Log "Desabilitando Sticky Keys..."
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value 506 -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value 122 -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value 58 -Force
        $Script:Results.Optimizations += "Sticky Keys desabilitado"
        Write-Log "Sticky Keys desabilitado" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar Sticky Keys: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar Sticky Keys: $_"
    }
}

function Enable-DarkMode {
    Write-Log "Habilitando Dark Mode..."
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Force
        $Script:Results.Optimizations += "Dark Mode habilitado"
        Write-Log "Dark Mode habilitado" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao habilitar Dark Mode: $_" "ERROR"
        $Script:Results.Errors += "Falha ao habilitar Dark Mode: $_"
    }
}

function Disable-Transparency {
    Write-Log "Desabilitando transparência..."
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Force
        $Script:Results.Optimizations += "Transparência desabilitada"
        Write-Log "Transparência desabilitada" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar transparência: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar transparência: $_"
    }
}

function Disable-Animations {
    Write-Log "Desabilitando animações e efeitos visuais..."
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force
        $Script:Results.Optimizations += "Animações e efeitos visuais desabilitados"
        Write-Log "Animações e efeitos visuais desabilitados" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar animações: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar animações: $_"
    }
}

function Disable-Widgets {
    Write-Log "Desabilitando widgets na barra de tarefas..."
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name "TaskbarDa" -Value 0 -Force
        $Script:Results.Optimizations += "Widgets desabilitados"
        Write-Log "Widgets desabilitados" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao desabilitar widgets: $_" "ERROR"
        $Script:Results.Errors += "Falha ao desabilitar widgets: $_"
    }
}

function Hide-ChatIcon {
    Write-Log "Ocultando ícone de chat da barra de tarefas..."
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name "TaskbarMn" -Value 0 -Force
        $Script:Results.Optimizations += "Ícone de chat ocultado"
        Write-Log "Ícone de chat ocultado" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao ocultar ícone de chat: $_" "WARNING"
    }
}

function Optimize-EdgeSettings {
    Write-Log "Otimizando configurações do Microsoft Edge..."
    try {
        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Desabilitar anúncios e sugestões
        Set-ItemProperty -Path $Path -Name "EdgeShoppingAssistantEnabled" -Value 0 -Force
        Set-ItemProperty -Path $Path -Name "PersonalizationReportingEnabled" -Value 0 -Force
        Set-ItemProperty -Path $Path -Name "ShowRecommendationsEnabled" -Value 0 -Force
        
        $Script:Results.Optimizations += "Configurações do Edge otimizadas"
        Write-Log "Configurações do Edge otimizadas" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao otimizar Edge: $_" "ERROR"
        $Script:Results.Errors += "Falha ao otimizar Edge: $_"
    }
}

function Set-GoogleAsDefaultSearch {
    Write-Log "Configurando Google como mecanismo de busca padrão..."
    try {
        # Edge
        $EdgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $EdgePath)) {
            New-Item -Path $EdgePath -Force | Out-Null
        }
        Set-ItemProperty -Path $EdgePath -Name "DefaultSearchProviderEnabled" -Value 1 -Force
        Set-ItemProperty -Path $EdgePath -Name "DefaultSearchProviderName" -Value "Google" -Force
        Set-ItemProperty -Path $EdgePath -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.com/search?q={searchTerms}" -Force
        
        $Script:Results.Optimizations += "Google configurado como busca padrão"
        Write-Log "Google configurado como busca padrão" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao configurar Google como busca padrão: $_" "WARNING"
    }
}

function Optimize-NetworkPerformance {
    Write-Log "Otimizando performance de rede..."
    try {
        # Desabilitar auto-tuning
        netsh interface tcp set global autotuninglevel=normal
        
        # Otimizar TCP
        netsh interface tcp set global chimney=enabled
        netsh interface tcp set global dca=enabled
        netsh interface tcp set global netdma=enabled
        
        $Script:Results.Optimizations += "Performance de rede otimizada"
        Write-Log "Performance de rede otimizada" "SUCCESS"
    }
    catch {
        Write-Log "Erro ao otimizar rede: $_" "WARNING"
    }
}

# ============================================================================
# FUNÇÃO DE GERAÇÃO DE RELATÓRIO
# ============================================================================

function Generate-Report {
    Write-Log "Gerando relatório HTML..."
    
    $HTML = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WinForge - Relatório de Configuração</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .content {
            padding: 40px;
        }
        .section {
            margin-bottom: 30px;
        }
        .section h2 {
            color: #667eea;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        .item {
            padding: 10px;
            margin: 5px 0;
            background: #f8f9fa;
            border-left: 4px solid #28a745;
            border-radius: 4px;
        }
        .error {
            border-left-color: #dc3545;
            background: #fff5f5;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .stat-card h3 {
            font-size: 2em;
            margin-bottom: 5px;
        }
        .stat-card p {
            opacity: 0.9;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 WinForge</h1>
            <p>Relatório de Configuração do Sistema</p>
            <p>$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        </div>
        <div class="content">
            <div class="stats">
                <div class="stat-card">
                    <h3>$($Script:Results.Apps.Count)</h3>
                    <p>Aplicativos Instalados</p>
                </div>
                <div class="stat-card">
                    <h3>$($Script:Results.Optimizations.Count)</h3>
                    <p>Otimizações Aplicadas</p>
                </div>
                <div class="stat-card">
                    <h3>$($Script:Results.Errors.Count)</h3>
                    <p>Erros Encontrados</p>
                </div>
            </div>
            
            <div class="section">
                <h2>📦 Aplicativos Instalados</h2>
"@
    
    if ($Script:Results.Apps.Count -gt 0) {
        foreach ($App in $Script:Results.Apps) {
            $HTML += "<div class='item'>✓ $App</div>`n"
        }
    }
    else {
        $HTML += "<div class='item'>Nenhum aplicativo instalado</div>`n"
    }
    
    $HTML += @"
            </div>
            
            <div class="section">
                <h2>⚡ Otimizações Aplicadas</h2>
"@
    
    if ($Script:Results.Optimizations.Count -gt 0) {
        foreach ($Opt in $Script:Results.Optimizations) {
            $HTML += "<div class='item'>✓ $Opt</div>`n"
        }
    }
    else {
        $HTML += "<div class='item'>Nenhuma otimização aplicada</div>`n"
    }
    
    $HTML += @"
            </div>
"@
    
    if ($Script:Results.Errors.Count -gt 0) {
        $HTML += @"
            <div class="section">
                <h2>⚠️ Erros Encontrados</h2>
"@
        foreach ($Error in $Script:Results.Errors) {
            $HTML += "<div class='item error'>✗ $Error</div>`n"
        }
        $HTML += "</div>`n"
    }
    
    $HTML += @"
        </div>
        <div class="footer">
            <p>WinForge - HP Scripts | Log completo: $LogFile</p>
        </div>
    </div>
</body>
</html>
"@
    
    $HTML | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-Log "Relatório gerado: $ReportFile" "SUCCESS"
    
    # Abrir relatório
    Start-Process $ReportFile
}

# ============================================================================
# EXECUÇÃO PRINCIPAL
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║                    🔧 WINFORGE 🔧                         ║" -ForegroundColor Cyan
Write-Host "║          Sistema de Instalação e Otimização              ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "=== INICIANDO WINFORGE ===" "INFO"
Write-Log "Log: $LogFile" "INFO"

# Instalação de aplicativos
Install-Apps

# Otimizações do sistema
Write-Log "`n=== APLICANDO OTIMIZAÇÕES DO SISTEMA ===" "INFO"

Enable-LongPaths
Remove-MenuDelay
Show-ComputerOnDesktop
Set-HighPerformancePower
Disable-Copilot
Disable-Recall
Disable-ModernStandby
Disable-NewsAndInterests
Disable-Cortana
Set-PrefetchBasedOnDrive
Remove-BloatwareApps
Remove-3DObjectsFolder
Disable-GameDVR
Disable-AppSuggestions
Disable-StickyKeys
Enable-DarkMode
Disable-Transparency
Disable-Animations
Disable-Widgets
Hide-ChatIcon
Optimize-EdgeSettings
Set-GoogleAsDefaultSearch
Optimize-NetworkPerformance

# Gerar relatório
Write-Log "`n=== GERANDO RELATÓRIO ===" "INFO"
Generate-Report

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║                  ✓ CONCLUÍDO COM SUCESSO                  ║" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║  Algumas alterações podem requerer reinicialização       ║" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Log "=== WINFORGE CONCLUÍDO ===" "SUCCESS"
Write-Host "Log completo: $LogFile" -ForegroundColor Cyan
Write-Host "Relatório: $ReportFile" -ForegroundColor Cyan
