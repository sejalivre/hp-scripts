try {
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
    w32tm /resync /rediscover /force
    
    Write-Host "Horario sincronizado com sucesso." -ForegroundColor Green

    # --- 2. Configuração da Tarefa Agendada ---
    $TaskName = "SincronizarHorarioHPTI"
    
    # MUDANÇA AQUI: A tarefa agora chama o PowerShell para garantir que o serviço suba
    $ScriptBlock = "Start-Service w32time; w32tm.exe /resync /rediscover /force"
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$ScriptBlock`""
    
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT45S" 

    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica (Garante servico ativo)." -Force -ErrorAction Stop | Out-Null
    
    Write-Host "Tarefa '$TaskName' atualizada com comando de Start-Service!" -ForegroundColor Green
}
catch {
    Write-Error "Erro: $_"
}
