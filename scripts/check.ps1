<#
.SYNOPSIS
    Check-up HPTI Master v8.0 - Diagnóstico Completo Windows
.DESCRIPTION
    - Verificação completa de licenciamento Windows com múltiplos métodos
    - 24 verificações abrangentes de sistema, segurança e performance
    - Compatível com PowerShell 2.0+ (Windows 7+)
.NOTES
    Compatibilidade: PowerShell 2.0, 3.0, 4.0, 5.0, 5.1
#>

# ============================================================
# BLOCO DE COMPATIBILIDADE - Windows 7+
# ============================================================

# Importa módulo de compatibilidade
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "CompatibilityLayer.ps1")

# Configuração de TLS 1.2 (Essencial para HTTPS em sistemas antigos)
try {
    # Método primário (PowerShell 5.0+)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
catch {
    try {
        # Fallback para versões antigas
        [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    }
    catch {
        Write-Warning "Não foi possível forçar TLS 1.2. Conexões HTTPS podem falhar."
    }
}

$ErrorActionPreference = "SilentlyContinue"

# --- ENTRADA DE DADOS ---
Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   RELATÓRIO TÉCNICO HPinfo" -ForegroundColor White
Write-Host "   Diagnóstico Completo do Sistema" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$OSNumber = Read-Host "Digite o número da OS ou nome do cliente"
if ([string]::IsNullOrWhiteSpace($OSNumber)) {
    $OSNumber = "N/A"
}

# --- CONFIGURAÇÕES ---
$ComputerName = $env:COMPUTERNAME
$HPTIReportsDir = "C:\Program Files\HPTI\Reports"
if (-not (Test-Path $HPTIReportsDir)) { New-Item -Path $HPTIReportsDir -ItemType Directory -Force | Out-Null }
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportHTML = "$HPTIReportsDir\checkup_${ComputerName}_$timestamp.html"
$WhatsAppLink = "https://wa.me/556235121468?text=Ola%20HPinfo,%20segue%20o%20relatorio%20do%20PC%20$ComputerName%20-%20OS:%20$OSNumber"

# ============================================================
# VERSÃO PORTÁTIL - USA FERRAMENTAS LOCAIS DO PENDRIVE
# ============================================================

# Detecta o diretório do script e do pendrive
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PortableRoot = Split-Path -Parent $ScriptDir
$ToolsDir = Join-Path $PortableRoot "tools"

$tempDir = "$env:TEMP\HP-Tools"
$7zipExe = "$tempDir\7z.exe"
$Password = "0"

# --- PREPARAÇÃO ---
Write-Host "[*] Iniciando Diagnóstico HPTI v8.0 (Portátil)..." -ForegroundColor Cyan
Write-Host "[*] Executando de: $PortableRoot" -ForegroundColor DarkGray

if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# Copia 7z do pendrive para o temp (se existir localmente)
$local7z = Join-Path $ToolsDir "7z.txe"
if (Test-Path $local7z) {
    Copy-Item $local7z $7zipExe -Force
    Write-Host "[OK] 7-Zip carregado do pendrive" -ForegroundColor Green
}

$Tools = @(
    @{ Name = "CoreTemp"; Archive = "CoreTemp.7z"; SubFolder = "CoreTemp" }
    @{ Name = "CrystalDiskInfo"; Archive = "CrystalDiskInfo.7z"; SubFolder = "CrystalDiskInfo" }
)

$ExtractedPaths = @{}
if (Test-Path $7zipExe) {
    foreach ($tool in $Tools) {
        $pasta = Join-Path $tempDir $tool.SubFolder
        $localArchive = Join-Path $ToolsDir $tool.Archive
        
        if (Test-Path $localArchive) {
            Write-Host "[OK] Extraindo $($tool.Name) do pendrive..." -ForegroundColor Green
            if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Path $pasta -Force | Out-Null }
            & $7zipExe x "$localArchive" -o"$pasta" -p"$Password" -y | Out-Null
            $ExtractedPaths[$tool.Name] = $pasta
        }
        else {
            Write-Host "[AVISO] $($tool.Name) não encontrado no pendrive" -ForegroundColor Yellow
        }
    }
}

# --- LISTA DE RESULTADOS ---
$Resultados = New-Object System.Collections.Generic.List[PSCustomObject]

function Add-Check ($ID, $Nome, $Res, $Stat, $Rec) {
    if ([string]::IsNullOrWhiteSpace($Res)) { $Res = "Não Detectado" }
    $Icone = switch ($Stat) { "OK" { "✅" } "ALERTA" { "⚠️" } "CRÍTICO" { "❌" } default { "❓" } }
    
    $obj = [PSCustomObject]@{
        ID           = $ID
        Verificacao  = $Nome
        Resultado    = $Res
        Status       = $Stat
        Icone        = $Icone
        Recomendacao = $Rec
    }
    $Resultados.Add($obj)
    
    # --- CORREÇÃO OBRIGATÓRIA PARA PS 5.1 ---
    # O cálculo da cor TEM que ser feito fora do Write-Host
    $CorConsole = "Green"
    if ($Stat -ne "OK") { $CorConsole = "Yellow" }
    
    Write-Host "[$Stat] ${Nome}: $Res" -ForegroundColor $CorConsole
}

Write-Host "`n--- EXECUTANDO 23 CHECAGENS ---" -ForegroundColor Yellow

# 1. Temperatura Processador
$t1_Res = "N/A"; $t1_Stat = "ALERTA"; $t1_Rec = "Verificar sensores."
try {
    $ctPath = if ($ExtractedPaths.ContainsKey("CoreTemp")) { Join-Path $ExtractedPaths["CoreTemp"] "CoreTemp.exe" } else { $null }
    if ($ctPath -and (Test-Path $ctPath)) {
        Write-Host "   -> Rodando CoreTemp (Aguarde 12s)..." -NoNewline -ForegroundColor Gray
        $p = Start-Process $ctPath -NoNewWindow -PassThru
        Start-Sleep -Seconds 12 
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        
        $log = Get-ChildItem $ExtractedPaths["CoreTemp"] -Filter "CT-Log*.csv" | Sort-Object LastWriteTime -Descending | Select -First 1
        if ($log) {
            $content = Get-Content $log.FullName | Select -Last 1
            $parts = $content -split ","
            if ($parts.Count -gt 2) {
                $val = [double](($parts[3])) 
                if ($val -gt 1000) { $val = $val / 1000 }
                if ($val -lt 10) { $val = [double]$parts[2] }
                
                $t1_Res = "$([math]::Round($val,0)) °C"
                $t1_Stat = if ($val -ge 85) { "CRÍTICO" } elseif ($val -ge 70) { "ALERTA" } else { "OK" }
                $t1_Rec = if ($t1_Stat -eq "OK") { "Refrigeração OK." } else { "Limpeza + Pasta Térmica." }
                Write-Host " OK" -ForegroundColor Green
            }
        }
        else { Write-Host " Falha (Sem Log)" -ForegroundColor Red }
    }
    
    if ($t1_Res -eq "N/A") {
        $wmi = Get-CimOrWmi -ClassName MsAcpi_ThermalZoneTemperature -Namespace "root/wmi"
        if ($wmi) {
            $val = ($wmi.CurrentTemperature / 10) - 273.15
            $t1_Res = "$([math]::Round($val,0)) °C (WMI)"
            $t1_Stat = if ($val -ge 85) { "CRÍTICO" } elseif ($val -ge 70) { "ALERTA" } else { "OK" }
            $t1_Rec = if ($t1_Stat -eq "OK") { "Refrigeração OK." } else { "Limpeza + Pasta Térmica." }
        }
    }
}
catch { $t1_Res = "Erro Coleta" }
Add-Check 1 "Temperatura CPU" $t1_Res $t1_Stat $t1_Rec

# 2. Saúde Disco (SMART)
$t2_Res = "Desconhecido"; $t2_Stat = "ALERTA"; $t2_Rec = "Verificar manualmente."
try {
    $cdiPath = if ($ExtractedPaths.ContainsKey("CrystalDiskInfo")) { Join-Path $ExtractedPaths["CrystalDiskInfo"] "DiskInfo64.exe" } else { $null }
    if ($cdiPath -and (Test-Path $cdiPath)) {
        Start-Process $cdiPath -ArgumentList "/CopyExit" -Wait
        $logCDI = Join-Path $ExtractedPaths["CrystalDiskInfo"] "DiskInfo.txt"
        if (Test-Path $logCDI) {
            $txt = Get-Content $logCDI -Raw
            if ($txt -match "Health Status : (.*)") {
                $statusReal = $matches[1].Trim()
                $t2_Res = $statusReal
                if ($statusReal -match "Good|Saudável") { $t2_Stat = "OK"; $t2_Rec = "Disco Saudável." } 
                else { $t2_Stat = "CRÍTICO"; $t2_Rec = "Risco de perda de dados. Trocar disco." }
            }
        }
    }
    if ($t2_Res -eq "Desconhecido") {
        $disk = Get-CimOrWmi -ClassName Win32_DiskDrive -First
        $t2_Res = $disk.Status
        if ($disk.Status -eq "OK") { $t2_Stat = "OK"; $t2_Rec = "Status WMI OK." } else { $t2_Stat = "CRÍTICO"; $t2_Rec = "Erro detectado." }
    }
}
catch {}
Add-Check 2 "Saúde Física (SMART)" $t2_Res $t2_Stat $t2_Rec

# 3. Espaço Livre
$t3_Res = ""; $t3_Stat = "OK"; $t3_Rec = "Espaço suficiente."
try {
    $disks = Get-CimOrWmi -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($d in $disks) {
        $pct = [math]::Round(($d.FreeSpace / $d.Size) * 100, 1)
        $t3_Res += "$($d.DeviceID) $pct% | "
        if ($pct -lt 15) { $t3_Stat = "CRÍTICO"; $t3_Rec = "Limpeza urgente." }
        elseif ($pct -lt 25 -and $t3_Stat -ne "CRÍTICO") { $t3_Stat = "ALERTA"; $t3_Rec = "Considerar upgrade." }
    }
    $t3_Res = $t3_Res.TrimEnd(" | ")
}
catch { $t3_Res = "Erro leitura" }
Add-Check 3 "Espaço em Disco" $t3_Res $t3_Stat $t3_Rec

# 4. Licenciamento Windows - VERIFICAÇÃO APRIMORADA
Write-Host "`n[4] Verificando Licenciamento Windows..." -ForegroundColor Cyan
try {
    # Inicializa variáveis
    $t4_Res = ""
    $t4_Stat = "ALERTA"
    $t4_Rec = "Verificar status da licença."
    
    # MÉTODO 1: Verificação de Ativadores Ilegais
    Write-Host "   -> Verificando ativadores ilegais..." -NoNewline -ForegroundColor DarkGray
    $suspectPaths = @("C:\Program Files", "C:\Program Files (x86)", "C:\Windows", "$env:APPDATA", "$env:LOCALAPPDATA")
    $suspectFiles = @("*KMS*", "*AutoPico*", "*KMSAuto*", "*KMSpico*", "*Microsoft Toolkit*")
    
    $hackFound = $false
    $hackFiles = @()
    
    foreach ($path in $suspectPaths) {
        if (Test-Path $path) {
            foreach ($pattern in $suspectFiles) {
                try {
                    $files = Get-ChildItem -Path $path -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Depth 1
                    if ($files) {
                        $hackFound = $true
                        $hackFiles += $files | Select-Object -First 1
                    }
                }
                catch {}
            }
        }
    }
    
    if ($hackFound) {
        $t4_Stat = "CRÍTICO"
        $t4_Res = "Pirataria Detectada"
        $t4_Rec = "Remover ativadores ilegais imediatamente."
        Write-Host " [PIRATARIA]" -ForegroundColor Red
    }
    else {
        Write-Host " [OK]" -ForegroundColor Green
        
        # MÉTODO 2: Verificação via Registro Windows
        Write-Host "   -> Verificando registro do Windows..." -NoNewline -ForegroundColor DarkGray
        try {
            # Verifica ativação no registro
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
            $activationStatus = Get-ItemProperty -Path $regPath -Name "KeyManagementServiceName" -ErrorAction SilentlyContinue
            
            if ($activationStatus -and $activationStatus.KeyManagementServiceName) {
                $t4_Res = "Ativado via KMS"
                $t4_Stat = "ALERTA"
                $t4_Rec = "Licença corporativa (temporária)"
                Write-Host " [KMS]" -ForegroundColor Yellow
            }
            else {
                # Verifica se está ativado
                $regStatus = Get-ItemProperty -Path $regPath -Name "NotificationDisabled" -ErrorAction SilentlyContinue
                $digitalProductId = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DigitalProductId" -ErrorAction SilentlyContinue
                
                if ($digitalProductId -and $digitalProductId.DigitalProductId) {
                    $t4_Res = "Ativado (Registro)"
                    $t4_Stat = "OK"
                    $t4_Rec = "Licença válida detectada"
                    Write-Host " [ATIVADO]" -ForegroundColor Green
                }
                else {
                    Write-Host " [NÃO ATIVADO]" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Host " [ERRO REG]" -ForegroundColor Red
        }
        
        # MÉTODO 3: Verificação via WMI Licensing (se ainda não tem resultado)
        if ([string]::IsNullOrWhiteSpace($t4_Res) -or $t4_Res -eq "Ativado (Registro)") {
            Write-Host "   -> Verificando via WMI..." -NoNewline -ForegroundColor DarkGray
            try {
                $license = Get-CimOrWmi -ClassName SoftwareLicensingProduct -Namespace "root\cimv2" | 
                Where-Object { $_.Name -like "*Windows*" -and $_.LicenseStatus -eq 1 } | 
                Select-Object -First 1
                
                if ($license) {
                    $licenseType = switch ($license.ProductKeyChannel) {
                        "Retail" { "Retail" }
                        "OEM" { "OEM" }
                        "Volume" { "Volume" }
                        default { "Original" }
                    }
                    
                    if ($t4_Res -eq "Ativado (Registro)") {
                        # Complementa informação existente
                        $t4_Res = "$t4_Res - $licenseType"
                    }
                    else {
                        $t4_Res = "Ativado ($licenseType)"
                        $t4_Stat = "OK"
                        $t4_Rec = "Status WMI: $($license.LicenseStatus)"
                    }
                    Write-Host " [$licenseType]" -ForegroundColor Green
                }
                else {
                    Write-Host " [N/D]" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host " [ERRO WMI]" -ForegroundColor Red
            }
        }
        
        # MÉTODO 4: Verificação via SLMGR (como fallback)
        if ([string]::IsNullOrWhiteSpace($t4_Res)) {
            Write-Host "   -> Verificando via SLMGR..." -NoNewline -ForegroundColor DarkGray
            try {
                $output = cmd /c "cscript //nologo %windir%\system32\slmgr.vbs /dli" 2>&1
                $outputString = $output -join "`n"
                
                if ($outputString -match "License Status:.*Licensed") {
                    $t4_Res = "Ativado (SLMGR)"
                    $t4_Stat = "OK"
                    $t4_Rec = "Ativação confirmada via comando"
                    Write-Host " [ATIVADO]" -ForegroundColor Green
                }
                elseif ($outputString -match "error|não encontrado") {
                    Write-Host " [COMANDO N/D]" -ForegroundColor Yellow
                }
                else {
                    Write-Host " [NÃO ATIVADO]" -ForegroundColor Red
                }
            }
            catch {
                Write-Host " [ERRO]" -ForegroundColor Red
            }
        }
        
        # Se ainda não tem resultado, verifica chave BIOS
        if ([string]::IsNullOrWhiteSpace($t4_Res)) {
            Write-Host "   -> Verificando chave BIOS..." -NoNewline -ForegroundColor DarkGray
            try {
                $biosKey = (Get-CimOrWmi -ClassName SoftwareLicensingService).OA3xOriginalProductKey
                if ($biosKey) {
                    $t4_Res = "Chave BIOS Detectada"
                    $t4_Stat = "ALERTA"
                    $t4_Rec = "Ativar usando chave da BIOS"
                    Write-Host " [CHAVE BIOS]" -ForegroundColor Yellow
                }
                else {
                    $t4_Res = "Não Ativado"
                    $t4_Stat = "CRÍTICO"
                    $t4_Rec = "Ativação necessária"
                    Write-Host " [NÃO ATIVADO]" -ForegroundColor Red
                }
            }
            catch {
                $t4_Res = "Erro na verificação"
                $t4_Stat = "ALERTA"
                $t4_Rec = "Verificar manualmente"
                Write-Host " [ERRO]" -ForegroundColor Red
            }
        }
    }
    
}
catch {
    $t4_Res = "Erro Leitura"
    $t4_Stat = "ALERTA"
    $t4_Rec = "Verificar manualmente."
    Write-Host "   -> [ERRO GLOBAL]" -ForegroundColor Red
}
Add-Check 4 "Licenciamento Windows" $t4_Res $t4_Stat $t4_Rec

# 5. Pacote Office
Write-Host "`n[5] Verificando Pacote Office..." -ForegroundColor Cyan
try {
    $t5_Res = ""; $t5_Stat = "ALERTA"; $t5_Rec = "Verificar manualmente."
    
    # Detecta instalação do Office
    $officeReg = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match "Microsoft (Office|365|Word)" } | Select-Object -First 1
    $officeName = if ($officeReg) { $officeReg.DisplayName } else { $null }
    
    if ($officeName) {
        $cleanName = $officeName -replace "Microsoft ", "" -replace "Standard ", "" -replace "Professional Plus", "Pro Plus"
        Write-Host "   -> Office detectado: $cleanName" -NoNewline -ForegroundColor DarkGray
        
        # MÉTODO 1: Verificação via ospp.vbs (mais confiável)
        $osppPaths = @(
            "C:\Program Files\Microsoft Office\Office16\ospp.vbs",
            "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
            "C:\Program Files\Microsoft Office\Office15\ospp.vbs",
            "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs"
        )
        
        $osppFound = $false
        foreach ($osppPath in $osppPaths) {
            if (Test-Path $osppPath) {
                try {
                    Write-Host " [Verificando...]" -ForegroundColor Yellow
                    $osppOutput = cscript //nologo "$osppPath" /dstatus 2>&1
                    $osppString = $osppOutput -join "`n"
                    
                    if ($osppString -match "LICENSE STATUS:\s*---LICENSED---") {
                        $t5_Stat = "OK"
                        $t5_Res = "$cleanName (Ativo)"
                        $t5_Rec = "Pronto para uso."
                        $osppFound = $true
                        Write-Host "   -> Ativação confirmada via OSPP" -ForegroundColor Green
                        break
                    }
                    elseif ($osppString -match "LICENSE STATUS:") {
                        $t5_Stat = "ALERTA"
                        $t5_Res = "$cleanName (Não Ativado)"
                        $t5_Rec = "Ativar Office."
                        $osppFound = $true
                        Write-Host "   -> Office não ativado (OSPP)" -ForegroundColor Yellow
                        break
                    }
                }
                catch {
                    Write-Host "   -> Erro ao executar OSPP" -ForegroundColor Red
                }
            }
        }
        
        # MÉTODO 2: Fallback via WMI (se OSPP não funcionou)
        if (-not $osppFound) {
            Write-Host "   -> Verificando via WMI..." -NoNewline -ForegroundColor DarkGray
            $officeAct = Get-CimOrWmi -ClassName SoftwareLicensingProduct -Filter "Description like '%Office%' AND PartialProductKey IS NOT NULL" | Where-Object LicenseStatus -eq 1
            
            if ($officeAct) {
                $t5_Stat = "OK"
                $t5_Res = "$cleanName (Ativo)"
                $t5_Rec = "Pronto para uso."
                Write-Host " [ATIVADO]" -ForegroundColor Green
            }
            else {
                $t5_Stat = "ALERTA"
                $t5_Res = "$cleanName (Verificar Ativ.)"
                $t5_Rec = "Confirmar ativação manualmente."
                Write-Host " [NÃO CONFIRMADO]" -ForegroundColor Yellow
            }
        }
    }
    else {
        $t5_Stat = "ALERTA"
        $t5_Res = "Não instalado"
        $t5_Rec = "Ofertar pacote Office."
        Write-Host "   -> Office não instalado" -ForegroundColor Yellow
    }
}
catch { 
    $t5_Stat = "ALERTA"
    $t5_Res = "Erro na verificação"
    $t5_Rec = "Verificar manualmente."
    Write-Host "   -> [ERRO]" -ForegroundColor Red
}
Add-Check 5 "Pacote Office" $t5_Res $t5_Stat $t5_Rec

# 6. Bloatware
try {
    $junk = "*WebCompanion*", "*McAfee*", "*Norton*", "*Baidu*", "*Segurazo*", "*Avast*"
    $apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
    $found = $apps | Where { $n = $_.DisplayName; $junk | Where { $n -like $_ } }
    if ($found) { $t6_Stat = "ALERTA"; $t6_Res = "Detectado"; $t6_Rec = "Remover programas desnecessários." }
    else { $t6_Stat = "OK"; $t6_Res = "Limpo"; $t6_Rec = "Sistema otimizado." }
}
catch { $t6_Stat = "OK"; $t6_Res = "N/A" }
Add-Check 6 "Bloatware / Lixo" $t6_Res $t6_Stat $t6_Rec

# 7. Memória RAM
try {
    $os = Get-CimOrWmi -ClassName Win32_OperatingSystem
    $usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 0)
    if ($usedPct -gt 85) { $t7_Stat = "ALERTA"; $t7_Rec = "Fechar programas ou add RAM." }
    else { $t7_Stat = "OK"; $t7_Rec = "Uso dentro do normal." }
    $t7_Res = "$usedPct% em uso"
}
catch { $t7_Res = "Erro"; $t7_Stat = "ALERTA" }
Add-Check 7 "Memória RAM" $t7_Res $t7_Stat $t7_Rec

# 8. Versão Windows
try {
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    if ([int]$build -lt 19045) { $t8_Stat = "ALERTA"; $t8_Rec = "Atualizar Windows (Build antiga)." }
    else { $t8_Stat = "OK"; $t8_Rec = "Sistema atualizado." }
    $t8_Res = "Build $build"
}
catch { $t8_Res = "Erro"; $t8_Stat = "ALERTA" }
Add-Check 8 "Versão do Windows" $t8_Res $t8_Stat $t8_Rec

# 9. Drivers GPU
try {
    $gpu = Get-CimOrWmi -ClassName Win32_VideoController -First
    $date = [Management.ManagementDateTimeConverter]::ToDateTime($gpu.DriverDate)
    $days = ((Get-Date) - $date).Days
    if ($days -gt 365) { $t9_Stat = "ALERTA"; $t9_Rec = "Atualizar driver de vídeo." }
    else { $t9_Stat = "OK"; $t9_Rec = "Driver recente." }
    $t9_Res = "$days dias"
}
catch { $t9_Res = "Genérico"; $t9_Stat = "ALERTA" }
Add-Check 9 "Drivers GPU" $t9_Res $t9_Stat $t9_Rec

# 10. Inicialização
try {
    $count = (Get-CimOrWmi -ClassName Win32_StartupCommand).Count
    if ($count -gt 8) { $t10_Stat = "ALERTA"; $t10_Rec = "Otimizar inicialização." }
    else { $t10_Stat = "OK"; $t10_Rec = "Boot rápido." }
    $t10_Res = "$count itens"
}
catch { $t10_Res = "Erro"; $t10_Stat = "OK" }
Add-Check 10 "Inicialização" $t10_Res $t10_Stat $t10_Rec

# 11. Temperatura GPU
$t11_Res = "N/A"; $t11_Stat = "OK"; $t11_Rec = "Monitorar sob carga."
try {
    $wmiGPU = Get-CimOrWmi -ClassName MsAcpi_ThermalZoneTemperature -Namespace "root/wmi" -First
    if ($wmiGPU) {
        $val = ($wmiGPU.CurrentTemperature / 10) - 273.15
        if ($val -gt 20 -and $val -lt 120) {
            $t11_Res = "$([math]::Round($val,0)) °C"
            if ($val -ge 85) { $t11_Stat = "CRÍTICO"; $t11_Rec = "Melhorar fluxo de ar." }
            elseif ($val -ge 75) { $t11_Stat = "ALERTA"; $t11_Rec = "Limpeza recomendada." }
        }
    }
    if ($t11_Res -eq "N/A") {
        $gpuName = (Get-CimOrWmi -ClassName Win32_VideoController).Name
        $t11_Res = "$gpuName (Sem Sensor)"
    }
}
catch {}
Add-Check 11 "Temperatura GPU" $t11_Res $t11_Stat $t11_Rec

# 12. Bateria
try {
    $bat = Get-CimOrWmi -ClassName Win32_Battery
    if ($bat) {
        $life = $bat.EstimatedChargeRemaining
        if ($life -lt 70) { $t12_Stat = "ALERTA"; $t12_Rec = "Considerar troca da bateria." }
        else { $t12_Stat = "OK"; $t12_Rec = "Bateria saudável." }
        $t12_Res = "$life% Carga"
    }
    else {
        $t12_Stat = "OK"; $t12_Res = "Desktop (Tomada)"; $t12_Rec = "Energia estável."
    }
}
catch { $t12_Stat = "OK"; $t12_Res = "N/A" }
Add-Check 12 "Bateria" $t12_Res $t12_Stat $t12_Rec

# 13. Windows Update
$t13_Res = "N/A"; $t13_Stat = "ALERTA"; $t13_Rec = "Verificar manualmente."
try {
    Write-Host "   -> Verificando Windows Update..." -NoNewline -ForegroundColor DarkGray
    
    # Método 1: Tentar via COM Object (mais confiável)
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction Stop
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
        $pend = $searchResult.Updates.Count
        
        if ($pend -gt 0) { 
            $t13_Stat = "ALERTA"
            $t13_Rec = "Instalar $pend atualizações pendentes." 
        }
        else { 
            $t13_Stat = "OK"
            $t13_Rec = "Sistema atualizado." 
        }
        $t13_Res = "$pend pendentes"
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        # Método 2: Verificar via registro e serviço
        Write-Host " [Fallback]" -ForegroundColor Yellow
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        
        if ($wuService -and $wuService.Status -eq "Running") {
            # Verifica última verificação de updates
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect"
            $lastCheck = Get-ItemProperty -Path $regPath -Name "LastSuccessTime" -ErrorAction SilentlyContinue
            
            if ($lastCheck) {
                $lastCheckDate = [DateTime]::Parse($lastCheck.LastSuccessTime)
                $daysSince = ((Get-Date) - $lastCheckDate).Days
                
                if ($daysSince -gt 7) {
                    $t13_Stat = "ALERTA"
                    $t13_Res = "Última verificação há $daysSince dias"
                    $t13_Rec = "Executar Windows Update manualmente."
                }
                else {
                    $t13_Stat = "OK"
                    $t13_Res = "Verificado há $daysSince dias"
                    $t13_Rec = "Verificação recente."
                }
            }
            else {
                $t13_Res = "Serviço ativo"
                $t13_Stat = "OK"
                $t13_Rec = "Windows Update funcionando."
            }
        }
        else {
            $t13_Res = "Serviço Windows Update parado"
            $t13_Stat = "CRÍTICO"
            $t13_Rec = "Iniciar serviço Windows Update."
        }
    }
}
catch { 
    $t13_Res = "Erro na verificação"
    $t13_Stat = "ALERTA"
    $t13_Rec = "Verificar Windows Update manualmente." 
}
Add-Check 13 "Windows Update" $t13_Res $t13_Stat $t13_Rec

# 14. Integridade do Sistema (SFC/DISM)
$t14_Res = "N/A"; $t14_Stat = "OK"; $t14_Rec = "Sistema íntegro."
try {
    Write-Host "   -> Verificando integridade do sistema..." -NoNewline -ForegroundColor DarkGray
    
    # Verifica logs do SFC anteriores
    $sfcLog = "$env:windir\Logs\CBS\CBS.log"
    if (Test-Path $sfcLog) {
        $recentLog = Get-Content $sfcLog -Tail 100 -ErrorAction SilentlyContinue
        if ($recentLog -match "corrupt|violation|failed") {
            $t14_Stat = "CRÍTICO"
            $t14_Res = "Corrupção detectada"
            $t14_Rec = "Executar: sfc /scannow e DISM /RestoreHealth"
            Write-Host " [CORRUPTO]" -ForegroundColor Red
        }
        else {
            # Executa verificação rápida DISM
            $dismCheck = & dism.exe /Online /Cleanup-Image /CheckHealth 2>&1
            if ($dismCheck -match "No component store corruption detected") {
                $t14_Res = "Sistema íntegro (DISM)"
                $t14_Stat = "OK"
                $t14_Rec = "Arquivos do sistema OK."
                Write-Host " [OK]" -ForegroundColor Green
            }
            elseif ($dismCheck -match "repairable|corruption") {
                $t14_Stat = "ALERTA"
                $t14_Res = "Corrupção reparável"
                $t14_Rec = "Executar: DISM /RestoreHealth"
                Write-Host " [REPARÁVEL]" -ForegroundColor Yellow
            }
            else {
                $t14_Res = "Verificação OK"
                $t14_Stat = "OK"
                Write-Host " [OK]" -ForegroundColor Green
            }
        }
    }
    else {
        $t14_Res = "Log não encontrado"
        $t14_Stat = "OK"
        Write-Host " [N/D]" -ForegroundColor Gray
    }
}
catch { 
    $t14_Res = "Erro na verificação"
    $t14_Stat = "ALERTA"
    $t14_Rec = "Executar sfc /scannow manualmente."
}
Add-Check 14 "Integridade Sistema" $t14_Res $t14_Stat $t14_Rec

# 15. Eventos Críticos do Sistema
$t15_Res = "N/A"; $t15_Stat = "OK"; $t15_Rec = "Sistema estável."
try {
    Write-Host "   -> Analisando eventos críticos..." -NoNewline -ForegroundColor DarkGray
    
    $horasAtras = (Get-Date).AddHours(-48)
    
    # Eventos críticos de System e Application
    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'System', 'Application'
        Level     = 1, 2  # Critical e Error
        StartTime = $horasAtras
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    
    # Verifica BSODs (Event ID 41 - Kernel-Power, 1001 - BugCheck)
    $bsodEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        ID        = 41, 1001
        StartTime = $horasAtras
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    
    $totalErrors = $criticalEvents + $bsodEvents
    
    if ($bsodEvents -gt 0) {
        $t15_Stat = "CRÍTICO"
        $t15_Res = "$bsodEvents BSOD(s), $criticalEvents erros"
        $t15_Rec = "Investigar causa de travamentos."
        Write-Host " [BSOD]" -ForegroundColor Red
    }
    elseif ($totalErrors -gt 10) {
        $t15_Stat = "CRÍTICO"
        $t15_Res = "$totalErrors erros críticos"
        $t15_Rec = "Verificar Event Viewer urgente."
        Write-Host " [MUITOS ERROS]" -ForegroundColor Red
    }
    elseif ($totalErrors -gt 3) {
        $t15_Stat = "ALERTA"
        $t15_Res = "$totalErrors erros (48h)"
        $t15_Rec = "Revisar Event Viewer."
        Write-Host " [ALERTA]" -ForegroundColor Yellow
    }
    else {
        $t15_Res = "$totalErrors erros (48h)"
        $t15_Stat = "OK"
        $t15_Rec = "Poucos erros registrados."
        Write-Host " [OK]" -ForegroundColor Green
    }
}
catch { 
    $t15_Res = "Erro ao ler eventos"
    $t15_Stat = "ALERTA"
    $t15_Rec = "Verificar Event Viewer manualmente."
}
Add-Check 15 "Eventos Críticos" $t15_Res $t15_Stat $t15_Rec

# 16. Antivírus/Windows Defender
$t16_Res = "N/A"; $t16_Stat = "ALERTA"; $t16_Rec = "Verificar proteção."
try {
    Write-Host "   -> Verificando Windows Defender..." -NoNewline -ForegroundColor DarkGray
    
    # Verifica status do Windows Defender
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    
    if ($defender) {
        $realtimeEnabled = $defender.RealTimeProtectionEnabled
        $lastScan = $defender.QuickScanAge
        $sigAge = $defender.AntivirusSignatureAge
        
        if (-not $realtimeEnabled) {
            $t16_Stat = "CRÍTICO"
            $t16_Res = "Proteção em tempo real DESATIVADA"
            $t16_Rec = "ATIVAR Windows Defender imediatamente!"
            Write-Host " [DESATIVADO]" -ForegroundColor Red
        }
        elseif ($sigAge -gt 7) {
            $t16_Stat = "ALERTA"
            $t16_Res = "Definições desatualizadas ($sigAge dias)"
            $t16_Rec = "Atualizar definições de vírus."
            Write-Host " [DESATUALIZADO]" -ForegroundColor Yellow
        }
        elseif ($lastScan -gt 14) {
            $t16_Stat = "ALERTA"
            $t16_Res = "Ativo, última varredura há $lastScan dias"
            $t16_Rec = "Executar varredura completa."
            Write-Host " [SCAN ANTIGO]" -ForegroundColor Yellow
        }
        else {
            $t16_Stat = "OK"
            $t16_Res = "Ativo e atualizado (Scan: $lastScan dias)"
            $t16_Rec = "Proteção funcionando."
            Write-Host " [OK]" -ForegroundColor Green
        }
    }
    else {
        # Verifica se há outro antivírus instalado
        $avList = Get-CimOrWmi -ClassName AntiVirusProduct -Namespace "root/SecurityCenter2"
        if ($avList) {
            $activeAV = $avList | Where-Object { $_.productState -band 0x1000 }
            if ($activeAV) {
                $t16_Res = "$($activeAV.displayName) ativo"
                $t16_Stat = "OK"
                $t16_Rec = "Antivírus de terceiro detectado."
                Write-Host " [3RD PARTY]" -ForegroundColor Green
            }
            else {
                $t16_Res = "Nenhum antivírus ativo"
                $t16_Stat = "CRÍTICO"
                $t16_Rec = "Sistema desprotegido!"
                Write-Host " [SEM PROTEÇÃO]" -ForegroundColor Red
            }
        }
        else {
            $t16_Res = "Não detectado"
            $t16_Stat = "CRÍTICO"
            $t16_Rec = "Ativar proteção antivírus."
            Write-Host " [N/D]" -ForegroundColor Red
        }
    }
}
catch { 
    $t16_Res = "Erro na verificação"
    $t16_Stat = "ALERTA"
    $t16_Rec = "Verificar antivírus manualmente."
}
Add-Check 16 "Antivírus/Defender" $t16_Res $t16_Stat $t16_Rec

# 17. Rede/Conectividade
$t17_Res = "N/A"; $t17_Stat = "ALERTA"; $t17_Rec = "Verificar conexão."
try {
    Write-Host "   -> Testando conectividade..." -NoNewline -ForegroundColor DarkGray
    
    # Verifica adaptador de rede
    $adapter = Get-NetworkAdapter -Status "Up" | Where-Object { $_.PhysicalMediaType -ne "Unspecified" } | Select-Object -First 1
    
    if ($adapter) {
        # Teste de ping para Google DNS
        $pingTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet -ErrorAction SilentlyContinue
        
        if ($pingTest) {
            $pingStats = Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue
            $avgLatency = ($pingStats | Measure-Object -Property ResponseTime -Average).Average
            
            # Teste DNS
            $dnsTest = Resolve-DnsName google.com -ErrorAction SilentlyContinue
            
            if ($dnsTest) {
                if ($avgLatency -gt 100) {
                    $t17_Stat = "ALERTA"
                    $t17_Res = "Conectado, latência alta ($([math]::Round($avgLatency))ms)"
                    $t17_Rec = "Verificar qualidade da conexão."
                    Write-Host " [LENTO]" -ForegroundColor Yellow
                }
                else {
                    $t17_Stat = "OK"
                    $t17_Res = "Conectado ($([math]::Round($avgLatency))ms)"
                    $t17_Rec = "Rede funcionando bem."
                    Write-Host " [OK]" -ForegroundColor Green
                }
            }
            else {
                $t17_Stat = "ALERTA"
                $t17_Res = "Ping OK, DNS com problemas"
                $t17_Rec = "Verificar configurações DNS."
                Write-Host " [DNS FALHOU]" -ForegroundColor Yellow
            }
        }
        else {
            $t17_Stat = "CRÍTICO"
            $t17_Res = "Sem conectividade com Internet"
            $t17_Rec = "Verificar cabo/WiFi e roteador."
            Write-Host " [SEM INTERNET]" -ForegroundColor Red
        }
    }
    else {
        $t17_Stat = "CRÍTICO"
        $t17_Res = "Nenhum adaptador ativo"
        $t17_Rec = "Conectar cabo de rede ou WiFi."
        Write-Host " [DESCONECTADO]" -ForegroundColor Red
    }
}
catch { 
    $t17_Res = "Erro no teste"
    $t17_Stat = "ALERTA"
    $t17_Rec = "Verificar rede manualmente."
}
Add-Check 17 "Rede/Conectividade" $t17_Res $t17_Stat $t17_Rec

# 18. Serviços Críticos do Windows
$t18_Res = "N/A"; $t18_Stat = "OK"; $t18_Rec = "Serviços OK."
try {
    Write-Host "   -> Verificando serviços críticos..." -NoNewline -ForegroundColor DarkGray
    
    $criticalServices = @(
        @{Name = "wuauserv"; Display = "Windows Update" },
        @{Name = "WinDefend"; Display = "Windows Defender" },
        @{Name = "BITS"; Display = "BITS" },
        @{Name = "WSearch"; Display = "Windows Search" },
        @{Name = "W32Time"; Display = "Horário Windows" }
    )
    
    $stoppedServices = @()
    $runningCount = 0
    
    foreach ($svc in $criticalServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -ne "Running") {
                $stoppedServices += $svc.Display
            }
            else {
                $runningCount++
            }
        }
    }
    
    $stoppedCount = $stoppedServices.Count
    
    if ($stoppedCount -gt 2) {
        $t18_Stat = "CRÍTICO"
        $t18_Res = "$stoppedCount serviços parados"
        $t18_Rec = "Iniciar: $($stoppedServices -join ', ')"
        Write-Host " [CRÍTICO]" -ForegroundColor Red
    }
    elseif ($stoppedCount -gt 0) {
        $t18_Stat = "ALERTA"
        $t18_Res = "$stoppedCount parado(s): $($stoppedServices -join ', ')"
        $t18_Rec = "Verificar serviços parados."
        Write-Host " [ALERTA]" -ForegroundColor Yellow
    }
    else {
        $t18_Stat = "OK"
        $t18_Res = "Todos os 5 serviços ativos"
        $t18_Rec = "Serviços funcionando."
        Write-Host " [OK]" -ForegroundColor Green
    }
}
catch { 
    $t18_Res = "Erro na verificação"
    $t18_Stat = "ALERTA"
    $t18_Rec = "Verificar services.msc manualmente."
}
Add-Check 18 "Serviços Críticos" $t18_Res $t18_Stat $t18_Rec

