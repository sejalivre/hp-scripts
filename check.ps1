<#
.SYNOPSIS
    Check-up HPTI Master v7.0 - Versão Final Ajustada
.DESCRIPTION
    - CoreTemp com delay maior para gerar log corretamente.
    - Correção na leitura de Licença do Windows (Filtro por GUID).
    - Office exibe a VERSÃO exata e status correto.
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
Write-Host "[*] Iniciando Diagnóstico HPTI v7.0..." -ForegroundColor Cyan

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
    
    # Exibe no console colorido
    Write-Host "[$Stat] ${Nome}: $Res" -ForegroundColor (if($Stat -eq "OK"){"Green"}else{"Yellow"})
}

Write-Host "`n--- EXECUTANDO 13 CHECAGENS ---" -ForegroundColor Yellow

# 1. Temperatura Processador (Lógica Ajustada)
$t1_Res = "N/A"; $t1_Stat = "ALERTA"; $t1_Rec = "Verificar sensores."
try {
    # Tenta CoreTemp com delay maior (Solicitação do Usuário)
    $ctPath = if ($ExtractedPaths.ContainsKey("CoreTemp")) { Join-Path $ExtractedPaths["CoreTemp"] "CoreTemp.exe" } else { $null }
    if ($ctPath -and (Test-Path $ctPath)) {
        Write-Host "   -> Rodando CoreTemp (Aguarde 12s)..." -NoNewline -ForegroundColor Gray
        $p = Start-Process $ctPath -NoNewWindow -PassThru
        
        # AUMENTADO PARA GARANTIR LEITURA
        Start-Sleep -Seconds 12 
        
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        
        # Busca log mais recente
        $logDir = $ExtractedPaths["CoreTemp"]
        $log = Get-ChildItem $logDir -Filter "CT-Log*.csv" | Sort-Object LastWriteTime -Descending | Select -First 1
        
        if ($log) {
            $content = Get-Content $log.FullName | Select -Last 1
            # O formato do CoreTemp CSV tem a temp geralmente na coluna 3 ou 4 dependendo da versão, vamos tentar parser seguro
            $parts = $content -split ","
            if ($parts.Count -gt 2) {
                $val = [double](($parts[3])) # Tenta pegar direto se não tiver offset
                if ($val -gt 1000) { $val = $val / 1000 } # Ajuste se vier em raw
                if ($val -lt 10) { $val = [double]$parts[2] } # Tenta coluna anterior se falhar
                
                $t1_Res = "$([math]::Round($val,0)) °C"
                $t1_Stat = if ($val -ge 85) { "CRÍTICO" } elseif ($val -ge 70) { "ALERTA" } else { "OK" }
                $t1_Rec = if ($t1_Stat -eq "OK") { "Refrigeração OK." } else { "Limpeza + Pasta Térmica." }
                Write-Host " OK" -ForegroundColor Green
            }
        } else { Write-Host " Falha (Sem Log)" -ForegroundColor Red }
    }
    
    # Fallback WMI se CoreTemp falhou
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

# --- 4. Licenciamento Windows (Blindado v2) ---
try {
    $t4_Stat = "ALERTA"
    $t4_Res  = "Não Ativado"
    $t4_Rec  = "Regularizar licença."

    # 1. Busca Rastros de Pirataria (Arquivos comuns de ativadores)
    $hack = Get-ChildItem "C:\Program Files", "C:\Windows" -Filter "*KMS*", "*AutoPico*", "*KMSAuto*" -Recurse -ErrorAction SilentlyContinue | Select -First 1
    
    if ($hack) {
        $t4_Stat = "CRÍTICO"
        $t4_Res  = "Pirataria Detectada"
        $t4_Rec  = "Remover ativadores ilegais (Risco de Segurança)."
    } 
    else {
        # 2. Tenta WMI (Método Rápido)
        # Filtramos 'Name like Windows' para não pegar licenças do Office misturadas
        $winLic = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%' AND LicenseStatus = 1" -ErrorAction SilentlyContinue | Select -First 1
        
        if ($winLic) {
            $t4_Stat = "OK"
            $t4_Res  = "Ativado (Original)"
            $t4_Rec  = "Licença válida."
        } 
        else {
            # 3.  PLANO B: Comando Nativo SLMGR (Se o WMI falhar, este funciona)
            # Executa o verificador oficial da Microsoft e lê a saída de texto
            $slmgrOut = cmd /c "cscript //nologo %windir%\system32\slmgr.vbs /xpr" 2>&1 | Out-String
            
            if ($slmgrOut -match "permanently|definitivamente") {
                $t4_Stat = "OK"
                $t4_Res  = "Ativado (Permanente)"
                $t4_Rec  = "Licença Vitalícia OK."
            }
            elseif ($slmgrOut -match "expire|vence") {
                $t4_Stat = "ALERTA"
                $t4_Res  = "Ativação Temporária"
                $t4_Rec  = "Verificar prazo de expiração."
            }
            else {
                # 4. Última esperança: Chave na BIOS (OEM)
                $biosKey = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
                if ($biosKey) {
                    $t4_Stat = "ALERTA"
                    $t4_Res  = "Não Ativado (Chave BIOS: Sim)"
                    $t4_Rec  = "Ativar usando a chave original da BIOS."
                }
            }
        }
    }
} catch {
    $t4_Stat = "ALERTA"
    $t4_Res  = "Erro Leitura"
    $t4_Rec  = "Verificar manualmente (slmgr /xpr)."
}
Add-Check 4 "Licenciamento Windows" $t4_Res $t4_Stat $t4_Rec

# 5. Pacote Office (Com Nome da Versão)
try {
    # 1. Tenta pegar o nome da versão no Registro
    $officeReg = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match "Microsoft (Office|365|Word)" } | Select-Object -First 1
    $officeName = if ($officeReg) { $officeReg.DisplayName } else { $null }

    # 2. Verifica ativação (Procurando qualquer licença Office ativa)
    $officeAct = Get-CimInstance SoftwareLicensingProduct -Filter "Description like '%Office%' AND PartialProductKey IS NOT NULL" | Where-Object LicenseStatus -eq 1
    
    if ($officeName) {
        # Limpa o nome para ficar bonito (remove builds longas se tiver)
        $cleanName = $officeName -replace "Microsoft ", "" -replace "Standard ", "" -replace "Professional Plus", "Pro Plus"
        
        if ($officeAct) { 
            $t5_Stat="OK"; $t5_Res="$cleanName (Ativo)"; $t5_Rec="Pronto para uso." 
        } else { 
            # Às vezes WMI falha, vamos assumir Alerta se não achou licença explicita
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
    $searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
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