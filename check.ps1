<#
.SYNOPSIS
    Check-up HPTI Master v5.0 - Blindado
.DESCRIPTION
    Garante a exibição de todos os 13 itens.
    Inclui "Plano B" (Fallback) para quando as ferramentas externas falham.
#>

$ErrorActionPreference = "SilentlyContinue"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

#region 1. Configurações
$ComputerName = $env:COMPUTERNAME
$ReportHTML   = "$env:TEMP\Checkup_HPTI_Final.html"
$ReportPDF    = "$env:USERPROFILE\Desktop\Diagnostico_HPTI_$ComputerName.pdf"
$WhatsAppLink = "https://wa.me/556235121468?text=Ola%20HPTI,%20segue%20meu%20relatorio%20tecnico."

$repoBase     = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir      = "$env:TEMP\HP-Tools"
$7zipExe      = "$tempDir\7z.exe"
$Password     = "0"

# Garante que a pasta existe
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# Função para baixar ferramentas com verificação
function Baixar-Ferramenta ($nomeArquivo) {
    $destino = "$tempDir\$nomeArquivo"
    if (Test-Path $destino) { return $true }
    try {
        Write-Host "Baixando $nomeArquivo..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri "$repoBase/$nomeArquivo" -OutFile $destino -TimeoutSec 15 -ErrorAction Stop
        return $true
    } catch { 
        Write-Host "Falha ao baixar $nomeArquivo" -ForegroundColor Red
        return $false 
    }
}

Write-Host "[*] Iniciando Diagnóstico HPTI v5.0..." -ForegroundColor Cyan

# Prepara 7-Zip
Baixar-Ferramenta "7z.txe"
if (Test-Path "$tempDir\7z.txe") { Copy-Item "$tempDir\7z.txe" $7zipExe -Force }

# Prepara Ferramentas Externas
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
#endregion

#region 2. Motor de Verificação (Blindado)
$Resultados = @()

# Função auxiliar para garantir que o script nunca pare
function Adicionar-Item {
    param ($ID, $Verificacao, $Resultado, $Status, $Rec)
    
    # Padronização de Status para Cores
    $Icone = switch($Status) { 
        "OK" { "✅" } 
        "ALERTA" { "⚠️" } 
        "CRÍTICO" { "❌" }
        default { "❓" }
    }
    
    $obj = [PSCustomObject]@{
        ID = $ID
        Verificacao = $Verificacao
        Resultado = $Resultado
        Status = $Status
        Icone = $Icone
        Recomendacao = $Rec
    }
    
    $global:Resultados += $obj
}

Write-Host "Executando bateria de testes..." -ForegroundColor Yellow

# --- 1. Temperatura Processador ---
$t1_Res = "N/A"; $t1_Stat = "ALERTA"; $t1_Rec = "Verificar sensores."
try {
    # Tenta CoreTemp
    $ctPath = if ($ExtractedPaths.ContainsKey("CoreTemp")) { Join-Path $ExtractedPaths["CoreTemp"] "CoreTemp.exe" } else { $null }
    if ($ctPath -and (Test-Path $ctPath)) {
        $p = Start-Process $ctPath -NoNewWindow -PassThru
        Start-Sleep -Seconds 5
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        $log = Get-ChildItem $ExtractedPaths["CoreTemp"] -Filter "CT-Log*.csv" | Sort LastWriteTime -Descending | Select -First 1
        if ($log) {
            $content = Get-Content $log.FullName | Select -Last 1
            $val = [double](($content -split ",")[3]) / 1000
            $t1_Res = "$([math]::Round($val,0)) °C"
            $t1_Stat = if ($val -ge 85) { "CRÍTICO" } elseif ($val -ge 70) { "ALERTA" } else { "OK" }
            $t1_Rec = if ($t1_Stat -eq "OK") { "Temperatura normal." } else { "Limpeza + pasta térmica." }
        }
    }
    # Fallback WMI se CoreTemp falhou
    if ($t1_Res -eq "N/A") {
        $wmi = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($wmi) {
            $val = ($wmi.CurrentTemperature / 10) - 273.15
            $t1_Res = "$([math]::Round($val,0)) °C (WMI)"
            $t1_Stat = if ($val -ge 85) { "CRÍTICO" } elseif ($val -ge 70) { "ALERTA" } else { "OK" }
            $t1_Rec = if ($t1_Stat -eq "OK") { "Temperatura normal." } else { "Limpeza + pasta térmica." }
        }
    }
} catch {}
Adicionar-Item 1 "Temperatura Processador" $t1_Res $t1_Stat $t1_Rec

