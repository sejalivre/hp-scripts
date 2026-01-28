# ResetRede.ps1 - Reset de configurações de rede + serviços relacionados
# Executar como ADMINISTRADOR

# ============================================================
# CONFIGURAÇÃO DE DIRETÓRIOS E LOGGING
# ============================================================

$HPTIBase = "C:\Program Files\HPTI"
$BackupDir = Join-Path $HPTIBase "NetworkBackups"
$LogDir = Join-Path $HPTIBase "Logs"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "network_backup_$timestamp.ps1"
$LogFile = Join-Path $LogDir "net_$(Get-Date -Format 'yyyyMMdd').log"

# Criar diretórios se não existirem
if (-not (Test-Path $HPTIBase)) { New-Item -Path $HPTIBase -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }

# Função de logging
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $logTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$logTimestamp] [$Type] $Message"
    $logMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    switch ($Type) {
        "ERROR" { Write-Warning $Message }
        "SUCCESS" { Write-Output $Message }
        default { Write-Output $Message }
    }
}

# ============================================================
# FUNÇÃO DE BACKUP DE CONFIGURAÇÕES DE REDE
# ============================================================

function Backup-NetworkConfiguration {
    Write-Log "=== INICIANDO BACKUP DE CONFIGURAÇÕES DE REDE ===" "SUCCESS"
    
    $backupContent = @"
# Script de Restore de Configurações de Rede
# Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
# Backup criado antes do reset de rede

Write-Host "=== RESTAURANDO CONFIGURAÇÕES DE REDE ===" -ForegroundColor Cyan

"@

    try {
        # 1. Backup de Configurações de IP
        Write-Log "Fazendo backup de configurações de IP..."
        $netConfigs = Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -match 'Wi-Fi|Ethernet|WiFi' }
        
        foreach ($config in $netConfigs) {
            $alias = $config.InterfaceAlias
            $adapter = Get-NetAdapter -Name $alias -ErrorAction SilentlyContinue
            if (-not $adapter) { continue }

            $ipConfig = Get-NetIPConfiguration -InterfaceAlias $alias -ErrorAction SilentlyContinue
            $dhcpEnabled = (Get-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue).Dhcp -eq 'Enabled'

            if (-not $dhcpEnabled -and $ipConfig.IPv4Address.IPAddress -and $ipConfig.IPv4Address.IPAddress -notmatch '^169\.254|^0\.0\.0\.') {
                $ip = $ipConfig.IPv4Address.IPAddress
                $prefix = $ipConfig.IPv4Address.PrefixLength
                $gw = $ipConfig.IPv4DefaultGateway.NextHop
                $dns = if ($ipConfig.DNSServer.ServerAddresses) { "'$($ipConfig.DNSServer.ServerAddresses -join "','")'" } else { $null }

                $backupContent += @"

# Restaurando IP estático na interface '$alias'
Write-Host "Configurando interface: $alias" -ForegroundColor Yellow
try {
    Remove-NetIPAddress -InterfaceAlias '$alias' -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias '$alias' -Confirm:`$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias '$alias' -IPAddress '$ip' -PrefixLength $prefix -DefaultGateway '$gw' -AddressFamily IPv4 -ErrorAction Stop
    Write-Host "  IP configurado: $ip/$prefix" -ForegroundColor Green

"@
                if ($dns) {
                    $backupContent += @"
    Set-DnsClientServerAddress -InterfaceAlias '$alias' -ServerAddresses $dns -ErrorAction Stop
    Write-Host "  DNS configurado" -ForegroundColor Green

"@
                }
                $backupContent += @"
}
catch {
    Write-Warning "Erro ao configurar '$alias': `$(`$_.Exception.Message)"
}

"@
                Write-Log "  Backup de IP estático: $alias ($ip)"
            }
        }

        # 2. Backup de Perfis Wi-Fi
        Write-Log "Fazendo backup de perfis Wi-Fi..."
        $wifiBackupPath = Join-Path $BackupDir "WiFi_$timestamp"
        if (-not (Test-Path $wifiBackupPath)) { New-Item -Path $wifiBackupPath -ItemType Directory -Force | Out-Null }
        
        $profileLines = netsh wlan show profiles 2>&1
        if ($profileLines -notmatch "não há nenhuma interface|no wireless|AutoConfig.*not running") {
            $wifiProfiles = @()
            foreach ($line in $profileLines) {
                if ($line -match ':\s*(.+)$') {
                    $name = $matches[1].Trim()
                    if ($name -and $name -ne '<None>' -and $name -notmatch '^(\s*|-|política|group)') {
                        $wifiProfiles += $name
                    }
                }
            }
            
            if ($wifiProfiles.Count -gt 0) {
                foreach ($wifiProfile in $wifiProfiles) {
                    netsh wlan export profile name="$wifiProfile" folder="$wifiBackupPath" key=clear 2>&1 | Out-Null
                }
                
                $backupContent += @"

# Restaurando perfis Wi-Fi
Write-Host "`nRestaurando perfis Wi-Fi..." -ForegroundColor Yellow
`$wifiPath = '$wifiBackupPath'
if (Test-Path `$wifiPath) {
    Get-ChildItem -Path `$wifiPath -Filter '*.xml' | ForEach-Object {
        netsh wlan add profile filename="`$(`$_.FullName)" 2>&1 | Out-Null
        Write-Host "  Importado: `$(`$_.BaseName)" -ForegroundColor Green
    }
}
else {
    Write-Warning "Pasta de perfis Wi-Fi não encontrada"
}

"@
                Write-Log "  Backup de $($wifiProfiles.Count) perfis Wi-Fi"
            }
        }

        # 3. Backup de Configurações de Proxy
        Write-Log "Fazendo backup de configurações de proxy..."
        $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
        if ($proxySettings -and $proxySettings.ProxyEnable -eq 1) {
            $proxyServer = $proxySettings.ProxyServer
            $backupContent += @"

# Restaurando configurações de proxy
Write-Host "`nRestaurando proxy..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "$proxyServer"
Write-Host "  Proxy configurado: $proxyServer" -ForegroundColor Green

"@
            Write-Log "  Backup de proxy: $proxyServer"
        }

        # Finalização do script de restore
        $backupContent += @"

Write-Host "`n=== RESTORE CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Recomenda-se reiniciar o computador para aplicar todas as configurações." -ForegroundColor Yellow
pause
"@

        # Salvar arquivo de backup
        Set-Content -Path $BackupFile -Value $backupContent -Encoding UTF8
        Write-Log "Backup salvo em: $BackupFile" "SUCCESS"
        
        # Criar cópia como restore_network.ps1 (sempre o mais recente)
        $latestRestore = Join-Path $BackupDir "restore_network.ps1"
        Copy-Item -Path $BackupFile -Destination $latestRestore -Force
        Write-Log "Cópia de restore criada: $latestRestore" "SUCCESS"
        
        Write-Log "=== BACKUP CONCLUÍDO COM SUCESSO ===" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "ERRO durante backup: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Verifica e solicita elevação administrativa
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


if (-not $isAdmin) {
    Write-Warning "Solicitando privilégios de administrador..."
    $arguments = "& '$PSCommandPath'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Write-Log "=== RESET DE REDE E SERVIÇOS ===" "SUCCESS"

# ============================================================
# BACKUP DE CONFIGURAÇÕES ANTES DO RESET
# ============================================================

Write-Log "`nCriando backup das configurações atuais..." "SUCCESS"
$backupSuccess = Backup-NetworkConfiguration

if (-not $backupSuccess) {
    Write-Log "AVISO: Backup falhou, mas continuando com reset..." "ERROR"
    Write-Host "`nDeseja continuar mesmo sem backup? (S/N): " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'S' -and $response -ne 's') {
        Write-Log "Operação cancelada pelo usuário" "ERROR"
        exit
    }
}

# ============================================================
# INÍCIO DO RESET DE REDE
# ============================================================

try {
    # 1. Serviços a configurar (habilitar automático)
    Write-Log "`nConfigurando serviços..."
    
    $servicesToEnable = @(
        "browser",
        "Dhcp",
        "lanmanserver",
        "lanmanworkstation",
        "Netman",
        "Schedule",
        "Netlogon",
        "NtLmSsp",
        "Dnscache",      # DNS Client - importante para cache DNS funcionar depois
        "Nla",
        "netsvcs"
    )

    foreach ($svc in $servicesToEnable) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            Write-Log "→ $svc → Automatic"
        }
    }

    # 2. Iniciar os serviços
    Write-Log "`nIniciando serviços..."
    
    foreach ($svc in $servicesToEnable) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            Write-Log "→ Iniciado: $svc"
        }
    }

    # 3. Ajustes de Registro
    Write-Log "`nAplicando ajustes de registro..."

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Csc\Parameters" `
        -Name "FormatDatabase" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
        -Name "LimitBlankPasswordUse" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    Write-Log "→ Registros atualizados"

    # 4. Reset de rede + Limpeza de cache DNS
    Write-Log "`nExecutando reset de rede e cache DNS..."
    
    # Resets clássicos
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    netsh advfirewall reset | Out-Null

    # Limpeza do cache DNS
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Log "→ Cache DNS limpo com sucesso"
    }
    else {
        # Fallback para PowerShell 2.0
        ipconfig /flushdns | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "→ Cache DNS limpo com sucesso"
        }
        else {
            Write-Log "Falha ao limpar cache DNS" "ERROR"
        }
    }

    Write-Log "[OK] Reset concluído" "SUCCESS"

}
catch {
    Write-Log "`n[ERRO] $($_.Exception.Message)" "ERROR"
}

Write-Log "`nConcluído. Recomenda-se reiniciar o computador para aplicar todas as alterações." "SUCCESS"
Write-Log "Backup salvo em: $BackupDir" "SUCCESS"

