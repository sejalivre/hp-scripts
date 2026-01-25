# Verifica se o script está rodando com privilégios de administrador 
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este script precisa ser executado como Administrador."
    Write-Warning "Por favor, abra o PowerShell como Administrador e tente novamente."
    exit
}

try {
    Write-Host "1. Configurando e sincronizando horário inicial..." -ForegroundColor Cyan

    # Garante que o serviço esteja limpo e rodando no momento da instalação
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time 2>$null
    w32tm /unregister 2>$null
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

    Write-Host "`n2. Configurando tarefa agendada com script de auto-reparo..." -ForegroundColor Cyan
    
    $TaskName = "SincronizarHorarioHPTI"
    $intelPath = "C:\intel"
    if (-not (Test-Path $intelPath)) {
        New-Item -Path $intelPath -ItemType Directory -Force | Out-Null
    }
    
    # CONTEÚDO DO SCRIPT AUXILIAR (Modificado com sua sugestão de limpeza)
    $scriptContent = @'
    $logPath = "C:\intel\time_sync_log.txt"
    Start-Transcript -Path $logPath -Append

    function Log-Message {
        param([string]$Message)
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "[$TimeStamp] $Message"
    }

    Log-Message "Iniciando script de sincronização (Modo Auto-Reparo)..."

    try {
        # Aplica a limpeza do serviço antes de tentar iniciar [Sua sugestão]
        Log-Message "Executando limpeza e re-registro do w32time..."
        Set-Service -Name w32time -StartupType Automatic
        net stop w32time 2>$null
        w32tm /unregister 2>$null
        Start-Sleep -Seconds 1
        w32tm /register
        net start w32time

        # Re-aplica a configuração de servidores
        w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update

        $maxRetries = 5
        $retryCount = 0
        $synced = $false

        while (-not $synced -and $retryCount -lt $maxRetries) {
            $retryCount++
            Log-Message "Tentativa $retryCount de $maxRetries..."
            
            if (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet) {
                $result = w32tm /resync /rediscover 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "Sucesso: $result"
                    $synced = $true
                } else {
                    Log-Message "Falha no comando w32tm: $result"
                }
            } else {
                Log-Message "Sem conectividade de rede no momento."
            }

            if (-not $synced) { Start-Sleep -Seconds 10 }
        }

        if ($synced) {
            Log-Message "Sincronização concluída."
            Stop-Transcript
            exit 0
        } else {
            Log-Message "Falha após todas as tentativas."
            Stop-Transcript
            exit 1
        }
    } catch {
        Log-Message "Erro crítico: $_"
        Stop-Transcript
        exit 1
    }
'@
    
    $scriptPath = "$intelPath\sync-time-hpti.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force -ErrorAction Stop
    
    # Configuração da Tarefa Agendada
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT45S" 

    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica com reparo de servico." -Force | Out-Null
    
    Write-Host "Tarefa '$TaskName' e script auxiliar atualizados!" -ForegroundColor Green
}
catch {
    Write-Error "Erro: $_"
}

Write-Host "`nConcluído. O log será gerado em C:\intel\time_sync_log.txt após o próximo logon."
Start-Sleep -Seconds 5