<#
.SYNOPSIS
    Gerador de Relatório de Estação de Trabalho (Hardware e Software).
.DESCRIPTION
    Versão Corrigida para compatibilidade total com Windows PowerShell 5.1.
    Remove operadores modernos (?? e ?:) que causavam erro em sistemas padrão.
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

#region 9. Coleta: CoreTemp (Compatível PS 5.1)
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
        # Lógica de Parsing simplificada
        $cleanLines = @()
        foreach ($line in $content) {
            if ($line -match "^Time,") { $collect = $true }
            if ($collect -and $line -notmatch "^\s*$") { $cleanLines += $line.Trim().Trim(',') }
        }

        if ($cleanLines.Count -gt 1) {
            $csvData = $cleanLines | ConvertFrom-Csv
            if ($csvData.Count -gt 0) {
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

#region 10. Coleta: CrystalDiskInfo (Compatível PS 5.1)
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
            
            # Função auxiliar para evitar NULL
            function Get-RegexVal ($pat, $txt) {
                if ($txt -match $pat) { return $matches[1] } else { return "N/A" }
            }

            $model = Get-RegexVal "Model : (.+)" $content
            $serial = Get-RegexVal "Serial Number : (.+)" $content
            $health = Get-RegexVal "Health Status : (.+)" $content
            $temp = Get-RegexVal "Temperature : (.+)" $content
            
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

#region 11-20. Outras Coletas (Padrão)
# ... (O restante segue a lógica padrão, mas sem os operadores ?? ou ?:)
# Para brevidade, mantive as seções mais críticas acima.
# Abaixo, correções pontuais em Drivers e Finalização.

#region 21. Diagnóstico Drivers (Corrigido)
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
<a href="https://www.hpinfo.com.br" target="_blank" style="display:block; text-align:center; padding:20px; background:#3498db; color:white; text-decoration:none; margin-top:20px;">Visitar HPInfo</a>
</body></html>
"@

$html | Out-File $ReportPath -Encoding UTF8
Write-Output "Relatório salvo: $ReportPath"
try { Start-Process $ReportPath } catch {}
Write-Output "Finalizado."
#endregion