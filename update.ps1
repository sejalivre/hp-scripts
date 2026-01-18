# Windows Update Manager Script
# Executar como Administrador

# Configurações
$ErrorActionPreference = "Stop"
$logFile = "C:\Windows\Logs\WindowsUpdateScript.log"

# Função para logging
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage -Force
}

# Função para limpar cache do Windows Update
function Clear-WindowsUpdateCache {
    Write-Log "Iniciando limpeza do cache do Windows Update..."
    
    try {
        # Para serviços do Windows Update
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue
        Stop-Service cryptsvc -Force -ErrorAction SilentlyContinue
        Write-Log "Serviços parados"
        
        # Renomeia pastas do cache
        $foldersToRename = @(
            "C:\Windows\SoftwareDistribution",
            "C:\Windows\System32\catroot2"
        )
        
        foreach ($folder in $foldersToRename) {
            if (Test-Path $folder) {
                $backupFolder = "$folder.old"
                if (Test-Path $backupFolder) {
                    Remove-Item $backupFolder -Recurse -Force -ErrorAction SilentlyContinue
                }
                Rename-Item $folder $backupFolder -Force -ErrorAction SilentlyContinue
                Write-Log "Pasta $folder renomeada para $backupFolder"
            }
        }
        
        # Limpa cache do PowerShell Gallery (se existir)
        if (Get-Command Clear-PSRepositoryCache -ErrorAction SilentlyContinue) {
            Clear-PSRepositoryCache
            Write-Log "Cache do PowerShell Gallery limpo"
        }
        
        # Inicia serviços novamente
        Start-Service cryptsvc -ErrorAction SilentlyContinue
        Start-Service bits -ErrorAction SilentlyContinue
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Write-Log "Serviços reiniciados"
        
        # Executa comandos de reparo do Windows Update
        Write-Log "Executando comandos de reparo do DISM e SFC..."
        
        # Reparação DISM
        Write-Log "Executando DISM /Online /Cleanup-Image /RestoreHealth..."
        dism /online /cleanup-image /restorehealth
        
        # Verificação de arquivos do sistema
        Write-Log "Executando sfc /scannow..."
        sfc /scannow
        
        # Redefine componentes do Windows Update
        Write-Log "Redefinindo componentes do Windows Update..."
        & "C:\Windows\System32\rundll32.exe" "C:\Windows\System32\wuapi.dll", WuauSelfUpdate
        
        Write-Log "Limpeza de cache concluída com sucesso"
        return $true
    }
    catch {
        Write-Log "ERRO na limpeza de cache: $_"
        return $false
    }
}

# Função para verificar e instalar o módulo PSWindowsUpdate
function Install-PSWindowsUpdateModule {
    Write-Log "Verificando módulo PSWindowsUpdate..."
    
    try {
        # Verifica se o módulo está instalado
        $module = Get-Module -ListAvailable -Name PSWindowsUpdate
        if (-not $module) {
            Write-Log "Instalando módulo PSWindowsUpdate..."
            
            # Tenta instalar de diferentes repositórios
            $repositories = @("PSGallery", "PSGalleryInternal")
            
            foreach ($repo in $repositories) {
                try {
                    # Registra o repositório PSGallery se necessário
                    if (-not (Get-PSRepository -Name $repo -ErrorAction SilentlyContinue)) {
                        Register-PSRepository -Default -ErrorAction SilentlyContinue
                    }
                    
                    Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber -Repository $repo
                    Write-Log "Módulo instalado do repositório $repo"
                    Import-Module PSWindowsUpdate -Force
                    return $true
                }
                catch {
                    Write-Log "Falha ao instalar do repositório $repo: $_"
                }
            }
            
            # Fallback: instalação manual
            Write-Log "Tentando instalação manual..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Install-Module PSWindowsUpdate -Force -Confirm:$false -AllowClobber
            Import-Module PSWindowsUpdate -Force
            
            Write-Log "Módulo PSWindowsUpdate instalado com sucesso"
            return $true
        }
        else {
            Import-Module PSWindowsUpdate -Force
            Write-Log "Módulo PSWindowsUpdate já está instalado"
            return $true
        }
    }
    catch {
        Write-Log "ERRO ao instalar módulo: $_"
        return $false
    }
}

# Função para instalar atualizações
function Install-WindowsUpdates {
    Write-Log "Procurando atualizações disponíveis..."
    
    try {
        # Verifica atualizações
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
        $updateCount = $updates.Count
        
        if ($updateCount -gt 0) {
            Write-Log "Encontradas $updateCount atualização(ões) disponível(is)"
            
            # Exibe lista de atualizações
            foreach ($update in $updates) {
                Write-Log "  - $($update.Title) (KB$($update.KB))"
            }
            
            Write-Log "Instalando atualizações..."
            
            # Instala atualizações com diferentes estratégias
            $result = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -IgnoreUserInput -ErrorAction Stop
            
            Write-Log "Instalação de atualizações concluída"
            Write-Log "Resultado: $($result | Out-String)"
            
            return $true
        }
        else {
            Write-Log "Nenhuma atualização disponível"
            return $true
        }
    }
    catch {
        Write-Log "ERRO ao instalar atualizações: $_"
        
        # Tenta método alternativo
        try {
            Write-Log "Tentando método alternativo de instalação..."
            Install-WindowsUpdate -AcceptAll -AutoReboot -NotCategory "Drivers" -ErrorAction Stop
            return $true
        }
        catch {
            Write-Log "ERRO no método alternativo: $_"
            return $false
        }
    }
}

