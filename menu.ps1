<#
.SYNOPSIS
    Launcher Principal HP-Scripts - Hub de Automação Profissional.
.DESCRIPTION
    Versão 2.0 - Target: Windows 10/11.
.NOTES
    Requer PowerShell 5.1+ (Windows 10/11)
#>

param([switch]$PortableMode)

# ============================================================
# REQUISITOS DE SISTEMA
# ============================================================

# Verificação de Versão do PowerShell
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERRO] Este script requer PowerShell 5.1 ou superior (Windows 10/11)." -ForegroundColor Red
    exit 1
}

# Configuração de TLS 1.2 (Essencial para HTTPS em Windows 10 1507/1511)
try {
    # Método primário (PowerShell 5.0+)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
catch {
    try {
        # Fallback para versões antigas
        [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    }
    catch {
        Write-Warning "Não foi possível forçar TLS 1.2. Conexões HTTPS podem falhar."
    }
}

# ============================================================
# LIBERAR POLITICA DE EXECUCAO AUTOMATICAMENTE
# ============================================================
try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned" -or $currentPolicy -eq "Undefined") {
        Write-Host "[INFO] Liberando politica de execucao do PowerShell..." -ForegroundColor Cyan
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($newPolicy -eq "Unrestricted" -or $newPolicy -eq "RemoteSigned" -or $newPolicy -eq "Bypass") {
            Write-Host "[OK] Politica liberada: $newPolicy" -ForegroundColor Green
        }
    }
}
catch {
    # Silenciosamente ignora erros - o usuario pode usar a opcao 16 manualmente
}

# Detecção robusta do diretório do script e modo de execução
$ScriptRoot = $PSScriptRoot
$IsLocalExecution = $false

if ([string]::IsNullOrEmpty($ScriptRoot)) {
    # Fallback 1: Tentar obter do caminho do script atual
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    # Fallback 2: Usar diretório atual
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = Get-Location | Select-Object -ExpandProperty Path
    }
}

# Verificar se estamos executando de um repositório local (com scripts/)
if ($PortableMode -and (Test-Path (Join-Path $ScriptRoot "scripts"))) {
    $IsLocalExecution = $true
    Write-Host "[INFO] Modo: Execução Local (repositório detectado)" -ForegroundColor DarkGray
}
else {
    $IsLocalExecution = $false
    Write-Host "[INFO] Modo: Execução Remota (baixando scripts sob demanda)" -ForegroundColor DarkGray
}

# Configuração de Origem 
$baseUrl = "get.hpinfo.com.br"


# 1. Definição das Ferramentas
$ferramentas = @(
    @{ ID = "CHECK"      ; Desc = "Verificações Rápidas e Integridade" ; Path = "scripts/check" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "REPAIR"     ; Desc = "Reparo Automático do Sistema"       ; Path = "scripts/repair" ; Color = "Magenta" ; IsLocalScript = $true }
    @{ ID = "SFC"        ; Desc = "Diagnóstico e Reparação Completa"   ; Path = "scripts/sfc"   ; Color = "Red" ; IsLocalScript = $true }
    @{ ID = "INSTALLPS1" ; Desc = "Instalar/Atualizar PowerShell"   ; Path = "installps1.cmd" ; Color = "Cyan" ; IsCmd = $true }
    @{ ID = "WINFORGE"   ; Desc = "Instalação e Otimização do Sistema" ; Path = "scripts/winforge" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "LIMP"       ; Desc = "Limpeza de Arquivos Temporários"     ; Path = "scripts/limp"  ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "UPDATE"     ; Desc = "Atualizações do Sistema"             ; Path = "scripts/update_menu"; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "HORA"       ; Desc = "Sincronizando Horário"               ; Path = "scripts/hora"  ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "REDE"       ; Desc = "Reparo de Rede e Conectividade"      ; Path = "scripts/net"   ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "PRINT"      ; Desc = "Módulo de Impressão"                 ; Path = "scripts/print" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "BACKUP"     ; Desc = "Rotina de Backup de Usuário"         ; Path = "scripts/backup"; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "ATIV"       ; Desc = "Ativação (get.activated.win)"        ; Path = "https://get.activated.win" ; External = $true }
    @{ ID = "WALL"       ; Desc = "Configurar Wallpaper Padrão"         ; Path = "scripts/wallpaper" ; Color = "Yellow" ; IsLocalScript = $true }
    @{ ID = "NEXTDNS"    ; Desc = "Gerenciamento NextDNS"               ; Path = "tools/nextdns/nextdns" ; Color = "Yellow" ; IsLocal = $true }
    @{ ID = "TOOLS"      ; Desc = "Menu de Ferramentas Portáteis"       ; Path = "menu_tools" ; Color = "Green" ; IsLocal = $true }
    @{ ID = "POLICY"     ; Desc = "Liberar Política de Execução"        ; Path = "SetExecutionPolicy" ; Color = "Magenta" ; IsFunction = $true }
)

