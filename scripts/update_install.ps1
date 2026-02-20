# Windows Update Install Script - HPCRAFT v2.0.0
# Executar como Administrador
# Instalação de atualizações via PSWindowsUpdate

$ErrorActionPreference = "Continue"
$logFile = "C:\Program Files\HPTI\Logs\update_install_$(Get-Date -Format 'yyyyMMdd').log"

# Cria a pasta de log se não existir
$logDir = "C:\Program Files\HPTI\Logs"
if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "Gray"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    $logMessage | Out-File -FilePath $logFile -Append -Force
}

function Test-Administrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$isAdmin) {
        Write-Log "ERRO: Este script requer privilégios de Administrador!" "Red"
        Write-Log "Execute o PowerShell como Administrador e tente novamente." "Yellow"
        return $false
    }
    return $true
}

function Restart-WindowsUpdateServices {
    Write-Log "=== REINICIANDO SERVIÇOS DO WINDOWS UPDATE ===" "Yellow"
    
    $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
    foreach ($serviceName in $services) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            Write-Log "Reiniciando serviço: $serviceName (Status: $($service.Status))" "Gray"
            
            if ($service.Status -eq "Running") {
                Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
            }
            
            Start-Service $serviceName -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            Write-Log "  Status após reinício: $($service.Status)" "Green"
        }
        catch {
            Write-Log "  Aviso: Não foi possível reiniciar $serviceName" "Yellow"
        }
    }
    
    Write-Log "Serviços reiniciados" "Green"
    Write-Log "" "White"
}

function Install-PSWindowsUpdateModule {
    Write-Log "=== INSTALANDO MÓDULO PSWINDOWSUPDATE ===" "Yellow"
    
    try {
        # Detectar proxy
        $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
        if ($proxySettings -and $proxySettings.ProxyEnable -eq 1) {
            $proxy = $proxySettings.ProxyServer
            Write-Log "Proxy detectado: $proxy" "Gray"
            [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxy, $true)
            [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        }
        
        Write-Log "Instalando NuGet..." "Yellow"
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        
        Write-Log "Instalando PSWindowsUpdate..." "Yellow"
        Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber -ErrorAction Stop
        
        Write-Log "Módulo PSWindowsUpdate instalado com sucesso" "Green"
        return $true
    }
    catch {
        Write-Log "ERRO ao instalar módulo: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Get-WindowsUpdateWithFallback {
    Write-Log "=== BUSCANDO ATUALIZAÇÕES ===" "Cyan"
    
    try {
        # Importar módulo PSWindowsUpdate
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Log "Módulo PSWindowsUpdate não encontrado" "Red"
            return $null
        }
        
        Import-Module PSWindowsUpdate -ErrorAction Stop
        
        Write-Log "Conectando ao Windows Update..." "Yellow"
        
        # Buscar atualizações
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop -Verbose
        
        if ($updates -and $updates.Count -gt 0) {
            Write-Log "Encontradas $($updates.Count) atualizações disponíveis" "Green"
            return $updates
        }
        else {
            Write-Log "Nenhuma atualização disponível no momento" "Green"
            return @()
        }
    }
    catch {
        Write-Log "ERRO ao buscar atualizações: $($_.Exception.Message)" "Red"
        
        # Fallback: Método alternativo usando WUA
        Write-Log "Tentando método alternativo..." "Yellow"
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            
            Write-Log "Buscando atualizações via Windows Update Agent..." "Yellow"
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            if ($searchResult.Updates.Count -eq 0) {
                Write-Log "Nenhuma atualização encontrada" "Green"
                return @()
            }
            
            Write-Log "Encontradas $($searchResult.Updates.Count) atualizações via método alternativo" "Green"
            return $searchResult.Updates
        }
        catch {
            Write-Log "ERRO no método alternativo: $($_.Exception.Message)" "Red"
            return $null
        }
    }
}

