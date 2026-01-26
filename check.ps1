<#
.SYNOPSIS
    Check-up HPTI Master v7.4 - Verificação Aprimorada de Licenciamento
.DESCRIPTION
    - Verificação completa de licenciamento Windows com múltiplos métodos
    - Mantém todas as 13 verificações originais
    - Corrige erro fatal do 'if' no PowerShell 5.1.
#>

$ErrorActionPreference = "SilentlyContinue"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# --- CONFIGURAÇÕES ---
$ComputerName = $env:COMPUTERNAME
$ReportHTML   = "$env:TEMP\Checkup_HPTI_Final.html"
$ReportPDF    = "$env:USERPROFILE\Desktop\Diagnostico_HPTI_$ComputerName.pdf"
$WhatsAppLink = "https://wa.me/556235121468?text=Ola%20HPTI,%20segue%20o%20relatorio%20do%20PC%20$ComputerName"

$repoBase     = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir      = "$env:TEMP\HP-Tools"
$7zipExe      = "$tempDir\7z.exe"
$Password     = "0"

# --- PREPARAÇÃO ---
Write-Host "[*] Iniciando Diagnóstico HPTI v7.4..." -ForegroundColor Cyan

if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

function Baixar-Ferramenta ($nomeArquivo) {
    $destino = "$tempDir\$nomeArquivo"
    if (Test-Path $destino) { return $true }
    try {
        Write-Host "Baixando $nomeArquivo..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri "$repoBase/$nomeArquivo" -OutFile $destino -TimeoutSec 15 -ErrorAction Stop
        return $true
    } catch { return $false }
}

Baixar-Ferramenta "7z.txe"
if (Test-Path "$tempDir\7z.txe") { Copy-Item "$tempDir\7z.txe" $7zipExe -Force }

$Tools = @(
    @{ Name = "CoreTemp"; Archive = "CoreTemp.7z"; SubFolder = "CoreTemp" }
    @{ Name = "CrystalDiskInfo"; Archive = "CrystalDiskInfo.7z"; SubFolder = "CrystalDiskInfo" }
)

$ExtractedPaths = @{}
if (Test-Path $7zipExe) {
    foreach ($tool in $Tools) {
        $pasta = Join-Path $tempDir $tool.SubFolder
        if (Baixar-Ferramenta $tool.Archive) {
            if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Path $pasta -Force | Out-Null }
            & $7zipExe x "$tempDir\$($tool.Archive)" -o"$pasta" -p"$Password" -y | Out-Null
            $ExtractedPaths[$tool.Name] = $pasta
        }
    }
}

# --- LISTA DE RESULTADOS ---
$Resultados = New-Object System.Collections.Generic.List[PSCustomObject]

function Add-Check ($ID, $Nome, $Res, $Stat, $Rec) {
    if ([string]::IsNullOrWhiteSpace($Res)) { $Res = "Não Detectado" }
    $Icone = switch($Stat) { "OK"{"✅"} "ALERTA"{"⚠️"} "CRÍTICO"{"❌"} default{"❓"} }
    
    $obj = [PSCustomObject]@{
        ID = $ID
        Verificacao = $Nome
        Resultado = $Res
        Status = $Stat
        Icone = $Icone
        Recomendacao = $Rec
    }
    $Resultados.Add($obj)
    
    # --- CORREÇÃO OBRIGATÓRIA PARA PS 5.1 ---
    # O cálculo da cor TEM que ser feito fora do Write-Host
    $CorConsole = "Green"
    if ($Stat -ne "OK") { $CorConsole = "Yellow" }
    
    Write-Host "[$Stat] ${Nome}: $Res" -ForegroundColor $CorConsole
}

Write-Host "`n--- EXECUTANDO 13 CHECAGENS ---" -ForegroundColor Yellow

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
        } else { Write-Host " Falha (Sem Log)" -ForegroundColor Red }
    }
    
    if ($t1_Res -eq "N/A") {
        $wmi = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($wmi) {
            $val = ($wmi.CurrentTemperature / 10) - 273.15
            $t1_Res = "$([math]::Round($val,0)) °C (WMI)"
            $t1_Stat = if ($val -ge 85) { "CRÍTICO" } elseif ($val -ge 70) { "ALERTA" } else { "OK" }
            $t1_Rec = if ($t1_Stat -eq "OK") { "Refrigeração OK." } else { "Limpeza + Pasta Térmica." }
        }
    }
} catch { $t1_Res = "Erro Coleta" }
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
                if ($statusReal -match "Good|Saudável") { $t2_Stat="OK"; $t2_Rec="Disco Saudável." } 
                else { $t2_Stat="CRÍTICO"; $t2_Rec="Risco de perda de dados. Trocar disco." }
            }
        }
    }
    if ($t2_Res -eq "Desconhecido") {
        $disk = Get-CimInstance Win32_DiskDrive | Select -First 1
        $t2_Res = $disk.Status
        if ($disk.Status -eq "OK") { $t2_Stat="OK"; $t2_Rec="Status WMI OK." } else { $t2_Stat="CRÍTICO"; $t2_Rec="Erro detectado." }
    }
} catch {}
Add-Check 2 "Saúde Física (SMART)" $t2_Res $t2_Stat $t2_Rec

