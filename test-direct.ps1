# Teste direto no PowerShell admin
$TaskName = "SincronizarHorarioHPTI"
$scriptPath = "C:\Windows\System32\sync-time-hpti.ps1"

Write-Host "Removendo tarefa antiga se existir..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Criando nova tarefa..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Trigger.Delay = "PT45S"
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

$result = Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario via HPTI Informatica 45s apos logon." -Force

Write-Host "`nResultado:" -ForegroundColor Green
$result | Format-List TaskName, State

Write-Host "`nVerificando tarefa criada:" -ForegroundColor Cyan
Get-ScheduledTask -TaskName $TaskName | Format-List TaskName, State