# 19. Fragmentação do Disco
$t19_Res = "N/A"; $t19_Stat = "OK"; $t19_Rec = "Disco otimizado."
try {
    Write-Host "   -> Verificando fragmentação..." -NoNewline -ForegroundColor DarkGray
    
    # Detecta tipo de disco (SSD vs HDD)
    $disk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | Select-Object -First 1
    $isSSD = $disk.MediaType -eq "SSD"
    
    if ($isSSD) {
        # Para SSD, verifica otimização (TRIM)
        $optimizeInfo = Get-ScheduledTask -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
        if ($optimizeInfo -and $optimizeInfo.State -ne "Disabled") {
            $t19_Res = "SSD - Otimização automática ativa"
            $t19_Stat = "OK"
            $t19_Rec = "TRIM configurado."
            Write-Host " [SSD OK]" -ForegroundColor Green
        }
        else {
            $t19_Res = "SSD - Otimização desabilitada"
            $t19_Stat = "ALERTA"
            $t19_Rec = "Habilitar otimização automática."
            Write-Host " [SSD SEM TRIM]" -ForegroundColor Yellow
        }
    }
    else {
        # Para HDD, tenta obter nível de fragmentação
        try {
            $defragReport = defrag C: /A /V 2>&1
            if ($defragReport -match "(\d+)%.*fragmented") {
                $fragPercent = [int]$matches[1]
                if ($fragPercent -gt 15) {
                    $t19_Stat = "ALERTA"
                    $t19_Res = "HDD $fragPercent% fragmentado"
                    $t19_Rec = "Desfragmentar disco C:"
                    Write-Host " [FRAGMENTADO]" -ForegroundColor Yellow
                }
                else {
                    $t19_Stat = "OK"
                    $t19_Res = "HDD $fragPercent% fragmentado"
                    $t19_Rec = "Fragmentação aceitável."
                    Write-Host " [OK]" -ForegroundColor Green
                }
            }
            else {
                $t19_Res = "HDD - Análise indisponível"
                $t19_Stat = "OK"
                Write-Host " [N/D]" -ForegroundColor Gray
            }
        }
        catch {
            $t19_Res = "HDD - Verificar manualmente"
            $t19_Stat = "OK"
            Write-Host " [N/D]" -ForegroundColor Gray
        }
    }
}
catch { 
    $t19_Res = "Erro na verificação"
    $t19_Stat = "OK"
    $t19_Rec = "Verificar otimização de disco."
}
Add-Check 19 "Fragmentação Disco" $t19_Res $t19_Stat $t19_Rec

