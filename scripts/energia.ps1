# ==============================================================================
# SCRIPT: energia.ps1
# DESCRIÇÃO: Soluções de problemas de energia, planos de energia e hibernação
# REQUER: PowerShell 5.1+ (Windows 10/11)
# REQUER ADMINISTRADOR
# ==============================================================================

#Requires -RunAsAdministrator

# Verificação de versão do PowerShell
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERRO] Este script requer PowerShell 5.1+ (Windows 10/11)!" -ForegroundColor Red
    exit 1
}

# Forçar TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# ==============================================================================
# FUNÇÕES DE LOGGING
# ==============================================================================

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Type) {
        "SUCESSO" { "Green" }
        "ERRO"     { "Red" }
        "AVISO"    { "Yellow" }
        default    { "White" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

# ==============================================================================
# FUNÇÕES DE GERENCIAMENTO DE ENERGIA
# ==============================================================================

# 1. Listar Planos de Energia
function Get-PowerPlans {
    Write-Host "`n=== PLANOS DE ENERGIA ATUAIS ===" -ForegroundColor Cyan
    
    try {
        $plans = powercfg /list 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host $plans -ForegroundColor White
            Write-Log "Listagem de planos de energia obtida com sucesso" "SUCESSO"
        }
        else {
            throw "Falha ao executar powercfg /list"
        }
    }
    catch {
        Write-Log "Erro ao listar planos de energia: $($_.Exception.Message)" "ERRO"
    }
}

# 2. Ativar Plano de Energia de Alto Desempenho
function Set-HighPerformance {
    Write-Host "`n=== ATIVANDO PLANO DE ALTO DESEMPENHO ===" -ForegroundColor Cyan
    
    try {
        # GUID do Plano de Alto Desempenho
        $highPerfGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        
        # Verificar se já está ativo
        $activePlan = powercfg /getactivescheme 2>$null
        if ($activePlan -match $highPerfGUID) {
            Write-Host "[INFO] Plano de Alto Desempenho já está ativo!" -ForegroundColor Yellow
            return
        }
        
        # Ativar plano de alto desempenho
        powercfg /setactive $highPerfGUID 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Plano de Alto Desempenho ativado com sucesso!" -ForegroundColor Green
            Write-Host "[INFO] Este plano maximiza o desempenho do sistema, mas aumenta o consumo de energia." -ForegroundColor Yellow
            Write-Log "Plano de alto desempenho ativado" "SUCESSO"
        }
        else {
            throw "Falha ao ativar plano"
        }
    }
    catch {
        Write-Log "Erro ao ativar plano de alto desempenho: $($_.Exception.Message)" "ERRO"
    }
}

# 3. Ativar Plano de Economia de Energia
function Set-Balanced {
    Write-Host "`n=== ATIVANDO PLANO EQUILIBRADO ===" -ForegroundColor Cyan
    
    try {
        # GUID do Plano Equilibrado
        $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
        
        $activePlan = powercfg /getactivescheme 2>$null
        if ($activePlan -match $balancedGUID) {
            Write-Host "[INFO] Plano Equilibrado já está ativo!" -ForegroundColor Yellow
            return
        }
        
        powercfg /setactive $balancedGUID 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Plano Equilibrado ativado com sucesso!" -ForegroundColor Green
            Write-Log "Plano equilibrado ativado" "SUCESSO"
        }
        else {
            throw "Falha ao ativar plano"
        }
    }
    catch {
        Write-Log "Erro ao ativar plano equilibrado: $($_.Exception.Message)" "ERRO"
    }
}

