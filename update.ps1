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
    } catch {
        Write-Log "Erro no cache: $($_.Exception.Message)"
        return $false
    }
}

function Install-PSWindowsUpdateModule {
    Write-Log "Verificando modulo PSWindowsUpdate..."
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber
            return $true
        } catch { return $false }
    }
    return $true
}

function Main {
    Write-Log "=== INICIO DA ATUALIZACAO ==="
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$isAdmin) {
        Write-Log "ERRO: Necessario Privilegios de Administrador"
        return
    }

    Clear-WindowsUpdateCache
    if (Install-PSWindowsUpdateModule) {
        Import-Module PSWindowsUpdate
        Write-Log "Buscando atualizacoes..."
        Get-WindowsUpdate -Install -AcceptAll -AutoReboot
    }
    
    Write-Log "=== FIM DO PROCESSO ==="
}

Main