# 20. Firewall
$t20_Res = "N/A"; $t20_Stat = "ALERTA"; $t20_Rec = "Verificar firewall."
try {
    Write-Host "   -> Verificando firewall..." -NoNewline -ForegroundColor DarkGray
    
    $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    
    if ($firewallProfiles) {
        $disabledProfiles = $firewallProfiles | Where-Object { $_.Enabled -eq $false }
        
        if ($disabledProfiles.Count -eq 3) {
            $t20_Stat = "CRÍTICO"
            $t20_Res = "Firewall DESATIVADO (todos perfis)"
            $t20_Rec = "ATIVAR firewall imediatamente!"
            Write-Host " [DESATIVADO]" -ForegroundColor Red
        }
        elseif ($disabledProfiles.Count -gt 0) {
            $t20_Stat = "ALERTA"
            $t20_Res = "$($disabledProfiles.Count) perfil(is) desativado(s)"
            $t20_Rec = "Ativar todos os perfis de firewall."
            Write-Host " [PARCIAL]" -ForegroundColor Yellow
        }
        else {
            $t20_Stat = "OK"
            $t20_Res = "Ativo em todos os perfis"
            $t20_Rec = "Firewall protegendo o sistema."
            Write-Host " [OK]" -ForegroundColor Green
        }
    }
    else {
        $t20_Res = "Não detectado"
        $t20_Stat = "CRÍTICO"
        $t20_Rec = "Verificar firewall manualmente."
        Write-Host " [N/D]" -ForegroundColor Red
    }
}
catch { 
    $t20_Res = "Erro na verificação"
    $t20_Stat = "ALERTA"
    $t20_Rec = "Verificar firewall.cpl manualmente."
}
Add-Check 20 "Firewall Windows" $t20_Res $t20_Stat $t20_Rec

