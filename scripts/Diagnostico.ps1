#Requires -RunAsAdministrator
<#
.SYNOPSIS
Script de diagnóstico completo para técnicos em informática.
.DESCRIPTION
Executa o diagnóstico técnico completo da máquina e gera, em C:\DiagTecnico,
o relatório (Relatorio_*.txt), os scripts de reparo (Reparo_*.ps1 e Reparo_*.cmd),
a lista de itens não consertados (NaoConsertado_*.txt) e os itens de inicialização
(StartupItems_*.txt).
.NOTES
Chamado pelo menu HP Scripts em: 03 (SFC) > 2 (Diagnóstico Técnico Completo).
Ao final devolve o controle ao menu (não encerra a sessão).
#>

# 1. VERIFICAÇÃO DE ADMINISTRADOR
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERRO: Execute como Administrador!' -ForegroundColor Red
    Write-Host 'Pressione qualquer tecla para voltar ao menu...' -ForegroundColor Yellow
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Start-Sleep -Seconds 2 }
    return
}

# 2. CONFIGURAÇÃO INICIAL
$ComputerName = $env:COMPUTERNAME
$DateStr = Get-Date -Format "yyyyMMdd_HHmmss"
$DateBR = Get-Date -Format "dd/MM/yyyy HH:mm"
$OutputDir = "C:\DiagTecnico"

if (-Not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$ReportFile = "$OutputDir\Relatorio_${ComputerName}_${DateStr}.txt"
$RepairPS1 = "$OutputDir\Reparo_${ComputerName}_${DateStr}.ps1"
$RepairCMD = "$OutputDir\Reparo_${ComputerName}_${DateStr}.cmd"
$NotFixedFile = "$OutputDir\NaoConsertado_${ComputerName}_${DateStr}.txt"
$StartupFile = "$OutputDir\StartupItems_${ComputerName}_${DateStr}.txt"

$script:ReportLines = New-Object System.Collections.ArrayList
$script:RepairPS1Fast = New-Object System.Collections.ArrayList
$script:RepairPS1Medium = New-Object System.Collections.ArrayList
$script:RepairPS1Slow = New-Object System.Collections.ArrayList
$script:RepairCMDFast = New-Object System.Collections.ArrayList
$script:RepairCMDMedium = New-Object System.Collections.ArrayList
$script:RepairCMDSlow = New-Object System.Collections.ArrayList
$script:NotFixable = New-Object System.Collections.ArrayList
$script:StartupItems = New-Object System.Collections.ArrayList

$script:CountOK = 0
$script:CountWarning = 0
$script:CountCritical = 0
$script:CountError = 0

# 3. FUNÇÕES AUXILIARES
function Write-Status {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $color = "Cyan"
    $prefix = "[INFO]"
    
    switch ($Level) {
        "OK" { $color = "Green"; $prefix = "[OK]"; $script:CountOK++ }
        "AVISO" { $color = "Yellow"; $prefix = "[AVISO]"; $script:CountWarning++ }
        "CRITICO" { $color = "Red"; $prefix = "[CRÍTICO]"; $script:CountCritical++ }
        "ERRO" { $color = "DarkRed"; $prefix = "[ERRO]"; $script:CountError++ }
        "INFO" { $color = "Cyan"; $prefix = "[INFO]" }
    }
    
    $fullMessage = "$prefix $Message"
    Write-Host "  $fullMessage" -ForegroundColor $color
    [void]$script:ReportLines.Add($fullMessage)
}

function Write-Section {
    param([string]$Title)
    $line = "`n" + ("=" * 60)
    $text = "--- $Title ---"
    Write-Host $line -ForegroundColor Blue
    Write-Host $text -ForegroundColor Blue
    Write-Host $line -ForegroundColor Blue
    
    [void]$script:ReportLines.Add("")
    [void]$script:ReportLines.Add("=" * 60)
    [void]$script:ReportLines.Add("--- $Title ---")
    [void]$script:ReportLines.Add("=" * 60)
}

function Show-Progress {
    param([int]$Step, [int]$Total, [string]$Activity)
    $percent = [math]::Round(($Step / $Total) * 100)
    Write-Host "`n[$Step/$Total] ($percent%) $Activity..." -ForegroundColor Magenta
}

function Get-FolderSizeMB {
    param([string]$Path)
    try {
        if (Test-Path $Path) {
            $colItems = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            if ($colItems) {
                $size = ($colItems | Measure-Object -Property Length -Sum).Sum
                return [math]::Round($size / 1MB, 2)
            }
        }
    } catch {}
    return 0
}

function Add-RepairPS1 {
    param([string]$Speed, [string]$Description, [string]$Code)
    $task = [PSCustomObject]@{ Description = $Description; Code = $Code }
    switch ($Speed) {
        "Fast" { [void]$script:RepairPS1Fast.Add($task) }
        "Medium" { [void]$script:RepairPS1Medium.Add($task) }
        "Slow" { [void]$script:RepairPS1Slow.Add($task) }
    }
}

function Add-RepairCMD {
    param([string]$Speed, [string]$Description, [string]$Code)
    $task = [PSCustomObject]@{ Description = $Description; Code = $Code }
    switch ($Speed) {
        "Fast" { [void]$script:RepairCMDFast.Add($task) }
        "Medium" { [void]$script:RepairCMDMedium.Add($task) }
        "Slow" { [void]$script:RepairCMDSlow.Add($task) }
    }
}

# 4. BANNER INICIAL
Clear-Host
$banner = @"
╔══════════════════════════════════════════════════════════╗
║    DIAGNÓSTICO COMPLETO — TÉCNICO EM INFORMÁTICA         ║
║    Computador: $(("{0,-13}" -f $ComputerName)) Data: $DateBR        ║
╚══════════════════════════════════════════════════════════╝
"@
Write-Host $banner -ForegroundColor Cyan
[void]$script:ReportLines.Add($banner)

# 5. AS 20 VERIFICAÇÕES DE DIAGNÓSTICO
$totalSteps = 20
$step = 0

# [1/20] INFORMAÇÕES DO SISTEMA
$step++
Show-Progress $step $totalSteps "INFORMAÇÕES DO SISTEMA"
Write-Section "INFORMAÇÕES DO SISTEMA"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    
    if ($os -and $cs) {
        Write-Status "SO: $($os.Caption) (Build: $($os.BuildNumber), Versão: $($os.Version), $($os.OSArchitecture))" "INFO"
        Write-Status "Hardware: $($cs.Manufacturer) - $($cs.Model)" "INFO"
        
        $uptime = (Get-Date) - $os.LastBootUpTime
        $uptimeDays = $uptime.Days
        if ($uptimeDays -gt 30) {
            Write-Status "Uptime alto: $uptimeDays dias sem reiniciar" "AVISO"
        } else {
            Write-Status "Uptime: $uptimeDays dias" "OK"
        }
        
        $activation = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseStatus=1" -ErrorAction SilentlyContinue
        if (-not $activation) {
            Write-Status "Windows NÃO está ativado!" "AVISO"
            [void]$script:NotFixable.Add("Ativação do Windows pendente")
        } else {
            Write-Status "Windows Ativado" "OK"
        }
    } else {
        Write-Status "Falha ao obter informações do sistema" "ERRO"
    }
} catch { Write-Status "Erro na verificação do sistema" "ERRO" }