function Set-ExecutionPolicy-Unrestricted {
    $command = "Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force"

    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser

        if ($currentPolicy -eq "Unrestricted" -or $currentPolicy -eq "RemoteSigned" -or $currentPolicy -eq "Bypass") {
            Write-Host "[OK] Política de execução já está liberada: $currentPolicy" -ForegroundColor Green
            return
        }

        Write-Host "[INFO] Política atual: $currentPolicy" -ForegroundColor Yellow
        Write-Host "[INFO] Tentando alterar para Unrestricted..." -ForegroundColor Cyan

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction Stop

        $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
        Write-Host "[OK] Política alterada com sucesso para: $newPolicy" -ForegroundColor Green
        Write-Host "[INFO] Comando executado: $command" -ForegroundColor Gray
    }
    catch {
        Write-Host "[AVISO] Não foi possível alterar automaticamente." -ForegroundColor Yellow
        Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host "`n[INFO] Copiando comando para área de transferência..." -ForegroundColor Cyan

        try {
            Set-Clipboard -Value $command
            Write-Host "[OK] Comando copiado: $command" -ForegroundColor Green
            Write-Host "[INFO] Cole no PowerShell com CTRL+V e execute como Administrador" -ForegroundColor Yellow
        }
        catch {
            Write-Host "[INFO] Comando para copiar manualmente:" -ForegroundColor Cyan
            Write-Host $command -ForegroundColor White
        }
    }
}

# Função para obter informações de hardware
function Get-HardwareInfo {
    try {
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        if (-not $cpu) { $cpu = "N/A" }

        $ram = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $ramTotal = if ($ram) { [math]::Round($ram.TotalPhysicalMemory / 1GB, 2) } else { 0 }

        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        $diskFree = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 2) } else { 0 }
        $diskTotal = if ($disk) { [math]::Round($disk.Size / 1GB, 2) } else { 0 }

        return @{
            CPU = $cpu
            RAM = $ramTotal
            DiskFree = $diskFree
            DiskTotal = $diskTotal
        }
    }
    catch {
        return $null
    }
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

