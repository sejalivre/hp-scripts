# Verifica privilégios de administrador
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Execute como Administrador."
    exit
}

try {
    Write-Host "1. Configurando e sincronizando horário inicial..." -ForegroundColor Cyan

    # Sua sugestão de limpeza e reinício
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time 2>$null
    w32tm /unregister 2>$null
    w32tm /register
    net start w32time

    # Remove limites de correção (Aumenta a tolerância para grandes diferenças)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
    Set-ItemProperty -Path $regPath -Name "MaxPosPhaseCorrection" -Value 4294967295
    Set-ItemProperty -Path $regPath -Name "MaxNegPhaseCorrection" -Value 4294967295
    w32tm /config /update

    # Força uma atualização bruta de hora para diminuir a diferença "muito grande"
    $time = Invoke-RestMethod -Uri "http://worldtimeapi.org/api/ip"
    Set-Date -Date (Get-Date $time.datetime) -ErrorAction SilentlyContinue

    w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    w32tm /resync /rediscover
    
    Write-Host "Horário inicial configurado." -ForegroundColor Green

    Write-Host "`n2. Criando tarefa agendada de auto-reparo..." -ForegroundColor Cyan
    
    $intelPath = "C:\intel"
    if (-not (Test-Path $intelPath)) { New-Item -Path $intelPath -ItemType Directory -Force | Out-Null }
    
    $scriptContent = @'
    $logPath = "C:\intel\time_sync_log.txt"
    Start-Transcript -Path $logPath -Append

    function Log-Message {
        param([string]$Message)
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "[$TimeStamp] $Message"
    }

    try {
        Log-Message "Executando limpeza e re-registro do w32time..."
        Set-Service -Name w32time -StartupType Automatic
        net stop w32time 2>$null
        w32tm /unregister 2>$null
        w32tm /register
        net start w32time

        # Garante que as chaves de registro permitam correções grandes
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
        Set-ItemProperty -Path $regPath -Name "MaxPosPhaseCorrection" -Value 4294967295
        Set-ItemProperty -Path $regPath -Name "MaxNegPhaseCorrection" -Value 4294967295
        
        w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update

        $maxRetries = 5
        $retryCount = 0
        $synced = $false

        while (-not $synced -and $retryCount -lt $maxRetries) {
            $retryCount++
            Log-Message "Tentativa $retryCount de $maxRetries..."
            
            if (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet) {
                # Tenta ajustar a hora via Web se a diferença for gigante
                try {
                    $webTime = Invoke-RestMethod -Uri "http://worldtimeapi.org/api/ip" -TimeoutSec 5
                    Set-Date -Date (Get-Date $webTime.datetime)
                } catch {}

                $result = w32tm /resync /rediscover 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "Sucesso: $result"
                    $synced = $true
                } else {
                    Log-Message "Falha w32tm: $result"
                }
            }
            if (-not $synced) { Start-Sleep -Seconds 10 }
        }

        Stop-Transcript
        exit ($synced ? 0 : 1)
    } catch {
        Log-Message "Erro: $_"
        Stop-Transcript
        exit 1
    }
'@
    
    $scriptPath = "$intelPath\sync-time-hpti.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force
    
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT45S" 
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName "SincronizarHorarioHPTI" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null
    Write-Host "Tarefa e Script Auxiliar atualizados com correção de 'Diferença Grande'!" -ForegroundColor Green
}
catch { Write-Error "Erro: $_" }
Start-Sleep -Seconds 5