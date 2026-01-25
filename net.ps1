# ResetRede.ps1 - Reset de configurações de rede + serviços relacionados
# Executar como ADMINISTRADOR

# Verifica e solicita elevação administrativa
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # USO DE WRITE-WARNING PARA SOLICITAÇÃO DE PRIVILÉGIO
    Write-Warning "Solicitando privilégios de administrador..."
    $arguments = "& '$PSCommandPath'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# USO DE WRITE-OUTPUT
Write-Output "=== RESET DE REDE E SERVIÇOS === "

try {
    # 1. Serviços a configurar (habilitar automático)
    # USO DE WRITE-OUTPUT
    Write-Output "`nConfigurando serviços..."
    
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
            # USO DE WRITE-OUTPUT
            Write-Output "→ $svc → Automatic"
        }
    }

    # 2. Iniciar os serviços
    # USO DE WRITE-OUTPUT
    Write-Output "`nIniciando serviços..."
    
    foreach ($svc in $servicesToEnable) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            # USO DE WRITE-OUTPUT
            Write-Output "→ Iniciado: $svc"
        }
    }

    # 3. Ajustes de Registro
    # USO DE WRITE-OUTPUT
    Write-Output "`nAplicando ajustes de registro..."

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Csc\Parameters" `
                     -Name "FormatDatabase" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
                     -Name "LimitBlankPasswordUse" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
                     -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    # USO DE WRITE-OUTPUT
    Write-Output "→ Registros atualizados"

    # 4. Reset de rede + Limpeza de cache DNS
    # USO DE WRITE-OUTPUT
    Write-Output "`nExecutando reset de rede e cache DNS..."
    
    # Resets clássicos
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    netsh advfirewall reset | Out-Null

    # Limpeza do cache DNS (equivalente a ipconfig /flushdns)
    Clear-DnsClientCache -ErrorAction Stop
    # USO DE WRITE-OUTPUT
    Write-Output "→ Cache DNS limpo com sucesso"

    # USO DE WRITE-OUTPUT
    Write-Output "[OK] Reset concluído"

} catch {
    # USO DE WRITE-WARNING PARA ERROS
    Write-Warning "`n[ERRO] $($_.Exception.Message)"
}

# USO DE WRITE-OUTPUT
Write-Output "`nConcluído. Recomenda-se reiniciar o computador para aplicar todas as alterações."

