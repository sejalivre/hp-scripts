
# Verifica se o script está rodando com privilégios de administrador 
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este script precisa ser executado como Administrador."
    Write-Warning "Por favor, abra o PowerShell como Administrador e tente novamente."
    exit
}

try {
    Write-Host "1. Configurando e sincronizando horário..." -ForegroundColor Cyan

    # Garante que o serviço esteja limpo e rodando
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time

    # Remove limites de correção de fase   
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
    Set-ItemProperty -Path $regPath -Name "MaxPosPhaseCorrection" -Value 4294967295
    Set-ItemProperty -Path $regPath -Name "MaxNegPhaseCorrection" -Value 4294967295

    # Configura servidores NTP do Brasil
    w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    
    Start-Sleep -Seconds 2
    w32tm /resync /rediscover
    
    Write-Host "Horário sincronizado com sucesso." -ForegroundColor Green

    Write-Host "`n2. Configurando tarefa agendada..." -ForegroundColor Cyan
    
    $TaskName = "SincronizarHorarioHPTI"
    
    # Cria a pasta c:\intel se não existir
    $intelPath = "C:\intel"
    if (-not (Test-Path $intelPath)) {
        New-Item -Path $intelPath -ItemType Directory -Force | Out-Null
        Write-Host "Pasta $intelPath criada." -ForegroundColor Cyan
    }
    
    # Cria o script auxiliar em c:\intel
    $scriptContent = @'
    # Script auxiliar para sincronização de horário via tarefa agendada
    $logPath = "C:\intel\time_sync_log.txt"
    Start-Transcript -Path $logPath -Append

    function Log-Message {
        param([string]$Message)
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "[$TimeStamp] $Message"
    }

    Log-Message "Iniciando script de sincronização de horário..."

    try {
        $service = Get-Service -Name w32time -ErrorAction SilentlyContinue
        if ($service.Status -ne 'Running') {
            Log-Message "Serviço w32time não está rodando. Iniciando..."
            Start-Service -Name w32time -ErrorAction Stop
            Start-Sleep -Seconds 2
        } else {
            Log-Message "Serviço w32time já está rodando."
        }

        # Tenta sincronizar com retentativas
        $maxRetries = 5
        $retryCount = 0
        $synced = $false

        while (-not $synced -and $retryCount -lt $maxRetries) {
            $retryCount++
            Log-Message "Tentativa $retryCount de $maxRetries..."
            
            # Verifica conectividade básica antes de tentar
            if (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet) {
                Log-Message "Conectividade de rede detectada."
                
                try {
                    $result = w32tm /resync /rediscover 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Log-Message "Sucesso: $result"
                        $synced = $true
                    } else {
                        Log-Message "Falha no comando w32tm: $result"
                        throw "Erro ao executar w32tm"
                    }
                } catch {
                    Log-Message "Erro ao tentar sincronizar: $_"
                }
            } else {
                Log-Message "Sem conectividade de rede ainda."
            }

            if (-not $synced) {
                Log-Message "Aguardando 10 segundos antes da próxima tentativa..."
                Start-Sleep -Seconds 10
            }
        }

        if ($synced) {
            Log-Message "Sincronização concluída com sucesso."
            Stop-Transcript
            exit 0
        } else {
            Log-Message "Falha após todas as tentativas."
            Stop-Transcript
            exit 1
        }

    } catch {
        Log-Message "Erro crítico no script: $_"
        Stop-Transcript
        exit 1
    }
'@
    
    $scriptPath = "$intelPath\sync-time-hpti.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force -ErrorAction Stop
    
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT45S" 

    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica 45s apos logon." -Force -ErrorAction Stop | Out-Null
    
    Write-Host "Tarefa '$TaskName' criada com sucesso!" -ForegroundColor Green
    Write-Host "Script auxiliar criado em: $scriptPath" -ForegroundColor Cyan
    Write-Host "A tarefa rodará 45 segundos após qualquer logon de usuário." -ForegroundColor Gray

}
catch {
    Write-Error "Ocorreu um erro: $_"
    Read-Host "Pressione Enter para sair..."
}

Write-Host "`nConcluído."
Start-Sleep -Seconds 5