# [2/20] DISCO / ARMAZENAMENTO
$step++
Show-Progress $step $totalSteps "DISCO E ARMAZENAMENTO"
Write-Section "DISCO E ARMAZENAMENTO"
try {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
    foreach ($disk in $disks) {
        $totalGB = [math]::Round($disk.Size / 1GB, 1)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
        $usedPct = 0
        if ($disk.Size -gt 0) { $usedPct = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1) }
        
        $statusText = "Disco $($disk.DeviceID) - Total: $totalGB GB | Livre: $freeGB GB | Usado: $usedPct%"
        if ($usedPct -ge 95) { Write-Status $statusText "CRITICO" }
        elseif ($usedPct -ge 85) { Write-Status $statusText "AVISO" }
        else { Write-Status $statusText "OK" }
    }
    
    $tempSize = 0
    $tempPaths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Prefetch",
        "C:\Windows\SoftwareDistribution\Download",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    )
    foreach ($path in $tempPaths) { $tempSize += Get-FolderSizeMB $path }
    
    try {
        $recycleBin = (New-Object -ComObject Shell.Application).NameSpace(10)
        if ($recycleBin) {
            $recycleSize = 0
            foreach ($item in $recycleBin.Items()) { $recycleSize += $item.Size }
            $tempSize += [math]::Round($recycleSize / 1MB, 2)
        }
    } catch {}
    
    if ($tempSize -gt 1024) {
        $tempGB = [math]::Round($tempSize / 1024, 2)
        Write-Status "Tamanho dos arquivos temporários: $tempGB GB" "AVISO"
        
        Add-RepairPS1 "Fast" "Limpar Temporários" "Remove-Item -Path `"`$env:TEMP\*`" -Recurse -Force -EA SilentlyContinue; Remove-Item -Path 'C:\Windows\Temp\*' -Recurse -Force -EA SilentlyContinue; Remove-Item -Path 'C:\Windows\Prefetch\*' -Force -EA SilentlyContinue; Clear-RecycleBin -Force -EA SilentlyContinue; Remove-Item `"`$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*`" -Force -EA SilentlyContinue"
        Add-RepairCMD "Fast" "Limpar Temporários" "del /s /f /q `"%TEMP%\*`" >nul 2>&1 & for /d %%i in (`"%TEMP%\*`") do rd /s /q `"%%i`" >nul 2>&1 & del /s /f /q `"C:\Windows\Temp\*`" >nul 2>&1 & del /s /f /q `"C:\Windows\Prefetch\*`" >nul 2>&1 & rd /s /q C:\`$Recycle.Bin >nul 2>&1"
    } else {
        Write-Status "Tamanho dos arquivos temporários: $tempSize MB" "OK"
    }
    
    $swDistSize = Get-FolderSizeMB "C:\Windows\SoftwareDistribution\Download"
    if ($swDistSize -gt 500) {
        Write-Status "Pasta SoftwareDistribution\Download grande: $swDistSize MB" "AVISO"
        Add-RepairPS1 "Medium" "Limpar SoftwareDistribution" "Stop-Service wuauserv -Force -EA SilentlyContinue; Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv -EA SilentlyContinue"
        Add-RepairCMD "Medium" "Limpar SoftwareDistribution" "net stop wuauserv >nul 2>&1 & del /s /f /q `"C:\Windows\SoftwareDistribution\Download\*`" >nul 2>&1 & net start wuauserv >nul 2>&1"
    }
    
    $vss = vssadmin list shadowstorage 2>&1
    if ($vss -match "Erro") { Write-Status "Sem pontos de restauração ou erro no VSS" "AVISO" }
    else { Write-Status "Pontos de restauração funcionais" "OK" }
} catch { Write-Status "Erro na verificação de armazenamento" "ERRO" }

