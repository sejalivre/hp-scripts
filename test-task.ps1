# Teste de criação de tarefa agendada
try {
    Write-Host "Criando tarefa de teste..." -ForegroundColor Cyan
    
    $TaskName = "SincronizarHorarioHPTI"
    $scriptPath = "C:\Windows\System32\sync-time-hpti.ps1"
    
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT45S"
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica 45s apos logon." -Force
    
    Write-Host "Tarefa criada com sucesso!" -ForegroundColor Green
    
    # Verificar
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "Tarefa encontrada: $($task.TaskName) - Estado: $($task.State)" -ForegroundColor Green
    }
    else {
        Write-Host "ERRO: Tarefa não encontrada!" -ForegroundColor Red
    }
}
catch {
    Write-Host "ERRO: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