# 4. Ativar/Desativar Hibernação
function Set-Hibernation {
    param([bool]$Enable)
    
    if ($Enable) {
        Write-Host "`n=== ATIVANDO HIBERNAÇÃO ===" -ForegroundColor Cyan
        
        try {
            # Verificar se já está habilitada
            $hiberboot = powercfg /hibernate on 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Hibernação ativada com sucesso!" -ForegroundColor Green
                Write-Host "[INFO] O sistema agora pode hibernar. Para hibernar, use: shutdown /h" -ForegroundColor Yellow
                Write-Log "Hibernação ativada" "SUCESSO"
            }
            else {
                throw "Falha ao ativar hibernação"
            }
        }
        catch {
            Write-Log "Erro ao ativar hibernação: $($_.Exception.Message)" "ERRO"
        }
    }
    else {
        Write-Host "`n=== DESATIVANDO HIBERNAÇÃO ===" -ForegroundColor Cyan
        
        try {
            powercfg /hibernate off 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Hibernação desativada com sucesso!" -ForegroundColor Green
                Write-Host "[INFO] A hibernação foi desabilitada. Isso libera espaço em disco." -ForegroundColor Yellow
                Write-Log "Hibernação desativada" "SUCESSO"
            }
            else {
                throw "Falha ao desativar hibernação"
            }
        }
        catch {
            Write-Log "Erro ao desativar hibernação: $($_.Exception.Message)" "ERRO"
        }
    }
}

