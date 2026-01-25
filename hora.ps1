
# Verifica se o script está rodando com privilégios de administrador 
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa de permissões de administrador. Reiniciando como Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
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