function Install-WindowsUpdates {
    param(
        [object]$Updates,
        [switch]$AutoReboot
    )
    
    Write-Log "=== INSTALANDO ATUALIZAÇÕES ===" "Cyan"
    
    if ($Updates -eq $null) {
        Write-Log "Sem atualizações para instalar" "Yellow"
        return $false
    }
    
    if ($Updates.Count -eq 0 -or $Updates.Count -eq $null) {
        Write-Log "Nenhuma atualização disponível" "Green"
        return $true
    }
    
    # Mostrar lista de atualizações
    Write-Log "" "White"
    Write-Log "Atualizações encontradas:" "Yellow"
    foreach ($update in $Updates) {
        $title = if ($update.Title) { $update.Title } else { $update }
        Write-Log "  - $title" "Gray"
    }
    Write-Log "" "White"
    
    # Confirmar instalação
    $rebootNeeded = $false
    
    foreach ($update in $Updates) {
        if ($update.RebootRequired) {
            $rebootNeeded = $true
            break
        }
    }
    
    if ($rebootNeeded -and -not $AutoReboot) {
        Write-Log "ATENÇÃO: Atualizações que requerem reinicialização foram detectadas." "Yellow"
        Write-Log "O sistema será reiniciado automaticamente após a instalação." "Yellow"
        $confirm = Read-Host "Deseja continuar? (S/N)"
        
        if ($confirm -ne 'S' -and $confirm -ne 's') {
            Write-Log "Instalação cancelada pelo usuário" "Yellow"
            return $false
        }
    }
    
    try {
        # Método 1: Usar PSWindowsUpdate
        if (Get-Module -Name PSWindowsUpdate -ErrorAction SilentlyContinue) {
            Write-Log "Instalando via PSWindowsUpdate..." "Yellow"
            
            $installArgs = @("-MicrosoftUpdate", "-Install", "-AcceptAll")
            if ($AutoReboot) {
                $installArgs += "-AutoReboot"
            }
            else {
                $installArgs += "-IgnoreReboot"
            }
            
            Get-WindowsUpdate @installArgs -ErrorAction Stop
        }
        else {
            # Método 2: Fallback com WUA
            Write-Log "Instalando via Windows Update Agent..." "Yellow"
            
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            if ($searchResult.Updates.Count -eq 0) {
                Write-Log "Nenhuma atualização para instalar" "Green"
                return $true
            }
            
            $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $searchResult.Updates) {
                $updatesToInstall.Add($update) | Out-Null
            }
            
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $updatesToInstall
            $installResult = $installer.Install()
            
            if ($installResult.ResultCode -eq 2) {
                Write-Log "Atualizações instaladas com sucesso!" "Green"
                return $true
            }
            else {
                Write-Log "Resultado da instalação: $($installResult.ResultCode)" "Yellow"
                return $false
            }
        }
        
        Write-Log "Atualizações instaladas com sucesso!" "Green"
        
        if ($rebootNeeded -and $AutoReboot) {
            Write-Log "Reinicializando o sistema em 30 segundos..." "Yellow"
            Write-Log "Pressione Ctrl+C para cancelar a reinicialização" "Yellow"
            Start-Sleep -Seconds 30
            Restart-Computer -Force
        }
        else {
            Write-Log "Reinicie o computador quando possível para concluir a instalação." "Yellow"
        }
        
        return $true
    }
    catch {
        Write-Log "ERRO durante a instalação: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Main {
    Write-Log "=== WINDOWS UPDATE INSTALL - HPCRAFT v2.0.0 ===" "Cyan"
    Write-Log "Iniciado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Write-Log "" "White"
    
    # Verificar privilégios de administrador
    if (-not (Test-Administrator)) {
        return
    }
    
    # Verificar espaço em disco
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($drive) {
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        Write-Log "Espaço livre em C: $freeGB GB" "Gray"
        
        if ($freeGB -lt 5) {
            Write-Log "AVISO: Espaço em disco baixo! Recomenda-se pelo menos 5GB livres." "Yellow"
            Write-Host "Espaço livre: $freeGB GB. Continuar? (S/N): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host
            if ($response -ne 'S' -and $response -ne 's') {
                Write-Log "Operação cancelada pelo usuário" "Yellow"
                return
            }
        }
    }
    
    Write-Log "" "White"
    
    # Reiniciar serviços do Windows Update
    Restart-WindowsUpdateServices
    
    # Instalar/atualizar módulo PSWindowsUpdate
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        if (-not (Install-PSWindowsUpdateModule)) {
            Write-Log "AVISO: Continuando sem PSWindowsUpdate (método alternativo)" "Yellow"
        }
    }
    else {
        Write-Log "Módulo PSWindowsUpdate já está instalado" "Green"
    }
    
    Write-Log "" "White"
    
    # Buscar atualizações
    $updates = Get-WindowsUpdateWithFallback
    
    if ($updates -eq $null) {
        Write-Log "Falha ao buscar atualizações" "Red"
        return
    }
    
    # Instalar atualizações
    if ($updates.Count -eq 0) {
        Write-Log "Nenhuma atualização disponível no momento" "Green"
    }
    else {
        Write-Log "Instalando $($updates.Count) atualizações..." "Yellow"
        $success = Install-WindowsUpdates -Updates $updates
        
        if ($success) {
            Write-Log "=== INSTALAÇÃO CONCLUÍDA COM SUCESSO ===" "Green"
        }
        else {
            Write-Log "=== INSTALAÇÃO FALHOU ===" "Red"
        }
    }
    
    Write-Log "" "White"
    Write-Log "=== PROCESSO CONCLUÍDO ===" "Cyan"
    Write-Log "Finalizado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Write-Log "Log completo salvo em: $logFile" "Gray"
}

Main