# [3/20] MEMÓRIA RAM
$step++
Show-Progress $step $totalSteps "MEMÓRIA RAM"
Write-Section "MEMÓRIA RAM"
try {
    $osMem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $totalRAM = [math]::Round($osMem.TotalVisibleMemorySize / 1024, 1) # MB
    $freeRAM = [math]::Round($osMem.FreePhysicalMemory / 1024, 1) # MB
    $usedPct = [math]::Round((($totalRAM - $freeRAM) / $totalRAM) * 100, 1)
    
    $statusText = "RAM Total: $totalRAM MB | Uso: $usedPct%"
    if ($usedPct -ge 90) { Write-Status $statusText "CRITICO" }
    elseif ($usedPct -ge 80) { Write-Status $statusText "AVISO" }
    else { Write-Status $statusText "OK" }
    
    if ($totalRAM -lt 4000) {
        Write-Status "RAM total insuficiente ($totalRAM MB)" "AVISO"
        [void]$script:NotFixable.Add("RAM insuficiente, recomendado upgrade")
    }
    
    Write-Status "Top 5 processos por memória:" "INFO"
    Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | ForEach-Object {
        $mb = [math]::Round($_.WorkingSet64 / 1MB, 1)
        Write-Status "  $($_.ProcessName) (PID: $($_.Id)) — $mb MB" "INFO"
    }
    
    $pagefile = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
    if (-not $pagefile) {
        Write-Status "Arquivo de paginação não detectado ou gerenciado automaticamente pelo sistema" "INFO"
    } else {
        Write-Status "Arquivo de paginação fixo detectado" "INFO"
    }
} catch { Write-Status "Erro na verificação de RAM" "ERRO" }

# [4/20] CPU
$step++
Show-Progress $step $totalSteps "PROCESSADOR (CPU)"
Write-Section "PROCESSADOR (CPU)"
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    Write-Status "Modelo: $($cpu.Name) ($($cpu.NumberOfCores) Cores)" "INFO"
    
    $load = $cpu.LoadPercentage
    if ($load -gt 90) { Write-Status "Uso da CPU crítico: $load%" "CRITICO" }
    elseif ($load -gt 70) { Write-Status "Uso da CPU alto: $load%" "AVISO" }
    else { Write-Status "Uso da CPU normal: $load%" "OK" }
    
    Write-Status "Top 5 processos por CPU:" "INFO"
    Get-Process -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Status "  $($_.ProcessName) (PID: $($_.Id)) — CPU: $([math]::Round($_.CPU, 1))s" "INFO"
    }
    
    try {
        $temp = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($temp) {
            $celsius = [math]::Round(($temp.CurrentTemperature / 10) - 273.15, 1)
            if ($celsius -gt 80) {
                Write-Status "Temperatura da CPU alta: $celsius °C" "AVISO"
                [void]$script:NotFixable.Add("Temperatura da CPU alta ($celsius °C)")
            } else {
                Write-Status "Temperatura da CPU normal: $celsius °C" "OK"
            }
        }
    } catch { }
} catch { Write-Status "Erro na verificação de CPU" "ERRO" }

# [5/20] PROGRAMAS NA INICIALIZAÇÃO
$step++
Show-Progress $step $totalSteps "PROGRAMAS NA INICIALIZAÇÃO"
Write-Section "PROGRAMAS NA INICIALIZAÇÃO"
try {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    
    $startupCount = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $items = Get-ItemProperty $p -ErrorAction SilentlyContinue
            foreach ($prop in $items.psobject.properties) {
                if ($prop.Name -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider")) {
                    [void]$script:StartupItems.Add("[REGISTRO $p] Nome: $($prop.Name) | Caminho: $($prop.Value)")
                    $startupCount++
                }
            }
        }
    }
    
    $folderStartup = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )
    foreach ($f in $folderStartup) {
        if (Test-Path $f) {
            $files = Get-ChildItem $f -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                [void]$script:StartupItems.Add("[PASTA STARTUP] Nome: $($file.Name) | Caminho: $($file.FullName)")
                $startupCount++
            }
        }
    }
    
    $cimStartup = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue
    if ($cimStartup) {
        foreach ($c in $cimStartup) {
            [void]$script:StartupItems.Add("[WMI] Nome: $($c.Name) | Caminho: $($c.Command)")
            $startupCount++
        }
    }
    
    if ($startupCount -gt 20) { Write-Status "Total de itens na inicialização muito alto: $startupCount" "CRITICO" }
    elseif ($startupCount -gt 10) { Write-Status "Total de itens na inicialização alto: $startupCount" "AVISO" }
    else { Write-Status "Total de itens na inicialização aceitável: $startupCount" "OK" }
} catch { Write-Status "Erro na verificação de inicialização" "ERRO" }

