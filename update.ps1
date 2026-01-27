# Windows Update Manager Script - HPCRAFT v1.2.1
# Executar como Administrador

$ErrorActionPreference = "Stop"
$logFile = "C:\Windows\Logs\WindowsUpdateScript.log"

# Cria a pasta de log se não existir
if (!(Test-Path "C:\Windows\Logs")) { New-Item -Path "C:\Windows\Logs" -ItemType Directory -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor Gray
    $logMessage | Out-File -FilePath $logFile -Append -Force
}

function Clear-WindowsUpdateCache {
    Write-Log "Iniciando limpeza do cache do Windows Update..."
    try {
        $servicos = @("wuauserv", "bits", "cryptsvc")
        foreach ($s in $servicos) { Stop-Service $s -Force -ErrorAction SilentlyContinue }
        
        $folders = @("C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2")
        foreach ($folder in $folders) {
            if (Test-Path $folder) {
                $backup = "${folder}.old"
                if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
                Rename-Item -Path $folder -NewName $backup -Force
            }
        }
        foreach ($s in $servicos) { Start-Service $s -ErrorAction SilentlyContinue }
        Write-Log "Cache limpo e serviços reiniciados."
        return $true
    }
    catch {
        Write-Log "Erro no cache: $($_.Exception.Message)"
        return $false
    }
}

function Install-PSWindowsUpdateModule {
    Write-Log "Verificando modulo PSWindowsUpdate..."
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        try {
            # Habilitar TLS 1.2 se disponível
            try {
                $protocols = [Net.ServicePointManager]::SecurityProtocol
                if ($protocols -notmatch 'Tls12') {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Write-Log "TLS 1.2 habilitado"
                }
            }
            catch {
                Write-Log "AVISO: Não foi possível habilitar TLS 1.2"
            }
            
            # Detectar e configurar proxy se necessário
            $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
            if ($proxySettings -and $proxySettings.ProxyEnable -eq 1) {
                $proxy = $proxySettings.ProxyServer
                Write-Log "Proxy detectado: $proxy"
                [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxy, $true)
                [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
            }
            
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
            Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber -ErrorAction Stop
            Write-Log "Módulo PSWindowsUpdate instalado com sucesso"
            return $true
        }
        catch {
            Write-Log "ERRO ao instalar módulo: $($_.Exception.Message)"
            return $false
        }
    }
    Write-Log "Módulo PSWindowsUpdate já está instalado"
    return $true
}

function Main {
    Write-Log "=== INICIO DA ATUALIZACAO ==="
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$isAdmin) {
        Write-Log "ERRO: Necessario Privilegios de Administrador"
        return
    }

    # Verificar espaço em disco
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Log "Espaço livre em C: $freeGB GB"
    
    if ($freeGB -lt 10) {
        Write-Log "AVISO: Espaço em disco baixo! Recomenda-se pelo menos 10GB livres."
        Write-Host "Espaço livre: $freeGB GB. Continuar? (S/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne 'S' -and $response -ne 's') {
            Write-Log "Operação cancelada pelo usuário"
            return
        }
    }

    Clear-WindowsUpdateCache
    
    if (Install-PSWindowsUpdateModule) {
        try {
            Import-Module PSWindowsUpdate -ErrorAction Stop
            Write-Log "Buscando atualizacoes..."
            Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
            Write-Log "Atualizações instaladas. Reinicie o computador quando possível."
        }
        catch {
            Write-Log "ERRO ao executar atualizações: $($_.Exception.Message)"
        }
    }
    else {
        Write-Log "Não foi possível instalar o módulo PSWindowsUpdate"
    }
    
    Write-Log "=== FIM DO PROCESSO ==="
}

Main