# --- 2. Saúde do Disco (SMART) ---
$t2_Res = "Desconhecido"; $t2_Stat = "ALERTA"; $t2_Rec = "Verificar disco manualmente."
try {
    # Tenta CrystalDiskInfo
    $cdiPath = if ($ExtractedPaths.ContainsKey("CrystalDiskInfo")) { Join-Path $ExtractedPaths["CrystalDiskInfo"] "DiskInfo64.exe" } else { $null }
    if ($cdiPath -and (Test-Path $cdiPath)) {
        Start-Process $cdiPath -ArgumentList "/CopyExit" -Wait
        $logCDI = Join-Path $ExtractedPaths["CrystalDiskInfo"] "DiskInfo.txt"
        if (Test-Path $logCDI) {
            $txt = Get-Content $logCDI -Raw
            if ($txt -match "Health Status : (.*)") {
                $statusReal = $matches[1].Trim()
                $t2_Res = $statusReal
                if ($statusReal -match "Good|Saudável") {
                    $t2_Stat = "OK"
                    $t2_Rec = "Não tem alertas de SMART."
                } else {
                    $t2_Stat = "CRÍTICO"
                    $t2_Rec = "Substituir disco urgente."
                }
            }
        }
    }
    # Fallback WMI
    if ($t2_Res -eq "Desconhecido") {
        $disk = Get-CimInstance Win32_DiskDrive | Select -First 1
        $t2_Res = $disk.Status
        if ($disk.Status -eq "OK") { $t2_Stat="OK"; $t2_Rec="Status WMI OK." } else { $t2_Stat="CRÍTICO"; $t2_Rec="Erro físico detectado pelo Windows." }
    }
} catch {}
Adicionar-Item 2 "Saúde Física (SMART)" $t2_Res $t2_Stat $t2_Rec

# --- 3. Espaço Livre ---
$t3_Res = ""; $t3_Stat = "OK"; $t3_Rec = "Espaço suficiente."
try {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($d in $disks) {
        $pct = [math]::Round(($d.FreeSpace / $d.Size) * 100, 1)
        $t3_Res += "$($d.DeviceID) $pct% | "
        if ($pct -lt 15) { $t3_Stat = "CRÍTICO"; $t3_Rec = "Limpeza urgente necessária." }
        elseif ($pct -lt 25 -and $t3_Stat -ne "CRÍTICO") { $t3_Stat = "ALERTA"; $t3_Rec = "Considerar limpeza ou upgrade." }
    }
    $t3_Res = $t3_Res.TrimEnd(" | ")
} catch { $t3_Res = "Erro leitura" }
Adicionar-Item 3 "Espaço em Disco" $t3_Res $t3_Stat $t3_Rec