# [6/20] DATA E HORA
$step++
Show-Progress $step $totalSteps "DATA E HORA"
Write-Section "DATA E HORA"
try {
    Write-Status "Data atual do sistema: $(Get-Date)" "INFO"
    $tz = Get-TimeZone
    Write-Status "Fuso horário: $($tz.Id)" "INFO"
    
    if ($tz.Id -notmatch "South America") {
        Write-Status "Fuso horário suspeito para o Brasil" "AVISO"
        Add-RepairPS1 "Fast" "Corrigir Fuso Horário" "Set-TimeZone -Id 'E. South America Standard Time' -EA SilentlyContinue"
        Add-RepairCMD "Fast" "Corrigir Fuso Horário" "tzutil /s `"E. South America Standard Time`""
    } else { Write-Status "Fuso horário correto" "OK" }
    
    $timeSvc = Get-Service W32Time -ErrorAction SilentlyContinue
    if ($timeSvc.Status -ne "Running") {
        Write-Status "Serviço de tempo (W32Time) não está em execução" "AVISO"
        Add-RepairPS1 "Fast" "Sincronizar Relógio" "Start-Service W32Time -EA SilentlyContinue; w32tm /resync /force | Out-Null"
        Add-RepairCMD "Fast" "Sincronizar Relógio" "net start w32time & w32tm /resync /force >nul"
    } else { Write-Status "Serviço de tempo rodando normalmente" "OK" }
} catch { Write-Status "Erro na verificação de data/hora" "ERRO" }

# [7/20] IMPRESSORAS
$step++
Show-Progress $step $totalSteps "IMPRESSORAS"
Write-Section "IMPRESSORAS"
try {
    $printers = Get-Printer -ErrorAction SilentlyContinue
    Write-Status "Impressoras instaladas: $(@($printers).Count)" "INFO"
    
    $jobsCount = 0
    foreach ($p in $printers) {
        $jobs = Get-PrintJob -PrinterName $p.Name -ErrorAction SilentlyContinue
        if ($jobs) { $jobsCount += @($jobs).Count }
    }
    
    if ($jobsCount -gt 0) {
        Write-Status "Existem $jobsCount trabalhos de impressão presos" "AVISO"
        Add-RepairPS1 "Fast" "Limpar Fila de Impressão" "Get-PrintJob -PrinterName * | Remove-PrintJob -EA SilentlyContinue; Restart-Service Spooler -Force -EA SilentlyContinue"
        Add-RepairCMD "Fast" "Limpar Fila de Impressão" "net stop spooler & del /f /q `"%systemroot%\System32\spool\PRINTERS\*`" >nul 2>&1 & net start spooler"
    } else { Write-Status "Fila de impressão limpa" "OK" }
} catch { Write-Status "Erro na verificação de impressoras" "ERRO" }

# [8/20] INTERNET E REDE
$step++
Show-Progress $step $totalSteps "INTERNET E REDE"
Write-Section "INTERNET E REDE"
try {
    $ping = Test-Connection 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue
    if (-not $ping) {
        Write-Status "Sem conexão com a internet (ping 8.8.8.8 falhou)" "CRITICO"
    } else {
        $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
        if ($avgLatency -gt 200) { Write-Status "Latência alta detectada: $([math]::Round($avgLatency,1)) ms" "AVISO" }
        else { Write-Status "Conexão com internet OK (Latência: $([math]::Round($avgLatency,1)) ms)" "OK" }
    }
    
    $proxy = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue).ProxyEnable
    if ($proxy -eq 1) {
        Write-Status "Proxy manual ativado. Isso pode bloquear a internet." "AVISO"
        Add-RepairPS1 "Fast" "Desativar Proxy" "Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 0 -EA SilentlyContinue"
        Add-RepairCMD "Fast" "Desativar Proxy" "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`" /v ProxyEnable /t REG_DWORD /d 0 /f >nul"
    }
    
    Add-RepairPS1 "Fast" "Limpar Cache DNS" "Clear-DnsClientCache -EA SilentlyContinue"
    Add-RepairCMD "Fast" "Limpar Cache DNS" "ipconfig /flushdns >nul"
} catch { Write-Status "Erro na verificação de rede" "ERRO" }

# [9/20] INTEGRIDADE DO WINDOWS
$step++
Show-Progress $step $totalSteps "INTEGRIDADE DO WINDOWS"
Write-Section "INTEGRIDADE DO WINDOWS"
try {
    Write-Status "Executando DISM CheckHealth (Rápido)..." "INFO"
    $dism = DISM /Online /Cleanup-Image /CheckHealth 2>&1
    if ($dism -match "reparável|repairable|corruption|corrupção|component store") {
        Write-Status "Corrupção detectada pelo DISM" "AVISO"
        Add-RepairPS1 "Slow" "Reparar Imagem do Windows (DISM)" "DISM /Online /Cleanup-Image /RestoreHealth"
        Add-RepairCMD "Slow" "Reparar Imagem do Windows (DISM)" "DISM /Online /Cleanup-Image /RestoreHealth"
    } else { Write-Status "DISM não detectou corrupção grave (CheckHealth)" "OK" }

    Write-Status "Executando SFC VerifyOnly..." "INFO"
    $sfc = sfc /verifyonly 2>&1
    if ($sfc -match "violações de integridade|integrity violations|encontrou|found") {
        Write-Status "Violações de integridade detectadas pelo SFC" "AVISO"
        Add-RepairPS1 "Slow" "Reparar Arquivos do Sistema (SFC)" "sfc /scannow"
        Add-RepairCMD "Slow" "Reparar Arquivos do Sistema (SFC)" "sfc /scannow"
    } else { Write-Status "SFC não detectou violações" "OK" }
} catch { Write-Status "Erro na verificação de integridade" "ERRO" }

