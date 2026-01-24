
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

    # Configura o serviço de hora para iniciar automaticamente
    Set-Service -Name w32time -StartupType Automatic

    # Inicia o serviço caso não esteja rodando
    Start-Service -Name w32time

    # Atualiza a hora
    w32tm /resync /nowait
    Write-Host "Serviço configurado para automático e sincronização iniciada." -ForegroundColor Green

    Write-Host "`n2. Configurando tarefa agendada..." -ForegroundColor Cyan
    $TaskName = "SincronizarHoraLogon"
    
    # Acao: Rodar comando cmd para iniciar servico e sincronizar
    $Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c net start w32time & w32tm /resync"
    
    # Gatilho: Ao fazer logon, com atraso de 45 segundos
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    # Usa string ISO 8601 direta para garantir compatibilidade com XML do Agendador (PT45S = 45 segundos)
    $Trigger.Delay = 'PT45S'
    
    # Principal: Executar como SYSTEM
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Configuracoes adicionais
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    # Registra a tarefa (Sobrescreve se ja existir devido ao -Force)
    # Adicionado -ErrorAction Stop para capturar erro no catch
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Sincroniza o horario do Windows com a internet 45s apos o logon." -Force -ErrorAction Stop | Out-Null
    
    Write-Host "Tarefa '$TaskName' criada com sucesso!" -ForegroundColor Green
    Write-Host "A tarefa rodara 45 segundos apos qualquer logon de usuario." -ForegroundColor Gray

}
catch {
    Write-Error "Ocorreu um erro: $_"
    Read-Host "Pressione Enter para sair..."
}

Write-Host "`nConcluído."
Start-Sleep -Seconds 5