# --- 4. Licenciamento Windows ---
try {
    $lic = (Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" | Where LicenseStatus -eq 1).Count
    $hack = Get-ChildItem "C:\Program Files", "C:\Windows" -Filter "*KMS*", "*AutoPico*" -Recurse -ErrorAction SilentlyContinue | Select -First 1
    if ($hack) { $t4_Stat="CRÍTICO"; $t4_Res="Pirataria Detectada"; $t4_Rec="Remover ativadores ilegais." }
    elseif ($lic -gt 0) { $t4_Stat="OK"; $t4_Res="Ativado (Original)"; $t4_Rec="Licença válida." }
    else { $t4_Stat="ALERTA"; $t4_Res="Não Ativado"; $t4_Rec="Regularizar licença." }
} catch { $t4_Stat="ALERTA"; $t4_Res="Erro verificação" }
Adicionar-Item 4 "Licenciamento Windows" $t4_Res $t4_Stat $t4_Rec

# --- 5. Pacote Office ---
try {
    $hasOffice = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where DisplayName -match "Microsoft (Office|365)"
    $officeAct = (Get-CimInstance SoftwareLicensingProduct -Filter "Description like '%Office%'" | Where LicenseStatus -eq 1).Count -gt 0
    if ($hasOffice -and $officeAct) { $t5_Stat="OK"; $t5_Res="Instalado e Ativado"; $t5_Rec="Pronto para uso." }
    elseif ($hasOffice) { $t5_Stat="ALERTA"; $t5_Res="Instalado (Inativo)"; $t5_Rec="Ativar licença Office." }
    else { $t5_Stat="ALERTA"; $t5_Res="Não instalado"; $t5_Rec="Instalar se necessário." }
} catch { $t5_Stat="ALERTA"; $t5_Res="Erro"; $t5_Rec="Verificar manualmente." }
Adicionar-Item 5 "Pacote Office" $t5_Res $t5_Stat $t5_Rec

# --- 6. Bloatware ---
try {
    $junk = "*WebCompanion*","*McAfee*","*Norton*","*Baidu*","*Segurazo*","*Avast*"
    $apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
    $found = $apps | Where { $n=$_.DisplayName; $junk | Where { $n -like $_ } }
    if ($found) { $t6_Stat="ALERTA"; $t6_Res="Detectado"; $t6_Rec="Remover: $(($found.DisplayName -join ', ').Substring(0, [math]::Min(30, ($found.DisplayName -join ', ').Length)))..." }
    else { $t6_Stat="OK"; $t6_Res="Limpo"; $t6_Rec="Nenhum bloatware crítico." }
} catch { $t6_Stat="OK"; $t6_Res="N/A" }
Adicionar-Item 6 "Bloatware / Lixo" $t6_Res $t6_Stat $t6_Rec

# --- 7. Memória RAM ---
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 0)
    if ($usedPct -gt 85) { $t7_Stat="ALERTA"; $t7_Rec="Fechar programas ou adicionar RAM." }
    else { $t7_Stat="OK"; $t7_Rec="Uso dentro do normal." }
    $t7_Res = "$usedPct% em uso"
} catch { $t7_Res="Erro"; $t7_Stat="ALERTA" }
Adicionar-Item 7 "Memória RAM" $t7_Res $t7_Stat $t7_Rec

# --- 8. Versão Windows ---
try {
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    if ([int]$build -lt 19045) { $t8_Stat="ALERTA"; $t8_Rec="Atualizar Windows (Build antiga)." }
    else { $t8_Stat="OK"; $t8_Rec="Sistema atualizado." }
    $t8_Res = "Build $build"
} catch { $t8_Res="Erro"; $t8_Stat="ALERTA" }
Adicionar-Item 8 "Versão do Windows" $t8_Res $t8_Stat $t8_Rec

# --- 9. Drivers GPU ---
try {
    $gpu = Get-CimInstance Win32_VideoController | Select -First 1
    $date = [Management.ManagementDateTimeConverter]::ToDateTime($gpu.DriverDate)
    $days = ((Get-Date) - $date).Days
    if ($days -gt 365) { $t9_Stat="ALERTA"; $t9_Rec="Atualizar driver de vídeo." }
    else { $t9_Stat="OK"; $t9_Rec="Driver recente." }
    $t9_Res = "$days dias"
} catch { $t9_Res="Genérico"; $t9_Stat="ALERTA" }
Adicionar-Item 9 "Drivers GPU" $t9_Res $t9_Stat $t9_Rec

# --- 10. Inicialização (Startup) ---
try {
    $count = (Get-CimInstance Win32_StartupCommand).Count
    if ($count -gt 8) { $t10_Stat="ALERTA"; $t10_Rec="Otimizar inicialização." }
    else { $t10_Stat="OK"; $t10_Rec="Boot otimizado." }
    $t10_Res = "$count itens"
} catch { $t10_Res="Erro"; $t10_Stat="OK" }
Adicionar-Item 10 "Inicialização" $t10_Res $t10_Stat $t10_Rec

# --- 11. Temperatura GPU ---
$t11_Res = "N/A"; $t11_Stat = "OK"; $t11_Rec = "Monitorar sob carga."
try {
    # Tenta via WMI genérico
    $wmiGPU = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | Select -First 1
    if ($wmiGPU) {
        $val = ($wmiGPU.CurrentTemperature / 10) - 273.15
        if ($val -gt 20 -and $val -lt 120) { # Filtra valores loucos
            $t11_Res = "$([math]::Round($val,0)) °C"
            if ($val -ge 85) { $t11_Stat="CRÍTICO"; $t11_Rec="Melhorar fluxo de ar." }
            elseif ($val -ge 75) { $t11_Stat="ALERTA"; $t11_Rec="Limpeza recomendada." }
        }
    }
} catch {}
Adicionar-Item 11 "Temperatura GPU" $t11_Res $t11_Stat $t11_Rec

