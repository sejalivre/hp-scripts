try {
    Write-Host "1. Configurando e sincronizando horário..." -ForegroundColor Cyan

    # Garante que o serviço esteja limpo e rodando
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time

    # Configura servidores NTP do Brasil para maior confiabilidade
    w32tm /config /manualpeerlist:"a.st1.ntp.br b.st1.ntp.br pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    
    # Pausa curta para o serviço "respirar" antes de sincronizar
    Start-Sleep -Seconds 2
    w32tm /resync /rediscover
    
    Write-Host "Serviço configurado e tentativa de sincronização enviada." -ForegroundColor Green

    # 2. Configuração da Tarefa  Agendada 
    $TaskName = "SincronizarHorarioHPTI"
    $Action = New-ScheduledTaskAction -Execute "w32tm.exe" -Argument "/resync /rediscover"
    
    # Correção do Erro 'Delay': Usamos uma estrutura compatível com versões anteriores
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    # O delay de 45 segundos é injetado diretamente na propriedade do objeto
    $Trigger.Delay = "PT45S" 

    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica 45s apos logon." -Force -ErrorAction Stop | Out-Null
    
    Write-Host "Tarefa '$TaskName' criada com sucesso!" -ForegroundColor Green

}
catch {
    Write-Error "Ocorreu um erro no script: $_"
}

Write-Host "`nConcluído."
Start-Sleep -Seconds 5