# 21. Fontes de Energia
$t21_Res = "N/A"; $t21_Stat = "OK"; $t21_Rec = "Configuração adequada."
try {
    Write-Host "   -> Verificando energia..." -NoNewline -ForegroundColor DarkGray
    
    # Verifica plano de energia ativo
    $activePlan = powercfg /getactivescheme
    
    if ($activePlan -match "Balanced|Equilibrado") {
        $planName = "Equilibrado"
        $t21_Stat = "OK"
    }
    elseif ($activePlan -match "High performance|Alto desempenho") {
        $planName = "Alto Desempenho"
        $t21_Stat = "OK"
    }
    elseif ($activePlan -match "Power saver|Economia de energia") {
        $planName = "Economia de Energia"
        $t21_Stat = "ALERTA"
        $t21_Rec = "Modo economia pode reduzir performance."
    }
    else {
        $planName = "Personalizado"
        $t21_Stat = "OK"
    }
    
    # Verifica se é laptop
    $battery = Get-CimOrWmi -ClassName Win32_Battery
    if ($battery) {
        $batteryPercent = $battery.EstimatedChargeRemaining
        $t21_Res = "Laptop - $planName ($batteryPercent% bateria)"
        
        if ($planName -eq "Alto Desempenho" -and $batteryPercent -lt 50) {
            $t21_Stat = "ALERTA"
            $t21_Rec = "Considerar modo Equilibrado para economizar bateria."
        }
    }
    else {
        $t21_Res = "Desktop - $planName"
        $t21_Rec = "Configuração adequada para desktop."
    }
    
    Write-Host " [OK]" -ForegroundColor Green
}
catch { 
    $t21_Res = "Erro na verificação"
    $t21_Stat = "OK"
    $t21_Rec = "Verificar powercfg.cpl manualmente."
}
Add-Check 21 "Fontes de Energia" $t21_Res $t21_Stat $t21_Rec

