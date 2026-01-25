<#
.SYNOPSIS
    Script de Remoção Total HPTI - NextDNS -> Google DNS
.DESCRIPTION
    1. Remove tarefa agendada.
    2. Desinstala o serviço NextDNS.
    3. Apaga arquivos de script.
    4. Define DNS para Google (8.8.8.8).
#>

# --- VERIFICAÇÃO DE ADM ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    Exit
}

Write-Host "--- INICIANDO REMOÇÃO HPTI ---" -ForegroundColor Cyan

# --- 1. REMOVER AGENDAMENTO ---
Write-Host "1. Removendo automação de reparo..." -ForegroundColor Yellow
$TaskName = "HPTI_NextDNS_Reparo"
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host " -> Tarefa agendada removida." -ForegroundColor Green
} else {
    Write-Host " -> Nenhuma tarefa agendada encontrada." -ForegroundColor Gray
}

# --- 2. TENTAR DESINSTALAÇÃO OFICIAL ---
Write-Host "`n2. Desinstalando NextDNS..." -ForegroundColor Yellow

# Tenta encontrar o executável na pasta padrão
$Uninstaller = "$env:ProgramFiles\NextDNS\NextDNSSetup.exe"

if (Test-Path $Uninstaller) {
    Write-Host " -> Desinstalador encontrado. Executando..." -ForegroundColor Gray
    Start-Process -FilePath $Uninstaller -ArgumentList "/S", "/REMOVE" -Wait
    Write-Host " -> Desinstalação concluída." -ForegroundColor Green
} else {
    # SE NÃO ACHAR O DESINSTALADOR, FAZ REMOÇÃO FORÇADA DO SERVIÇO
    Write-Warning " -> Desinstalador oficial não encontrado. Forçando remoção manual do serviço..."
    
    $Service = Get-Service | Where-Object { $_.DisplayName -like "*NextDNS*" } | Select-Object -First 1
    if ($Service) {
        Stop-Service -InputObject $Service -Force -ErrorAction SilentlyContinue
        
        # Remove o serviço via sc.exe (PowerShell não tem comando nativo simples pra deletar serviço)
        sc.exe delete $Service.Name | Out-Null
        Write-Host " -> Serviço removido forçadamente." -ForegroundColor Green
    }
}

# --- 3. LIMPEZA DE ARQUIVOS ---
Write-Host "`n3. Limpando pastas HPTI..." -ForegroundColor Yellow
$HptiDir = "$env:ProgramFiles\HPTI"
if (Test-Path $HptiDir) {
    Remove-Item -Path $HptiDir -Recurse -Force
    Write-Host " -> Pasta HPTI removida." -ForegroundColor Green
}
# Limpa pasta residual do NextDNS se estiver vazia ou sobrar lixo
$NextDir = "$env:ProgramFiles\NextDNS"
if (Test-Path $NextDir) {
    Remove-Item -Path $NextDir -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 4. VOLTAR DNS PARA GOOGLE ---
Write-Host "`n4. Configurando DNS do Google (8.8.8.8)..." -ForegroundColor Yellow
$GoogleDNS = @("8.8.8.8", "8.8.4.4")

try {
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($nic in $Adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ServerAddresses $GoogleDNS -ErrorAction SilentlyContinue
        Write-Host " -> Interface '$($nic.Name)' definida para Google DNS." -ForegroundColor Gray
    }
} catch {
    Write-Error "Erro ao definir DNS."
}

# --- 5. LIMPEZA FINAL ---
Write-Host "`n5. Limpando Cache..." -ForegroundColor Yellow
Invoke-Expression -Command "ipconfig /flushdns"

Write-Host "`n[SUCESSO] Sistema limpo e restaurado." -ForegroundColor Cyan
Start-Sleep -Seconds 5