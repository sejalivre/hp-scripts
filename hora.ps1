# 1. Elevação de Privilégio
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa de permissões de administrador. Reiniciando..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

try {
    Write-Host "1. Configurando e sincronizando horário..." -ForegroundColor Cyan

    # Configura e Reinicia o Serviço -
    Set-Service -Name w32time -StartupType Automatic
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time
    
    # Sincronização
    w32tm /resync /rediscover
    Write-Host "Serviço sincronizado." -ForegroundColor Green

    # 2. Configuração da Tarefa Agendada (Definindo variáveis ausentes)
    $TaskName = "SincronizarHorarioInternet"
    $Action = New-ScheduledTaskAction -Execute "w32tm.exe" -Argument "/resync"
    $Trigger = New-ScheduledTaskTrigger -AtLogOn -Delay (New-TimeSpan -Seconds 45)
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    # Registro da Tarefa
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario do Windows com a internet 45s apos o logon." -Force -ErrorAction Stop | Out-Null
    
    Write-Host "Tarefa '$TaskName' criada com sucesso!" -ForegroundColor Green

}
catch {
    Write-Error "Ocorreu um erro: $_"
}

Write-Host "`nConcluído. Este console fechará em 5 segundos."
Start-Sleep -Seconds 5