# 22. Certificados Expirados
$t22_Res = "N/A"; $t22_Stat = "OK"; $t22_Rec = "Certificados válidos."
try {
    Write-Host "   -> Verificando certificados..." -NoNewline -ForegroundColor DarkGray
    
    # Verifica certificados expirados no sistema
    $expiredCerts = @()
    
    # Verifica CurrentUser
    $userCerts = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue | Where-Object { $_.NotAfter -lt (Get-Date) }
    if ($userCerts) { $expiredCerts += $userCerts }
    
    # Verifica LocalMachine (apenas Root e CA)
    $machineCerts = Get-ChildItem Cert:\LocalMachine\Root, Cert:\LocalMachine\CA -ErrorAction SilentlyContinue | Where-Object { $_.NotAfter -lt (Get-Date) }
    if ($machineCerts) { $expiredCerts += $machineCerts }
    
    if ($expiredCerts.Count -gt 5) {
        $t22_Stat = "ALERTA"
        $t22_Res = "$($expiredCerts.Count) certificados expirados"
        $t22_Rec = "Limpar certificados antigos (certmgr.msc)."
        Write-Host " [EXPIRADOS]" -ForegroundColor Yellow
    }
    elseif ($expiredCerts.Count -gt 0) {
        $t22_Stat = "OK"
        $t22_Res = "$($expiredCerts.Count) certificados expirados"
        $t22_Rec = "Poucos certificados expirados, OK."
        Write-Host " [OK]" -ForegroundColor Green
    }
    else {
        $t22_Res = "Nenhum certificado expirado"
        $t22_Stat = "OK"
        $t22_Rec = "Certificados em dia."
        Write-Host " [OK]" -ForegroundColor Green
    }
}
catch { 
    $t22_Res = "Erro na verificação"
    $t22_Stat = "OK"
    $t22_Rec = "Verificar certmgr.msc se houver problemas SSL."
}
Add-Check 22 "Certificados" $t22_Res $t22_Stat $t22_Rec

