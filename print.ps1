# Reset-Spooler.ps1 - Reinicia serviço de impressão + ajustes de registro de compatibilidade
# Executa sem confirmações - use com cautela!

# Verifica se está rodando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    # USO DE WRITE-WARNING PARA ALERTA CRÍTICO
    Write-Warning "Este script precisa ser executado como Administrador!"
    Pause
    exit
}

try {
    # 1. Parar o serviço Spooler
    # USO DE WRITE-OUTPUT
    Write-Output "Parando serviço Spooler..."
    Stop-Service -Name Spooler -Force -ErrorAction Stop

    # 2. Limpar pasta de spool
    # USO DE WRITE-OUTPUT
    Write-Output "Limpando arquivos de spool..."
    Remove-Item -Path "$env:WINDIR\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue

    # 3. Aplicar ajustes de registro (compatibilidade / desativação de proteções)
    # USO DE WRITE-OUTPUT
    Write-Output "`nAplicando ajustes de registro para maior compatibilidade..."

    $regChanges = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides"; Name = "713073804"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides"; Name = "1921033356"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides"; Name = "3598754956"; Value = 0; Type = "DWord" }

        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"; Name = "RestrictDriverInstallationToAdministrators"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"; Name = "UpdatePromptSettings"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"; Name = "NoWarningNoElevationOnInstall"; Value = 0; Type = "DWord" }

        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"; Name = "RpcAuthnLevelPrivacyEnabled"; Value = 0; Type = "DWord" }
    )

    foreach ($reg in $regChanges) {
        $path = $reg.Path
        $name = $reg.Name
        $value = $reg.Value
        $type = $reg.Type

        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }

        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
        # USO DE WRITE-OUTPUT
        Write-Output "→ Configurado: $name = $value  ($path)"
    }

    # 4. Reiniciar o serviço Spooler
    # USO DE WRITE-OUTPUT
    Write-Output "`nIniciando serviço Spooler..."
    Start-Service -Name Spooler -ErrorAction Stop

    Start-Sleep -Seconds 5

    $status = Get-Service -Name Spooler
    if ($status.Status -eq 'Running') {
        # USO DE WRITE-OUTPUT PARA SUCESSO
        Write-Output "`n[OK] Spooler reiniciado com sucesso!"
    }
    else {
        # USO DE WRITE-WARNING PARA STATUS IRREGULAR
        Write-Warning "`n[!] Spooler iniciado mas não está rodando normalmente (Status: $($status.Status))"
    }

    # 5. Listar impressoras instaladas
    # USO DE WRITE-OUTPUT
    Write-Output "`n=== IMPRESSORAS INSTALADAS ==="
    
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        Get-Printer | Format-Table Name, DriverName, PortName -AutoSize
    }
    else {
        # Fallback para PowerShell 2.0 usando WMI
        Get-WmiObject Win32_Printer | Format-Table Name, DriverName, PortName -AutoSize
    }

    # 6. Abrir a pasta clássica "Dispositivos e Impressoras" (legacy view)
    # USO DE WRITE-OUTPUT
    Write-Output "`nAbrindo a pasta clássica 'Dispositivos e Impressoras'..."
    Start-Process "explorer.exe" "shell:::{A8A91A66-3A7D-4424-8D24-04E180695C7A}"

}
catch {
    # USO DE WRITE-WARNING PARA ERRO GERAL
    Write-Warning "`n[ERRO] Ocorreu um erro: $($_.Exception.Message)"
}

# USO DE WRITE-OUTPUT
Write-Output "`nFinalizado. Pressione qualquer tecla para sair..."

