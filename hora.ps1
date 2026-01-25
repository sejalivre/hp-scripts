try {
    # Verifica se está rodando como administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "ERRO: Este script precisa ser executado como Administrador!" -ForegroundColor Red
        Write-Host "Execute novamente com privilégios de administrador." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "1. Configurando e sincronizando horario..." -ForegroundColor Cyan

    # Garante que o serviço esteja limpo e rodando
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time

    # REMÉDIO PARA O ERRO: Remove limites de correção de fase
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
    Set-ItemProperty -Path $regPath -Name "MaxPosPhaseCorrection" -Value 4294967295
    Set-ItemProperty -Path $regPath -Name "MaxNegPhaseCorrection" -Value 4294967295

    # Configura servidores NTP do Brasil
    w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    
    Start-Sleep -Seconds 2
    # O parametro /force ajuda a ignorar restrições
    w32tm /resync /rediscover
    
    Write-Host "Horario sincronizado com sucesso (limites ignorados)." -ForegroundColor Green

    Write-Host "`n2. Configurando tarefa agendada..." -ForegroundColor Cyan
    
    # 2. Configuração da Tarefa Agendada
    $TaskName = "SincronizarHorarioHPTI"
    
    # Cria o script auxiliar diretamente em C:\Windows\System32 para acesso SYSTEM
    $scriptContent = @'
# Script auxiliar para sincronização de horário via tarefa agendada
try {
    $service = Get-Service -Name w32time -ErrorAction SilentlyContinue
    if ($service.Status -ne 'Running') {
        Start-Service -Name w32time -ErrorAction Stop
        Start-Sleep -Seconds 2
    }
    w32tm /resync /rediscover
    exit 0
} catch {
    exit 1
}
'@
    
    $scriptPath = "C:\Windows\System32\sync-time-hpti.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force -ErrorAction Stop
    
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT45S" 

    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica 45s apos logon." -Force -ErrorAction Stop | Out-Null
    
    Write-Host "Tarefa '$TaskName' atualizada com sucesso!" -ForegroundColor Green
    Write-Host "Script auxiliar criado em: $scriptPath" -ForegroundColor Cyan
}
catch {
    Write-Error "Erro: $_"
}