# 3. Espaço Livre
$t3_Res = ""; $t3_Stat = "OK"; $t3_Rec = "Espaço suficiente."
try {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($d in $disks) {
        $pct = [math]::Round(($d.FreeSpace / $d.Size) * 100, 1)
        $t3_Res += "$($d.DeviceID) $pct% | "
        if ($pct -lt 15) { $t3_Stat = "CRÍTICO"; $t3_Rec = "Limpeza urgente." }
        elseif ($pct -lt 25 -and $t3_Stat -ne "CRÍTICO") { $t3_Stat = "ALERTA"; $t3_Rec = "Considerar upgrade." }
    }
    $t3_Res = $t3_Res.TrimEnd(" | ")
} catch { $t3_Res = "Erro leitura" }
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
                } catch {}
            }
        }
    }
    
    if ($hackFound) {
        $t4_Stat = "CRÍTICO"
        $t4_Res = "Pirataria Detectada"
        $t4_Rec = "Remover ativadores ilegais imediatamente."
        Write-Host " [PIRATARIA]" -ForegroundColor Red
    } else {
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
            } else {
                # Verifica se está ativado
                $regStatus = Get-ItemProperty -Path $regPath -Name "NotificationDisabled" -ErrorAction SilentlyContinue
                $digitalProductId = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DigitalProductId" -ErrorAction SilentlyContinue
                
                if ($digitalProductId -and $digitalProductId.DigitalProductId) {
                    $t4_Res = "Ativado (Registro)"
                    $t4_Stat = "OK"
                    $t4_Rec = "Licença válida detectada"
                    Write-Host " [ATIVADO]" -ForegroundColor Green
                } else {
                    Write-Host " [NÃO ATIVADO]" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host " [ERRO REG]" -ForegroundColor Red
        }
        
        # MÉTODO 3: Verificação via WMI Licensing (se ainda não tem resultado)
        if ([string]::IsNullOrWhiteSpace($t4_Res) -or $t4_Res -eq "Ativado (Registro)") {
            Write-Host "   -> Verificando via WMI..." -NoNewline -ForegroundColor DarkGray
            try {
                $license = Get-WmiObject -Class SoftwareLicensingProduct -Namespace "root\cimv2" -ErrorAction SilentlyContinue | 
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
                    } else {
                        $t4_Res = "Ativado ($licenseType)"
                        $t4_Stat = "OK"
                        $t4_Rec = "Status WMI: $($license.LicenseStatus)"
                    }
                    Write-Host " [$licenseType]" -ForegroundColor Green
                } else {
                    Write-Host " [N/D]" -ForegroundColor Yellow
                }
            } catch {
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
                } elseif ($outputString -match "error|não encontrado") {
                    Write-Host " [COMANDO N/D]" -ForegroundColor Yellow
                } else {
                    Write-Host " [NÃO ATIVADO]" -ForegroundColor Red
                }
            } catch {
                Write-Host " [ERRO]" -ForegroundColor Red
            }
        }
        
        # Se ainda não tem resultado, verifica chave BIOS
        if ([string]::IsNullOrWhiteSpace($t4_Res)) {
            Write-Host "   -> Verificando chave BIOS..." -NoNewline -ForegroundColor DarkGray
            try {
                $biosKey = (Get-CimInstance SoftwareLicensingService -ErrorAction SilentlyContinue).OA3xOriginalProductKey
                if ($biosKey) {
                    $t4_Res = "Chave BIOS Detectada"
                    $t4_Stat = "ALERTA"
                    $t4_Rec = "Ativar usando chave da BIOS"
                    Write-Host " [CHAVE BIOS]" -ForegroundColor Yellow
                } else {
                    $t4_Res = "Não Ativado"
                    $t4_Stat = "CRÍTICO"
                    $t4_Rec = "Ativação necessária"
                    Write-Host " [NÃO ATIVADO]" -ForegroundColor Red
                }
            } catch {
                $t4_Res = "Erro na verificação"
                $t4_Stat = "ALERTA"
                $t4_Rec = "Verificar manualmente"
                Write-Host " [ERRO]" -ForegroundColor Red
            }
        }
    }
    
} catch {
    $t4_Res = "Erro Leitura"
    $t4_Stat = "ALERTA"
    $t4_Rec = "Verificar manualmente."
    Write-Host "   -> [ERRO GLOBAL]" -ForegroundColor Red
}
Add-Check 4 "Licenciamento Windows" $t4_Res $t4_Stat $t4_Rec

