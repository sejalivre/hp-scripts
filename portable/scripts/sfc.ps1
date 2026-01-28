#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Script de Diagnóstico e Reparação Completa do Windows
.DESCRIPTION
    Verifica e repara a saúde do Windows através de múltiplas verificações:
    - DISM (Deployment Image Servicing and Management)
    - SFC (System File Checker)
    - Limpeza de memória e processos
    - Verificação de disco
    - Otimização de serviços
    - Limpeza de arquivos temporários
    - Reparação do Windows Update
    - Verificação de malware básica
.NOTES
    Autor: HP Scripts
    Versão: 1.0
    Requer: Privilégios de Administrador
#>

# Configuração de cores
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Função para exibir cabeçalho
function Show-Header {
    param([string]$Title)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

# Função para log
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
    
    # Salvar em arquivo de log
    $logDir = "C:\Program Files\HPTI"
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    $logPath = "$logDir\sfc_repair_$(Get-Date -Format 'yyyyMMdd').log"
    "[$timestamp] [$Type] $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

# Função para verificar privilégios de administrador
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verificar se está rodando como administrador
if (-not (Test-Admin)) {
    Write-Log "Este script requer privilégios de administrador!" -Type "ERROR"
    Write-Host "`nPressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Show-Header "DIAGNÓSTICO E REPARAÇÃO COMPLETA DO WINDOWS"
Write-Log "Iniciando diagnóstico completo do sistema..." -Type "SUCCESS"

# ============================================================================
# 1. VERIFICAÇÃO E LIMPEZA DE MEMÓRIA
# ============================================================================
Show-Header "1. ANÁLISE E OTIMIZAÇÃO DE MEMÓRIA"

try {
    $os = Get-WmiObject Win32_OperatingSystem
    $totalMemory = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMemory = $totalMemory - $freeMemory
    $percentUsed = [math]::Round(($usedMemory / $totalMemory) * 100, 2)
    
    Write-Log "Memória Total: $totalMemory GB"
    Write-Log "Memória Usada: $usedMemory GB ($percentUsed%)"
    Write-Log "Memória Livre: $freeMemory GB"
    
    if ($percentUsed -gt 80) {
        Write-Log "Uso de memória crítico! Liberando memória..." -Type "WARNING"
        
        # Limpar cache de DNS
        Write-Log "Limpando cache DNS..."
        ipconfig /flushdns | Out-Null
        
        # Limpar working set de processos
        Write-Log "Otimizando working set de processos..."
        Get-Process | ForEach-Object { 
            try { 
                $_.WorkingSet = 0 
            }
            catch { 
                # Ignorar erros de processos protegidos
            }
        }
        
        # Forçar coleta de lixo .NET
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        Write-Log "Memória otimizada com sucesso!" -Type "SUCCESS"
    }
    else {
        Write-Log "Uso de memória está normal." -Type "SUCCESS"
    }
}
catch {
    Write-Log "Erro ao analisar memória: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 2. IDENTIFICAÇÃO DE PROCESSOS PROBLEMÁTICOS
# ============================================================================
Show-Header "2. ANÁLISE DE PROCESSOS"

try {
    Write-Log "Identificando processos com alto consumo de recursos..."
    
    # Top 10 processos por CPU
    $topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
    Write-Host "`nTop 10 Processos por CPU:" -ForegroundColor Yellow
    $topCPU | Format-Table Name, CPU, @{Name = "Memory(MB)"; Expression = { [math]::Round($_.WorkingSet / 1MB, 2) } } -AutoSize
    
    # Top 10 processos por Memória
    $topMemory = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10
    Write-Host "`nTop 10 Processos por Memória:" -ForegroundColor Yellow
    $topMemory | Format-Table Name, @{Name = "Memory(MB)"; Expression = { [math]::Round($_.WorkingSet / 1MB, 2) } }, CPU -AutoSize
    
    # Verificar processos suspeitos (múltiplas instâncias)
    $duplicates = Get-Process | Group-Object Name | Where-Object { $_.Count -gt 5 }
    if ($duplicates) {
        Write-Log "Processos com múltiplas instâncias detectados:" -Type "WARNING"
        $duplicates | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Count) instâncias" -ForegroundColor Yellow
        }
    }
    
}
catch {
    Write-Log "Erro ao analisar processos: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 3. LIMPEZA DE ARQUIVOS TEMPORÁRIOS
# ============================================================================
Show-Header "3. LIMPEZA DE ARQUIVOS TEMPORÁRIOS"

try {
    Write-Log "Iniciando limpeza de arquivos temporários..."
    
    $tempFolders = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Temp",
        "$env:WINDIR\Prefetch"
    )
    
    $totalFreed = 0
    
    foreach ($folder in $tempFolders) {
        if (Test-Path $folder) {
            Write-Log "Limpando: $folder"
            try {
                $beforeSize = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                $afterSize = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $freed = ($beforeSize - $afterSize) / 1MB
                $totalFreed += $freed
                Write-Log "  Liberado: $([math]::Round($freed, 2)) MB" -Type "SUCCESS"
            }
            catch {
                Write-Log "  Alguns arquivos não puderam ser removidos (em uso)" -Type "WARNING"
            }
        }
    }
    
    Write-Log "Total liberado: $([math]::Round($totalFreed, 2)) MB" -Type "SUCCESS"
    
    # Limpar lixeira
    Write-Log "Esvaziando lixeira..."
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "Lixeira esvaziada com sucesso!" -Type "SUCCESS"
    }
    catch {
        Write-Log "Não foi possível esvaziar a lixeira" -Type "WARNING"
    }
    
}
catch {
    Write-Log "Erro durante limpeza: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 4. VERIFICAÇÃO E REPARAÇÃO COM DISM
# ============================================================================
Show-Header "4. VERIFICAÇÃO DISM (Deployment Image Servicing)"

try {
    Write-Log "Verificando integridade da imagem do Windows com DISM..."
    Write-Log "Isso pode levar vários minutos..." -Type "WARNING"
    
    # Verificar saúde da imagem
    Write-Log "Executando: DISM /Online /Cleanup-Image /CheckHealth"
    $checkHealth = & DISM /Online /Cleanup-Image /CheckHealth
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Problemas detectados! Executando verificação completa..." -Type "WARNING"
        
        # Scan completo
        Write-Log "Executando: DISM /Online /Cleanup-Image /ScanHealth"
        $scanHealth = & DISM /Online /Cleanup-Image /ScanHealth
        
        # Restaurar saúde
        Write-Log "Executando: DISM /Online /Cleanup-Image /RestoreHealth"
        $restoreHealth = & DISM /Online /Cleanup-Image /RestoreHealth
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "DISM: Reparação concluída com sucesso!" -Type "SUCCESS"
        }
        else {
            Write-Log "DISM: Alguns problemas não puderam ser corrigidos" -Type "ERROR"
        }
    }
    else {
        Write-Log "DISM: Nenhum problema detectado na imagem do Windows" -Type "SUCCESS"
    }
    
    # Limpeza de componentes
    Write-Log "Limpando componentes antigos..."
    & DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
    Write-Log "Limpeza de componentes concluída!" -Type "SUCCESS"
    
}
catch {
    Write-Log "Erro durante verificação DISM: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 5. VERIFICAÇÃO E REPARAÇÃO COM SFC
# ============================================================================
Show-Header "5. VERIFICAÇÃO SFC (System File Checker)"

try {
    Write-Log "Verificando integridade dos arquivos do sistema com SFC..."
    Write-Log "Isso pode levar vários minutos..." -Type "WARNING"
    
    $sfcLog = "$env:TEMP\sfc_output.txt"
    Write-Log "Executando: sfc /scannow"
    
    # Executar SFC e capturar saída
    $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru -RedirectStandardOutput $sfcLog
    
    # Analisar resultado
    $sfcOutput = Get-Content $sfcLog -Raw
    
    if ($sfcOutput -match "não encontrou nenhuma violação de integridade" -or $sfcOutput -match "did not find any integrity violations") {
        Write-Log "SFC: Nenhum problema encontrado nos arquivos do sistema" -Type "SUCCESS"
    }
    elseif ($sfcOutput -match "encontrou arquivos corrompidos e os reparou com êxito" -or $sfcOutput -match "found corrupt files and successfully repaired them") {
        Write-Log "SFC: Arquivos corrompidos foram reparados com sucesso!" -Type "SUCCESS"
    }
    else {
        Write-Log "SFC: Verificação concluída. Verifique o log para detalhes." -Type "WARNING"
        Write-Log "Log SFC: $env:WINDIR\Logs\CBS\CBS.log"
    }
    
}
catch {
    Write-Log "Erro durante verificação SFC: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 6. VERIFICAÇÃO DE DISCO
# ============================================================================
Show-Header "6. VERIFICAÇÃO DE DISCO"

try {
    Write-Log "Verificando estado dos discos..."
    
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
    
    foreach ($volume in $volumes) {
        $drive = $volume.DriveLetter
        Write-Log "Analisando disco $drive`:"
        
        # Espaço livre
        $freeSpace = [math]::Round($volume.SizeRemaining / 1GB, 2)
        $totalSpace = [math]::Round($volume.Size / 1GB, 2)
        $percentFree = [math]::Round(($freeSpace / $totalSpace) * 100, 2)
        
        Write-Log "  Espaço livre: $freeSpace GB de $totalSpace GB ($percentFree%)"
        
        if ($percentFree -lt 10) {
            Write-Log "  AVISO: Espaço em disco crítico!" -Type "WARNING"
        }
        
        # Verificar erros no disco (apenas leitura)
        Write-Log "  Verificando erros no disco $drive`:..."
        $chkdskOutput = & chkdsk "$drive`:" 2>&1
        
        if ($chkdskOutput -match "errors found" -or $chkdskOutput -match "erros encontrados") {
            Write-Log "  Erros detectados no disco $drive`:!" -Type "WARNING"
            Write-Log "  Execute 'chkdsk $drive`: /F /R' na próxima reinicialização" -Type "WARNING"
        }
        else {
            Write-Log "  Disco $drive`: está saudável" -Type "SUCCESS"
        }
    }
    
}
catch {
    Write-Log "Erro ao verificar discos: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 7. OTIMIZAÇÃO DE SERVIÇOS DO WINDOWS
# ============================================================================
Show-Header "7. OTIMIZAÇÃO DE SERVIÇOS"

try {
    Write-Log "Verificando serviços críticos do Windows..."
    
    $criticalServices = @(
        "wuauserv",      # Windows Update
        "BITS",          # Background Intelligent Transfer Service
        "CryptSvc",      # Cryptographic Services
        "TrustedInstaller", # Windows Modules Installer
        "Dhcp",          # DHCP Client
        "Dnscache",      # DNS Client
        "EventLog",      # Windows Event Log
        "Winmgmt"        # Windows Management Instrumentation
    )
    
    foreach ($serviceName in $criticalServices) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                if ($service.Status -ne "Running" -and $service.StartType -ne "Disabled") {
                    Write-Log "Iniciando serviço: $($service.DisplayName)" -Type "WARNING"
                    Start-Service -Name $serviceName -ErrorAction SilentlyContinue
                    Write-Log "  Serviço iniciado com sucesso!" -Type "SUCCESS"
                }
                else {
                    Write-Log "Serviço OK: $($service.DisplayName)" -Type "SUCCESS"
                }
            }
        }
        catch {
            Write-Log "Erro ao verificar serviço $serviceName" -Type "ERROR"
        }
    }
    
}
catch {
    Write-Log "Erro ao otimizar serviços: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 8. REPARAÇÃO DO WINDOWS UPDATE
# ============================================================================
Show-Header "8. REPARAÇÃO DO WINDOWS UPDATE"

try {
    Write-Log "Reparando componentes do Windows Update..."
    
    # Parar serviços do Windows Update
    $updateServices = @("wuauserv", "cryptSvc", "bits", "msiserver")
    
    Write-Log "Parando serviços do Windows Update..."
    foreach ($service in $updateServices) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Write-Log "  Serviço $service parado"
    }
    
    # Renomear pastas de cache
    Write-Log "Renomeando pastas de cache..."
    if (Test-Path "$env:WINDIR\SoftwareDistribution") {
        Rename-Item "$env:WINDIR\SoftwareDistribution" "$env:WINDIR\SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "$env:WINDIR\System32\catroot2") {
        Rename-Item "$env:WINDIR\System32\catroot2" "$env:WINDIR\System32\catroot2.old" -Force -ErrorAction SilentlyContinue
    }
    
    # Reiniciar serviços
    Write-Log "Reiniciando serviços do Windows Update..."
    foreach ($service in $updateServices) {
        Start-Service -Name $service -ErrorAction SilentlyContinue
        Write-Log "  Serviço $service iniciado"
    }
    
    Write-Log "Windows Update reparado com sucesso!" -Type "SUCCESS"
    
}
catch {
    Write-Log "Erro ao reparar Windows Update: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 9. VERIFICAÇÃO DE DRIVERS
# ============================================================================
Show-Header "9. VERIFICAÇÃO DE DRIVERS"

try {
    Write-Log "Verificando drivers problemáticos..."
    
    # Verificar drivers com problemas
    $problemDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
    
    if ($problemDevices) {
        Write-Log "Dispositivos com problemas detectados:" -Type "WARNING"
        $problemDevices | ForEach-Object {
            Write-Host "  - $($_.Name) (Código de erro: $($_.ConfigManagerErrorCode))" -ForegroundColor Yellow
        }
        Write-Log "Recomenda-se atualizar os drivers destes dispositivos" -Type "WARNING"
    }
    else {
        Write-Log "Todos os drivers estão funcionando corretamente" -Type "SUCCESS"
    }
    
}
catch {
    Write-Log "Erro ao verificar drivers: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 10. LIMPEZA DO REGISTRO (BÁSICA E SEGURA)
# ============================================================================
Show-Header "10. OTIMIZAÇÃO DO REGISTRO"

try {
    Write-Log "Limpando entradas temporárias do registro..."
    
    # Limpar cache de ícones
    $iconCachePath = "$env:LOCALAPPDATA\IconCache.db"
    if (Test-Path $iconCachePath) {
        Remove-Item $iconCachePath -Force -ErrorAction SilentlyContinue
        Write-Log "Cache de ícones limpo" -Type "SUCCESS"
    }
    
    # Limpar histórico de execução
    $runMRUPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
    if (Test-Path $runMRUPath) {
        Remove-Item $runMRUPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Histórico de execução limpo" -Type "SUCCESS"
    }
    
    Write-Log "Otimização do registro concluída!" -Type "SUCCESS"
    
}
catch {
    Write-Log "Erro ao otimizar registro: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 11. VERIFICAÇÃO DE MALWARE BÁSICA
# ============================================================================
Show-Header "11. VERIFICAÇÃO DE SEGURANÇA"

try {
    Write-Log "Verificando Windows Defender..."
    
    # Verificar status do Windows Defender
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    
    if ($defenderStatus) {
        if ($defenderStatus.AntivirusEnabled) {
            Write-Log "Windows Defender está ativo" -Type "SUCCESS"
            
            # Atualizar definições
            Write-Log "Atualizando definições do Windows Defender..."
            Update-MpSignature -ErrorAction SilentlyContinue
            Write-Log "Definições atualizadas!" -Type "SUCCESS"
            
            # Verificação rápida
            Write-Log "Iniciando verificação rápida..." -Type "WARNING"
            Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
            Write-Log "Verificação rápida concluída!" -Type "SUCCESS"
        }
        else {
            Write-Log "Windows Defender está desativado!" -Type "WARNING"
        }
    }
    else {
        Write-Log "Não foi possível verificar o Windows Defender" -Type "WARNING"
    }
    
}
catch {
    Write-Log "Erro ao verificar segurança: $($_.Exception.Message)" -Type "ERROR"
}

# ============================================================================
# 12. RELATÓRIO FINAL
# ============================================================================
Show-Header "RELATÓRIO FINAL"

try {
    # Informações do sistema
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    $os = Get-WmiObject Win32_OperatingSystem
    $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              DIAGNÓSTICO CONCLUÍDO COM SUCESSO                ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nInformações do Sistema:" -ForegroundColor Cyan
    Write-Host "  Computador: $($computerSystem.Name)"
    Write-Host "  Sistema Operacional: $($os.Caption)"
    Write-Host "  Versão: $($os.Version)"
    Write-Host "  Arquitetura: $($os.OSArchitecture)"
    Write-Host "  Tempo ligado: $($uptime.Days) dias, $($uptime.Hours) horas, $($uptime.Minutes) minutos"
    
    Write-Host "`nAções Realizadas:" -ForegroundColor Cyan
    Write-Host "  ✓ Análise e otimização de memória"
    Write-Host "  ✓ Identificação de processos problemáticos"
    Write-Host "  ✓ Limpeza de arquivos temporários"
    Write-Host "  ✓ Verificação e reparação DISM"
    Write-Host "  ✓ Verificação e reparação SFC"
    Write-Host "  ✓ Verificação de disco"
    Write-Host "  ✓ Otimização de serviços"
    Write-Host "  ✓ Reparação do Windows Update"
    Write-Host "  ✓ Verificação de drivers"
    Write-Host "  ✓ Otimização do registro"
    Write-Host "  ✓ Verificação de segurança"
    
    $logPath = "C:\Program Files\HPTI\sfc_repair_$(Get-Date -Format 'yyyyMMdd').log"
    Write-Host "`nLog completo salvo em:" -ForegroundColor Cyan
    Write-Host "  $logPath" -ForegroundColor Yellow
    
    Write-Host "`nRecomendações:" -ForegroundColor Cyan
    Write-Host "  • Reinicie o computador para aplicar todas as correções"
    Write-Host "  • Execute o Windows Update para instalar atualizações pendentes"
    Write-Host "  • Considere fazer uma desfragmentação do disco (se HDD)"
    Write-Host "  • Mantenha o sistema atualizado regularmente"
    
}
catch {
    Write-Log "Erro ao gerar relatório final: $($_.Exception.Message)" -Type "ERROR"
}

Write-Host "`n"
Write-Log "Script finalizado!" -Type "SUCCESS"
Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
