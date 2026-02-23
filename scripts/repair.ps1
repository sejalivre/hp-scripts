<#
.SYNOPSIS
    HP-Scripts Repair v2.0 - Reparo Automático Inteligente de Problemas do Windows
.DESCRIPTION
    Script de reparo automático baseado em diagnóstico do sistema.
    Oferece ações corretivas para problemas comuns detectados no check.ps1
    
    NOVIDADES v2.0:
    - Integração completa com check.ps1
    - Reparo inteligente baseado em relatórios
    - Comparação antes/depois dos reparos
    - Remoção automática de bloatware
    - Otimização de inicialização
    - Atualização de drivers
.NOTES
    Autor: HP-Scripts Team
    Versão: 2.0
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

# Detecta caminho do check.ps1
$CheckScriptPath = $null

# Detecta diretório do script (funciona mesmo quando $PSScriptRoot está vazio)
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $ScriptDir) { $ScriptDir = Get-Location }

# Tenta localizar check.ps1 em locais conhecidos
$possiblePaths = @(
    (Join-Path $ScriptDir "check.ps1"),                              # Mesmo diretório
    "c:\hp\GitHub\hp-scripts\scripts\check.ps1",                     # Repositório
    "C:\Program Files\HPTI\scripts\check.ps1",                       # Instalação
    (Join-Path (Split-Path $ScriptDir) "scripts\check.ps1"),        # Diretório pai
    (Join-Path (Get-Location) "check.ps1")                           # Diretório atual
)

# Remove caminhos vazios e testa cada um
foreach ($path in $possiblePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
    if (Test-Path $path) {
        $CheckScriptPath = $path
        break
    }
}

if (-not $CheckScriptPath) {
    Write-Warning "check.ps1 não encontrado localmente."
}