# 5. Pacote Office
try {
    $officeReg = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match "Microsoft (Office|365|Word)" } | Select-Object -First 1
    $officeName = if ($officeReg) { $officeReg.DisplayName } else { $null }
    $officeAct = Get-CimInstance SoftwareLicensingProduct -Filter "Description like '%Office%' AND PartialProductKey IS NOT NULL" | Where-Object LicenseStatus -eq 1
    
    if ($officeName) {
        $cleanName = $officeName -replace "Microsoft ", "" -replace "Standard ", "" -replace "Professional Plus", "Pro Plus"
        if ($officeAct) { 
            $t5_Stat="OK"; $t5_Res="$cleanName (Ativo)"; $t5_Rec="Pronto para uso." 
        } else { 
            $t5_Stat="ALERTA"; $t5_Res="$cleanName (Verificar Ativ.)"; $t5_Rec="Confirmar ativação." 
        }
    } else {
        $t5_Stat="ALERTA"; $t5_Res="Não instalado"; $t5_Rec="Ofertar pacote Office."
    }
} catch { $t5_Stat="ALERTA"; $t5_Res="Erro"; $t5_Rec="Verificar manualmente." }
Add-Check 5 "Pacote Office" $t5_Res $t5_Stat $t5_Rec

# 6. Bloatware
try {
    $junk = "*WebCompanion*","*McAfee*","*Norton*","*Baidu*","*Segurazo*","*Avast*"
    $apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
    $found = $apps | Where { $n=$_.DisplayName; $junk | Where { $n -like $_ } }
    if ($found) { $t6_Stat="ALERTA"; $t6_Res="Detectado"; $t6_Rec="Remover programas desnecessários." }
    else { $t6_Stat="OK"; $t6_Res="Limpo"; $t6_Rec="Sistema otimizado." }
} catch { $t6_Stat="OK"; $t6_Res="N/A" }
Add-Check 6 "Bloatware / Lixo" $t6_Res $t6_Stat $t6_Rec

# 7. Memória RAM
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 0)
    if ($usedPct -gt 85) { $t7_Stat="ALERTA"; $t7_Rec="Fechar programas ou add RAM." }
    else { $t7_Stat="OK"; $t7_Rec="Uso dentro do normal." }
    $t7_Res = "$usedPct% em uso"
} catch { $t7_Res="Erro"; $t7_Stat="ALERTA" }
Add-Check 7 "Memória RAM" $t7_Res $t7_Stat $t7_Rec

# 8. Versão Windows
try {
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    if ([int]$build -lt 19045) { $t8_Stat="ALERTA"; $t8_Rec="Atualizar Windows (Build antiga)." }
    else { $t8_Stat="OK"; $t8_Rec="Sistema atualizado." }
    $t8_Res = "Build $build"
} catch { $t8_Res="Erro"; $t8_Stat="ALERTA" }
Add-Check 8 "Versão do Windows" $t8_Res $t8_Stat $t8_Rec

# 9. Drivers GPU
try {
    $gpu = Get-CimInstance Win32_VideoController | Select -First 1
    $date = [Management.ManagementDateTimeConverter]::ToDateTime($gpu.DriverDate)
    $days = ((Get-Date) - $date).Days
    if ($days -gt 365) { $t9_Stat="ALERTA"; $t9_Rec="Atualizar driver de vídeo." }
    else { $t9_Stat="OK"; $t9_Rec="Driver recente." }
    $t9_Res = "$days dias"
} catch { $t9_Res="Genérico"; $t9_Stat="ALERTA" }
Add-Check 9 "Drivers GPU" $t9_Res $t9_Stat $t9_Rec

# 10. Inicialização
try {
    $count = (Get-CimInstance Win32_StartupCommand).Count
    if ($count -gt 8) { $t10_Stat="ALERTA"; $t10_Rec="Otimizar inicialização." }
    else { $t10_Stat="OK"; $t10_Rec="Boot rápido." }
    $t10_Res = "$count itens"
} catch { $t10_Res="Erro"; $t10_Stat="OK" }
Add-Check 10 "Inicialização" $t10_Res $t10_Stat $t10_Rec