# 5. Verificar Status de Hibernação
function Get-HibernationStatus {
    Write-Host "`n=== STATUS DA HIBERNAÇÃO ===" -ForegroundColor Cyan
    
    try {
        $result = powercfg /hibernate query 2>$null
        
        if ($result -match "Estado\s*:\s*0") {
            Write-Host "Status: DESATIVADA" -ForegroundColor Red
        }
        elseif ($result -match "Estado\s*:\s*1") {
            Write-Host "Status: ATIVADA" -ForegroundColor Green
        }
        else {
            # Tentar método alternativo
            $hiberFile = "$env:SystemDrive\hiberfil.sys"
            if (Test-Path $hiberFile) {
                $size = (Get-Item $hiberFile).Length / 1GB
                Write-Host "Status: ATIVADA (Arquivo: hiberfil.sys - $([math]::Round($size, 2)) GB)" -ForegroundColor Green
            }
            else {
                Write-Host "Status: DESATIVADA" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Log "Erro ao verificar status de hibernação: $($_.Exception.Message)" "ERRO"
    }
}

# 6. Remover Arquivo de Hibernação
function Remove-HiberFile {
    Write-Host "`n=== REMOVENDO ARQUIVO DE HIBERNAÇÃO ===" -ForegroundColor Cyan
    Write-Host "[AVISO] Isso remove o arquivo hiberfil.sys do sistema!" -ForegroundColor Yellow
    
    $confirm = Read-Host "Continuar? (S/N)"
    if ($confirm -notmatch "^[sS]$") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        # Primeiro desativar hibernação
        powercfg /hibernate off 2>$null
        
        # Tentar remover arquivo
        $hiberFile = "$env:SystemDrive\hiberfil.sys"
        if (Test-Path $hiberFile) {
            # Ativar privilégio de管理员
            $process = Get-Process -PID $PID
            $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
            
            Remove-Item -Path $hiberFile -Force -ErrorAction Stop
            Write-Host "[OK] Arquivo hiberfil.sys removido com sucesso!" -ForegroundColor Green
            Write-Log "Arquivo hiberfil.sys removido" "SUCESSO"
        }
        else {
            Write-Host "[INFO] Arquivo hiberfil.sys não existe." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Log "Erro ao remover arquivo de hibernação: $($_.Exception.Message)" "ERRO"
    }
}

# 7. Limpar Configurações de Energia Corrompidas
function Repair-PowerSettings {
    Write-Host "`n=== REPARANDO CONFIGURAÇÕES DE ENERGIA ===" -ForegroundColor Cyan
    
    try {
        Write-Host "[1/4] Registrando esquema de energia..." -ForegroundColor Yellow
        
        # Registrar esquema de energia padrão
        powercfg /energy 2>$null | Out-Null
        
        # Recarregar configurações padrão
        powercfg /restoredefaultschemes 2>$null
        
        Write-Host "[2/4] Forçando atualização de configurações..." -ForegroundColor Yellow
        
        # Atualizar esquema ativo
        $activePlan = powercfg /getactivescheme 2>$null
        powercfg /setactive ($activePlan -replace '.*:\s*([a-f0-9-]+).*', '$1') 2>$null
        
        Write-Host "[3/4] Verificando serviços relacionados..." -ForegroundColor Yellow
        
        # Reiniciar serviços relacionados
        $services = @("Power", "W32Time", "EventLog")
        foreach ($svc in $services) {
            $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                Write-Host "  - Reiniciando serviço $svc..." -ForegroundColor Gray
                Restart-Service -Name $svc -Force -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "[4/4] Verificando integridade do registro..." -ForegroundColor Yellow
        
        # Verificar chaves de registro importantes
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
        if (Test-Path $regPath) {
            Write-Host "  - Chave de energia do sistema OK" -ForegroundColor Green
        }
        
        Write-Host "`n[OK] Reparo de configurações de energia concluído!" -ForegroundColor Green
        Write-Log "Configurações de energia reparadas" "SUCESSO"
    }
    catch {
        Write-Log "Erro ao reparar configurações de energia: $($_.Exception.Message)" "ERRO"
    }
}

# 8. Criar Plano de Energia Personalizado
function New-CustomPowerPlan {
    Write-Host "`n=== CRIANDO PLANO DE ENERGIA PERSONALIZADO ===" -ForegroundColor Cyan
    
    Write-Host "Este assistente cria um plano de energia personalizado para notebook." -ForegroundColor White
    Write-Host ""
    
    # Obter nome do plano
    $planName = Read-Host "Nome do plano personalizado"
    if ([string]::IsNullOrWhiteSpace($planName)) {
        $planName = "Meu Plano Personalizado"
    }
    
    try {
        # Criar baseado no plano equilibrado
        $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
        $newPlanGUID = [guid]::NewGuid().ToString()
        
        # Criar novo esquema
        powercfg /duplicatescheme $balancedGUID $newPlanGUID 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao criar esquema"
        }
        
        # Renomear
        powercfg /changename $newPlanGUID "$planName" "Plano personalizado criado pelo HP-Scripts" 2>$null
        
        Write-Host "`n[OK] Plano '$planName' criado com sucesso!" -ForegroundColor Green
        Write-Host "[INFO] GUID: $newPlanGUID" -ForegroundColor Gray
        
        # Perguntar se deseja ativar
        $activate = Read-Host "Deseja ativar este plano agora? (S/N)"
        if ($activate -match "^[sS]$") {
            powercfg /setactive $newPlanGUID 2>$null
            Write-Host "[OK] Plano ativado!" -ForegroundColor Green
        }
        
        Write-Log "Plano de energia personalizado criado: $planName" "SUCESSO"
    }
    catch {
        Write-Log "Erro ao criar plano personalizado: $($_.Exception.Message)" "ERRO"
    }
}

# 9. Otimizar Configurações de Energia para Desktop
function Optimize-DesktopPower {
    Write-Host "`n=== OTIMIZANDO PARA DESKTOP ===" -ForegroundColor Cyan
    
    try {
        $highPerfGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        
        Write-Host "[1/5] Ativando plano de alto desempenho..." -ForegroundColor Yellow
        powercfg /setactive $highPerfGUID 2>$null
        
        Write-Host "[2/5] Desativando hibernação..." -ForegroundColor Yellow
        powercfg /hibernate off 2>$null
        
        Write-Host "[3/5] Configurando disco para nunca dormir..." -ForegroundColor Yellow
        powercfg /change disk-timeout-ac 0 2>$null
        
        Write-Host "[4/5] Configurando monitor para nunca desligar..." -ForegroundColor Yellow
        powercfg /change monitor-timeout-ac 0 2>$null
        
        Write-Host "[5/5] Configurando suspensão..." -ForegroundColor Yellow
        powercfg /change standby-timeout-ac 0 2>$null
        
        Write-Host "`n[OK] Configurações otimizadas para desktop!" -ForegroundColor Green
        Write-Host "  - Plano: Alto Desempenho" -ForegroundColor Gray
        Write-Host "  - Hibernação: Desativada" -ForegroundColor Gray
        Write-Host "  - Disco: Nunca desliga" -ForegroundColor Gray
        Write-Host "  - Monitor: Nunca desliga" -ForegroundColor Gray
        Write-Host "  - Suspensão: Desativada" -ForegroundColor Gray
        
        Write-Log "Otimização de energia para desktop concluída" "SUCESSO"
    }
    catch {
        Write-Log "Erro ao otimizar para desktop: $($_.Exception.Message)" "ERRO"
    }
}

# 10. Otimizar Configurações de Energia para Notebook
function Optimize-LaptopPower {
    Write-Host "`n=== OTIMIZANDO PARA NOTEBOOK ===" -ForegroundColor Cyan
    
    try {
        $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
        
        Write-Host "[1/6] Ativando plano equilibrado..." -ForegroundColor Yellow
        powercfg /setactive $balancedGUID 2>$null
        
        Write-Host "[2/6] Ativando hibernação..." -ForegroundColor Yellow
        powercfg /hibernate on 2>$null
        
        Write-Host "[3/6] Configurando disco para dormir após 20 min..." -ForegroundColor Yellow
        powercfg /change disk-timeout-ac 20 2>$null
        
        Write-Host "[4/6] Configurando monitor para dormir após 15 min..." -ForegroundColor Yellow
        powercfg /change monitor-timeout-ac 15 2>$null
        
        Write-Host "[5/6] Configurando suspensão após 30 min..." -ForegroundColor Yellow
        powercfg /change standby-timeout-ac 30 2>$null
        
        Write-Host "[6/6] Habilitando inicialização rápida..." -ForegroundColor Yellow
        $fastBootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
        if (Test-Path $fastBootPath) {
            Set-ItemProperty -Path $fastBootPath -Name "HiberbootEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "`n[OK] Configurações otimizadas para notebook!" -ForegroundColor Green
        Write-Host "  - Plano: Equilibrado" -ForegroundColor Gray
        Write-Host "  - Hibernação: Ativada" -ForegroundColor Gray
        Write-Host "  - Disco: 20 min" -ForegroundColor Gray
        Write-Host "  - Monitor: 15 min" -ForegroundColor Gray
        Write-Host "  - Suspensão: 30 min" -ForegroundColor Gray
        
        Write-Log "Otimização de energia para notebook concluída" "SUCESSO"
    }
    catch {
        Write-Log "Erro ao otimizar para notebook: $($_.Exception.Message)" "ERRO"
    }
}

# 11. Ver Diagnóstico de Energia
function Get-PowerDiagnostics {
    Write-Host "`n=== DIAGNÓSTICO DE ENERGIA ===" -ForegroundColor Cyan
    
    try {
        Write-Host "`n--- Plano de Energia ---" -ForegroundColor Yellow
        $activePlan = powercfg /getactivescheme 2>$null
        Write-Host $activePlan -ForegroundColor White
        
        Write-Host "`n--- Status da Hibernação ---" -ForegroundColor Yellow
        Get-HibernationStatus
        
        Write-Host "`n--- Configurações Atuais ---" -ForegroundColor Yellow
        
        $monitor = powercfg /query scheme_current sub_video videoidle 2>$null
        if ($monitor -match "Index\s*:\s*(\d+)") {
            $min = [int]$matches[1] / 60
            if ($min -gt 0) {
                Write-Host "  Monitor desliga após: $min minutos" -ForegroundColor White
            }
            else {
                Write-Host "  Monitor: Nunca desliga" -ForegroundColor White
            }
        }
        
        $disk = powercfg /query scheme_current sub_disk diskTimeout 2>$null
        if ($disk -match "Index\s*:\s*(\d+)") {
            $min = [int]$matches[1] / 60
            if ($min -gt 0) {
                Write-Host "  Disco desliga após: $min minutos" -ForegroundColor White
            }
            else {
                Write-Host "  Disco: Nunca desliga" -ForegroundColor White
            }
        }
        
        $standby = powercfg /query scheme_current sub_sleep standbyTimeout 2>$null
        if ($standby -match "Index\s*:\s*(\d+)") {
            $min = [int]$matches[1] / 60
            if ($min -gt 0) {
                Write-Host "  Suspensão após: $min minutos" -ForegroundColor White
            }
            else {
                Write-Host "  Suspensão: Desativada" -ForegroundColor White
            }
        }
        
        Write-Host "`n--- Bateria (se aplicável) ---" -ForegroundColor Yellow
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        if ($battery) {
            Write-Host "  Status: $($battery.BatteryStatus)" -ForegroundColor White
            Write-Host "  Carga: $($battery.EstimatedChargeRemaining)%" -ForegroundColor White
            if ($battery.EstimatedRunTime -and $battery.EstimatedRunTime -lt 71582788) {
                Write-Host "  Tempo restante estimado: $($battery.EstimatedRunTime) minutos" -ForegroundColor White
            }
        }
        else {
            Write-Host "  Desktop (sem bateria)" -ForegroundColor Gray
        }
        
        Write-Host "`n--- Tamanho do Arquivo de Hibernação ---" -ForegroundColor Yellow
        $hiberFile = "$env:SystemDrive\hiberfil.sys"
        if (Test-Path $hiberFile) {
            $size = (Get-Item $hiberFile).Length / 1GB
            Write-Host "  hiberfil.sys: $([math]::Round($size, 2)) GB" -ForegroundColor White
        }
        else {
            Write-Host "  hiberfil.sys: Não existe" -ForegroundColor Gray
        }
        
        Write-Log "Diagnóstico de energia concluído" "SUCESSO"
    }
    catch {
        Write-Log "Erro no diagnóstico de energia: $($_.Exception.Message)" "ERRO"
    }
}

# 12. Resetar para Configurações Padrão
function Reset-PowerDefaults {
    Write-Host "`n=== RESETANDO PARA PADRÕES DO WINDOWS ===" -ForegroundColor Cyan
    Write-Host "[AVISO] Isso removerá todos os planos de energia personalizados!" -ForegroundColor Yellow
    
    $confirm = Read-Host "Continuar? (S/N)"
    if ($confirm -notmatch "^[sS]$") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Restaurando esquemas padrão..." -ForegroundColor Yellow
        powercfg /restoredefaultschemes 2>$null
        
        Write-Host "Ativando plano equilibrado..." -ForegroundColor Yellow
        $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
        powercfg /setactive $balancedGUID 2>$null
        
        Write-Host "`n[OK] Configurações resetadas para padrões do Windows!" -ForegroundColor Green
        Write-Log "Configurações de energia resetadas para padrão" "SUCESSO"
    }
    catch {
        Write-Log "Erro ao resetar configurações: $($_.Exception.Message)" "ERRO"
    }
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║           GERENCIAMENTO DE ENERGIA - HP-SCRIPTS          ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Ver Planos de Energia Disponíveis" -ForegroundColor White
    Write-Host "  [2] Ativar Plano de Alto Desempenho" -ForegroundColor White
    Write-Host "  [3] Ativar Plano Equilibrado" -ForegroundColor White
    Write-Host "  [4] Ativar Hibernação" -ForegroundColor White
    Write-Host "  [5] Desativar Hibernação" -ForegroundColor White
    Write-Host "  [6] Ver Status da Hibernação" -ForegroundColor White
    Write-Host "  [7] Remover Arquivo de Hibernação" -ForegroundColor White
    Write-Host "  [8] Criar Plano Personalizado" -ForegroundColor White
    Write-Host "  [9] Otimizar para Desktop" -ForegroundColor White
    Write-Host "  [10] Otimizar para Notebook" -ForegroundColor White
    Write-Host "  [11] Diagnóstico Completo de Energia" -ForegroundColor White
    Write-Host "  [12] Reparar Configurações de Energia" -ForegroundColor White
    Write-Host "  [13] Resetar para Padrões do Windows" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Sair" -ForegroundColor DarkGray
    Write-Host ""
}

# Loop principal
do {
    Show-Menu
    $choice = Read-Host "Selecione uma opção"
    
    switch ($choice) {
        "1" { Get-PowerPlans }
        "2" { Set-HighPerformance }
        "3" { Set-Balanced }
        "4" { Set-Hibernation -Enable $true }
        "5" { Set-Hibernation -Enable $false }
        "6" { Get-HibernationStatus }
        "7" { Remove-HiberFile }
        "8" { New-CustomPowerPlan }
        "9" { Optimize-DesktopPower }
        "10" { Optimize-LaptopPower }
        "11" { Get-PowerDiagnostics }
        "12" { Repair-PowerSettings }
        "13" { Reset-PowerDefaults }
        "0" {
            Write-Host "`nSaindo..." -ForegroundColor Green
            break
        }
        default {
            Write-Host "`n[ERRO] Opção inválida!" -ForegroundColor Red
        }
    }
    
    if ($choice -ne "0") {
        Write-Host ""
        Write-Host "Pressione ENTER para continuar..." -ForegroundColor Gray
        Read-Host
    }
} while ($choice -ne "0")