# 23. Uptime do Sistema
$t23_Res = "N/A"; $t23_Stat = "OK"; $t23_Rec = "Uptime normal."
try {
    Write-Host "   -> Verificando uptime..." -NoNewline -ForegroundColor DarkGray
    
    # Calcula uptime
    $os = Get-CimOrWmi -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    $uptimeDays = [math]::Round($uptime.TotalDays, 1)
    
    # Verifica reinicializações recentes (últimos 7 dias)
    $rebootEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        ID        = 1074, 6006, 6008  # Shutdown, proper shutdown, unexpected shutdown
        StartTime = (Get-Date).AddDays(-7)
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($uptimeDays -gt 30) {
        $t23_Stat = "ALERTA"
        $t23_Res = "$uptimeDays dias sem reiniciar"
        $t23_Rec = "Reiniciar para aplicar updates e limpar memória."
        Write-Host " [MUITO TEMPO]" -ForegroundColor Yellow
    }
    elseif ($rebootEvents -gt 10) {
        $t23_Stat = "ALERTA"
        $t23_Res = "$uptimeDays dias, $rebootEvents reboots/semana"
        $t23_Rec = "Muitas reinicializações, investigar causa."
        Write-Host " [INSTÁVEL]" -ForegroundColor Yellow
    }
    else {
        $t23_Stat = "OK"
        $t23_Res = "$uptimeDays dias, $rebootEvents reboots/semana"
        $t23_Rec = "Uptime saudável."
        Write-Host " [OK]" -ForegroundColor Green
    }
}
catch { 
    $t23_Res = "Erro no cálculo"
    $t23_Stat = "OK"
    $t23_Rec = "Verificar systeminfo manualmente."
}
Add-Check 23 "Uptime Sistema" $t23_Res $t23_Stat $t23_Rec