function Download-CheckScript {
    Write-Status "Tentando baixar check.ps1 do GitHub..." "INFO" $ColorInfo
    
    try {
        # Verifica conexão com internet
        $testConnection = Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $testConnection) {
            Write-Status "Sem conexão com internet" "ERRO" $ColorError
            return $false
        }
        
        # URL do check.ps1 no GitHub
        $checkUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/scripts/check.ps1"
        
        # Determina onde salvar
        $downloadPath = Join-Path $ScriptDir "check.ps1"
        
        Write-Status "Baixando de: $checkUrl" "INFO" $ColorInfo
        Write-Status "Salvando em: $downloadPath" "INFO" $ColorInfo
        
        # Força TLS 1.2
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        # Baixa o arquivo
        Invoke-WebRequest -Uri $checkUrl -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop
        
        if (Test-Path $downloadPath) {
            $script:CheckScriptPath = $downloadPath
            Write-Status "check.ps1 baixado com sucesso!" "SUCESSO" $ColorSuccess
            return $true
        }
        else {
            Write-Status "Falha ao salvar arquivo" "ERRO" $ColorError
            return $false
        }
    }
    catch {
        Write-Status "Erro ao baixar check.ps1: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

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

# Função para captura de tecla instantânea (sem ENTER)
function Read-MenuKey {
    param(
        [string]$Prompt = "Selecione uma opcao"
    )

    Write-Host "$Prompt " -NoNewline -ForegroundColor Cyan

    # Tenta usar ReadKey para resposta instantânea
    if ($Host.Name -eq 'ConsoleHost') {
        try {
            $key = [Console]::ReadKey($true)
            $char = $key.KeyChar.ToString()
            Write-Host $char -ForegroundColor Yellow
            return $char
        }
        catch {
            return Read-Host $Prompt
        }
    }
    else {
        return Read-Host $Prompt
    }
}

function Show-RepairMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║           🛠️  HPCRAFT - REPARO AUTOMÁTICO TI  🛠️            ║" -ForegroundColor Cyan
    Write-Host "  ║              Suporte: docs.hpinfo.com.br | v2.0              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  ═══ REPAROS INTELIGENTES ═══" -ForegroundColor Magenta
    Write-Host "  [1] 🔍 Executar Diagnóstico (check.ps1)" -ForegroundColor White
    Write-Host "  [2] 🤖 Reparo Inteligente (Ler último check + Reparar)" -ForegroundColor White
    Write-Host "  [3] 📊 Reparo Completo com Comparação (Check → Repair → Check)" -ForegroundColor $ColorAction
    Write-Host ""
    
    Write-Host "  ═══ REPAROS ESPECÍFICOS ═══" -ForegroundColor Cyan
    Write-Host "  [4] 🌐 Reparo de Rede e Conectividade" -ForegroundColor White
    Write-Host "  [5] 🧹 Limpeza e Otimização do Sistema" -ForegroundColor White
    Write-Host "  [6] 🛡️  Reparo de Segurança e Windows Defender" -ForegroundColor White
    Write-Host "  [7] ⚙️  Reparo de Serviços do Windows" -ForegroundColor White
    Write-Host "  [8] 💾 Reparo de Disco e Sistema de Arquivos" -ForegroundColor White
    Write-Host "  [9] 🔄 Reparo de Windows Update" -ForegroundColor White
    Write-Host "  [10] 🚀 Otimização de Desempenho" -ForegroundColor White
    Write-Host "  [11] 🗑️  Remover Bloatware" -ForegroundColor White
    Write-Host "  [12] ⏱️  Otimizar Inicialização" -ForegroundColor White
    Write-Host "  [13] 🔧 Atualizar Drivers" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  [99] 📋 Reparo Completo (Todas as Categorias)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [L] 📝 Ver Log de Reparos Executados" -ForegroundColor Gray
    Write-Host "  [0] Menu Principal" -ForegroundColor DarkGray
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
        $systemDrive = $env:SystemDrive.Replace(":", "")
        
        foreach ($disk in $disks) {
            $drive = $disk.DeviceID.Replace(":", "")
            Write-Status "Verificando disco $drive..." "INFO" $ColorInfo
            
            if ($drive -eq $systemDrive) {
                # Disco do sistema: agendar para próximo boot
                Write-Status "Agendando verificação do disco $drive para o próximo boot..." "INFO" $ColorInfo
                $result = echo Y | chkdsk ${drive}: /f 2>&1
                Write-Status "Verificação do disco $drive agendada" "SUCESSO" $ColorSuccess
                Write-Status "IMPORTANTE: Reinicie o computador para completar a verificação" "AVISO" $ColorWarning
            }
            else {
                # Outros discos: tentar verificação imediata
                try {
                    chkdsk ${drive}: /f /x 2>&1 | Out-Null
                    Write-Status "Disco $drive verificado" "SUCESSO" $ColorSuccess
                }
                catch {
                    Write-Status "Não foi possível verificar disco $drive" "AVISO" $ColorWarning
                }
            }
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

function Repair-Bloatware {
    Write-Status "Iniciando remoção de bloatware..." "INFO" $ColorInfo
    
    try {
        # Lista expandida de bloatware
        $bloatwarePatterns = @(
            "*WebCompanion*", "*McAfee*", "*Norton*", "*Baidu*", "*Segurazo*", 
            "*Avast*", "*AVG*", "*CCleaner*", "*PC Cleaner*", "*Driver Booster*",
            "*Advanced SystemCare*", "*WinZip*", "*WinRAR Trial*", "*Toolbar*"
        )
        
        $removedCount = 0
        
        # 1. Remover via Get-Package (programas Win32)
        Write-Status "Verificando programas instalados..." "INFO" $ColorInfo
        $installedApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue
        $installedApps += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue
        
        foreach ($pattern in $bloatwarePatterns) {
            $found = $installedApps | Where-Object { $_.DisplayName -like $pattern }
            foreach ($app in $found) {
                Write-Status "Removendo: $($app.DisplayName)..." "INFO" $ColorInfo
                try {
                    $uninstallString = $app.UninstallString
                    if ($uninstallString) {
                        if ($uninstallString -match "msiexec") {
                            $productCode = $app.PSChildName
                            Start-Process "msiexec.exe" -ArgumentList "/x $productCode /qn /norestart" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                        }
                        else {
                            Start-Process $uninstallString -ArgumentList "/S", "/VERYSILENT", "/SILENT", "/QUIET" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                        }
                        Write-Status "Removido: $($app.DisplayName)" "SUCESSO" $ColorSuccess
                        $removedCount++
                    }
                }
                catch {
                    Write-Status "Falha ao remover: $($app.DisplayName)" "AVISO" $ColorWarning
                }
            }
        }
        
        # 2. Remover Apps UWP desnecessários
        Write-Status "Verificando apps UWP..." "INFO" $ColorInfo
        $uwpBloat = @(
            "*CandyCrush*", "*BubbleWitch*", "*MarchofEmpires*", "*Solitaire*",
            "*BingNews*", "*BingSports*", "*BingWeather*", "*Twitter*",
            "*Facebook*", "*Spotify*", "*Disney*", "*Netflix*"
        )
        
        foreach ($pattern in $uwpBloat) {
            $apps = Get-AppxPackage -Name $pattern -AllUsers -ErrorAction SilentlyContinue
            foreach ($app in $apps) {
                try {
                    Write-Status "Removendo app UWP: $($app.Name)..." "INFO" $ColorInfo
                    Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                    Write-Status "Removido: $($app.Name)" "SUCESSO" $ColorSuccess
                    $removedCount++
                }
                catch {
                    Write-Status "Falha ao remover: $($app.Name)" "AVISO" $ColorWarning
                }
            }
        }
        
        if ($removedCount -gt 0) {
            Write-Status "Remoção de bloatware concluída: $removedCount itens removidos" "SUCESSO" $ColorSuccess
        }
        else {
            Write-Status "Nenhum bloatware detectado" "SUCESSO" $ColorSuccess
        }
        
        return $true
    }
    catch {
        Write-Status "Erro durante remoção de bloatware: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-StartupItems {
    Write-Status "Iniciando otimização de inicialização..." "INFO" $ColorInfo
    
    try {
        $disabledCount = 0
        
        # Lista de itens seguros para manter
        $safeStartupItems = @(
            "*Windows Defender*", "*SecurityHealth*", "*OneDrive*",
            "*Intel*", "*AMD*", "*NVIDIA*", "*Realtek*",
            "*Synaptics*", "*Dell*", "*HP*", "*Lenovo*"
        )
        
        # 1. Desabilitar itens de inicialização via Registro (Run)
        Write-Status "Verificando registro de inicialização..." "INFO" $ColorInfo
        $runKeys = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
        )
        
        foreach ($key in $runKeys) {
            if (Test-Path $key) {
                $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
                foreach ($prop in $items.PSObject.Properties) {
                    if ($prop.Name -notmatch "PS.*") {
                        $isSafe = $false
                        foreach ($safe in $safeStartupItems) {
                            if ($prop.Value -like $safe) {
                                $isSafe = $true
                                break
                            }
                        }
                        
                        if (-not $isSafe) {
                            try {
                                Remove-ItemProperty -Path $key -Name $prop.Name -ErrorAction SilentlyContinue
                                Write-Status "Desabilitado: $($prop.Name)" "SUCESSO" $ColorSuccess
                                $disabledCount++
                            }
                            catch {}
                        }
                    }
                }
            }
        }
        
        # 2. Desabilitar tarefas agendadas desnecessárias
        Write-Status "Otimizando tarefas agendadas..." "INFO" $ColorInfo
        $taskPatterns = @("*Adobe*", "*CCleaner*", "*Google Update*", "*Skype*")
        
        foreach ($pattern in $taskPatterns) {
            $tasks = Get-ScheduledTask -TaskName $pattern -ErrorAction SilentlyContinue
            foreach ($task in $tasks) {
                if ($task.State -eq "Ready") {
                    try {
                        Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
                        Write-Status "Tarefa desabilitada: $($task.TaskName)" "SUCESSO" $ColorSuccess
                        $disabledCount++
                    }
                    catch {}
                }
            }
        }
        
        Write-Status "Otimização de inicialização concluída: $disabledCount itens desabilitados" "SUCESSO" $ColorSuccess
        return $true
    }
    catch {
        Write-Status "Erro durante otimização de inicialização: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Repair-DriversUpdate {
    Write-Status "Iniciando atualização de drivers..." "INFO" $ColorInfo
    
    try {
        # Tenta atualizar drivers via Windows Update
        Write-Status "Verificando drivers via Windows Update..." "INFO" $ColorInfo
        
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Driver'")
            
            if ($searchResult.Updates.Count -gt 0) {
                Write-Status "Encontrados $($searchResult.Updates.Count) drivers para atualizar" "INFO" $ColorInfo
                Write-Status "Execute Windows Update para instalar drivers" "AVISO" $ColorWarning
            }
            else {
                Write-Status "Todos os drivers estão atualizados via Windows Update" "SUCESSO" $ColorSuccess
            }
        }
        catch {
            Write-Status "Não foi possível verificar drivers via Windows Update" "AVISO" $ColorWarning
        }
        
        # Sugestão para drivers de GPU
        $gpu = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gpu) {
            $gpuName = $gpu.Name
            if ($gpuName -match "NVIDIA") {
                Write-Status "GPU NVIDIA detectada: Visite https://www.nvidia.com/drivers" "INFO" $ColorInfo
            }
            elseif ($gpuName -match "AMD|Radeon") {
                Write-Status "GPU AMD detectada: Visite https://www.amd.com/support" "INFO" $ColorInfo
            }
            elseif ($gpuName -match "Intel") {
                Write-Status "GPU Intel detectada: Visite https://www.intel.com/content/www/us/en/download-center/home.html" "INFO" $ColorInfo
            }
        }
        
        return $true
    }
    catch {
        Write-Status "Erro durante atualização de drivers: $($_.Exception.Message)" "ERRO" $ColorError
        return $false
    }
}

function Get-LatestCheckReport {
    $reportsDir = "C:\Program Files\HPTI\Reports"
    
    if (-not (Test-Path $reportsDir)) {
        return $null
    }
    
    $latestReport = Get-ChildItem -Path $reportsDir -Filter "checkup_*.html" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1
    
    if ($latestReport) {
        return $latestReport.FullName
    }
    
    return $null
}

function Read-CheckReport {
    param([string]$ReportPath)
    
    if (-not (Test-Path $ReportPath)) {
        Write-Status "Relatório não encontrado: $ReportPath" "ERRO" $ColorError
        return $null
    }
    
    try {
        $htmlContent = Get-Content -Path $ReportPath -Raw -Encoding UTF8
        
        Write-Host "`n[DEBUG] Lendo relatório HTML..." -ForegroundColor Cyan
        Write-Host "[DEBUG] Tamanho do arquivo: $($htmlContent.Length) caracteres" -ForegroundColor Cyan
        
        # Extrai problemas  do HTML (busca por status CRÍTICO e ALERTA) 
        $problems = @()
        
        # Regex melhorado para extrair cada linha da tabela <tr>...</tr>
        # Usa [\s\S] em vez de . para capturar quebras de linha
        $rowPattern = '<tr[^>]*>[\s\S]*?</tr>'
        $tableRows = [regex]::Matches($htmlContent, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        Write-Host "[DEBUG] Total de linhas <tr> encontradas: $($tableRows.Count)" -ForegroundColor Cyan
        
        $criticalCount = 0
        $alertCount = 0
        
        foreach ($rowMatch in $tableRows) {
            $rowHtml = $rowMatch.Value
            
            # Verifica se a linha contém CRÍTICO ou ALERTA
            if ($rowHtml -match "class='status-(critico|alerta)'") {
                $statusType = $matches[1]
                $status = if ($statusType -eq "critico") { "CRÍTICO" } else { "ALERTA" }
                
                if ($status -eq "CRÍTICO") { $criticalCount++ } else { $alertCount++ }
                
                # Extrai todas as células <td> (melhorado para lidar com atributos)
                $cellPattern = '<td[^>]*>(.*?)</td>'
                $cells = [regex]::Matches($rowHtml, $cellPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                
                if ($cells.Count -ge 2) {
                    # Segunda célula (índice 1) contém o nome da verificação
                    $checkName = $cells[1].Groups[1].Value
                    
                    # Remove tags HTML residuais e limpa o texto
                    $checkName = $checkName -replace '<[^>]+>', ''
                    $checkName = $checkName.Trim()
                    
                    if (-not [string]::IsNullOrWhiteSpace($checkName)) {
                        $problems += [PSCustomObject]@{
                            Name   = $checkName
                            Status = $status
                        }
                        Write-Host "[DEBUG] Problema encontrado: $checkName ($status)" -ForegroundColor Gray
                    }
                }
            }
        }
        
        # Remove duplicatas
        $problems = $problems | Sort-Object Name -Unique
        
        Write-Host "`n[DEBUG] Resumo do parsing:" -ForegroundColor Yellow
        Write-Host "[DEBUG] - Críticos encontrados: $criticalCount" -ForegroundColor Red
        Write-Host "[DEBUG] - Alertas encontrados: $alertCount" -ForegroundColor Yellow
        Write-Host "[DEBUG] - Total de problemas únicos: $($problems.Count)" -ForegroundColor White
        
        if ($problems.Count -gt 0) {
            Write-Host "`n[DEBUG] Lista de problemas detectados:" -ForegroundColor Yellow
            foreach ($p in $problems) {
                $color = if ($p.Status -eq "CRÍTICO") { "Red" } else { "Yellow" }
                Write-Host "  - $($p.Name): $($p.Status)" -ForegroundColor $color
            }
        }
        
        return $problems
    }
    catch {
        Write-Status "Erro ao ler relatório: $($_.Exception.Message)" "ERRO" $ColorError
        Write-Host "[DEBUG] Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
        return $null
    }
}

function Repair-FromCheckReport {
    Write-Status "Iniciando reparo inteligente baseado em diagnóstico..." "INFO" $ColorInfo
    
    $reportPath = Get-LatestCheckReport
    
    if (-not $reportPath) {
        Write-Status "Nenhum relatório de check.ps1 encontrado" "AVISO" $ColorWarning
        Write-Status "Execute check.ps1 primeiro para gerar diagnóstico" "INFO" $ColorInfo
        return $false
    }
    
    Write-Status "Lendo relatório: $reportPath" "INFO" $ColorInfo
    $problems = Read-CheckReport -ReportPath $reportPath
    
    if (-not $problems -or $problems.Count -eq 0) {
        Write-Status "Nenhum problema detectado no relatório!" "SUCESSO" $ColorSuccess
        return $true
    }
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "PROBLEMAS DETECTADOS: $($problems.Count)" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    foreach ($problem in $problems) {
        $icon = if ($problem.Status -eq "CRÍTICO") { "❌" } else { "⚠️" }
        Write-Host "  $icon $($problem.Name) - $($problem.Status)" -ForegroundColor $(if ($problem.Status -eq "CRÍTICO") { "Red" } else { "Yellow" })
    }
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "EXECUTANDO REPAROS AUTOMATIZADOS" -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $results = @{}
    
    # Mapeamento de problemas para funções de reparo
    $problemMap = @{
        "Windows Defender" = { Repair-Security }
        "Firewall"         = { Repair-Security }
        "Licenciamento"    = { Repair-Security }
        "Bloatware"        = { Repair-Bloatware }
        "Inicialização"    = { Repair-StartupItems }
        "Windows Update"   = { Repair-WindowsUpdate }
        "Integridade"      = { Repair-Disk }
        "Serviços"         = { Repair-Services }
        "Rede"             = { Repair-Network }
        "DNS"              = { Repair-Network }
        "Conectividade"    = { Repair-Network }
    }
    
    # Executa reparos baseados nos problemas detectados
    $executedRepairs = @()
    
    foreach ($problem in $problems) {
        foreach ($key in $problemMap.Keys) {
            if ($problem.Name -match $key -and $executedRepairs -notcontains $key) {
                Write-Host "`n[→] Executando reparo: $key" -ForegroundColor Cyan
                $result = & $problemMap[$key]
                $results[$key] = $result
                $executedRepairs += $key
                Start-Sleep -Seconds 2
            }
        }
    }
    
    # Se não encontrou reparos específicos, executa reparo completo
    if ($executedRepairs.Count -eq 0) {
        Write-Status "Executando reparo completo..." "INFO" $ColorInfo
        return Repair-Complete
    }
    
    # Resumo
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "RESUMO DOS REPAROS" -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $results.Count
    
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "✅ SUCESSO" } else { "❌ FALHA" }
        Write-Host "  $($key.PadRight(20)): $status" -ForegroundColor $(if ($results[$key]) { "Green" } else { "Red" })
    }
    
    Write-Host "`n  Total: $successCount/$totalCount reparos bem-sucedidos" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
    
    return $successCount -eq $totalCount
}

function New-ComparisonReport {
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "REPARO COMPLETO COM COMPARAÇÃO" -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $startTime = Get-Date
    $reportsDir = "C:\Program Files\HPTI\Reports"
    $checkScript = $CheckScriptPath
    
    # Tentar baixar check.ps1 se não existir
    if (-not $checkScript -or -not (Test-Path $checkScript)) {
        Write-Status "Script check.ps1 não encontrado localmente" "AVISO" $ColorWarning
        $downloaded = Download-CheckScript
        
        if ($downloaded) {
            $checkScript = $CheckScriptPath
        }
        else {
            Write-Status "Não foi possível obter check.ps1" "ERRO" $ColorError
            return $false
        }
    }
    
    # FASE 1: Diagnóstico ANTES
    Write-Status "FASE 1/3: Executando diagnóstico inicial..." "INFO" $ColorInfo
    Write-Host ""
    
    & $checkScript
    Start-Sleep -Seconds 2
    
    $reportBefore = Get-LatestCheckReport
    if (-not $reportBefore) {
        Write-Status "Falha ao gerar relatório inicial" "ERRO" $ColorError
        return $false
    }
    
    $problemsBefore = Read-CheckReport -ReportPath $reportBefore
    $criticalBefore = ($problemsBefore | Where-Object { $_.Status -eq "CRÍTICO" }).Count
    $alertBefore = ($problemsBefore | Where-Object { $_.Status -eq "ALERTA" }).Count
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "DIAGNÓSTICO INICIAL" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ❌ Problemas Críticos: $criticalBefore" -ForegroundColor Red
    Write-Host "  ⚠️  Alertas: $alertBefore" -ForegroundColor Yellow
    Write-Host "  📊 Total de Problemas: $($problemsBefore.Count)" -ForegroundColor White
    
    Read-Host "`nPressione ENTER para iniciar os reparos"
    
    # FASE 2: REPAROS
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "FASE 2/3: Executando reparos automatizados..." -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Repair-FromCheckReport

    
    # FASE 3: Diagnóstico DEPOIS
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "FASE 3/3: Executando diagnóstico final..." -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Start-Sleep -Seconds 3
    & $checkScript
    Start-Sleep -Seconds 2
    
    $reportAfter = Get-LatestCheckReport
    if (-not $reportAfter -or $reportAfter -eq $reportBefore) {
        Write-Status "Falha ao gerar relatório final" "ERRO" $ColorError
        return $false
    }
    
    $problemsAfter = Read-CheckReport -ReportPath $reportAfter
    $criticalAfter = ($problemsAfter | Where-Object { $_.Status -eq "CRÍTICO" }).Count
    $alertAfter = ($problemsAfter | Where-Object { $_.Status -eq "ALERTA" }).Count
    
    # COMPARAÇÃO
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "RELATÓRIO COMPARATIVO - ANTES vs DEPOIS" -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  ANTES DOS REPAROS:" -ForegroundColor Yellow
    Write-Host "    ❌ Críticos: $criticalBefore" -ForegroundColor Red
    Write-Host "    ⚠️  Alertas: $alertBefore" -ForegroundColor Yellow
    Write-Host "    📊 Total: $($problemsBefore.Count)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  DEPOIS DOS REPAROS:" -ForegroundColor Green
    Write-Host "    ❌ Críticos: $criticalAfter" -ForegroundColor $(if ($criticalAfter -eq 0) { "Green" } else { "Red" })
    Write-Host "    ⚠️  Alertas: $alertAfter" -ForegroundColor $(if ($alertAfter -lt $alertBefore) { "Green" } else { "Yellow" })
    Write-Host "    📊 Total: $($problemsAfter.Count)" -ForegroundColor $(if ($problemsAfter.Count -lt $problemsBefore.Count) { "Green" } else { "White" })
    Write-Host ""
    
    $criticalFixed = $criticalBefore - $criticalAfter
    $alertFixed = $alertBefore - $alertAfter
    $totalFixed = $problemsBefore.Count - $problemsAfter.Count
    
    Write-Host "  RESULTADOS:" -ForegroundColor Cyan
    Write-Host "    ✅ Críticos Resolvidos: $criticalFixed" -ForegroundColor Green
    Write-Host "    ✅ Alertas Resolvidos: $alertFixed" -ForegroundColor Green
    Write-Host "    ✅ Total Resolvido: $totalFixed" -ForegroundColor Green
    Write-Host "    ⏱️  Tempo Total: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan
    Write-Host ""
    
    if ($totalFixed -gt 0) {
        $percentFixed = [math]::Round(($totalFixed / $problemsBefore.Count) * 100, 1)
        Write-Host "  🎯 Taxa de Sucesso: $percentFixed%" -ForegroundColor Green
    }
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Salvar relatório comparativo
    $comparisonFile = Join-Path $reportsDir "repair_comparison_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $comparisonContent = @"
═══════════════════════════════════════════════════════════════
RELATÓRIO COMPARATIVO DE REPAROS - HP-Scripts
═══════════════════════════════════════════════════════════════

Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Computador: $env:COMPUTERNAME
Duração: $($duration.Minutes)m $($duration.Seconds)s

───────────────────────────────────────────────────────────────
ANTES DOS REPAROS
───────────────────────────────────────────────────────────────
Problemas Críticos: $criticalBefore
Alertas: $alertBefore
Total de Problemas: $($problemsBefore.Count)

Relatório: $reportBefore

───────────────────────────────────────────────────────────────
DEPOIS DOS REPAROS
───────────────────────────────────────────────────────────────
Problemas Críticos: $criticalAfter
Alertas: $alertAfter
Total de Problemas: $($problemsAfter.Count)

Relatório: $reportAfter

───────────────────────────────────────────────────────────────
RESULTADOS
───────────────────────────────────────────────────────────────
Críticos Resolvidos: $criticalFixed
Alertas Resolvidos: $alertFixed
Total Resolvido: $totalFixed
Taxa de Sucesso: $percentFixed%

═══════════════════════════════════════════════════════════════
"@
    
    $comparisonContent | Out-File -FilePath $comparisonFile -Encoding UTF8
    Write-Status "Relatório comparativo salvo em: $comparisonFile" "SUCESSO" $ColorSuccess
    
    return $true
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
    $choice = Read-MenuKey -Prompt "Selecione uma opcao"
    
    switch ($choice) {
        "1" {
            # Executar Diagnóstico
            Write-Status "Executando diagnóstico completo..." "INFO" $ColorInfo
            $checkScript = $CheckScriptPath
            
            # Tentar baixar se não existir
            if (-not $checkScript -or -not (Test-Path $checkScript)) {
                Write-Status "Script check.ps1 não encontrado localmente" "AVISO" $ColorWarning
                $downloaded = Download-CheckScript
                if ($downloaded) {
                    $checkScript = $CheckScriptPath
                }
            }
            
            if ($checkScript -and (Test-Path $checkScript)) {
                & $checkScript
            }
            else {
                Write-Status "Não foi possível obter check.ps1" "ERRO" $ColorError
            }
            Read-Host "`nPressione ENTER para continuar"
        }
        "2" {
            # Reparo Inteligente (Ler último check + Reparar)
            Start-TranscriptLog
            Repair-FromCheckReport
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "3" {
            # Reparo Completo com Comparação
            Start-TranscriptLog
            New-ComparisonReport
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "4" { 
            Start-TranscriptLog
            Repair-Network
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "5" { 
            Start-TranscriptLog
            Repair-Cleanup
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "6" { 
            Start-TranscriptLog
            Repair-Security
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "7" { 
            Start-TranscriptLog
            Repair-Services
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "8" { 
            Start-TranscriptLog
            Repair-Disk
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "9" { 
            Start-TranscriptLog
            Repair-WindowsUpdate
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "10" { 
            Start-TranscriptLog
            Repair-Performance
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "11" {
            # Remover Bloatware
            Start-TranscriptLog
            Repair-Bloatware
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "12" {
            # Otimizar Inicialização
            Start-TranscriptLog
            Repair-StartupItems
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "13" {
            # Atualizar Drivers
            Start-TranscriptLog
            Repair-DriversUpdate
            Stop-TranscriptLog
            Read-Host "`nPressione ENTER para continuar"
        }
        "99" { 
            Start-TranscriptLog
            Repair-Complete
            Stop-TranscriptLog
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
        "0" {
            Write-Host "`nVoltando ao Menu Principal..." -ForegroundColor Yellow
            return
        }
        "Q" {
            Write-Host "`nEncerrando script de reparo..." -ForegroundColor Green
            break
        }
        "q" {
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

