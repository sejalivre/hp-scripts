#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Instalação de Updates do Windows via PSWindowsUpdate
.DESCRIPTION
    Reinicia serviços do Windows Update e instala atualizações usando PSWindowsUpdate
#>

$ErrorActionPreference = "Continue"
$logFile = "C:\Program Files\HPTI\Logs\update_install_$(Get-Date -Format 'yyyyMMdd').log"

# Cria pasta de log
$logDir = "C:\Program Files\HPTI\Logs"
if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Color = "Gray")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    $logMessage | Out-File -FilePath $logFile -Append -Force
}

Write-Log "=== INSTALAÇÃO DE UPDATES - HPCRAFT ===" "Cyan"
Write-Log "Iniciado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
Write-Log "" "White"

# Verificar privilégios
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin) {
    Write-Log "ERRO: Execute como Administrador!" "Red"
    Start-Sleep -Seconds 3
    return
}

# 1. Reiniciar serviços
Write-Log "Reiniciando serviços do Windows Update..." "Yellow"
$services = @("wuauserv", "bits", "cryptsvc", "msiserver")

foreach ($svc in $services) {
    try {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Write-Log "  Serviço $svc parado" "Gray"
            }
            Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            Write-Log "  Serviço $svc iniciado" "Green"
        }
    }
    catch {
        Write-Log "  Aviso: Não foi possível reiniciar $svc" "Yellow"
    }
}

Write-Log "" "White"

# 2. Instalar PSWindowsUpdate
Write-Log "Verificando módulo PSWindowsUpdate..." "Yellow"
try {
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "Instalando módulo PSWindowsUpdate..." "Yellow"
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber -ErrorAction Stop
        Write-Log "Módulo instalado com sucesso!" "Green"
    } else {
        Write-Log "Módulo já está instalado" "Green"
    }
}
catch {
    Write-Log "ERRO ao instalar módulo: $($_.Exception.Message)" "Red"
    Write-Log "Tentando método alternativo..." "Yellow"
}

Write-Log "" "White"

# 3. Executar Windows Update
Write-Log "Buscando e instalando atualizações..." "Cyan"
try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
    
    Write-Log "Procurando atualizações disponíveis..." "Yellow"
    $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
    
    if ($updates.Count -eq 0) {
        Write-Log "Nenhuma atualização disponível!" "Green"
    } else {
        Write-Log "Encontradas $($updates.Count) atualização(ões)" "Yellow"
        foreach ($update in $updates) {
            Write-Log "  - $($update.Title)" "Gray"
        }
        
        Write-Log "" "White"
        Write-Log "Instalando atualizações..." "Yellow"
        Get-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -IgnoreReboot -Verbose -ErrorAction Stop
        
        Write-Log "" "White"
        Write-Log "Atualizações instaladas com sucesso!" "Green"
        Write-Log "Reinicie o computador se necessário." "Yellow"
    }
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)" "Red"
    Write-Log "" "White"
    Write-Log "Tentando método alternativo via COM..." "Yellow"
    
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
        
        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "Nenhuma atualização disponível!" "Green"
        } else {
            Write-Log "Instalando $($searchResult.Updates.Count) atualização(ões)..." "Yellow"
            $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $searchResult.Updates) {
                $updatesToInstall.Add($update) | Out-Null
            }
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $updatesToInstall
            $installResult = $installer.Install()
            
            if ($installResult.ResultCode -eq 2) {
                Write-Log "Atualizações instaladas com sucesso!" "Green"
            }
        }
    }
    catch {
        Write-Log "ERRO no método alternativo: $($_.Exception.Message)" "Red"
    }
}

Write-Log "" "White"
Write-Log "=== PROCESSO CONCLUÍDO ===" "Cyan"
Write-Log "Log salvo em: $logFile" "Gray"

Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Gray
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