# [10/20] SAÚDE DO DISCO
$step++
Show-Progress $step $totalSteps "SAÚDE DO DISCO"
Write-Section "SAÚDE DO DISCO"
try {
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if ($disks) {
        foreach ($d in $disks) {
            $status = $d.OperationalStatus
            $type = $d.MediaType
            if ($status -ne "OK" -and $status -ne "Healthy") {
                Write-Status "Disco físico com problema: $($d.FriendlyName) - Status: $status" "CRITICO"
                [void]$script:NotFixable.Add("Disco físico ($($d.FriendlyName)) com falha SMART ou erro")
            } else { Write-Status "Saúde do disco físico OK: $($d.FriendlyName) ($type)" "OK" }
            
            if ($type -eq "HDD") {
                Add-RepairPS1 "Slow" "Desfragmentar HDD" "Optimize-Volume -DriveLetter C -Defrag -Verbose -EA SilentlyContinue"
                Add-RepairCMD "Slow" "Desfragmentar HDD" "defrag C: /O /U"
            } elseif ($type -eq "SSD") {
                Add-RepairPS1 "Slow" "Otimizar SSD (TRIM)" "Optimize-Volume -DriveLetter C -ReTrim -Verbose -EA SilentlyContinue"
                Add-RepairCMD "Slow" "Otimizar SSD (TRIM)" "defrag C: /O /U"
            }
        }
    } else {
        $wmicDisks = Get-WmiObject Win32_DiskDrive -ErrorAction SilentlyContinue
        foreach ($wd in $wmicDisks) {
            if ($wd.Status -ne "OK") { Write-Status "Disco $($wd.Model) com status de erro SMART" "CRITICO" }
            else { Write-Status "Saúde do disco $($wd.Model) OK" "OK" }
        }
    }
} catch { Write-Status "Erro na verificação de saúde do disco" "ERRO" }

# [11/20] LOGS DE ERROS
$step++
Show-Progress $step $totalSteps "LOGS DE ERROS"
Write-Section "LOGS DE ERROS"
try {
    $sysErrors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) -ErrorAction SilentlyContinue
    $appErrors = Get-EventLog -LogName Application -EntryType Error -After (Get-Date).AddDays(-1) -ErrorAction SilentlyContinue
    
    $totalErrors = @($sysErrors).Count + @($appErrors).Count
    if ($totalErrors -gt 50) { Write-Status "Muitos erros no EventLog nas últimas 24h: $totalErrors" "CRITICO" }
    elseif ($totalErrors -gt 20) { Write-Status "Erros no EventLog nas últimas 24h: $totalErrors" "AVISO" }
    else { Write-Status "Poucos erros no EventLog: $totalErrors" "OK" }
    
    $bsods = Get-EventLog -LogName System -ErrorAction SilentlyContinue | Where-Object { $_.EventID -eq 1001 -and $_.Source -eq 'BugCheck' } | Select-Object -First 5
    if ($bsods) {
        Write-Status "Telas Azuis (BSOD) recentes detectadas!" "CRITICO"
        [void]$script:NotFixable.Add("Telas Azuis (BSOD) registradas no EventLog")
    } else { Write-Status "Nenhuma BSOD recente registrada" "OK" }
} catch { Write-Status "Erro na leitura de logs" "ERRO" }

# [12/20] SEGURANÇA
$step++
Show-Progress $step $totalSteps "SEGURANÇA"
Write-Section "SEGURANÇA"
try {
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defender) {
        if (-not $defender.AntivirusEnabled -or -not $defender.RealTimeProtectionEnabled) {
            Write-Status "Windows Defender (ou antivírus) está DESATIVADO!" "CRITICO"
        } else { Write-Status "Proteção em tempo real ATIVADA" "OK" }
        
        $sigDate = $defender.AntivirusSignatureLastUpdated
        if ($sigDate) {
            $daysOld = ((Get-Date) - $sigDate).Days
            if ($daysOld -gt 7) {
                Write-Status "Assinaturas do Defender estão $daysOld dias desatualizadas" "AVISO"
                Add-RepairPS1 "Fast" "Atualizar Defender" "Update-MpSignature -EA SilentlyContinue"
                Add-RepairCMD "Fast" "Atualizar Defender" "`"%ProgramFiles%\Windows Defender\MpCmdRun.exe`" -SignatureUpdate"
            } else { Write-Status "Assinaturas do Defender atualizadas" "OK" }
        }
    }
    
    $fw = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    $fwOff = $fw | Where-Object { $_.Enabled -eq $false }
    if ($fwOff) { Write-Status "Um ou mais perfis de Firewall estão desativados" "AVISO" }
    else { Write-Status "Firewall do Windows ativado" "OK" }
} catch { Write-Status "Erro na verificação de segurança" "ERRO" }

# [13/20] ANTIVÍRUS FALSOS E BLOATWARE
$step++
Show-Progress $step $totalSteps "BLOATWARE"
Write-Section "ANTIVÍRUS FALSOS E BLOATWARE"
try {
    $bloatware = @('Segurazo', 'SAntivirus', 'ByteFence', 'PC Accelerate', 'MyPC Backup', 'Reimage Repair', 'SpyHunter', 'TotalAV', '360 Total Security', 'Baidu', 'Ask Toolbar', 'Babylon', 'Conduit', 'Coupon Printer', 'Driver Tonic', 'Hao123', 'iLivid', 'OpenCandy', 'PC Optimizer', 'Search Protect', 'Slimware', 'SlimCleaner', 'Sweet Page', 'WildTangent', 'WinZip Driver', 'Yahoo Toolbar', 'IObit', 'McAfee WebAdvisor', 'uTorrent', 'Advanced SystemCare', 'Chromium', 'DriverPack', 'Driver Easy', 'Smart Game Booster', 'OneClick Cleaner', 'PC Doctor', 'WebDiscover', 'Avast Cleanup', 'AVG TuneUp', 'MyWay', 'MiniTab', 'Wajam')
    
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $foundBloat = 0
    foreach ($p in $paths) {
        $progs = Get-ItemProperty $p -ErrorAction SilentlyContinue
        foreach ($prog in $progs) {
            if ($prog.DisplayName) {
                foreach ($b in $bloatware) {
                    if ($prog.DisplayName -match $b) {
                        Write-Status "Software indesejado detectado: $($prog.DisplayName)" "CRITICO"
                        $foundBloat++
                        $safeName = $b
                        Add-RepairPS1 "Medium" "Desinstalar $safeName" "Get-Package -Name '*$safeName*' -EA SilentlyContinue | Uninstall-Package -Force -EA SilentlyContinue"
                        Add-RepairCMD "Medium" "Desinstalar $safeName" "wmic product where `"name like '%%$safeName%%'`" call uninstall /nointeractive >nul 2>&1"
                        break
                    }
                }
            }
        }
    }
    if ($foundBloat -eq 0) { Write-Status "Nenhum bloatware conhecido detectado" "OK" }
} catch { Write-Status "Erro na verificação de bloatware" "ERRO" }