# --- CÁLCULO DA NOTA GERAL DA MÁQUINA (0-100) ---
Write-Host "`n[*] Calculando nota geral da máquina..." -ForegroundColor Cyan
$totalChecks = $Resultados.Count
$okCount = ($Resultados | Where-Object { $_.Status -eq "OK" }).Count
$alertCount = ($Resultados | Where-Object { $_.Status -eq "ALERTA" }).Count
$criticalCount = ($Resultados | Where-Object { $_.Status -eq "CRÍTICO" }).Count

# Cálculo ponderado: OK = 100%, ALERTA = 50%, CRÍTICO = 0%
$scorePoints = ($okCount * 100) + ($alertCount * 50) + ($criticalCount * 0)
$maxPoints = $totalChecks * 100
$healthScore = [math]::Round(($scorePoints / $maxPoints) * 100, 0)

# Determina classificação
$scoreClass = if ($healthScore -ge 80) { "EXCELENTE" } 
elseif ($healthScore -ge 60) { "BOM" } 
elseif ($healthScore -ge 40) { "REGULAR" } 
else { "CRÍTICO" }

$scoreColor = if ($healthScore -ge 80) { "Green" } 
elseif ($healthScore -ge 60) { "Yellow" } 
else { "Red" }

Write-Host "Nota Geral: $healthScore/100 - $scoreClass" -ForegroundColor $scoreColor
Write-Host "  ✅ OK: $okCount | ⚠️ Alertas: $alertCount | ❌ Críticos: $criticalCount" -ForegroundColor Gray