# --- 12. Bateria ---
try {
    $bat = Get-CimInstance Win32_Battery
    if ($bat) {
        $life = $bat.EstimatedChargeRemaining
        if ($life -lt 70) { $t12_Stat="ALERTA"; $t12_Rec="Considerar troca da bateria." }
        else { $t12_Stat="OK"; $t12_Rec="Bateria saudável." }
        $t12_Res = "$life% Carga"
    } else {
        $t12_Stat="OK"; $t12_Res="Desktop"; $t12_Rec="Alimentação via tomada."
    }
} catch { $t12_Stat="OK"; $t12_Res="N/A" }
Adicionar-Item 12 "Bateria" $t12_Res $t12_Stat $t12_Rec

# --- 13. Windows Update ---
try {
    $searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
    $pend = ($searcher.Search("IsInstalled=0 and Type='Software'").Updates).Count
    if ($pend -gt 0) { $t13_Stat="ALERTA"; $t13_Rec="Executar Windows Update." }
    else { $t13_Stat="OK"; $t13_Rec="Sistema em dia." }
    $t13_Res = "$pend pendentes"
} catch { 
    $t13_Res="Erro Check"; $t13_Stat="ALERTA"; $t13_Rec="Verificar manualmente." 
}
Adicionar-Item 13 "Windows Update" $t13_Res $t13_Stat $t13_Rec

#endregion

#region 3. Gerador de Relatório
$Rows = ""
foreach ($item in $Resultados) {
    $classCSS = "status-" + $item.Status.ToLower().Replace("í","i") # Remove acento pro CSS
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
    body { font-family: 'Segoe UI', sans-serif; background: #f3f4f6; padding: 20px; }
    .container { max-width: 1000px; margin: auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #0056b3; padding-bottom: 20px; margin-bottom: 20px; }
    .header h1 { color: #0056b3; margin: 0; font-size: 26px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th { background: #0056b3; color: white; padding: 12px; text-align: left; font-size: 14px; }
    td { padding: 12px; border-bottom: 1px solid #e1e4e8; font-size: 14px; color: #333; }
    tr:nth-child(even) { background-color: #f8f9fa; }
    .status-ok { color: #27ae60; font-weight: bold; }
    .status-alerta { color: #f39c12; font-weight: bold; }
    .status-critico { color: #c0392b; font-weight: bold; }
    .wa-btn { display: block; background: #25d366; color: white; text-align: center; padding: 15px; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 30px; font-size: 16px; }
    .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #888; }
</style>
"@

$html = @"
<!DOCTYPE html>
<html>
<head><meta charset='UTF-8'>$Style</head> 
<body>
    <div class='container'>
        <div class='header'>
            <div><h1>HPTI DIAGNÓSTICO PROFISSIONAL</h1><p>Relatório Técnico de Integridade</p></div>
            <div style='text-align:right'>
                <strong>Cliente:</strong> $env:USERNAME<br>
                <strong>PC:</strong> $ComputerName<br>
                <strong>Data:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm')
            </div>
        </div>
        <table>
            <thead><tr><th>#</th><th>Verificação</th><th>Resultado</th><th>Status</th><th>Recomendação</th></tr></thead>
            <tbody>$Rows</tbody>
        </table>
        <a href='$WhatsAppLink' class='wa-btn'>📲 ENVIAR RELATÓRIO PARA TÉCNICO</a>
        <div class='footer'>HPTI Tecnologia - www.hpinfo.com.br</div>
    </div>
</body>
</html>
"@

$html | Out-File $ReportHTML -Encoding UTF8
Write-Host "[OK] Relatório Gerado!" -ForegroundColor Green

# Abre o PDF (via Edge)
$edge = (Get-ChildItem "C:\Program Files*\Microsoft\Edge\Application\msedge.exe" | Select -First 1).FullName
if ($edge) {
    Start-Process $edge -ArgumentList "--headless --disable-gpu --print-to-pdf=`"$ReportPDF`" `"$ReportHTML`"" -Wait
    Invoke-Item $ReportPDF
} else {
    Invoke-Item $ReportHTML
}
#endregion