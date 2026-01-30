<#
.SYNOPSIS
    HP-Scripts Repair v1.0 - Reparo Automático de Problemas do Windows
.DESCRIPTION
    Script de reparo automático baseado em diagnóstico do sistema.
    Oferece ações corretivas para problemas comuns detectados no check.ps1
.NOTES
    Autor: HP-Scripts Team
    Versão: 1.0
    Compatibilidade: PowerShell 5.1+ (Windows 10/11)
    Requer: Execução como Administrador
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CONFIGURAÇÕES E FUNÇÕES AUXILIARES
# ============================================================

# Cores para output
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"
$ColorAction = "Magenta"

function Write-Status {
    param([string]$Message, [string]$Status, [string]$Color = "White")
    
    $icon = switch ($Status) {
        "SUCESSO" { "✅" }
        "AVISO" { "⚠️" }
        "ERRO" { "❌" }
        "INFO" { "ℹ️" }
        default { "➡️" }
    }
    
    Write-Host "$icon $Message" -ForegroundColor $Color
}

function Show-RepairMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║           🛠️  HPCRAFT - REPARO AUTOMÁTICO TI  🛠️            ║" -ForegroundColor Cyan
    Write-Host "  ║              Suporte: docs.hpinfo.com.br | v1.0              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [1] 🔍 Executar Diagnóstico Completo + Sugestões de Reparo" -ForegroundColor White
    Write-Host "  [2] 🌐 Reparo de Rede e Conectividade" -ForegroundColor White
    Write-Host "  [3] 🧹 Limpeza e Otimização do Sistema" -ForegroundColor White
    Write-Host "  [4] 🛡️  Reparo de Segurança e Windows Defender" -ForegroundColor White
    Write-Host "  [5] ⚙️  Reparo de Serviços do Windows" -ForegroundColor White
    Write-Host "  [6] 💾 Reparo de Disco e Sistema de Arquivos" -ForegroundColor White
    Write-Host "  [7] 🔄 Reparo de Windows Update" -ForegroundColor White
    Write-Host "  [8] 🚀 Otimização de Desempenho" -ForegroundColor White
    Write-Host "  [9] 📋 Reparo Completo (Todas as Categorias)" -ForegroundColor $ColorAction
    Write-Host ""
    Write-Host "  [D] 📊 Verificar Diagnóstico Atual do Sistema" -ForegroundColor Gray
    Write-Host "  [L] 📝 Ver Log de Reparos Executados" -ForegroundColor Gray
    Write-Host "  [Q] Sair" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================
# FUNÇÕES DE REPARO POR CATEGORIA
# ============================================================