# [14/20] PLANO DE ENERGIA
$step++
Show-Progress $step $totalSteps "PLANO DE ENERGIA"
Write-Section "PLANO DE ENERGIA"
try {
    $power = powercfg /getactivescheme
    if ($power -match "Economia") {
        Write-Status "Plano de energia em Economia. Isso reduz o desempenho." "AVISO"
        Add-RepairPS1 "Fast" "Mudar Plano de Energia" "powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e"
        Add-RepairCMD "Fast" "Mudar Plano de Energia" "powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e"
    } else { Write-Status "Plano de energia ativo: $power" "OK" }
    
    $existingPlans = powercfg /list
    if ($existingPlans -notmatch 'Desempenho Maximo') {
        $output = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        if ($LASTEXITCODE -ne 0) { $output = powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c }
        if ($output -match '([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})') {
            $guid = $matches[1]
            powercfg /changename $guid "Desempenho Maximo" "Plano criado pelo Diagnostico Tecnico - maximo desempenho" | Out-Null
            Write-Status "Plano 'Desempenho Maximo' criado (nao ativado)" "INFO"
        }
    }
} catch { Write-Status "Erro na configuração de energia" "ERRO" }

# [15/20] ARQUIVO HOSTS
$step++
Show-Progress $step $totalSteps "ARQUIVO HOSTS"
Write-Section "ARQUIVO HOSTS"
try {
    $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) {
        $lines = Get-Content $hostsPath -ErrorAction SilentlyContinue
        $susLines = 0
        foreach ($l in $lines) {
            $tl = $l.Trim()
            if ($tl -and -not $tl.StartsWith("#") -and -not $tl.Contains("localhost") -and -not $tl.Contains("127.0.0.1") -and -not $tl.Contains("::1")) {
                $susLines++
            }
        }
        if ($susLines -gt 5) {
            Write-Status "Muitas entradas suspeitas no arquivo hosts: $susLines" "AVISO"
            Add-RepairPS1 "Fast" "Restaurar Hosts" "Copy-Item $hostsPath `"$hostsPath.bak`" -Force; Set-Content $hostsPath `"# Arquivo Hosts Restaurado`r`n127.0.0.1 localhost`r`n::1 localhost`" -Force"
            Add-RepairCMD "Fast" "Restaurar Hosts" "copy /y `"%windir%\System32\drivers\etc\hosts`" `"%windir%\System32\drivers\etc\hosts.bak`" >nul & echo # Arquivo Hosts Restaurado > `"%windir%\System32\drivers\etc\hosts`""
        } else { Write-Status "Arquivo hosts normal" "OK" }
    }
} catch { Write-Status "Erro na verificação do arquivo hosts" "ERRO" }

# [16/20] TAREFAS AGENDADAS SUSPEITAS
$step++
Show-Progress $step $totalSteps "TAREFAS AGENDADAS"
Write-Section "TAREFAS AGENDADAS"
try {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and $_.State -ne 'Disabled' }
    $countTasks = @($tasks).Count
    if ($countTasks -gt 10) { Write-Status "Número elevado de tarefas agendadas de terceiros: $countTasks" "AVISO" }
    else { Write-Status "Tarefas agendadas normais: $countTasks" "OK" }
    
    foreach ($t in $tasks | Select-Object -First 5) {
        Write-Status "Tarefa de terceiro: $($t.TaskName)" "INFO"
    }
} catch { Write-Status "Erro na verificação de tarefas agendadas" "ERRO" }

# [17/20] DRIVERS COM PROBLEMA
$step++
Show-Progress $step $totalSteps "DRIVERS"
Write-Section "DRIVERS"
try {
    $drivers = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Error' -or $_.Status -eq 'Degraded' -or $_.ConfigManagerErrorCode -ne 0 }
    if ($drivers) {
        foreach ($d in $drivers) {
            Write-Status "Driver com problema: $($d.FriendlyName)" "AVISO"
            [void]$script:NotFixable.Add("Driver com problema: $($d.FriendlyName)")
        }
    } else { Write-Status "Todos os drivers parecem OK" "OK" }
} catch { Write-Status "Erro na verificação de drivers" "ERRO" }

# [18/20] PERFORMANCE VISUAL
$step++
Show-Progress $step $totalSteps "PERFORMANCE VISUAL"
Write-Section "PERFORMANCE VISUAL"
try {
    $osMem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $totalRAM = [math]::Round($osMem.TotalVisibleMemorySize / 1024, 1)
    
    if ($totalRAM -lt 4000) {
        Write-Status "Sistema com pouca RAM. Recomendado desativar efeitos visuais." "AVISO"
        Add-RepairPS1 "Fast" "Otimizar Efeitos Visuais" "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2 -EA SilentlyContinue"
        Add-RepairCMD "Fast" "Otimizar Efeitos Visuais" "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects`" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul"
    } else { Write-Status "Performance visual adequada para a quantidade de RAM" "OK" }
} catch { Write-Status "Erro na verificação de performance visual" "ERRO" }

