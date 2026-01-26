<#
.SYNOPSIS
    Gerador de Relatório de Estação de Trabalho (Hardware e Software).
.DESCRIPTION
    Versão FINAL COMPLETA (v7.4).
    Compatível com PowerShell 5.1 (sem operadores modernos).
    Inclui todas as seções: CoreTemp, DiskInfo, Drivers, BSOD, Logs, etc.
#>

$ErrorActionPreference = "SilentlyContinue"

#region 1. Configurações e Estilos
$ComputerName = $env:COMPUTERNAME
$DateNow      = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
$UserName     = whoami
$ReportPath   = "$env:USERPROFILE\Desktop\Relatorio_Estacao_$ComputerName_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"

$Style = @"
<style>
    body {font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin:40px; background:#f8f9fa;}
    h1   {color:#2c3e50;}
    h2   {color:#2980b9; border-bottom:2px solid #3498db; padding-bottom:8px; margin-top: 30px;}
    h3   {color:#2c3e50; margin-top: 20px;}
    table {border-collapse: collapse; width:100%; margin:15px 0;}
    th   {background:#3498db; color:white; padding:10px; text-align:left;}
    td   {padding:8px; border:1px solid #ddd;}
    tr:nth-child(even) {background:#f2f2f2;}
    .section {margin-bottom:40px;}
    .ok     {color:#27ae60; font-weight:bold;}
    .warn   {color:#e67e22; font-weight:bold;}
    .crit   {color:#c0392b; font-weight:bold;}
    #hp-floater {
        position: fixed; right: 30px; bottom: 30px;
        background-color: #3498db; color: white;
        padding: 12px 25px; border-radius: 50px;
        text-decoration: none; font-weight: bold;
        box-shadow: 0 4px 15px rgba(0,0,0,0.3);
        z-index: 9999; transition: all 0.5s ease;
        font-family: 'Segoe UI', sans-serif; border: 2px solid white;
    }
    #hp-floater:hover { background-color: #2980b9; transform: scale(1.05); }
</style>
"@
#endregion

#region 2. Preparação de Ferramentas
$repoBase   = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipTxe    = "$tempDir\7z.txe"
$7zipExe    = "$tempDir\7z.exe"
$Password   = "0" 

if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

function Baixar-Ferramenta ($nomeArquivo) {
    $destino = "$tempDir\$nomeArquivo"
    $url = "$repoBase/$nomeArquivo"
    if (Test-Path $destino) { return $true }
    try {
        Invoke-WebRequest -Uri $url -OutFile $destino -ErrorAction Stop
    } catch { return $false }
    return $true
}

Baixar-Ferramenta "7z.txe"
if (Test-Path $7zipTxe) { Copy-Item -Path $7zipTxe -Destination $7zipExe -Force }

$ToolsToExtract = @(
    @{ Name = "CoreTemp";        Archive = "CoreTemp.7z";        SubFolder = "CoreTemp" }
    @{ Name = "CrystalDiskInfo"; Archive = "CrystalDiskInfo.7z"; SubFolder = "CrystalDiskInfo" }
)
$ExtractedPaths = @{}

if (Test-Path $7zipExe) {
    foreach ($tool in $ToolsToExtract) {
        $pastaDestino = Join-Path $tempDir $tool.SubFolder
        if (Baixar-Ferramenta $tool.Archive) {
            if (-not (Test-Path $pastaDestino)) { New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null }
            $argumentos = "x `"$tempDir\$($tool.Archive)`" -o`"$pastaDestino`" -p`"$Password`" -y"
            Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow
            $ExtractedPaths[$tool.Name] = $pastaDestino
        }
    }
}
Start-Sleep -Milliseconds 800
#endregion

#region 3. Início do HTML
$html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Relatório de Estação - $ComputerName</title>
$Style
</head>
<body>
<h1>Relatório da Estação de Trabalho</h1>
<p><strong>Gerado em:</strong> $DateNow<br>
<strong>Computador:</strong> $ComputerName<br>
<strong>Usuário:</strong> $UserName</p>
"@
#endregion

#region 4. Coleta: Sistema Operacional
$html += "<div class='section'><h2>1. Informações do Sistema</h2><table><tr><th>Propriedade</th><th>Valor</th></tr>"
$os = Get-CimInstance Win32_OperatingSystem
$html += "<tr><td>SO</td><td>$($os.Caption) ($($os.OSArchitecture))</td></tr>"
$html += "<tr><td>Versão/Build</td><td>$($os.Version) - $($os.BuildNumber)</td></tr>"
$html += "<tr><td>Instalado</td><td>$($os.InstallDate -replace 'T',' ')</td></tr>"
$html += "<tr><td>Último boot</td><td>$($os.LastBootUpTime -replace 'T',' ')</td></tr>"

$cs = Get-CimInstance Win32_ComputerSystem
$html += "<tr><td>Fabricante</td><td>$($cs.Manufacturer)</td></tr>"
$html += "<tr><td>Modelo</td><td>$($cs.Model)</td></tr>"
$html += "<tr><td>Nome na rede</td><td>$($cs.Name)</td></tr>"
$html += "<tr><td>Domínio / Workgroup</td><td>$($cs.Domain)</td></tr>"
$html += "</table></div>"
#endregion

#region 5. Coleta: CPU e Memória
$html += "<div class='section'><h2>2. Processador e Memória RAM</h2><table>"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$html += "<tr><th>Propriedade</th><th>Valor</th></tr>"
$html += "<tr><td>Processador</td><td>$($cpu.Name)</td></tr>"
$html += "<tr><td>Núcleos / Threads</td><td>$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)</td></tr>"
$html += "<tr><td>Velocidade atual</td><td>$($cpu.CurrentClockSpeed) MHz</td></tr>"

$mem = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$memGB = [math]::Round($mem.Sum / 1GB, 1)
$html += "<tr><td>Memória RAM total</td><td>$memGB GB</td></tr>"

$osmem = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($osmem.FreePhysicalMemory / 1MB, 1)
$usedGB = $memGB - $freeGB
$html += "<tr><td>Memória em uso</td><td>$usedGB GB / $memGB GB ($([math]::Round(($usedGB/$memGB)*100))%)</td></tr>"
$html += "</table></div>"
#endregion

#region 6. Coleta: Placa de Vídeo (GPU)
$html += "<div class='section'><h2>12. Placa de Vídeo</h2>"
$gpus = Get-CimInstance Win32_VideoController
if ($gpus) {
    $html += "<table><tr><th>Modelo</th><th>RAM (MB)</th><th>Driver</th><th>Resolução Atual</th></tr>"
    foreach ($gpu in $gpus) {
        $ramMB = if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) { [math]::Round($gpu.AdapterRAM / 1MB, 0) } else { "N/A" }
        $html += "<tr><td>$($gpu.Name)</td><td>$ramMB MB</td><td>$($gpu.DriverVersion)</td><td>$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)</td></tr>"
    }
    $html += "</table>"
}
$html += "</div>"
#endregion

#region 7. Coleta: Discos Lógicos
$html += "<div class='section'><h2>3. Discos e Armazenamento</h2><table>"
$html += "<tr><th>Letra</th><th>Descrição</th><th>Tamanho</th><th>Livre</th><th>Uso %</th><th>Tipo</th></tr>"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $sizeGB  = [math]::Round($_.Size / 1GB, 1)
    $freeGB  = [math]::Round($_.FreeSpace / 1GB, 1)
    $usedPct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
    $colorClass = if ($usedPct -ge 90) {"crit"} elseif ($usedPct -ge 80) {"warn"} else {"ok"}
    $html += "<tr><td>$($_.DeviceID)</td><td>$($_.VolumeName)</td><td>$sizeGB GB</td><td>$freeGB GB</td><td class='$colorClass'>$usedPct %</td><td>$($_.FileSystem)</td></tr>"
}
$html += "</table></div>"
#endregion

#region 8. Coleta: Rede
$html += "<div class='section'><h2>4. Configuração de Rede</h2><table>"
$html += "<tr><th>Adaptador</th><th>IP</th><th>Máscara</th><th>Gateway</th><th>MAC</th></tr>"
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
    $ip = Get-NetIPAddress -InterfaceAlias $_.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ip) {
        $gw = (Get-NetRoute -InterfaceAlias $_.Name -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop
        $html += "<tr><td>$($_.Name)</td><td>$($ip.IPAddress)</td><td>$($ip.PrefixLength)</td><td>$($gw -join ', ')</td><td>$($_.MacAddress)</td></tr>"
    }
}
$html += "</table></div>"
#endregion

#region 9. Coleta: CoreTemp (Fix Compatibilidade)
$html += "<div class='section'><h2>5. Temperaturas CPU (Core Temp)</h2>"
$coreTempPath = $ExtractedPaths["CoreTemp"]
if ($coreTempPath -and (Test-Path (Join-Path $coreTempPath "CoreTemp.exe"))) {
    $coreTempExe = Join-Path $coreTempPath "CoreTemp.exe"
    Write-Output "Rodando CoreTemp..."
    $proc = Start-Process $coreTempExe -NoNewWindow -PassThru
    Start-Sleep -Seconds 15
    if (!$proc.HasExited) { Stop-Process -Id $proc.Id -Force }
    Start-Sleep -Seconds 3
    
    $log = Get-ChildItem $coreTempPath -Filter "CT-Log*.csv" | Sort-Object LastWriteTime -Descending | Select -First 1
    if ($log) {
        $content = Get-Content $log.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        # Parsing manual para evitar erros de versão PS
        $cleanLines = @()
        foreach ($line in $content) {
            if ($line -match "^Time,") { $collect = $true }
            if ($collect -and $line -notmatch "^\s*$") { $cleanLines += $line.Trim().Trim(',') }
        }

        if ($cleanLines.Count -gt 1) {
            $csvData = $cleanLines | ConvertFrom-Csv
            if ($csvData.Count -gt 0) {
                # Filtra colunas relevantes
                $tempCols = $csvData[0].PSObject.Properties.Name | Where-Object { $_ -match "CPU #0" -and $_ -notmatch "Low|High|Load" }
                
                $html += "<table><tr><th>Horário</th>"
                foreach ($col in $tempCols) { $html += "<th>$($col -replace 'Cur\. | CPU #0 | #0','')</th>" }
                $html += "</tr>"
                
                foreach ($row in $csvData) {
                    $timeStr = if ($row.Time) { $row.Time } else { "N/A" }
                    $html += "<tr><td>$timeStr</td>"
                    foreach ($col in $tempCols) {
                        $valRaw = if ($row.$col) { $row.$col } else { "0" }
                        $val = [double]$valRaw / 1000
                        $class = if ($val -ge 92) {"crit"} elseif ($val -ge 82) {"warn"} else {"ok"}
                        $html += "<td class='$class'>$([math]::Round($val,1)) °C</td>"
                    }
                    $html += "</tr>"
                }
                $html += "</table>"
            }
        } else { $html += "<p class='warn'>Falha ao ler CSV.</p>" }
    } else { $html += "<p class='warn'>Nenhum log encontrado.</p>" }
} else { $html += "<p class='warn'>CoreTemp não encontrado.</p>" }
$html += "</div>"
#endregion

#region 10. Coleta: CrystalDiskInfo (Fix Compatibilidade)
$html += "<div class='section'><h2>6. Saúde do Disco (CrystalDiskInfo)</h2>"
$cdiPath = $ExtractedPaths["CrystalDiskInfo"]
if ($cdiPath) {
    $exe = Join-Path $cdiPath "DiskInfo64.exe"
    if (-not (Test-Path $exe)) { $exe = Join-Path $cdiPath "DiskInfo32.exe" }
    
    if (Test-Path $exe) {
        Write-Output "Rodando CrystalDiskInfo..."
        Start-Process $exe -ArgumentList "/CopyExit" -NoNewWindow -Wait
        Start-Sleep -Seconds 5
        
        $logPath = Join-Path $cdiPath "DiskInfo.txt"
        if (Test-Path $logPath) {
            $content = Get-Content $logPath -Encoding UTF8 -Raw
            
            # Helper para extrair Regex sem operador ternário
            function Get-Val ($p, $t) { if ($t -match $p) { return $matches[1] } return "N/A" }

            $model = Get-Val "Model : (.+)" $content
            $serial = Get-Val "Serial Number : (.+)" $content
            $health = Get-Val "Health Status : (.+)" $content
            $temp = Get-Val "Temperature : (.+)" $content
            
            $hClass = if ($health -match 'Saudável|Good') { "ok" } else { "crit" }
            $tClass = if ($temp -match '^\d+ C') { "ok" } else { "warn" }

            $html += "<p><strong>Modelo:</strong> $model<br><strong>Serial:</strong> $serial<br>"
            $html += "<strong>Saúde:</strong> <span class='$hClass'>$health</span><br>"
            $html += "<strong>Temp:</strong> <span class='$tClass'>$temp</span></p>"
        } else { $html += "<p class='warn'>Log não gerado.</p>" }
    }
}
$html += "</div>"
#endregion

#region 11. Coleta: Discos Físicos
$html += "<div class='section'><h2>11. Discos Físicos - Detalhes</h2>"
$disks = Get-CimInstance Win32_DiskDrive
if ($disks) {
    $html += "<table><tr><th>Modelo</th><th>Tamanho</th><th>Interface</th><th>Partições</th><th>Status</th></tr>"
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        $html += "<tr><td>$($disk.Model)</td><td>$sizeGB GB</td><td>$($disk.InterfaceType)</td><td>$($disk.Partitions)</td><td>$($disk.Status)</td></tr>"
    }
    $html += "</table>"
}
$html += "</div>"
#endregion

#region 12. Coleta: Windows Update
$html += "<div class='section'><h2>7. Status de Atualizações (Windows Update)</h2>"
Write-Output "Coletando Windows Update..."
$hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
if ($hotfixes) {
    $html += "<h3>Últimos 5 patches instalados</h3><table><tr><th>KB ID</th><th>Descrição</th><th>Data</th></tr>"
    foreach ($hf in $hotfixes) {
        $dateStr = if ($hf.InstalledOn) { $hf.InstalledOn.ToString("dd/MM/yyyy") } else { "N/A" }
        $html += "<tr><td>$($hf.HotFixID)</td><td>$($hf.Description)</td><td>$dateStr</td></tr>"
    }
    $html += "</table>"
}
$html += "</div>"
#endregion

#region 13. Coleta: Top Processos
$html += "<div class='section'><h2>8. Processos que mais consomem Recursos</h2>"
Write-Output "Coletando Top Processos..."
$topCPU = Get-Process | Sort-Object CPU -Descending -ErrorAction SilentlyContinue | Select-Object -First 5
$topRAM = Get-Process | Sort-Object WorkingSet -Descending -ErrorAction SilentlyContinue | Select-Object -First 5 

$html += "<h3>Top 5 por CPU</h3><table><tr><th>Processo</th><th>PID</th><th>CPU(s)</th></tr>"
foreach ($p in $topCPU) { $c=[math]::Round($p.CPU,1); $html += "<tr><td>$($p.Name)</td><td>$($p.Id)</td><td>$c</td></tr>" }
$html += "</table>"

$html += "<h3>Top 5 por RAM</h3><table><tr><th>Processo</th><th>PID</th><th>RAM(MB)</th></tr>"
foreach ($p in $topRAM) { $r=[math]::Round($p.WorkingSet/1MB,1); $html += "<tr><td>$($p.Name)</td><td>$($p.Id)</td><td>$r</td></tr>" }
$html += "</table></div>"
#endregion

#region 14. Coleta: Logs de Erro
$html += "<div class='section'><h2>9. Erros Recentes do Sistema (7 dias)</h2>"
Write-Output "Coletando Logs..."
try {
    $sysEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 10 -ErrorAction Stop
    if ($sysEvents) {
        $html += "<table><tr><th>Data</th><th>Nível</th><th>ID</th><th>Mensagem</th></tr>"
        foreach ($evt in $sysEvents) {
            $msg = ($evt.Message -replace "`n"," " -replace "`r","")
            if ($msg.Length -gt 80) { $msg = $msg.Substring(0, 80) + "..." }
            $html += "<tr><td>$($evt.TimeCreated)</td><td class='crit'>$($evt.LevelDisplayName)</td><td>$($evt.Id)</td><td>$msg</td></tr>"
        }
        $html += "</table>"
    }
} catch { $html += "<p class='ok'>Nenhum erro crítico recente.</p>" }
$html += "</div>"
#endregion

#region 15. Coleta: BSOD
$html += "<div class='section'><h2>Histórico de Telas Azuis (BSOD)</h2>"
$bsod = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; ID=1001; StartTime=(Get-Date).AddDays(-30)} -ErrorAction SilentlyContinue
if ($bsod) {
    $html += "<p class='crit'>ATENÇÃO: $($bsod.Count) telas azuis detectadas.</p>"
    $html += "<table><tr><th>Data</th><th>Erro</th></tr>"
    foreach ($e in $bsod) { $html += "<tr><td>$($e.TimeCreated)</td><td>$($e.Message)</td></tr>" }
    $html += "</table>"
} else { $html += "<p class='ok'>Sem registros de BSOD (30 dias).</p>" }
$html += "</div>"
#endregion

#region 16. Coleta: Serviços
$html += "<div class='section'><h2>14. Serviços Críticos</h2>"
$svcs = @("Winmgmt", "Spooler", "WinDefend", "W32Time")
$html += "<table><tr><th>Serviço</th><th>Status</th></tr>"
foreach ($s in $svcs) {
    $obj = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($obj) {
        $cls = if ($obj.Status -eq "Running") {"ok"} else {"crit"}
        $html += "<tr><td>$($obj.DisplayName)</td><td class='$cls'>$($obj.Status)</td></tr>"
    }
}
$html += "</table></div>"
#endregion

#region 17. Inicialização
$html += "<div class='section'><h2>Programas de Inicialização</h2>"
$startup = Get-CimInstance Win32_StartupCommand
if ($startup) {
    $html += "<table><tr><th>Nome</th><th>Comando</th></tr>"
    foreach ($s in $startup) { $html += "<tr><td>$($s.Name)</td><td>$($s.Command)</td></tr>" }
    $html += "</table>"
}
$html += "</div>"
#endregion

#region 18. Bateria
$html += "<div class='section'><h2>Saúde da Bateria</h2>"
$bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
if ($bat) {
    $html += "<p>Status: $($bat.Status) | Carga: $($bat.EstimatedChargeRemaining)%</p>"
} else { $html += "<p>Sem bateria (Desktop).</p>" }
$html += "</div>"
#endregion

#region 19. BIOS
$html += "<div class='section'><h2>10. BIOS/UEFI</h2>"
$bios = Get-CimInstance Win32_BIOS
$html += "<table><tr><td>Versão</td><td>$($bios.SMBIOSBIOSVersion)</td></tr><tr><td>Data</td><td>$($bios.ReleaseDate)</td></tr></table></div>"
#endregion

#region 20. Resumo
$html += "<div class='section'><h2>18. Diagnóstico Rápido</h2><table><tr><th>Item</th><th>Status</th></tr>"
# Espaço Disco
$diskC = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeP = [math]::Round(($diskC.FreeSpace / $diskC.Size)*100, 0)
$dCls = if ($freeP -lt 15) {"crit"} else {"ok"}
$html += "<tr><td>Espaço C:</td><td class='$dCls'>$freeP% Livre</td></tr>"
# Memória
$usedM = [math]::Round(($osmem.TotalVisibleMemorySize - $osmem.FreePhysicalMemory)/$osmem.TotalVisibleMemorySize*100,0)
$mCls = if ($usedM -gt 90) {"crit"} else {"ok"}
$html += "<tr><td>Memória</td><td class='$mCls'>$usedM% em uso</td></tr>"
$html += "</table></div>"
#endregion

#region 21. Diagnóstico Drivers (Fix Compatibilidade)
$html += "<div class='section'><h2>Diagnóstico de Drivers</h2>"
$badDrivers = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 -and $_.ConfigManagerErrorCode -ne $null }

if ($badDrivers) {
    $html += "<h3 class='crit'>Drivers com Problemas</h3><table><tr><th>Dispositivo</th><th>Erro</th></tr>"
    foreach ($d in $badDrivers) {
        $html += "<tr><td>$($d.Name)</td><td>Código $($d.ConfigManagerErrorCode)</td></tr>"
    }
    $html += "</table>"
} else {
    $html += "<p class='ok'>Nenhum driver com problema crítico.</p>"
}

$unsigned = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.IsSigned -eq $false }
if ($unsigned) {
    $html += "<h3>Drivers não assinados: $($unsigned.Count)</h3>"
}
$html += "</div>"
#endregion

#region 22. Botão e Fim
$html += @"
<a href="https://www.hpinfo.com.br" target="_blank" id="hp-floater">Visitar HPInfo</a>
<script>
    window.onscroll = function() { var btn = document.getElementById("hp-floater"); if (document.body.scrollTop > 100 || document.documentElement.scrollTop > 100) { btn.style.bottom = "auto"; btn.style.top = "20px"; } else { btn.style.bottom = "30px"; btn.style.top = "auto"; } };
</script>
</body></html>
"@

$html | Out-File $ReportPath -Encoding UTF8
Write-Output "Relatório salvo: $ReportPath"
try { Start-Process $ReportPath } catch {}
Write-Output "Finalizado."
#endregion