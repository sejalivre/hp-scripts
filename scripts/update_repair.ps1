# Windows Update Repair Script - HPCRAFT v2.0.0
# Executar como Administrador
# Diagnóstico e reparo do Windows Update

$ErrorActionPreference = "Continue"
$logFile = "C:\Program Files\HPTI\Logs\update_repair_$(Get-Date -Format 'yyyyMMdd').log"

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

function Test-WindowsUpdateHealth {
    Write-Log "=== VERIFICANDO SAÚDE DO WINDOWS UPDATE ===" "Cyan"
    $isHealthy = $true
    $issues = @()
    
    # 1. Verificar serviços essenciais
    Write-Log "Verificando serviços essenciais..." "Yellow"
    $requiredServices = @("wuauserv", "bits", "cryptsvc", "msiserver")
    
    foreach ($serviceName in $requiredServices) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            $status = $service.Status
            $startType = $service.StartType
            
            if ($status -ne "Running" -and $startType -ne "Disabled") {
                Write-Log "  [X] Serviço $serviceName está $status (deveria estar Running)" "Red"
                $issues += "Serviço $serviceName não está em execução"
                $isHealthy = $false
            }
            else {
                Write-Log "  [OK] Serviço ${serviceName}: $status" "Green"
            }
        }
        catch {
            Write-Log "  [X] Erro ao verificar serviço $serviceName : $($_.Exception.Message)" "Red"
            $issues += "Erro ao acessar serviço $serviceName"
            $isHealthy = $false
        }
    }
    
    # 2. Verificar chaves de registro críticas
    Write-Log "Verificando registro do Windows Update..." "Yellow"
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    )
    
    foreach ($regPath in $registryPaths) {
        if (!(Test-Path $regPath)) {
            Write-Log "  [X] Chave de registro ausente: $regPath" "Red"
            $issues += "Chave de registro ausente: $regPath"
            $isHealthy = $false
        }
        else {
            Write-Log "  [OK] Chave de registro encontrada: $regPath" "Green"
        }
    }
    
    # 3. Verificar componentes do Windows Update Agent
    Write-Log "Verificando componentes do WUA..." "Yellow"
    $wuaComponents = @(
        "C:\Windows\System32\wuaueng.dll",
        "C:\Windows\System32\wuapi.dll",
        "C:\Windows\System32\wups.dll"
    )
    
    foreach ($component in $wuaComponents) {
        if (!(Test-Path $component)) {
            Write-Log "  [X] Componente ausente: $component" "Red"
            $issues += "Componente WUA ausente: $component"
            $isHealthy = $false
        }
        else {
            Write-Log "  [OK] Componente encontrado: $component" "Green"
        }
    }
    
    # 4. Verificar conectividade com servidores Microsoft
    Write-Log "Verificando conectividade com servidores Microsoft..." "Yellow"
    $testUrls = @(
        "http://update.microsoft.com",
        "http://windowsupdate.microsoft.com"
    )
    
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            Write-Log "  [OK] Conectividade com ${url}: OK" "Green"
        }
        catch {
            Write-Log "  [X] Falha ao conectar com $url" "Red"
            $issues += "Sem conectividade com $url"
            $isHealthy = $false
        }
    }
    
    # 5. Verificar pastas críticas
    Write-Log "Verificando pastas do Windows Update..." "Yellow"
    $criticalFolders = @(
        "C:\Windows\SoftwareDistribution",
        "C:\Windows\System32\catroot2"
    )
    
    foreach ($folder in $criticalFolders) {
        if (!(Test-Path $folder)) {
            Write-Log "  [X] Pasta ausente: $folder" "Red"
            $issues += "Pasta crítica ausente: $folder"
            $isHealthy = $false
        }
        else {
            Write-Log "  [OK] Pasta encontrada: $folder" "Green"
        }
    }
    
    # Resultado final
    Write-Log "" "White"
    if ($isHealthy) {
        Write-Log "=== RESULTADO: SISTEMA SAUDÁVEL ===" "Green"
        Write-Log "Todos os componentes do Windows Update estão funcionando corretamente." "Green"
    }
    else {
        Write-Log "=== RESULTADO: PROBLEMAS DETECTADOS ===" "Red"
        Write-Log "Total de problemas encontrados: $($issues.Count)" "Red"
        foreach ($issue in $issues) {
            Write-Log "  - $issue" "Red"
        }
    }
    Write-Log "" "White"
    
    return $isHealthy
}

