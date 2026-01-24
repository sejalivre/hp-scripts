
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
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time
    w32tm /resync /nowait
    w32tm /resync /rediscover
    Write-Host "Serviço configurado para automático e sincronização iniciada." -ForegroundColor Green
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