# Função para resolver problemas comuns
function Repair-WindowsUpdateIssues {
    Write-Log "Executando diagnósticos e reparos..."
    
    try {
        # 1. Verifica e repara serviços
        $services = @("wuauserv", "bits", "cryptsvc")
        foreach ($service in $services) {
            $svc = Get-Service $service -ErrorAction SilentlyContinue
            if ($svc) {
                if ($svc.Status -ne "Running") {
                    Start-Service $service
                    Write-Log "Serviço $service iniciado"
                }
                Set-Service $service -StartupType Automatic
            }
        }
        
        # 2. Verifica espaço em disco
        $disk = Get-PSDrive C
        if ($disk.Free / 1GB -lt 10) {
            Write-Log "AVISO: Espaço livre em disco menor que 10GB"
            
            # Limpa arquivos temporários
            CleanMgr /sagerun:1 | Out-Null
            Write-Log "Limpeza de disco executada"
        }
        
        # 3. Verifica integridade do sistema
        Write-Log "Verificando integridade do sistema..."
        $dismResult = dism /online /cleanup-image /scanhealth
        Write-Log "Resultado DISM: $dismResult"
        
        # 4. Verifica se há atualizações pendentes de reinicialização
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
            Write-Log "Reinicialização pendente detectada"
            $global:RebootRequired = $true
        }
        
        # 5. Reseta políticas do Windows Update
        Write-Log "Redefinindo políticas do Windows Update..."
        $commands = @(
            "net stop wuauserv",
            "net stop bits",
            "net stop cryptsvc",
            "reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v AccountDomainSid /f",
            "reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v PingID /f",
            "reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v SusClientId /f",
            "net start cryptsvc",
            "net start bits",
            "net start wuauserv"
        )
        
        foreach ($cmd in $commands) {
            cmd /c $cmd 2>&1 | Out-Null
        }
        
        Write-Log "Diagnósticos concluídos"
        return $true
    }
    catch {
        Write-Log "ERRO nos diagnósticos: $_"
        return $false
    }
}

# Função principal
function Main {
    Write-Log "=== INÍCIO DO SCRIPT DE ATUALIZAÇÃO DO WINDOWS ==="
    Write-Log "Usuário: $env:USERNAME"
    Write-Log "Computador: $env:COMPUTERNAME"
    
    # Verifica se está executando como administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Log "ERRO: Execute este script como Administrador"
        Write-Log "Clique com botão direito no script e selecione 'Executar como Administrador'"
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    # Variável global para controle de reinicialização
    $global:RebootRequired = $false
    
    # Passo 1: Limpar cache do Windows Update
    $cacheCleared = Clear-WindowsUpdateCache
    
    # Passo 2: Reparar problemas comuns
    $repairDone = Repair-WindowsUpdateIssues
    
    # Passo 3: Instalar módulo PSWindowsUpdate
    $moduleInstalled = Install-PSWindowsUpdateModule
    
    # Passo 4: Instalar atualizações
    if ($moduleInstalled) {
        $updatesInstalled = Install-WindowsUpdates
    }
    else {
        Write-Log "Não foi possível instalar o módulo PSWindowsUpdate"
        $updatesInstalled = $false
    }
    
    # Resumo
    Write-Log "=== RESUMO DA EXECUÇÃO ==="
    Write-Log "Limpeza de cache: $(if($cacheCleared){'Sucesso'}else{'Falha'})"
    Write-Log "Reparos executados: $(if($repairDone){'Sucesso'}else{'Falha'})"
    Write-Log "Módulo instalado: $(if($moduleInstalled){'Sucesso'}else{'Falha'})"
    Write-Log "Atualizações instaladas: $(if($updatesInstalled){'Sucesso'}else{'Falha'})"
    
    if ($global:RebootRequired) {
        Write-Log "AVISO: Reinicialização necessária para concluir as atualizações"
        
        $choice = Read-Host "Reiniciar agora? (S/N)"
        if ($choice -eq 'S' -or $choice -eq 's') {
            Write-Log "Reiniciando sistema..."
            Restart-Computer -Force
        }
    }
    
    Write-Log "=== FIM DO SCRIPT ==="
    Write-Log "Log salvo em: $logFile"
    
    Read-Host "Pressione Enter para sair"
}

# Executa o script
Main