# [19/20] PERFIL DO USUÁRIO
$step++
Show-Progress $step $totalSteps "PERFIL DO USUÁRIO"
Write-Section "PERFIL DO USUÁRIO"
try {
    if ($env:USERPROFILE -match "TEMP" -or $env:USERPROFILE -match "\.bak") {
        Write-Status "Usuário logado em PERFIL TEMPORÁRIO!" "CRITICO"
        [void]$script:NotFixable.Add("Perfil Temporário Detectado")
    } else { Write-Status "Perfil de usuário carregado normalmente" "OK" }
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $desktopSize = Get-FolderSizeMB $desktopPath
    if ($desktopSize -gt 5000) { Write-Status "Desktop muito grande: $([math]::Round($desktopSize/1024,1)) GB. Pode lentificar o login." "AVISO" }
    else { Write-Status "Tamanho do Desktop normal: $desktopSize MB" "OK" }
} catch { Write-Status "Erro na verificação de perfil de usuário" "ERRO" }

# [20/20] PROGRAMAS INSTALADOS
$step++
Show-Progress $step $totalSteps "PROGRAMAS INSTALADOS"
Write-Section "PROGRAMAS INSTALADOS"
try {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $installed = @()
    foreach ($p in $paths) {
        $progs = Get-ItemProperty $p -ErrorAction SilentlyContinue
        foreach ($prog in $progs) {
            if ($prog.DisplayName) { $installed += $prog }
        }
    }
    
    $installedCount = $installed.Count
    Write-Status "Total de programas instalados: $installedCount" "INFO"
    
    Write-Status "Top 5 maiores programas instalados (estimativa):" "INFO"
    $installed | Sort-Object EstimatedSize -Descending | Select-Object -First 5 | ForEach-Object {
        $mb = [math]::Round($_.EstimatedSize / 1024, 1)
        if ($mb -gt 0) { Write-Status "  $($_.DisplayName) ($mb MB)" "INFO" }
    }
} catch { Write-Status "Erro na listagem de programas" "ERRO" }


# 6. GERAR ARQUIVO DE STARTUP ITEMS
Write-Host "`nGerando lista de itens de inicialização..." -ForegroundColor Cyan
$startupText = "PROGRAMAS NA INICIALIZAÇÃO — $ComputerName — $DateBR`r`n"
$startupText += "================================================`r`n"
$startupText += "Avalie cada item abaixo. Marque com [X] os que deseja desativar.`r`n`r`n"
foreach ($item in $script:StartupItems) { $startupText += "$item`r`n" }
$startupText | Out-File -FilePath $StartupFile -Encoding UTF8
Start-Process notepad.exe $StartupFile

# 7. GERAR RELATÓRIO
Write-Host "Gerando relatório completo..." -ForegroundColor Cyan
$reportContent = "RELATÓRIO DE DIAGNÓSTICO — $ComputerName — $DateBR`r`n"
$reportContent += "================================================`r`n`r`n"
foreach ($line in $script:ReportLines) { $reportContent += "$line`r`n" }
$reportContent += "`r`n`r`n═══ RESUMO ═══`r`n"
$reportContent += "  OK:       $script:CountOK itens`r`n"
$reportContent += "  AVISOS:   $script:CountWarning itens`r`n"
$reportContent += "  CRÍTICOS: $script:CountCritical itens`r`n"
$reportContent += "  ERROS:    $script:CountError itens`r`n"
$reportContent += "`r`n═══ ARQUIVOS GERADOS ═══`r`n"
$reportContent += "  Relatório:         $ReportFile`r`n"
$reportContent += "  Script Reparo PS1: $RepairPS1`r`n"
$reportContent += "  Script Reparo CMD: $RepairCMD`r`n"
$reportContent += "  Não Consertado:    $NotFixedFile`r`n"
$reportContent += "  Startup Items:     $StartupFile`r`n"
$reportContent | Out-File -FilePath $ReportFile -Encoding UTF8

# 8. GERAR SCRIPTS DE REPARO
Write-Host "Gerando scripts de reparo..." -ForegroundColor Cyan

# Gerar PS1
$repairContentPS1 = @"
# Script de Reparo Automatico
# Gerado por Diagnostico.ps1 em $DateBR
# Computador: $ComputerName

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERRO: Execute como Administrador!' -ForegroundColor Red
    pause
    exit 1
}

Write-Host '=======================================' -ForegroundColor Cyan
Write-Host '       INICIANDO SCRIPT DE REPARO' -ForegroundColor Cyan
Write-Host '=======================================' -ForegroundColor Cyan

Write-Host "`n[1] ENCERRANDO PROCESSOS NAO ESSENCIAIS..." -ForegroundColor Yellow
`$protected = @('svchost','csrss','wininit','winlogon','lsass','services','smss','dwm','explorer','taskhostw','RuntimeBroker','fontdrvhost','cmd','powershell','conhost','WmiPrvSE','spoolsv','System','Idle','MsMpEng','SecurityHealthService','SecurityHealthSystray','NisSrv','SgrmBroker','Memory Compression','Registry','SearchIndexer','dllhost','sihost','ctfmon','TextInputHost','ShellExperienceHost','StartMenuExperienceHost','SearchApp','LsaIso','wuauserv','TrustedInstaller','msdtc','WUDFHost','audiodg','WindowsInternal','dasHost','DeviceCensus')
Get-Process | Where-Object { `$_.ProcessName -notin `$protected } | Stop-Process -Force -EA SilentlyContinue

Write-Host "`n[2] EXECUTANDO TAREFAS RAPIDAS (FAST)..." -ForegroundColor Yellow
"@
foreach ($t in $script:RepairPS1Fast) { $repairContentPS1 += "`nWrite-Host `"-> $($t.Description)`" -ForegroundColor Cyan`n$($t.Code)`n" }

$repairContentPS1 += "`nWrite-Host `"`n[3] EXECUTANDO TAREFAS MEDIAS (MEDIUM)...`" -ForegroundColor Yellow"
foreach ($t in $script:RepairPS1Medium) { $repairContentPS1 += "`nWrite-Host `"-> $($t.Description)`" -ForegroundColor Cyan`n$($t.Code)`n" }