function Show-MainMenu {
    do {
        Clear-Host
        Write-Host ""
        Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║           🚀  HPCRAFT - HUB DE AUTOMAÇÃO TI  🚀              ║" -ForegroundColor Cyan
        Write-Host "  ║              Suporte: docs.hpinfo.com.br | v1.5              ║" -ForegroundColor DarkCyan
        Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        # Exibir informações de hardware
        $hw = Get-HardwareInfo
        if ($hw) {
            Write-Host "  CPU: $($hw.CPU)" -ForegroundColor Gray
            Write-Host "  RAM: $($hw.RAM)GB | Disco C: $($hw.DiskFree)GB/$($hw.DiskTotal)GB" -ForegroundColor Gray
            Write-Host ""
        }
        
        # 2. Renderização Dinâmica do Menu  
        for ($i = 0; $i -lt $ferramentas.Count; $i++) {
            $n = $i + 1
            $item = $ferramentas[$i]
            Write-Host ("  {0,2}. [{1,-11}] {2}" -f $n, $item.ID, $item.Desc) -ForegroundColor White
        }

        Write-Host ""
        Write-Host "  [Q] Sair" -ForegroundColor DarkGray
        Write-Host ""
        
        $escolha = Read-MenuKey -Prompt "Selecione uma opcao"

        if ($escolha -eq "Q" -or $escolha -eq "q") { 
            Write-Host "`nEncerrando..." -ForegroundColor Green
            break 
        }

        # 3. Lógica de Execução
        $idx = 0 
        if ([int]::TryParse($escolha, [ref]$idx) -and $idx -le $ferramentas.Count -and $idx -gt 0) {
            $selecionada = $ferramentas[$idx - 1]
            $cor = if ($selecionada.Color) { $selecionada.Color } else { "White" }
            
            Write-Host "`n[🚀] Iniciando $($selecionada.ID)..." -ForegroundColor $cor
            
            # Verificar se é um arquivo .cmd (batch)
            if ($selecionada.IsCmd) {
                # Para arquivos .cmd, baixar e executar via cmd.exe
                $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                $TempCmd = "$env:TEMP\HPTI_Exec_$($selecionada.ID).cmd"
                
                try {
                    Write-Host "[INFO] Baixando instalador..." -ForegroundColor Gray
                    Invoke-WebRequest -Uri $finalUrl -OutFile $TempCmd -UseBasicParsing
                    
                    if (Test-Path $TempCmd) {
                        Write-Host "[INFO] Executando instalador..." -ForegroundColor Gray
                        # Executar o .cmd e aguardar conclusão
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$TempCmd`"" -Wait -NoNewWindow
                        
                        # Remove após execução
                        Remove-Item $TempCmd -Force -ErrorAction SilentlyContinue
                    }
                    else {
                        throw "Arquivo não foi baixado corretamente."
                    }
                }
                catch {
                    Write-Host "`n[❌] ERRO: Falha ao executar instalador." -ForegroundColor Red
                    Write-Host "URL: $finalUrl" -ForegroundColor Gray
                    Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            elseif ($selecionada.IsLocalScript) {
                # Para scripts PowerShell locais (dentro de ./scripts/)
                if ($IsLocalExecution) {
                    # Modo local: executar arquivo do disco 
                    $scriptPath = Join-Path $ScriptRoot "$($selecionada.Path).ps1"
                    if (Test-Path $scriptPath) {
                        & $scriptPath
                    }
                    else {
                        Write-Host "`n[❌] ERRO: Script local não encontrado: $scriptPath" -ForegroundColor Red
                    }
                }
                else {
                    # Modo remoto: baixar e executar
                    $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                    $TempScript = Join-Path $env:TEMP "HPTI_$($selecionada.ID).ps1"
                    try {
                        Write-Host "[INFO] Baixando script remoto..." -ForegroundColor Gray
                        Invoke-WebRequest -Uri $finalUrl -OutFile $TempScript -UseBasicParsing
                        if (Test-Path $TempScript) {
                            & $TempScript
                            Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-Host "`n[❌] ERRO: Falha ao baixar script remoto." -ForegroundColor Red
                        Write-Host "URL: $finalUrl" -ForegroundColor Gray
                        Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                    }
                }
            }
            elseif ($selecionada.IsLocal) {
                # Para scripts locais (como  menu_tools.ps1)
                if ($IsLocalExecution) {
                    # Modo local: executar arquivo do disco
                    $scriptPath = Join-Path $ScriptRoot "$($selecionada.Path).ps1"
                    if (Test-Path $scriptPath) {
                        & $scriptPath
                    }
                    else {
                        Write-Host "`n[❌] ERRO: Script local não encontrado: $($selecionada.Path)" -ForegroundColor Red
                    }
                }
                else {
                    # Modo remoto: baixar e executar
                    $finalUrl = "https://$baseUrl/$($selecionada.Path)"
                    $TempScript = Join-Path $env:TEMP "HPTI_$($selecionada.ID).ps1"
                    try {
                        Write-Host "[INFO] Baixando script remoto..." -ForegroundColor Gray
                        Invoke-WebRequest -Uri $finalUrl -OutFile $TempScript -UseBasicParsing
                        if (Test-Path $TempScript) {
                            & $TempScript
                            Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-Host "`n[❌] ERRO: Falha ao baixar script remoto." -ForegroundColor Red
                        Write-Host "URL: $finalUrl" -ForegroundColor Gray
                        Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                    }
                }
            }
            elseif ($selecionada.IsFunction) {
                # Para funções internas (não requerem download)
                switch ($selecionada.Path) {
                    "SetExecutionPolicy" { Set-ExecutionPolicy-Unrestricted }
                    default { Write-Warning "Função desconhecida: $($selecionada.Path)" }
                }
            }
            else {
                # Montagem da URL para scripts PowerShell
                $finalUrl = if ($selecionada.External) { 
                    $selecionada.Path 
                }
                else { 
                    "https://$baseUrl/$($selecionada.Path)" 
                }
                
                try {
                    # Baixar e executar o script
                    $scriptContent = Invoke-RestMethod -Uri $finalUrl -UseBasicParsing
                    
                    # Executar o conteúdo diretamente
                    Invoke-Expression $scriptContent
                }
                catch {
                    Write-Host "`n[❌] ERRO: Falha na execução remota." -ForegroundColor Red
                    Write-Host "URL: $finalUrl" -ForegroundColor Gray
                    Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
        else {
            Write-Warning "Opção inválida!"
            Start-Sleep -Seconds 1
        }
        
        Write-Host "`nPressione qualquer tecla para voltar..." -ForegroundColor Gray
        
        # Compatibilidade: ReadKey() não funciona em ISE ou sessões remotas
        if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI) {
            try {
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            catch {
                Read-Host "Pressione ENTER para continuar"
            }
        }
        else {
            Read-Host "Pressione ENTER para continuar"
        }

    } while ($true)
}

Show-MainMenu