# 11. Temperatura GPU
$t11_Res = "N/A"; $t11_Stat = "OK"; $t11_Rec = "Monitorar sob carga."
try {
    $wmiGPU = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | Select -First 1
    if ($wmiGPU) {
        $val = ($wmiGPU.CurrentTemperature / 10) - 273.15
        if ($val -gt 20 -and $val -lt 120) {
            $t11_Res = "$([math]::Round($val,0)) °C"
            if ($val -ge 85) { $t11_Stat="CRÍTICO"; $t11_Rec="Melhorar fluxo de ar." }
            elseif ($val -ge 75) { $t11_Stat="ALERTA"; $t11_Rec="Limpeza recomendada." }
        }
    }
    if ($t11_Res -eq "N/A") {
        $gpuName = (Get-CimInstance Win32_VideoController).Name
        $t11_Res = "$gpuName (Sem Sensor)"
    }
} catch {}
Add-Check 11 "Temperatura GPU" $t11_Res $t11_Stat $t11_Rec

# 12. Bateria
try {
    $bat = Get-CimInstance Win32_Battery
    if ($bat) {
        $life = $bat.EstimatedChargeRemaining
        if ($life -lt 70) { $t12_Stat="ALERTA"; $t12_Rec="Considerar troca da bateria." }
        else { $t12_Stat="OK"; $t12_Rec="Bateria saudável." }
        $t12_Res = "$life% Carga"
    } else {
        $t12_Stat="OK"; $t12_Res="Desktop (Tomada)"; $t12_Rec="Energia estável."
    }
} catch { $t12_Stat="OK"; $t12_Res="N/A" }
Add-Check 12 "Bateria" $t12_Res $t12_Stat $t12_Rec

# 13. Windows Update
try {
    $searcher = (New-Object -ComObject Microsoft.Update.Searcher).CreateUpdateSearcher()
    $pend = ($searcher.Search("IsInstalled=0 and Type='Software'").Updates).Count
    if ($pend -gt 0) { $t13_Stat="ALERTA"; $t13_Rec="Fazer updates pendentes." }
    else { $t13_Stat="OK"; $t13_Rec="Sistema em dia." }
    $t13_Res = "$pend pendentes"
} catch { 
    $t13_Res="Erro Check"; $t13_Stat="ALERTA"; $t13_Rec="Verificar manualmente." 
}
Add-Check 13 "Windows Update" $t13_Res $t13_Stat $t13_Rec

# --- GERAÇÃO HTML & PDF ---
$Rows = ""
foreach ($item in $Resultados) {
    $classCSS = "status-" + $item.Status.ToLower().Replace("í","i").Replace("Ó","O") 
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
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f0f2f5; padding: 20px; }
    .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #0056b3; padding-bottom: 15px; margin-bottom: 20px; }
    .header h1 { color: #0056b3; margin: 0; font-size: 24px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th { background: #0056b3; color: white; padding: 10px; text-align: left; font-size: 13px; text-transform: uppercase; }
    td { padding: 10px; border-bottom: 1px solid #eee; font-size: 13px; color: #333; }
    tr:nth-child(even) { background-color: #fafafa; }
    .status-ok { color: #27ae60; font-weight: bold; }
    .status-alerta { color: #f39c12; font-weight: bold; }
    .status-critico { color: #c0392b; font-weight: bold; background-color: #fff5f5; }
    .wa-btn { display: block; background: #25d366; color: white; text-align: center; padding: 15px; border-radius: 6px; text-decoration: none; font-weight: bold; margin-top: 25px; font-size: 16px; }
    .footer { text-align: center; margin-top: 20px; font-size: 11px; color: #999; }
</style>
"@

$html = @"
<!DOCTYPE html>
<html>
<head><meta charset='UTF-8'>$Style</head>
<body>
    <div class='container'>
        <div class='header'>
            <div><h1>HPTI DIAGNÓSTICO</h1><p>Relatório Técnico de Saúde do Equipamento</p></div>
            <div style='text-align:right; font-size:12px;'>
                <strong>Cliente:</strong> $env:USERNAME<br>
                <strong>PC:</strong> $ComputerName<br>
                <strong>Data:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm')
            </div>
        </div>
        <table>
            <thead><tr><th>#</th><th>Verificação</th><th>Resultado</th><th>Status</th><th>Recomendação</th></tr></thead>
            <tbody>$Rows</tbody>
        </table>
        <a href='$WhatsAppLink' class='wa-btn'>📲 FALAR COM SUPORTE TÉCNICO</a>
        <div class='footer'>HPTI Tecnologia | Relatório gerado automaticamente | www.hpinfo.com.br</div>
    </div>
</body>
</html>
"@

$html | Out-File $ReportHTML -Encoding UTF8
Write-Host "[OK] Relatório HTML Gerado." -ForegroundColor Green

$edge = (Get-ChildItem "C:\Program Files*\Microsoft\Edge\Application\msedge.exe" | Select -First 1).FullName
if ($edge) {
    Start-Process $edge -ArgumentList "--headless --disable-gpu --print-to-pdf=`"$ReportPDF`" `"$ReportHTML`"" -Wait
    Invoke-Item $ReportPDF
} else {
    Invoke-Item $ReportHTML
}