# --- GERAÇÃO HTML & PDF ---
$Rows = ""
foreach ($item in $Resultados) {
    $classCSS = "status-" + $item.Status.ToLower().Replace("í", "i").Replace("Ó", "O") 
    $Rows += "<tr>
        <td>$($item.ID)</td>
        <td>$($item.Verificacao)</td>
        <td>$($item.Resultado)</td>
        <td class='$classCSS'>$($item.Icone) $($item.Status)</td>
        <td>$($item.Recomendacao)</td>
    </tr>"
}

$Style = @"
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; padding: 20px; }
    .container { max-width: 950px; margin: auto; background: white; padding: 35px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.12); }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 4px solid #003D7A; padding-bottom: 20px; margin-bottom: 25px; }
    .header h1 { color: #003D7A; margin: 0; font-size: 28px; font-weight: 700; }
    .header p { color: #666; margin: 5px 0 0 0; font-size: 14px; }
    .score-box { background: linear-gradient(135deg, #EC7000 0%, #FF8C1A 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; margin-bottom: 25px; box-shadow: 0 3px 10px rgba(236, 112, 0, 0.3); }
    .score-box h2 { margin: 0 0 10px 0; font-size: 48px; font-weight: 700; }
    .score-box p { margin: 0; font-size: 16px; opacity: 0.95; }
    .score-details { display: flex; justify-content: space-around; margin-top: 15px; font-size: 14px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th { background: #003D7A; color: white; padding: 12px; text-align: left; font-size: 13px; text-transform: uppercase; font-weight: 600; }
    td { padding: 12px; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #333; }
    tr:nth-child(even) { background-color: #fafafa; }
    tr:hover { background-color: #f0f0f0; }
    .status-ok { color: #27ae60; font-weight: bold; }
    .status-alerta { color: #EC7000; font-weight: bold; }
    .status-critico { color: #c0392b; font-weight: bold; background-color: #fff5f5; }
    .wa-btn { display: block; background: #25d366; color: white; text-align: center; padding: 16px; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 30px; font-size: 16px; transition: background 0.3s; }
    .wa-btn:hover { background: #1fb855; }
    .footer { text-align: center; margin-top: 25px; font-size: 11px; color: #999; border-top: 1px solid #e8e8e8; padding-top: 15px; }
    .info-row { font-size: 12px; color: #666; }
</style>
"@

$html = @"
<!DOCTYPE html>
<html>
<head><meta charset='UTF-8'>$Style</head>
<body>
    <div class='container'>
        <div class='header'>
            <div><h1>RELATÓRIO TÉCNICO HPinfo</h1><p>Diagnóstico Completo do Sistema</p></div>
            <div style='text-align:right;' class='info-row'>
                <strong>OS/Cliente:</strong> $OSNumber<br>
                <strong>Computador:</strong> $ComputerName<br>
                <strong>Usuário:</strong> $env:USERNAME<br>
                <strong>Data:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm')
            </div>
        </div>
        <div class='score-box'>
            <h2>$healthScore/100</h2>
            <p>NOTA GERAL DA MÁQUINA - $scoreClass</p>
            <div class='score-details'>
                <span>✅ OK: $okCount</span>
                <span>⚠️ Alertas: $alertCount</span>
                <span>❌ Críticos: $criticalCount</span>
            </div>
        </div>
        <table>
            <thead><tr><th>#</th><th>Verificação</th><th>Resultado</th><th>Status</th><th>Recomendação</th></tr></thead>
            <tbody>$Rows</tbody>
        </table>
        <a href='$WhatsAppLink' class='wa-btn'>📲 FALAR COM SUPORTE TÉCNICO HPinfo</a>
        <div class='footer'>HPinfo Tecnologia | Relatório gerado automaticamente | www.hpinfo.com.br</div>
    </div>
</body>
</html>
"@

$html | Out-File $ReportHTML -Encoding UTF8
Write-Host "[OK] Relatório HTML Gerado em: $ReportHTML" -ForegroundColor Green

# Abrir relatório automaticamente
Write-Host "[*] Abrindo relatório..." -ForegroundColor Cyan
Invoke-Item $ReportHTML