function Repair-Network {
    Write-Status "Iniciando reparo de rede..." "INFO" $ColorInfo
    
    try {
        # 1. Reset DNS
        Write-Status "Resetando cache DNS..." "INFO" $ColorInfo
        ipconfig /flushdns 2>&1 | Out-Null
        Write-Status "Cache DNS limpo" "SUCESSO" $ColorSuccess
        
        # 2. Reset Winsock
        Write-Status "Resetando Winsock..." "INFO" $ColorInfo
        netsh winsock reset 2>&1 | Out-Null
        Write-Status "Winsock resetado" "SUCESSO" $ColorSuccess
        
        # 3. Reset TCP/IP
        Write-Status "Resetando TCP/IP..." "INFO" $ColorInfo
        netsh int ip reset 2>&1 | Out-Null
        Write-Status "TCP/IP resetado" "SUCESSO" $ColorSuccess
        
        # 4. Liberar e renovar IP
        Write-Status "Liberando e renovando IP..." "INFO" $ColorInfo
        ipconfig /release 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        ipconfig /renew 2>&1 | Out-Null
        Write-Status "IP renovado" "SUCESSO" $ColorSuccess
        
        # 5. Limpar tabela ARP
        Write-Status "Limpando tabela ARP..." "INFO" $ColorInfo
        arp -d * 2>&1 | Out-Null
        Write-Status "Tabela ARP limpa" "SUCESSO" $ColorSuccess
        
        # 6. Configurar DNS do Google
        Write-Status "Configurando DNS do Google..." "INFO" $ColorInfo
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4") -ErrorAction SilentlyContinue
        }
        Write-Status "DNS configurado" "SUCESSO" $ColorSuccess
        
        # 7. Reiniciar serviços de rede
        Write-Status "Reiniciando serviços de rede..." "INFO" $ColorInfo
        Restart-Service -Name "Dhcp" -Force -ErrorAction SilentlyContinue
        Restart-Service -Name "Dnscache" -Force -ErrorAction SilentlyContinue
        Write-Status "Serviços de rede reiniciados" "SUCESSO" $ColorSuccess
        
        Write-Status "Reparo de rede concluído com sucesso!" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante reparo de rede: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-Cleanup {
    Write-Status "Iniciando limpeza do sistema..." "INFO" $ColorInfo
    
    try {
        # 1. Limpar arquivos temporários
        Write-Status "Limpando arquivos temporários..." "INFO" $ColorInfo
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "Arquivos temporários removidos" "SUCESSO" $ColorSuccess
        
        # 2. Limpar cache do Windows Update
        Write-Status "Limpando cache do Windows Update..." "INFO" $ColorInfo
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        Write-Status "Cache do Windows Update limpo" "SUCESSO" $ColorSuccess
        
        # 3. Limpar cache do DNS
        Write-Status "Limpando cache DNS..." "INFO" $ColorInfo
        ipconfig /flushdns 2>&1 | Out-Null
        Write-Status "Cache DNS limpo" "SUCESSO" $ColorSuccess
        
        # 4. Limpar Prefetch
        Write-Status "Limpando Prefetch..." "INFO" $ColorInfo
        Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
        Write-Status "Prefetch limpo" "SUCESSO" $ColorSuccess
        
        # 5. Limpar logs antigos do Event Viewer
        Write-Status "Limpando logs antigos do Event Viewer..." "INFO" $ColorInfo
        wevtutil el | ForEach-Object { wevtutil cl $_ } 2>&1 | Out-Null
        Write-Status "Logs do Event Viewer limpos" "SUCESSO" $ColorSuccess
        
        # 6. Limpar cache do Microsoft Store
        Write-Status "Limpando cache do Microsoft Store..." "INFO" $ColorInfo
        Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore*" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -match "cache|temp" } | 
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "Cache do Microsoft Store limpo" "SUCESSO" $ColorSuccess
        
        # 7. Executar Disk Cleanup silencioso
        Write-Status "Executando Disk Cleanup..." "INFO" $ColorInfo
        cleanmgr /sagerun:1 2>&1 | Out-Null
        Write-Status "Disk Cleanup executado" "SUCESSO" $ColorSuccess
        
        Write-Status "Limpeza do sistema concluída com sucesso!" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante limpeza: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-Security {
    Write-Status "Iniciando reparo de segurança..." "INFO" $ColorInfo
    
    try {
        # 1. Verificar e ativar Windows Defender
        Write-Status "Verificando Windows Defender..." "INFO" $ColorInfo
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        if ($defenderStatus) {
            if (-not $defenderStatus.RealTimeProtectionEnabled) {
                Write-Status "Ativando proteção em tempo real..." "INFO" $ColorInfo
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
                Write-Status "Proteção em tempo real ativada" "SUCESSO" $ColorSuccess
            }
            else {
                Write-Status "Proteção em tempo real já está ativa" "SUCESSO" $ColorSuccess
            }
            
            # 2. Atualizar definições de vírus
            Write-Status "Atualizando definições de vírus..." "INFO" $ColorInfo
            Update-MpSignature -ErrorAction SilentlyContinue
            Write-Status "Definições atualizadas" "SUCESSO" $ColorSuccess
            
            # 3. Executar varredura rápida
            Write-Status "Executando varredura rápida..." "INFO" $ColorInfo
            Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
            Write-Status "Varredura rápida iniciada" "SUCESSO" $ColorSuccess
        }
        else {
            Write-Status "Windows Defender não disponível" "AVISO" $ColorWarning
        }
        
        # 4. Verificar e ativar Firewall
        Write-Status "Verificando Firewall..." "INFO" $ColorInfo
        $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        
        foreach ($profile in $firewallProfiles) {
            if (-not $profile.Enabled) {
                Write-Status "Ativando Firewall no perfil $($profile.Name)..." "INFO" $ColorInfo
                Set-NetFirewallProfile -Name $profile.Name -Enabled True -ErrorAction SilentlyContinue
                Write-Status "Firewall ativado no perfil $($profile.Name)" "SUCESSO" $ColorSuccess
            }
        }
        
        # 5. Verificar e remover ativadores ilegais
        Write-Status "Verificando ativadores ilegais..." "INFO" $ColorInfo
        $suspectPaths = @("C:\Program Files", "C:\Program Files (x86)", "C:\Windows", "$env:APPDATA", "$env:LOCALAPPDATA")
        $suspectFiles = @("*KMS*", "*AutoPico*", "*KMSAuto*", "*KMSpico*", "*Microsoft Toolkit*")
        
        $foundFiles = @()
        foreach ($path in $suspectPaths) {
            if (Test-Path $path) {
                foreach ($pattern in $suspectFiles) {
                    $files = Get-ChildItem -Path $path -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Depth 2
                    if ($files) {
                        $foundFiles += $files
                    }
                }
            }
        }
        
        if ($foundFiles.Count -gt 0) {
            Write-Status "Encontrados $($foundFiles.Count) arquivos suspeitos" "AVISO" $ColorWarning
            foreach ($file in $foundFiles | Select-Object -First 5) {
                Write-Status "  Suspeito: $($file.FullName)" "AVISO" $ColorWarning
            }
        }
        else {
            Write-Status "Nenhum ativador ilegal encontrado" "SUCESSO" $ColorSuccess
        }
        
        Write-Status "Reparo de segurança concluído!" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante reparo de segurança: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-Services {
    Write-Status "Iniciando reparo de serviços..." "INFO" $ColorInfo
    
    try {
        # Lista de serviços críticos que devem estar rodando
        $criticalServices = @(
            @{Name = "wuauserv"; Display = "Windows Update" },
            @{Name = "WinDefend"; Display = "Windows Defender" },
            @{Name = "BITS"; Display = "Background Intelligent Transfer" },
            @{Name = "WSearch"; Display = "Windows Search" },
            @{Name = "W32Time"; Display = "Horário Windows" },
            @{Name = "EventLog"; Display = "Event Log" },
            @{Name = "CryptSvc"; Display = "Cryptographic Services" },
            @{Name = "Dnscache"; Display = "DNS Client" },
            @{Name = "Dhcp"; Display = "DHCP Client" }
        )
        
        $repairedCount = 0
        $totalCount = $criticalServices.Count
        
        foreach ($svc in $criticalServices) {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            
            if ($service) {
                if ($service.Status -ne "Running") {
                    Write-Status "Iniciando serviço $($svc.Display)..." "INFO" $ColorInfo
                    try {
                        Start-Service -Name $svc.Name -ErrorAction Stop
                        Write-Status "Serviço $($svc.Display) iniciado" "SUCESSO" $ColorSuccess
                        $repairedCount++
                    }
                    catch {
                        Write-Status "Falha ao iniciar $($svc.Display)" "ERRO" $ColorError
                    }
                }
                else {
                    Write-Status "Serviço $($svc.Display) já está rodando" "SUCESSO" $ColorSuccess
                }
            }
            else {
                Write-Status "Serviço $($svc.Display) não encontrado" "AVISO" $ColorWarning
            }
        }
        
        # Configurar serviços para iniciar automaticamente
        foreach ($svc in $criticalServices) {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($service -and $service.StartType -ne "Automatic") {
                Write-Status "Configurando $($svc.Display) para iniciar automaticamente..." "INFO" $ColorInfo
                Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
                Write-Status "$($svc.Display) configurado para automático" "SUCESSO" $ColorSuccess
            }
        }
        
        Write-Status "Reparo de serviços concluído: $repairedCount/$totalCount serviços reparados" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante reparo de serviços: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-Disk {
    Write-Status "Iniciando reparo de disco..." "INFO" $ColorInfo
    
    try {
        # 1. Verificar integridade do sistema de arquivos com SFC
        Write-Status "Verificando integridade do sistema com SFC..." "INFO" $ColorInfo
        sfc /scannow 2>&1 | Out-Null
        Write-Status "Verificação SFC concluída" "SUCESSO" $ColorSuccess
        
        # 2. Executar DISM para reparar imagem do Windows
        Write-Status "Reparando imagem do Windows com DISM..." "INFO" $ColorInfo
        dism /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
        Write-Status "Reparo DISM concluído" "SUCESSO" $ColorSuccess
        
        # 3. Verificar e reparar discos com CHKDSK
        Write-Status "Verificando discos com CHKDSK..." "INFO" $ColorInfo
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($disk in $disks) {
            $drive = $disk.DeviceID.Replace(":", "")
            Write-Status "Verificando disco $drive..." "INFO" $ColorInfo
            chkdsk $drive: /f /x 2>&1 | Out-Null
            Write-Status "Disco $drive verificado" "SUCESSO" $ColorSuccess
        }
        
        # 4. Otimizar discos (TRIM para SSD, desfragmentação para HDD)
        Write-Status "Otimizando discos..." "INFO" $ColorInfo
        $physicalDisks = Get-PhysicalDisk
        foreach ($pdisk in $physicalDisks) {
            if ($pdisk.MediaType -eq "SSD") {
                Write-Status "Executando TRIM no SSD..." "INFO" $ColorInfo
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
                Write-Status "TRIM executado" "SUCESSO" $ColorSuccess
            }
            else {
                Write-Status "Desfragmentando HDD..." "INFO" $ColorInfo
                Optimize-Volume -DriveLetter C -Defrag -ErrorAction SilentlyContinue
                Write-Status "Desfragmentação concluída" "SUCESSO" $ColorSuccess
            }
        }
        
        # 5. Limpar arquivos temporários do sistema
        Write-Status "Limpando arquivos do sistema..." "INFO" $ColorInfo
        Remove-Item "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:windir\Logs\CBS\*.log" -Force -ErrorAction SilentlyContinue
        Write-Status "Arquivos do sistema limpos" "SUCESSO" $ColorSuccess
        
        Write-Status "Reparo de disco concluído com sucesso!" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante reparo de disco: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-WindowsUpdate {
    Write-Status "Iniciando reparo do Windows Update..." "INFO" $ColorInfo
    
    try {
        # 1. Parar serviços relacionados ao Windows Update
        Write-Status "Parando serviços do Windows Update..." "INFO" $ColorInfo
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "BITS" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "CryptSvc" -Force -ErrorAction SilentlyContinue
        Write-Status "Serviços parados" "SUCESSO" $ColorSuccess
        
        # 2. Renomear pasta SoftwareDistribution
        Write-Status "Renomeando pasta SoftwareDistribution..." "INFO" $ColorInfo
        $softwareDist = "C:\Windows\SoftwareDistribution"
        $softwareDistBackup = "C:\Windows\SoftwareDistribution.old"
        if (Test-Path $softwareDist) {
            Rename-Item -Path $softwareDist -NewName "SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
            Write-Status "Pasta renomeada" "SUCESSO" $ColorSuccess
        }
        
        # 3. Renomear catroot2
        Write-Status "Renomeando catroot2..." "INFO" $ColorInfo
        $catroot2 = "C:\Windows\System32\catroot2"
        $catroot2Backup = "C:\Windows\System32\catroot2.old"
        if (Test-Path $catroot2) {
            Rename-Item -Path $catroot2 -NewName "catroot2.old" -Force -ErrorAction SilentlyContinue
            Write-Status "Catroot2 renomeado" "SUCESSO" $ColorSuccess
        }
        
        # 4. Reiniciar serviços
        Write-Status "Reiniciando serviços..." "INFO" $ColorInfo
        Start-Service -Name "CryptSvc" -ErrorAction SilentlyContinue
        Start-Service -Name "BITS" -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        Write-Status "Serviços reiniciados" "SUCESSO" $ColorSuccess
        
        # 5. Resetar componentes do Windows Update
        Write-Status "Resetando componentes do Windows Update..." "INFO" $ColorInfo
        & "C:\Windows\System32\regsvr32.exe" /s atl.dll 2>&1 | Out-Null
        & "C:\Windows\System32\regsvr32.exe" /s urlmon.dll 2>&1 | Out-Null
        & "C:\Windows\System32\regsvr32.exe" /s mshtml.dll 2>&1 | Out-Null
        Write-Status "Componentes resetados" "SUCESSO" $ColorSuccess
        
        # 6. Executar DISM para reparar imagem
        Write-Status "Reparando imagem do Windows..." "INFO" $ColorInfo
        dism /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
        Write-Status "Imagem reparada" "SUCESSO" $ColorSuccess
        
        # 7. Verificar atualizações
        Write-Status "Verificando atualizações disponíveis..." "INFO" $ColorInfo
        $updateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue
        if ($updateSession) {
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            $updateCount = $searchResult.Updates.Count
            Write-Status "$updateCount atualizações disponíveis" "SUCESSO" $ColorSuccess
        }
        
        Write-Status "Reparo do Windows Update concluído!" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante reparo do Windows Update: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-Performance {
    Write-Status "Iniciando otimização de desempenho..." "INFO" $ColorInfo
    
    try {
        # 1. Ajustar plano de energia para Alto Desempenho
        Write-Status "Configurando plano de energia..." "INFO" $ColorInfo
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
        Write-Status "Plano de energia configurado" "SUCESSO" $ColorSuccess
        
        # 2. Desativar efeitos visuais para melhor performance
        Write-Status "Otimizando efeitos visuais..." "INFO" $ColorInfo
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
        Write-Status "Efeitos visuais otimizados" "SUCESSO" $ColorSuccess
        
        # 3. Ajustar configurações de sistema
        Write-Status "Ajustando configurações do sistema..." "INFO" $ColorInfo
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -ErrorAction SilentlyContinue
        Write-Status "Configurações ajustadas" "SUCESSO" $ColorSuccess
        
        # 4. Desativar serviços desnecessários
        Write-Status "Otimizando serviços..." "INFO" $ColorInfo
        $servicesToDisable = @(
            "Fax",
            "lfsvc",
            "MapsBroker",
            "NetTcpPortSharing",
            "RemoteRegistry",
            "SharedAccess",
            "TrkWks",
            "WbioSrvc",
            "WMPNetworkSvc",
            "wscsvc"
        )
        
        foreach ($service in $servicesToDisable) {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq "Running") {
                Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Status "Serviços otimizados" "SUCESSO" $ColorSuccess
        
        # 5. Limpar Prefetch e Superfetch
        Write-Status "Otimizando Prefetch..." "INFO" $ColorInfo
        Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 1 -ErrorAction SilentlyContinue
        Write-Status "Prefetch otimizado" "SUCESSO" $ColorSuccess
        
        # 6. Ajustar prioridade do processo
        Write-Status "Ajustando prioridades..." "INFO" $ColorInfo
        $process = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($process) {
            $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        }
        Write-Status "Prioridades ajustadas" "SUCESSO" $ColorSuccess
        
        Write-Status "Otimização de desempenho concluída!" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante otimização de desempenho: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-Complete {
    Write-Status "Iniciando reparo completo do sistema..." "INFO" $ColorInfo
    Write-Host "Este processo pode levar vários minutos. Aguarde..." -ForegroundColor Yellow
    
    $results = @{}
    
    # Executar todos os reparos em sequência
    $results.Network = Repair-Network
    Start-Sleep -Seconds 2
    
    $results.Cleanup = Repair-Cleanup
    Start-Sleep -Seconds 2
    
    $results.Security = Repair-Security
    Start-Sleep -Seconds 2
    
    $results.Services = Repair-Services
    Start-Sleep -Seconds 2
    
    $results.Disk = Repair-Disk
    Start-Sleep -Seconds 2
    
    $results.WindowsUpdate = Repair-WindowsUpdate
    Start-Sleep -Seconds 2
    
    $results.Performance = Repair-Performance
    
    # Resumo dos resultados
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "RESUMO DO REPARO COMPLETO" -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $results.Count
    
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "✅ SUCESSO" } else { "❌ FALHA" }
        Write-Host "  $($key.PadRight(15)): $status" -ForegroundColor $(if ($results[$key]) { "Green" } else { "Red" })
    }
    
    Write-Host "`n  Total: $successCount/$totalCount reparos concluídos com sucesso" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } elseif ($successCount -gt $totalCount / 2) { "Yellow" } else { "Red" })
    
    if ($successCount -eq $totalCount) {
        Write-Status "Reparo completo concluído com sucesso total!" "SUCESSO" $ColorSuccess
    }
    else {
        Write-Status "Reparo completo concluído com $successCount/$totalCount sucessos" "AVISO" $ColorWarning
    }
    
    return $successCount -eq $totalCount
}

# ============================================================
# LÓGICA PRINCIPAL DO SCRIPT
# ============================================================

# Criação de log - Usa variável de ambiente para compatibilidade
$logDir = "$env:ProgramData\HP-Scripts\Logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "repair_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Start-TranscriptLog {
    Start-Transcript -Path $logFile -Append -ErrorAction SilentlyContinue
}

function Stop-TranscriptLog {
    Stop-Transcript -ErrorAction SilentlyContinue
}

# Menu principal
do {
    Show-RepairMenu
    $choice = Read-Host "Selecione uma opção"
    
    switch ($choice) {
        "1" {
            # Diagnóstico + Sugestões
            Write-Status "Executando diagnóstico completo..." "INFO" $ColorInfo
            Write-Host "`n[INFO] Esta funcionalidade requer integração com check.ps1" -ForegroundColor Yellow
            Write-Host "[INFO] Execute o script check.ps1 primeiro para diagnóstico detalhado" -ForegroundColor Yellow
            Read-Host "`nPressione ENTER para continuar"
        }
        "2" { 
            Start-TranscriptLog
            Repair-Network
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "3" { 
            Start-TranscriptLog
            Repair-Cleanup
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "4" { 
            Start-TranscriptLog
            Repair-Security
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "5" { 
            Start-TranscriptLog
            Repair-Services
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "6" { 
            Start-TranscriptLog
            Repair-Disk
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "7" { 
            Start-TranscriptLog
            Repair-WindowsUpdate
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "8" { 
            Start-TranscriptLog
            Repair-Performance
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "9" { 
            Start-TranscriptLog
            Repair-Complete
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "D" {
            # Verificar diagnóstico atual
            Write-Status "Executando verificação rápida do sistema..." "INFO" $ColorInfo
            & "$PSScriptRoot\check.ps1"
            Read-Host "`nPressione ENTER para continuar"
        }
        "L" {
            # Ver logs
            if (Test-Path $logDir) {
                $logs = Get-ChildItem $logDir -Filter "repair_*.log" | Sort-Object LastWriteTime -Descending
                if ($logs) {
                    Write-Host "`nÚltimos logs de reparo:" -ForegroundColor Cyan
                    foreach ($log in $logs | Select-Object -First 5) {
                        Write-Host "  $($log.Name) - $($log.LastWriteTime)" -ForegroundColor Gray
                    }
                    $openLog = Read-Host "`nDigite o nome do log para abrir (ou ENTER para cancelar)"
                    if ($openLog -and (Test-Path (Join-Path $logDir $openLog))) {
                        notepad (Join-Path $logDir $openLog)
                    }
                }
                else {
                    Write-Host "Nenhum log encontrado." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Diretório de logs não encontrado." -ForegroundColor Yellow
            }
            Read-Host "`nPressione ENTER para continuar"
        }
        "Q" { 
            Write-Host "`nEncerrando script de reparo..." -ForegroundColor Green
            break 
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)

Write-Host "`nScript de reparo finalizado. Logs disponíveis em: $logDir" -ForegroundColor Cyan