function Repair-WindowsUpdate {
    Write-Log "=== INICIANDO RESTAURAÇÃO DO WINDOWS UPDATE ===" "Yellow"
    
    try {
        # 1. Parar serviços
        Write-Log "Parando serviços do Windows Update..." "Yellow"
        $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
        foreach ($s in $services) {
            try {
                Stop-Service $s -Force -ErrorAction SilentlyContinue
                Write-Log "  Serviço $s parado" "Gray"
            }
            catch {
                Write-Log "  Aviso: Não foi possível parar $s" "Yellow"
            }
        }
        
        # 2. Limpar cache e pastas corrompidas
        Write-Log "Limpando cache do Windows Update..." "Yellow"
        $folders = @("C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2")
        foreach ($folder in $folders) {
            if (Test-Path $folder) {
                $backup = "${folder}.old"
                try {
                    if (Test-Path $backup) { 
                        Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    Rename-Item -Path $folder -NewName $backup -Force -ErrorAction Stop
                    Write-Log "  Cache movido: $folder -> $backup" "Gray"
                }
                catch {
                    Write-Log "  Aviso: Não foi possível mover $folder" "Yellow"
                }
            }
        }
        
        # 3. Re-registrar DLLs do Windows Update
        Write-Log "Re-registrando componentes do Windows Update..." "Yellow"
        $dlls = @(
            "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll",
            "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll",
            "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
            "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
            "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll",
            "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
            "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
        )
        
        foreach ($dll in $dlls) {
            try {
                $result = Start-Process "regsvr32.exe" -ArgumentList "/s $dll" -Wait -PassThru -NoNewWindow
                if ($result.ExitCode -eq 0) {
                    Write-Log "  Registrado: $dll" "Gray"
                }
            }
            catch {
                # Silenciosamente ignora DLLs que não existem
            }
        }
        
        # 4. Resetar configurações do Windows Update
        Write-Log "Resetando configurações do Windows Update..." "Yellow"
        try {
            Start-Process "sc.exe" -ArgumentList "config wuauserv start= auto" -Wait -NoNewWindow
            Start-Process "sc.exe" -ArgumentList "config bits start= auto" -Wait -NoNewWindow
            Start-Process "sc.exe" -ArgumentList "config cryptsvc start= auto" -Wait -NoNewWindow
            Write-Log "  Configurações de serviços restauradas" "Gray"
        }
        catch {
            Write-Log "  Aviso: Erro ao configurar serviços" "Yellow"
        }
        
        # 5. Reiniciar serviços
        Write-Log "Reiniciando serviços..." "Yellow"
        foreach ($s in $services) {
            try {
                Start-Service $s -ErrorAction SilentlyContinue
                Write-Log "  Serviço $s iniciado" "Gray"
            }
            catch {
                Write-Log "  Aviso: Não foi possível iniciar $s" "Yellow"
            }
        }
        
        # 6. Executar DISM e SFC
        Write-Log "Executando verificação de integridade do sistema (DISM)..." "Yellow"
        try {
            $dismResult = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -NoNewWindow
            if ($dismResult.ExitCode -eq 0) {
                Write-Log "  DISM concluído com sucesso" "Green"
            }
            else {
                Write-Log "  DISM retornou código: $($dismResult.ExitCode)" "Yellow"
            }
        }
        catch {
            Write-Log "  Aviso: Erro ao executar DISM" "Yellow"
        }
        
        Write-Log "Executando verificação de arquivos do sistema (SFC)..." "Yellow"
        try {
            $sfcResult = Start-Process "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
            if ($sfcResult.ExitCode -eq 0) {
                Write-Log "  SFC concluído com sucesso" "Green"
            }
            else {
                Write-Log "  SFC retornou código: $($sfcResult.ExitCode)" "Yellow"
            }
        }
        catch {
            Write-Log "  Aviso: Erro ao executar SFC" "Yellow"
        }
        
        Write-Log "=== RESTAURAÇÃO CONCLUÍDA ===" "Green"
        Write-Log "Recomenda-se reiniciar o computador para aplicar todas as correções." "Yellow"
        return $true
    }
    catch {
        Write-Log "ERRO durante restauração: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Main {
    Write-Log "=== WINDOWS UPDATE REPAIR - HPCRAFT v2.0.0 ===" "Cyan"
    Write-Log "Iniciado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Write-Log "" "White"
    
    # Verificar privilégios de administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$isAdmin) {
        Write-Log "ERRO: Este script requer privilégios de Administrador!" "Red"
        Write-Log "Execute o PowerShell como Administrador e tente novamente." "Yellow"
        return
    }
    
    Write-Log "" "White"
    
    # ETAPA 1: Verificar saúde do Windows Update
    $isHealthy = Test-WindowsUpdateHealth
    
    # ETAPA 2: Se não estiver saudável, executar reparo
    if (-not $isHealthy) {
        Write-Log "" "White"
        Write-Log "Problemas detectados. Prosseguindo com restauração do Windows Update..." "Red"
        Write-Log "" "White"
        
        $repaired = Repair-WindowsUpdate
        
        if ($repaired) {
            Write-Log "" "White"
            Write-Log "Deseja verificar novamente a saúde do sistema? (S/N): " "Yellow"
            $response = Read-Host
            
            if ($response -eq 'S' -or $response -eq 's') {
                Write-Log "" "White"
                $isHealthy = Test-WindowsUpdateHealth
            }
        }
    }
    else {
        Write-Log "" "White"
        Write-Log "Sistema já está saudável. Use a opção 'Instala Update' para instalar atualizações." "Green"
    }
    
    Write-Log "" "White"
    Write-Log "=== PROCESSO CONCLUÍDO ===" "Cyan"
    Write-Log "Finalizado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Write-Log "Log completo salvo em: $logFile" "Gray"
}

Main