$repairContentPS1 += "`nWrite-Host `"`n[4] EXECUTANDO TAREFAS DEMORADAS (SLOW)...`" -ForegroundColor Yellow"
foreach ($t in $script:RepairPS1Slow) { $repairContentPS1 += "`nWrite-Host `"-> $($t.Description)`" -ForegroundColor Cyan`n$($t.Code)`n" }

$repairContentPS1 += @"

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "       REPARO CONCLUIDO COM SUCESSO!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
pause
"@
$repairContentPS1 | Out-File -FilePath $RepairPS1 -Encoding UTF8

# Gerar CMD
$repairContentCMD = @"
@echo off
:: Script de Reparo Automatico
:: Gerado por Diagnostico.ps1 em $DateBR
:: Computador: $ComputerName

net session >nul 2>&1
if %errorLevel% == 0 (
    echo Permissoes Administrativas confirmadas.
) else (
    echo ERRO: Execute como Administrador!
    pause
    exit /B 1
)

echo =======================================
echo        INICIANDO SCRIPT DE REPARO
echo =======================================

echo.
echo [1] ENCERRANDO PROCESSOS NAO ESSENCIAIS...
:: (Simplicado para CMD: fechando alguns comuns, evitar matar os essenciais)
taskkill /F /IM chrome.exe /T >nul 2>&1
taskkill /F /IM edge.exe /T >nul 2>&1
taskkill /F /IM firefox.exe /T >nul 2>&1
taskkill /F /IM skype.exe /T >nul 2>&1
taskkill /F /IM spotify.exe /T >nul 2>&1
taskkill /F /IM discord.exe /T >nul 2>&1
taskkill /F /IM teams.exe /T >nul 2>&1
taskkill /F /IM slack.exe /T >nul 2>&1
taskkill /F /IM steam.exe /T >nul 2>&1
taskkill /F /IM OneDrive.exe /T >nul 2>&1
taskkill /F /IM Dropbox.exe /T >nul 2>&1
taskkill /F /IM iCloudServices.exe /T >nul 2>&1
taskkill /F /IM AnyDesk.exe /T >nul 2>&1
taskkill /F /IM TeamViewer.exe /T >nul 2>&1

echo.
echo [2] EXECUTANDO TAREFAS RAPIDAS (FAST)...
"@
foreach ($t in $script:RepairCMDFast) { $repairContentCMD += "`necho -> $($t.Description)`n$($t.Code)`n" }

$repairContentCMD += "`necho.`necho [3] EXECUTANDO TAREFAS MEDIAS (MEDIUM)..."
foreach ($t in $script:RepairCMDMedium) { $repairContentCMD += "`necho -> $($t.Description)`n$($t.Code)`n" }

$repairContentCMD += "`necho.`necho [4] EXECUTANDO TAREFAS DEMORADAS (SLOW)..."
foreach ($t in $script:RepairCMDSlow) { $repairContentCMD += "`necho -> $($t.Description)`n$($t.Code)`n" }

$repairContentCMD += @"

echo.
echo =======================================
echo        REPARO CONCLUIDO COM SUCESSO!
echo =======================================
pause
"@
$repairContentCMD | Out-File -FilePath $RepairCMD -Encoding Default

# 9. GERAR RELATÓRIO DE NÃO CONSERTADO
if ($script:NotFixable.Count -gt 0) {
    $notFixedText = "ITENS QUE EXIGEM ATENÇÃO MANUAL / NÃO CONSERTADOS`r`n"
    $notFixedText += "=================================================`r`n`r`n"
    foreach ($item in $script:NotFixable) { $notFixedText += "- $item`r`n" }
    $notFixedText | Out-File -FilePath $NotFixedFile -Encoding UTF8
}

# 10. EXIBIR RESUMO FINAL NO TERMINAL
Write-Host "`n=======================================================" -ForegroundColor Blue
Write-Host "                DIAGNÓSTICO FINALIZADO" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host "  OK:       $script:CountOK" -ForegroundColor Green
Write-Host "  AVISOS:   $script:CountWarning" -ForegroundColor Yellow
Write-Host "  CRÍTICOS: $script:CountCritical" -ForegroundColor Red
Write-Host "  ERROS:    $script:CountError" -ForegroundColor DarkRed
Write-Host "`nArquivos gerados em: $OutputDir" -ForegroundColor Cyan
Write-Host "-> Relatório: $ReportFile"
Write-Host "-> Script Reparo PS1: $RepairPS1"
Write-Host "-> Script Reparo CMD: $RepairCMD"
if ($script:NotFixable.Count -gt 0) { Write-Host "-> Não Consertado: $NotFixedFile" -ForegroundColor Red }
Write-Host "-> Itens Inicialização: $StartupFile"
Write-Host "`nVerifique o Bloco de Notas aberto para revisar os itens de inicialização." -ForegroundColor Yellow
Write-Host "Execute o script de reparo (PS1 ou CMD) para aplicar as correções geradas." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow
try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Start-Sleep -Seconds 2 }
