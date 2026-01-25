# ==============================================================================
# SCRIPT: hora.ps1
# DESCRIÇÃO: Configura sincronização de horário e cria tarefa agendada de reparo.
# ==============================================================================

# 1. Verifica se o script está rodando com privilégios de administrador 
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este script precisa ser executado como Administrador."
    Write-Warning "Por favor, abra o PowerShell como Administrador e tente novamente."
    exit
}

try {
    Write-Host "1. Configurando e sincronizando horário inicial..." -ForegroundColor Cyan

    # Garante que o serviço esteja limpo e rodando no momento da instalação [Sua Sugestão]
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time 2>$null
    w32tm /unregister 2>$null
    w32tm /register
    net start w32time

    # Remove limites de correção de fase (Permite ajustar mesmo se o atraso for de dias/meses)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
    Set-ItemProperty -Path $regPath -Name "MaxPosPhaseCorrection" -Value 4294967295
    Set-ItemProperty -Path $regPath -Name "MaxNegPhaseCorrection" -Value 4294967295

    # Configura servidores NTP
    w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    
    # Força sincronização imediata
    Start-Sleep -Seconds 2
    w32tm /resync /rediscover
    
    Write-Host "Horário inicial sincronizado com sucesso." -ForegroundColor Green

    # 2. Preparando o script auxiliar de auto-reparo
    Write-Host "`n2. Criando script auxiliar e tarefa agendada..." -ForegroundColor Cyan
    
    $intelPath = "C:\intel"
    if (-not (Test-Path $intelPath)) {
        New-Item -Path $intelPath -ItemType Directory -Force | Out-Null
    }
    
    # CONTEÚDO DO SCRIPT AUXILIAR (sync-time-hpti.ps1)
    $scriptContent = @'
    $logPath = "C:\intel\time_sync_log.txt"
    Start-Transcript -Path $logPath -Append

    function Log-Message {
        param([string]$Message)
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "[$TimeStamp] $Message"
    }

    Log-Message "Iniciando script de sincronização via Tarefa Agendada..."

    try {
        # Limpeza e reinício do serviço [Sua Sugestão]
        Log-Message "Executando limpeza e re-registro do w32time..."
        Set-Service -Name w32time -StartupType Automatic
        net stop w32time 2>$null
        w32tm /unregister 2>$null
        Start-Sleep -Seconds 1
        w32tm /register
        net start w32time

        # Re-aplica limites de correção no Registro
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
        Set-ItemProperty -Path $regPath -Name "MaxPosPhaseCorrection" -Value 4294967295
        Set-ItemProperty -Path $regPath -Name "MaxNegPhaseCorrection" -Value 4294967295

        # Re-configura servidores NTP
        w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update
        w32tm /config /update

        $maxRetries = 10
        $synced = $false

        for ($i=1; $i -le $maxRetries; $i++) {
            Log-Message "Tentativa $i de $maxRetries..."
            
            # Verifica se há internet antes de tentar
            if (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet) {
                $result = w32tm /resync /rediscover 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "Sucesso: $result"
                    $synced = $true
                    break
                } else {
                    Log-Message "Falha w32tm: $result"
                }
            } else {
                Log-Message "Aguardando conexão de rede..."
            }
            Start-Sleep -Seconds 15
        }

        if ($synced) {
            Log-Message "Sincronização concluída com êxito."
        } else {
            Log-Message "ERRO: Não foi possível sincronizar após $maxRetries tentativas."
        }
    } catch {
        Log-Message "Erro crítico no script: $_"
    }
    Stop-Transcript
'@
    
    $scriptPath = "$intelPath\sync-time-hpti.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force -ErrorAction Stop
    
    # 3. Configuração da Tarefa Agendada
    $TaskName = "SincronizarHorarioHPTI"
    
    # Remove tarefa anterior se existir
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    # Ação: Chama o PowerShell usando o caminho completo do sistema
    $Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    
    # Gatilhos duplos: Ao iniciar o sistema E ao fazer logon
    $Trigger1 = New-ScheduledTaskTrigger -AtStartup
    $Trigger1.Delay = "PT1M" # Espera 1 minuto após o boot para a rede estabilizar
    
    $Trigger2 = New-ScheduledTaskTrigger -AtLogOn
    $Trigger2.Delay = "PT30S" # Espera 30 segundos após logon

    # Executa como SYSTEM (privilégio máximo)
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Configurações de resiliência
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger1, $Trigger2 -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI com auto-reparo do servico w32time." -Force | Out-Null
    
    Write-Host "Tarefa '$TaskName' configurada e pronta para o próximo boot/logon!" -ForegroundColor Green
}
catch {
    Write-Error "Erro ao executar o script principal: $_"
}

Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "`nPressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")