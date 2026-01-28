# Windows Update Manager Script - HPCRAFT v2.0.0
# Executar como Administrador
# Verifica saúde do Windows Update → Se OK: instala atualizações | Se NOK: restaura o sistema

$ErrorActionPreference = "Continue"
$logFile = "C:\Program Files\HPTI\Logs\update_$(Get-Date -Format 'yyyyMMdd').log"

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
    Write-Log "=== VERIFICANDO SAUDE DO WINDOWS UPDATE ===" "Cyan"
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
                Write-Log "  [X] Servico $serviceName esta $status (deveria estar Running)" "Red"
                $issues += "Servico $serviceName não está em execução"
                $isHealthy = $false
            }
            else {
                Write-Log "  [OK] Servico $serviceName: $status" "Green"
            }
        }
        catch {
            Write-Log "  [X] Erro ao verificar servico $serviceName : $($_.Exception.Message)" "Red"
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
            Write-Log "  [OK] Conectividade com $url : OK" "Green"
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
        Write-Log "=== RESULTADO: SISTEMA SAUDAVEL ===" "Green"
        Write-Log "Todos os componentes do Windows Update estao funcionando corretamente." "Green"
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
    Write-Log "=== INICIANDO RESTAURACAO DO WINDOWS UPDATE ===" "Yellow"
    
    try {
        # 1. Parar serviços
        Write-Log "Parando servicos do Windows Update..." "Yellow"
        $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
        foreach ($s in $services) {
            try {
                Stop-Service $s -Force -ErrorAction SilentlyContinue
                Write-Log "  Servico $s parado" "Gray"
            }
            catch {
                Write-Log "  Aviso: Nao foi possivel parar $s" "Yellow"
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
                    Write-Log "  Aviso: Nao foi possivel mover $folder" "Yellow"
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
        Write-Log "Resetando configuracoes do Windows Update..." "Yellow"
        try {
            Start-Process "sc.exe" -ArgumentList "config wuauserv start= auto" -Wait -NoNewWindow
            Start-Process "sc.exe" -ArgumentList "config bits start= auto" -Wait -NoNewWindow
            Start-Process "sc.exe" -ArgumentList "config cryptsvc start= auto" -Wait -NoNewWindow
            Write-Log "  Configuracoes de servicos restauradas" "Gray"
        }
        catch {
            Write-Log "  Aviso: Erro ao configurar servicos" "Yellow"
        }
        
        # 5. Reiniciar serviços
        Write-Log "Reiniciando servicos..." "Yellow"
        foreach ($s in $services) {
            try {
                Start-Service $s -ErrorAction SilentlyContinue
                Write-Log "  Servico $s iniciado" "Gray"
            }
            catch {
                Write-Log "  Aviso: Nao foi possivel iniciar $s" "Yellow"
            }
        }
        
        # 6. Executar DISM e SFC
        Write-Log "Executando verificacao de integridade do sistema (DISM)..." "Yellow"
        try {
            $dismResult = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -NoNewWindow
            if ($dismResult.ExitCode -eq 0) {
                Write-Log "  DISM concluido com sucesso" "Green"
            }
            else {
                Write-Log "  DISM retornou codigo: $($dismResult.ExitCode)" "Yellow"
            }
        }
        catch {
            Write-Log "  Aviso: Erro ao executar DISM" "Yellow"
        }
        
        Write-Log "Executando verificacao de arquivos do sistema (SFC)..." "Yellow"
        try {
            $sfcResult = Start-Process "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
            if ($sfcResult.ExitCode -eq 0) {
                Write-Log "  SFC concluido com sucesso" "Green"
            }
            else {
                Write-Log "  SFC retornou codigo: $($sfcResult.ExitCode)" "Yellow"
            }
        }
        catch {
            Write-Log "  Aviso: Erro ao executar SFC" "Yellow"
        }
        
        Write-Log "=== RESTAURACAO CONCLUIDA ===" "Green"
        Write-Log "Recomenda-se reiniciar o computador para aplicar todas as correcoes." "Yellow"
        return $true
    }
    catch {
        Write-Log "ERRO durante restauracao: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-PSWindowsUpdateModule {
    Write-Log "Verificando modulo PSWindowsUpdate..." "Yellow"
    
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        Write-Log "Modulo PSWindowsUpdate ja esta instalado" "Green"
        return $true
    }
    
    try {
        # Habilitar TLS 1.2
        try {
            $protocols = [Net.ServicePointManager]::SecurityProtocol
            if ($protocols -notmatch 'Tls12') {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Write-Log "TLS 1.2 habilitado" "Gray"
            }
        }
        catch {
            Write-Log "AVISO: Nao foi possivel habilitar TLS 1.2" "Yellow"
        }
        
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
        
        Write-Log "Modulo PSWindowsUpdate instalado com sucesso" "Green"
        return $true
    }
    catch {
        Write-Log "ERRO ao instalar modulo: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-WindowsUpdates {
    Write-Log "=== INSTALANDO ATUALIZACOES DO WINDOWS ===" "Cyan"
    
    if (!(Install-PSWindowsUpdateModule)) {
        Write-Log "Nao foi possivel instalar o modulo PSWindowsUpdate" "Red"
        Write-Log "Tentando metodo alternativo via Windows Update Agent..." "Yellow"
        
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            
            Write-Log "Buscando atualizacoes disponiveis..." "Yellow"
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            if ($searchResult.Updates.Count -eq 0) {
                Write-Log "Nenhuma atualizacao disponivel" "Green"
                return $true
            }
            
            Write-Log "Encontradas $($searchResult.Updates.Count) atualizacoes" "Yellow"
            
            $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $searchResult.Updates) {
                Write-Log "  - $($update.Title)" "Gray"
                $updatesToInstall.Add($update) | Out-Null
            }
            
            Write-Log "Baixando e instalando atualizacoes..." "Yellow"
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $updatesToInstall
            $installResult = $installer.Install()
            
            if ($installResult.ResultCode -eq 2) {
                Write-Log "Atualizacoes instaladas com sucesso!" "Green"
                Write-Log "Reinicie o computador quando possivel." "Yellow"
                return $true
            }
            else {
                Write-Log "Resultado da instalacao: $($installResult.ResultCode)" "Yellow"
                return $false
            }
        }
        catch {
            Write-Log "ERRO ao instalar atualizacoes via WUA: $($_.Exception.Message)" "Red"
            return $false
        }
    }
    
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Write-Log "Buscando atualizacoes..." "Yellow"
        
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
        
        if ($updates.Count -eq 0) {
            Write-Log "Nenhuma atualizacao disponivel" "Green"
            return $true
        }
        
        Write-Log "Encontradas $($updates.Count) atualizacoes" "Yellow"
        foreach ($update in $updates) {
            Write-Log "  - $($update.Title)" "Gray"
        }
        
        Write-Log "Instalando atualizacoes..." "Yellow"
        Get-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -IgnoreReboot -Verbose -ErrorAction Stop
        
        Write-Log "Atualizacoes instaladas com sucesso!" "Green"
        Write-Log "Reinicie o computador quando possivel." "Yellow"
        return $true
    }
    catch {
        Write-Log "ERRO ao executar atualizacoes: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Main {
    Write-Log "=== WINDOWS UPDATE MANAGER - HPCRAFT v2.0.0 ===" "Cyan"
    Write-Log "Iniciado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Write-Log "" "White"
    
    # Verificar privilégios de administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$isAdmin) {
        Write-Log "ERRO: Este script requer privilegios de Administrador!" "Red"
        Write-Log "Execute o PowerShell como Administrador e tente novamente." "Yellow"
        return
    }
    
    # Verificar espaço em disco
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($drive) {
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        Write-Log "Espaco livre em C: $freeGB GB" "Gray"
        
        if ($freeGB -lt 10) {
            Write-Log "AVISO: Espaco em disco baixo! Recomenda-se pelo menos 10GB livres." "Yellow"
            Write-Host "Espaco livre: $freeGB GB. Continuar? (S/N): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host
            if ($response -ne 'S' -and $response -ne 's') {
                Write-Log "Operacao cancelada pelo usuario" "Yellow"
                return
            }
        }
    }
    
    Write-Log "" "White"
    
    # ETAPA 1: Verificar saúde do Windows Update
    $isHealthy = Test-WindowsUpdateHealth
    
    # ETAPA 2: Decisão baseada na saúde
    if ($isHealthy) {
        # Sistema saudável → Instalar atualizações
        Write-Log "Sistema saudavel detectado. Prosseguindo com instalacao de atualizacoes..." "Green"
        Write-Log "" "White"
        Install-WindowsUpdates
    }
    else {
        # Sistema com problemas → Restaurar Windows Update
        Write-Log "Problemas detectados. Prosseguindo com restauracao do Windows Update..." "Red"
        Write-Log "" "White"
        
        $repaired = Repair-WindowsUpdate
        
        if ($repaired) {
            Write-Log "" "White"
            Write-Log "Deseja tentar instalar atualizacoes apos a restauracao? (S/N): " "Yellow"
            $response = Read-Host
            
            if ($response -eq 'S' -or $response -eq 's') {
                Write-Log "" "White"
                Install-WindowsUpdates
            }
        }
    }
    
    Write-Log "" "White"
    Write-Log "=== PROCESSO CONCLUIDO ===" "Cyan"
    Write-Log "Finalizado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Write-Log "Log completo salvo em: $logFile" "Gray"
}

Main
