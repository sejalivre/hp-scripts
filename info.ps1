<#
.SYNOPSIS
    Gerador de Relatório de Estação de Trabalho (Hardware e Software).

.DESCRIPTION
    Este script coleta informações detalhadas do sistema (CPU, RAM, Discos, Rede, 
    Drivers, Logs de Erro, etc.) e gera um relatório HTML interativo e estilizado.
    Baixa ferramentas externas (CoreTemp, CrystalDiskInfo) diretamente do GitHub.

.NOTES
    Arquivo: info.ps1
    Autor: [Seu Nome/Organização]
    Site: hpinfo.com.br
    Data: 2026
#>

$ErrorActionPreference = "SilentlyContinue"

#region 1. Configurações e Estilos
# ==============================================================================
# Configurações Iniciais
# ==============================================================================
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

#region 2. Preparação de Ferramentas (Download e Extração)
# ==============================================================================
# Baixa ferramentas do GitHub para pasta TEMP e extrai
# ==============================================================================

# --- BLOCO DE PREPARAÇÃO DE FERRAMENTAS ---
#region 2. Preparação de Ferramentas (Download e Extração)
# ==============================================================================
# Baixa ferramentas do GitHub para pasta TEMP e extrai em subpastas
# ==============================================================================

# --- DEFINIÇÃO DE CAMINHOS ---
$repoBase   = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir    = "$env:TEMP\HP-Tools"
$7zipTxe    = "$tempDir\7z.txe"
$7zipExe    = "$tempDir\7z.exe"
$Password   = "0" 

# 1. Garante que o diretório principal existe
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# 2. Função de Download
function Baixar-Ferramenta ($nomeArquivo) {
    $destino = "$tempDir\$nomeArquivo"
    $url = "$repoBase/$nomeArquivo"
    
    # Otimização: Se o arquivo .7z já existe, não baixa de novo (economiza banda)
    if (Test-Path $destino) { return $true }

    Write-Host " -> Baixando $nomeArquivo..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $url -OutFile $destino -ErrorAction Stop
    } catch {
        Write-Warning "ERRO ao baixar $nomeArquivo."
        return $false
    }
    return $true
}

# 3. Prepara o 7-Zip (Motor de extração)
Baixar-Ferramenta "7z.txe"
if (Test-Path $7zipTxe) {
    Copy-Item -Path $7zipTxe -Destination $7zipExe -Force
}

# 4. Lista de Ferramentas e Lógica de Extração
$ToolsToExtract = @(
    @{ Name = "CoreTemp";        Archive = "CoreTemp.7z";        SubFolder = "CoreTemp" }
    @{ Name = "CrystalDiskInfo"; Archive = "CrystalDiskInfo.7z"; SubFolder = "CrystalDiskInfo" }
)

$ExtractedPaths = @{}

if (Test-Path $7zipExe) {
    foreach ($tool in $ToolsToExtract) {
        
        # Define onde essa ferramenta específica vai morar
        $pastaDestino = Join-Path $tempDir $tool.SubFolder
        
        # Baixa o .7z
        if (Baixar-Ferramenta $tool.Archive) {
            
            # Se a pasta da ferramenta não existe, cria (para o 7z jogar dentro dela)
            if (-not (Test-Path $pastaDestino)) { New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null }

            Write-Host " -> Extraindo $($tool.Name)..." -ForegroundColor Yellow
            
            # A MÁGICA: O parametro -o agora aponta para a subpasta
            $argumentos = "x `"$tempDir\$($tool.Archive)`" -o`"$pastaDestino`" -p`"$Password`" -y"
            
            Start-Process -FilePath $7zipExe -ArgumentList $argumentos -Wait -NoNewWindow
            
            # Registra o caminho correto para o resto do script usar
            $ExtractedPaths[$tool.Name] = $pastaDestino
            
        }
    }
    Write-Host "Ferramentas prontas!" -ForegroundColor Green
} else {
    Write-Warning "Motor 7-Zip não encontrado. As ferramentas não serão extraídas."
}
Start-Sleep -Milliseconds 800
#endregion
#endregion

#region 3. Início do HTML
# ==============================================================================
# Cabeçalho HTML e Metadados
# ==============================================================================
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
        $html += "<tr>"
        $html += "<td>$($gpu.Name)</td>"
        $html += "<td>$ramMB MB</td>"
        $html += "<td>$($gpu.DriverVersion)</td>"
        $html += "<td>$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)</td>"
        $html += "</tr>"
    }
    $html += "</table>"
}
$html += "</div>"
#endregion

#region 7. Coleta: Discos Lógicos (Volumes)
$html += "<div class='section'><h2>3. Discos e Armazenamento (Volumes)</h2><table>"
$html += "<tr><th>Letra</th><th>Descrição</th><th>Tamanho</th><th>Livre</th><th>Uso %</th><th>Tipo</th></tr>"

Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $sizeGB  = [math]::Round($_.Size / 1GB, 1)
    $freeGB  = [math]::Round($_.FreeSpace / 1GB, 1)
    $usedPct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
    
    $colorClass = if ($usedPct -ge 90) {"crit"} elseif ($usedPct -ge 80) {"warn"} else {"ok"}
    
    $html += "<tr>"
    $html += "<td>$($_.DeviceID)</td>"
    $html += "<td>$($_.VolumeName)</td>"
    $html += "<td>$sizeGB GB</td>"
    $html += "<td>$freeGB GB</td>"
    $html += "<td class='$colorClass'>$usedPct %</td>"
    $html += "<td>$($_.FileSystem)</td>"
    $html += "</tr>"
}
$html += "</table></div>"
#endregion

#region 8. Coleta: Rede
$html += "<div class='section'><h2>4. Configuração de Rede</h2><table>"
$html += "<tr><th>Adaptador</th><th>IP</th><th>Máscara</th><th>Gateway</th><th>MAC</th></tr>"

Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
    $ip = Get-NetIPAddress -InterfaceAlias $_.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ip) {
        $html += "<tr>"
        $html += "<td>$($_.Name)</td>"
        $html += "<td>$($ip.IPAddress)</td>"
        $html += "<td>$($ip.PrefixLength)</td>"
        $gw = (Get-NetRoute -InterfaceAlias $_.Name -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop
        $html += "<td>$($gw -join ', ')</td>"
        $html += "<td>$($_.MacAddress)</td>"
        $html += "</tr>"
    }
}
$html += "</table></div>"
#endregion

#region 9. Coleta: CoreTemp (Temperatura CPU)
$html += "<div class='section'><h2>5. Temperaturas CPU (Core Temp)</h2>"

$coreTempPath = $ExtractedPaths["CoreTemp"]
if ($coreTempPath -and (Test-Path (Join-Path $coreTempPath "CoreTemp.exe"))) {
    $coreTempExe = Join-Path $coreTempPath "CoreTemp.exe"
    
    # USO DE WRITE-OUTPUT PARA STATUS
    Write-Output "Rodando CoreTemp..."
    $proc = Start-Process $coreTempExe -NoNewWindow -PassThru
    
    # Aguarda tempo suficiente para gerar log
    Start-Sleep -Seconds 15
    
    if (!$proc.HasExited) { Stop-Process -Id $proc.Id -Force }
    Start-Sleep -Seconds 3
    
    # Busca o log mais recente
    $log = Get-ChildItem $coreTempPath -Filter "CT-Log*.csv" | Sort-Object LastWriteTime -Descending | Select -First 1
    
    if ($log) {
        # USO DE WRITE-OUTPUT PARA STATUS
        Write-Output "Processando log CoreTemp: $($log.FullName)"
        
        $content = Get-Content $log.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        
        # Encontra onde começam os dados reais
        $dataStart = -1
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "^Time,") {
                $dataStart = $i
                break
            }
        }
        
        if ($dataStart -ge 0 -and $dataStart -lt $content.Count - 1) {
            # Limpeza e Parsing do CSV
            $cleanLines = @()
            for ($i = $dataStart; $i -lt $content.Count; $i++) {
                $line = $content[$i].Trim()
                if ($line -and $line -notmatch "^\s*$") {
                    if ($line -match ',$') { $line = $line -replace ',$', '' }
                    $cleanLines += $line
                }
            }
            
            if ($cleanLines.Count -gt 1) {
                $csvString = $cleanLines -join "`n"
                $csvData = $csvString | ConvertFrom-Csv
                
                if ($csvData.Count -gt 0) {
                    $tempCols = @(
                        'Cur. CPU #0 Core #0', 'Cur. CPU #0 Core #1', 'CPU #0 Package',
                        'CPU #0 IA Cores', 'CPU #0 iGPU', 'CPU #0 DRAM'
                    ) | Where-Object { $csvData[0].PSObject.Properties.Name -contains $_ }
                    
                    $processor = ($content | Where-Object { $_ -match "^Processor:," } | Select -First 1) -replace "^Processor:,",""
                    $html += "<p><strong>Processador:</strong> $($processor.Trim())<br>"
                    $html += "<strong>Arquivo Log:</strong> $($log.Name)</p>"
                    
                    # Tabela de leituras
                    $html += "<table><tr><th>Horário</th>"
                    foreach ($col in $tempCols) {
                        $short = $col -replace 'Cur\. | CPU #0 | #0','' -replace ' ',''
                        $html += "<th>$short</th>"
                    }
                    $html += "</tr>"
                    
                    foreach ($row in $csvData) {
                        $html += "<tr><td>$($row.Time ?? 'N/A')</td>"
                        foreach ($col in $tempCols) {
                            $valRaw = $row.$col ?? "0"
                            $val = [double]$valRaw / 1000  # Conversão específica do CoreTemp CSV
                            $class = if ($val -ge 92) {"crit"} elseif ($val -ge 82) {"warn"} else {"ok"}
                            $html += "<td class='$class'>$([math]::Round($val,1)) °C</td>"
                        }
                        $html += "</tr>"
                    }
                    $html += "</table>"
                    
                    # Resumo da ÚLTIMA medição
                    $last = $csvData[-1]
                    $core0   = [math]::Round(([double]($last.'Cur. CPU #0 Core #0' ?? 0))/1000, 1)
                    $package = [math]::Round(([double]($last.'CPU #0 Package' ?? 0))/1000, 1)
                    
                    $html += "<h3>Última Leitura</h3><table>"
                    $html += "<tr><th>Item</th><th>Valor</th></tr>"
                    $html += "<tr><td>Core 0 Atual</td><td class='$($core0 -ge 85 ? "crit" : "ok")'>$core0 °C</td></tr>"
                    $html += "<tr><td>Package Atual</td><td class='$($package -ge 90 ? "crit" : "ok")'>$package °C</td></tr>"
                    $html += "</table>"
                }
            }
        } else {
             $html += "<p class='warn'>Falha ao parsear CSV do CoreTemp.</p>"
        }
    } else {
        $html += "<p class='warn'>Nenhum log CT-Log*.csv encontrado</p>"
    }
} else {
    $html += "<p class='warn'>CoreTemp não extraído ou executável ausente (Verifique pasta tools)</p>"
}
$html += "</div>"
#endregion

#region 10. Coleta: CrystalDiskInfo (Saúde Disco)
$html += "<div class='section'><h2>6. Saúde do Disco (CrystalDiskInfo)</h2>"

$cdiPath = $ExtractedPaths["CrystalDiskInfo"]
if ($cdiPath) {
    $arch = if ([Environment]::Is64BitOperatingSystem) { "64" } else { "32" }
    $exe = Join-Path $cdiPath "DiskInfo$arch.exe"
    if ($arch -eq "64" -and (Test-Path (Join-Path $cdiPath "DiskInfo64.exe"))) { $exe = Join-Path $cdiPath "DiskInfo64.exe" }

    if (Test-Path $exe) {
        # USO DE WRITE-OUTPUT PARA STATUS
        Write-Output "Rodando CrystalDiskInfo..."
        Start-Process $exe -ArgumentList "/CopyExit" -NoNewWindow -Wait
        Start-Sleep -Seconds 5
        
        $logPath = Join-Path $cdiPath "DiskInfo.txt"
        if (Test-Path $logPath) {
            $html += "<p>Relatório DiskInfo.txt gerado com sucesso.</p>"
            
            $content = Get-Content $logPath -Encoding UTF8 -Raw
        
            # Extrai informações principais
            $model      = ($content | Select-String -Pattern "Model : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $firmware   = ($content | Select-String -Pattern "Firmware : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $serial     = ($content | Select-String -Pattern "Serial Number : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $size       = ($content | Select-String -Pattern "Disk Size : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $health     = ($content | Select-String -Pattern "Health Status : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $temperature= ($content | Select-String -Pattern "Temperature : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $poh        = ($content | Select-String -Pattern "Power On Hours : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            $poc        = ($content | Select-String -Pattern "Power On Count : (.+)")?.Matches.Groups[1].Value ?? "N/A"
            
            # Extrai atributos S.M.A.R.T. relevantes
            $smartSection = $content -split "-- S.M.A.R.T. --" | Select-Object -Index 1 -Skip 1
            $smartLines   = $smartSection -split "`n" | Where-Object { $_ -match "^[0-9A-F]{2} " }
            
            $reallocated = ($smartLines | Where-Object { $_ -match "^05 " })?.Split() | Select-Object -Index 1,2 ?? @("N/A", "N/A")
            $pending     = ($smartLines | Where-Object { $_ -match "^C5 " })?.Split() | Select-Object -Index 1,2 ?? @("N/A", "N/A")
            $uncorrect   = ($smartLines | Where-Object { $_ -match "^C6 " })?.Split() | Select-Object -Index 1,2 ?? @("N/A", "N/A")
            
            $badBlocksStatus = if ([int]$reallocated[0] -lt 100 -or [int]$pending[0] -lt 100 -or [int]$uncorrect[0] -lt 100) { "crit" } else { "ok" }
            
            $html += "<p><strong>Modelo:</strong> $model<br>"
            $html += "<strong>Serial:</strong> $serial<br>"
            $html += "<strong>Tamanho:</strong> $size<br>"
            $html += "<strong>Status de Saúde:</strong> <span class='$($health -match 'Saudável|Good' ? "ok" : "crit")'>$health</span><br>"
            $html += "<strong>Temperatura:</strong> <span class='$($temperature -match '^\d+ C' ? "ok" : "warn")'>$temperature</span><br>"
            $html += "<strong>Horas Ligado:</strong> $poh<br>"
            $html += "<strong>Ciclos de Energia:</strong> $poc</p>"
            
            $html += "<h3>Indicadores SMART Críticos</h3><table>"
            $html += "<tr><th>Atributo</th><th>Atual</th><th>Limiar</th><th>Status</th></tr>"
            $html += "<tr><td>Bad Blocks Reallocados (05)</td><td>$($reallocated[0])</td><td>$($reallocated[1])</td><td class='$badBlocksStatus'>$($badBlocksStatus -eq "ok" ? "OK" : "Atenção")</td></tr>"
            $html += "<tr><td>Setores Pendentes (C5)</td><td>$($pending[0])</td><td>$($pending[1])</td><td class='$badBlocksStatus'>$($badBlocksStatus -eq "ok" ? "OK" : "Atenção")</td></tr>"
            $html += "<tr><td>Setores Incorrigíveis (C6)</td><td>$($uncorrect[0])</td><td>$($uncorrect[1])</td><td class='$badBlocksStatus'>$($badBlocksStatus -eq "ok" ? "OK" : "Atenção")</td></tr>"
            $html += "</table>"

        } else {
            $html += "<p class='warn'>DiskInfo.txt não encontrado</p>"
        }
    } else {
        $html += "<p class='warn'>Executável CrystalDiskInfo não encontrado</p>"
    }
} else {
    $html += "<p class='warn'>CrystalDiskInfo não extraído</p>"
}
$html += "</div>"
#endregion

#region 11. Coleta: Discos Físicos (Detalhes)
$html += "<div class='section'><h2>11. Discos Físicos - Detalhes</h2>"
$disks = Get-CimInstance Win32_DiskDrive
if ($disks) {
    $html += "<table><tr><th>Modelo</th><th>Tamanho</th><th>Interface</th><th>Partições</th><th>Status</th></tr>"
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        $html += "<tr>"
        $html += "<td>$($disk.Model)</td>"
        $html += "<td>$sizeGB GB</td>"
        $html += "<td>$($disk.InterfaceType)</td>"
        $html += "<td>$($disk.Partitions)</td>"
        $html += "<td>$($disk.Status)</td>"
        $html += "</tr>"
    }
    $html += "</table>"
} else {
    $html += "<p class='warn'>Não foi possível obter informações dos discos físicos</p>"
}
$html += "</div>"
#endregion

#region 12. Coleta: Windows Update
$html += "<div class='section'><h2>7. Status de Atualizações (Windows Update)</h2>"
# USO DE WRITE-OUTPUT PARA STATUS
Write-Output "Coletando Windows Update..."

$hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5 -Property HotFixID, Description, InstalledOn
if ($hotfixes.Count -gt 0) {
    $html += "<h3>Últimos 5 patches instalados</h3>"
    $html += "<table><tr><th>KB ID</th><th>Descrição</th><th>Data</th></tr>"
    foreach ($hf in $hotfixes) {
        $dateStr = if ($hf.InstalledOn) { $hf.InstalledOn.ToString("dd/MM/yyyy") } else { "N/A" }
        $html += "<tr><td>$($hf.HotFixID)</td><td>$($hf.Description)</td><td>$dateStr</td></tr>"
    }
    $html += "</table>"
}
$html += "</div>"
#endregion

#region 13. Coleta: Top Processos (CPU/RAM)
$html += "<div class='section'><h2>8. Processos que mais consomem Recursos</h2>"
# USO DE WRITE-OUTPUT PARA STATUS
Write-Output "Coletando Top Processos..."

$topCPU = Get-Process | Sort-Object CPU -Descending -ErrorAction SilentlyContinue | Select-Object -First 5 -Property Name, Id, @{Name='CPU';Expression={[math]::Round($_.CPU,1)}}, @{Name='RAM';Expression={[math]::Round($_.WorkingSet / 1MB,1)}}
$topRAM = Get-Process | Sort-Object WorkingSet -Descending -ErrorAction SilentlyContinue | Select-Object -First 5 -Property Name, Id, @{Name='RAM';Expression={[math]::Round($_.WorkingSet / 1MB,1)}}, @{Name='CPU';Expression={[math]::Round($_.CPU,1)}}

$html += "<h3>Top 5 por CPU</h3><table><tr><th>Processo</th><th>PID</th><th>CPU(s)</th><th>RAM(MB)</th></tr>"
foreach ($p in $topCPU) { $html += "<tr><td>$($p.Name)</td><td>$($p.Id)</td><td>$($p.CPU)</td><td>$($p.RAM)</td></tr>" }
$html += "</table>"

$html += "<h3>Top 5 por RAM</h3><table><tr><th>Processo</th><th>PID</th><th>RAM(MB)</th><th>CPU(s)</th></tr>"
foreach ($p in $topRAM) { $html += "<tr><td>$($p.Name)</td><td>$($p.Id)</td><td>$($p.RAM)</td><td>$($p.CPU)</td></tr>" }
$html += "</table></div>"
#endregion

#region 14. Coleta: Logs de Erro (System)
$html += "<div class='section'><h2>9. Erros Recentes do Sistema (Últimos 7 dias)</h2>"
# USO DE WRITE-OUTPUT PARA STATUS
Write-Output "Coletando Eventos de Erro..."

$sysEvents = @()
try {
    $sysEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 10 -ErrorAction Stop
} catch {
    # Silencioso se não houver erros
}

$html += "<h3>System (Top 10)</h3>"

if ($sysEvents.Count -gt 0) {
    $html += "<table><tr><th>Data</th><th>Nível</th><th>ID</th><th>Mensagem</th></tr>"
    foreach ($evt in $sysEvents) {
        $msgText = if ($evt.Message) { $evt.Message } else { "Sem mensagem detalhada" }
        $msg = ($msgText -replace "`n"," " -replace "`r","")
        if ($msg.Length -gt 100) { $msg = $msg.Substring(0, 100) + "..." }

        $html += "<tr><td>$($evt.TimeCreated)</td><td class='crit'>$($evt.LevelDisplayName)</td><td>$($evt.Id)</td><td>$msg</td></tr>"
    }
    $html += "</table>"
} else {
    $html += "<p class='ok'>Nenhum erro crítico recente encontrado no log System.</p>"
}
$html += "</div>"
#endregion

#region 15. Coleta: Tela Azul (BSOD)
$html += "<div class='section'><h2>Histórico de Telas Azuis (BSOD)</h2>"
# Busca eventos de BugCheck nos últimos 30 dias
$bsodEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; ID=1001; StartTime=(Get-Date).AddDays(-30)} -ErrorAction SilentlyContinue

if ($bsodEvents) {
    $html += "<p class='crit'><strong>ATENÇÃO:</strong> Foram encontradas $($bsodEvents.Count) ocorrências de Tela Azul nos últimos 30 dias.</p>"
    $html += "<table><tr><th>Data</th><th>Mensagem de Erro (BugCheck)</th></tr>"
    
    foreach ($evt in $bsodEvents) {
        $msg = $evt.Message -replace "O computador foi reinicializado após uma verificação de erro. A verificação de erro foi: ","" 
        $html += "<tr><td>$($evt.TimeCreated)</td><td>$msg</td></tr>"
    }
    $html += "</table>"
} else {
    $html += "<p class='ok'>Nenhum registro de Tela Azul (BugCheck) encontrado nos últimos 30 dias.</p>"
}
$html += "</div>"
#endregion

#region 16. Coleta: Serviços Críticos
$html += "<div class='section'><h2>14. Serviços do Sistema - Status</h2>"
$criticalServices = @("Winmgmt", "EventLog", "Dhcp", "Dnscache", "Spooler", "WinDefend", "W32Time")
$html += "<table><tr><th>Serviço</th><th>Status</th><th>Tipo</th><th>Modo Inicialização</th></tr>"
foreach ($svcName in $criticalServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        $statusClass = if ($svc.Status -eq "Running") { "ok" } else { "crit" }
        $html += "<tr>"
        $html += "<td>$($svc.DisplayName)</td>"
        $html += "<td class='$statusClass'>$($svc.Status)</td>"
        $html += "<td>$($svc.ServiceType)</td>"
        $html += "<td>$($svc.StartType)</td>"
        $html += "</tr>"
    }
}
$html += "</table></div>"
#endregion

#region 17. Coleta: Inicialização (Autorun)
$html += "<div class='section'><h2>Programas de Inicialização</h2>"
$startup = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User

if ($startup) {
    $html += "<table><tr><th>Nome</th><th>Comando</th><th>Local</th><th>Usuário</th></tr>"
    foreach ($s in $startup) {
        $html += "<tr><td>$($s.Name)</td><td>$($s.Command)</td><td>$($s.Location)</td><td>$($s.User)</td></tr>"
    }
    $html += "</table>"
} else {
    $html += "<p class='ok'>Nenhum item de inicialização comum detectado via WMI.</p>"
}
$html += "</div>"
#endregion

#region 18. Coleta: Bateria
$html += "<div class='section'><h2>Saúde da Bateria</h2>"
$battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

if ($battery) {
    $fullCharge = $battery.DesignCapacity
    $currentCap = $battery.FullChargeCapacity
    
    if ($fullCharge -gt 0 -and $currentCap -gt 0) {
        $wearLevel = [math]::Round((($fullCharge - $currentCap) / $fullCharge) * 100, 1)
        $healthPct = 100 - $wearLevel
        
        $statusClass = if ($healthPct -lt 50) {"crit"} elseif ($healthPct -lt 70) {"warn"} else {"ok"}
        
        $html += "<table><tr><th>Status</th><th>Carga Restante</th><th>Saúde (Estimada)</th><th>Voltagem</th></tr>"
        $html += "<tr>"
        $html += "<td>$($battery.Status)</td>"
        $html += "<td>$($battery.EstimatedChargeRemaining)%</td>"
        $html += "<td class='$statusClass'>$healthPct% (Desgaste: $wearLevel%)</td>"
        $html += "<td>$($battery.DesignVoltage) mV</td>"
        $html += "</tr></table>"
        $html += "<p><em>Nota: Saúde baseada na Capacidade de Design vs. Capacidade de Carga Total reportada pelo firmware.</em></p>"
    } else {
         $html += "<p>Bateria detectada, mas não foi possível ler a capacidade de design/carga via WMI.</p>"
    }
} else {
    $html += "<p>Nenhuma bateria detectada (Desktop ou sem bateria).</p>"
}
$html += "</div>"
#endregion

#region 19. Coleta: BIOS
$html += "<div class='section'><h2>10. BIOS/UEFI e Firmware</h2>"
$bios = Get-CimInstance Win32_BIOS
$html += "<table><tr><th>Propriedade</th><th>Valor</th></tr>"
$html += "<tr><td>Fabricante</td><td>$($bios.Manufacturer)</td></tr>"
$html += "<tr><td>Versão</td><td>$($bios.SMBIOSBIOSVersion)</td></tr>"
$html += "<tr><td>Data</td><td>$($bios.ReleaseDate)</td></tr>"
$html += "<tr><td>SMBIOS</td><td>$($bios.SMBIOSMajorVersion).$($bios.SMBIOSMinorVersion)</td></tr>"
$html += "</table></div>"
#endregion

#region 20. Resumo e Diagnóstico Rápido
$html += "<div class='section'><h2>18. Diagnóstico Rápido - Pontos de Atenção</h2>"
$html += "<table><tr><th>Item</th><th>Status</th><th>Recomendação</th></tr>"

# Verifica espaço em disco
$diskCheck = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1) -ge 85 }
if ($diskCheck) {
    $html += "<tr><td>Espaço em disco</td><td class='crit'>CRÍTICO</td><td>Limpe arquivos temporários</td></tr>"
} else {
    $html += "<tr><td>Espaço em disco</td><td class='ok'>OK</td><td>Disponível > 15%</td></tr>"
}

# Verifica memória
$osmem = Get-CimInstance Win32_OperatingSystem
$usedPct = [math]::Round(($osmem.TotalVisibleMemorySize - $osmem.FreePhysicalMemory) / $osmem.TotalVisibleMemorySize * 100, 0)
if ($usedPct -ge 90) {
    $html += "<tr><td>Uso de memória</td><td class='crit'>CRÍTICO ($usedPct%)</td><td>Considere aumentar RAM</td></tr>"
} elseif ($usedPct -ge 80) {
    $html += "<tr><td>Uso de memória</td><td class='warn'>ALERTA ($usedPct%)</td><td>Verifique processos</td></tr>"
} else {
    $html += "<tr><td>Uso de memória</td><td class='ok'>OK ($usedPct%)</td><td>Nível normal</td></tr>"
}

# Verifica temperatura e disco (referências)
$html += "<tr><td>Temperatura CPU</td><td>Ver seção 5</td><td>Abaixo de 80°C ideal</td></tr>"
$html += "<tr><td>Saúde do disco</td><td>Ver seção 6</td><td>Status Saudável/Good</td></tr>"

# Verifica atualizações
$lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1 -ExpandProperty InstalledOn
$daysSinceUpdate = if ($lastUpdate) { ((Get-Date) - $lastUpdate).Days } else { 999 }
if ($daysSinceUpdate -gt 30) {
    $html += "<tr><td>Atualizações</td><td class='crit'>ATRASADO ($daysSinceUpdate dias)</td><td>Execute Windows Update</td></tr>"
} else {
    $html += "<tr><td>Atualizações</td><td class='ok'>ATUALIZADO</td><td>Última: $($lastUpdate.ToString('dd/MM/yyyy'))</td></tr>"
}

$html += "</table></div>"
#endregion

#region 21. Diagnóstico de Drivers (Avançado)
$html += "<div class='section'><h2>X. Diagnóstico de Drivers de Hardware</h2>"

# USO DE WRITE-OUTPUT PARA STATUS
Write-Output "Analisando drivers de dispositivo..."

# 1. Drivers com problemas (Error, Disabled, Unknown)
$badDrivers = Get-CimInstance Win32_PnPEntity | Where-Object {
    $_.ConfigManagerErrorCode -ne 0 -or 
    $_.Status -ne "OK" -or
    $_.Status -eq "Error" -or
    $_.Status -eq "Degraded" -or
    $_.Status -eq "Unknown"
} | Select-Object Name, DeviceID, Status, ConfigManagerErrorCode, @{
    Name="ErrorDesc"; Expression={
        switch ($_.ConfigManagerErrorCode) {
            0   { "OK" }
            1   { "Configurado incorretamente" }
            2   { "Driver ausente" }
            3   { "Driver defeituoso" }
            4   { "Driver ou serviço carregado com falha" }
            5   { "Conflito de driver" }
            6   { "Configuração inválida" }
            7   { "Driver ausente" }
            8   { "Recurso insuficiente" }
            9   { "Falha de BIOS" }
            10  { "Driver não pode iniciar" }
            11  { "Falha de certificação" }
            12  { "Hardware removido" }
            13  { "Falha de compatibilidade" }
            14  { "Arquivo de driver ausente" }
            15  { "Driver desativado" }
            16  { "Falha de driver" }
            17  { "Hardware não configurável" }
            18  { "Falha de teste/assinatura" }
            19  { "Driver bloqueado" }
            20  { "Hardware ausente" }
            21  { "Problema de segurança" }
            22  { "Problema de instalação" }
            23  { "Falha de interface" }
            24  { "Driver obsoleto" }
            default { "Código desconhecido: $_" }
        }
    }
}

# 2. Drivers sem assinatura digital
$unsignedDrivers = Get-CimInstance Win32_PnPSignedDriver | Where-Object {
    $_.IsSigned -eq $false -or 
    $_.DriverVersion -eq $null -or
    $_.DriverDate -lt (Get-Date).AddYears(-3)
} | Select-Object DeviceName, DriverVersion, DriverDate, IsSigned, @{
    Name="DriverAge"; Expression={
        if ($_.DriverDate) {
            $age = New-TimeSpan -Start $_.DriverDate -End (Get-Date)
            "$([math]::Round($age.TotalDays/365,1)) anos"
        } else { "Desconhecido" }
    }
}

# 3. Drivers críticos do sistema
$criticalDrivers = Get-CimInstance Win32_SystemDriver | Where-Object {
    $_.StartMode -eq "Auto" -and 
    $_.State -ne "Running" -and
    $_.Status -ne "OK"
} | Select-Object Name, DisplayName, State, Status, StartMode

# 4. Exibir resultados de Drivers
if ($badDrivers.Count -gt 0) {
    $html += "<h3 class='crit'>⚠ Drivers com Problemas Detectados: $($badDrivers.Count)</h3>"
    $html += "<table><tr><th>Dispositivo</th><th>Status</th><th>Código Erro</th><th>Descrição</th></tr>"
    foreach ($driver in $badDrivers | Sort-Object ConfigManagerErrorCode -Descending) {
        $errorClass = if ($driver.ConfigManagerErrorCode -ge 10) { "crit" } elseif ($driver.ConfigManagerErrorCode -ge 1) { "warn" } else { "ok" }
        $html += "<tr>"
        $html += "<td>$($driver.Name)</td>"
        $html += "<td class='$errorClass'>$($driver.Status)</td>"
        $html += "<td>$($driver.ConfigManagerErrorCode)</td>"
        $html += "<td>$($driver.ErrorDesc)</td>"
        $html += "</tr>"
    }
    $html += "</table>"
} else {
    $html += "<p class='ok'>✅ Nenhum driver com problemas críticos detectado.</p>"
}

# Exibição de drivers não assinados e sistema...
if ($unsignedDrivers.Count -gt 0) {
    $html += "<h3>⚠ Drivers Sem Assinatura ou Obsoletos: $($unsignedDrivers.Count)</h3>"
    $html += "<table><tr><th>Driver</th><th>Versão</th><th>Data</th><th>Idade</th><th>Assinado</th></tr>"
    foreach ($driver in $unsignedDrivers | Sort-Object DriverDate) {
        $ageClass = if ($driver.DriverDate -lt (Get-Date).AddYears(-5)) { "crit" } 
                   elseif ($driver.DriverDate -lt (Get-Date).AddYears(-3)) { "warn" } 
                   else { "ok" }
        $signClass = if ($driver.IsSigned -eq $false) { "crit" } else { "ok" }
        
        $dateStr = if ($driver.DriverDate) { $driver.DriverDate.ToString("dd/MM/yyyy") } else { "N/A" }
        $html += "<tr>"
        $html += "<td>$($driver.DeviceName)</td>"
        $html += "<td>$($driver.DriverVersion ?? 'N/A')</td>"
        $html += "<td>$dateStr</td>"
        $html += "<td class='$ageClass'>$($driver.DriverAge)</td>"
        $html += "<td class='$signClass'>$($driver.IsSigned)</td>"
        $html += "</tr>"
    }
    $html += "</table>"
}

if ($criticalDrivers.Count -gt 0) {
    $html += "<h3 class='warn'>⚠ Drivers do Sistema com Problemas: $($criticalDrivers.Count)</h3>"
    $html += "<table><tr><th>Serviço Driver</th><th>Nome Amigável</th><th>Estado</th><th>Modo Inicialização</th></tr>"
    foreach ($driver in $criticalDrivers) {
        $stateClass = if ($driver.State -ne "Running") { "crit" } else { "ok" }
        $html += "<tr>"
        $html += "<td>$($driver.Name)</td>"
        $html += "<td>$($driver.DisplayName)</td>"
        $html += "<td class='$stateClass'>$($driver.State)</td>"
        $html += "<td>$($driver.StartMode)</td>"
        $html += "</tr>"
    }
    $html += "</table>"
}

# 5. Resumo por categoria
$html += "<h3>📊 Resumo de Drivers por Categoria</h3>"
$deviceClasses = Get-CimInstance Win32_PnPEntity | Group-Object Class | Sort-Object Count -Descending | Select-Object -First 10

$html += "<table><tr><th>Categoria</th><th>Total</th><th>Com Problemas</th><th>% Problemas</th></tr>"
foreach ($class in $deviceClasses) {
    $problemCount = ($class.Group | Where-Object { $_.ConfigManagerErrorCode -ne 0 }).Count
    $percent = if ($class.Count -gt 0) { [math]::Round(($problemCount / $class.Count) * 100, 1) } else { 0 }
    $percentClass = if ($percent -ge 20) { "crit" } elseif ($percent -ge 10) { "warn" } else { "ok" }
    
    $html += "<tr>"
    $html += "<td>$($class.Name)</td>"
    $html += "<td>$($class.Count)</td>"
    $html += "<td>$problemCount</td>"
    $html += "<td class='$percentClass'>$percent%</td>"
    $html += "</tr>"
}
$html += "</table>"

# 6. Ações Recomendadas
$html += "<h3>🔧 Ações Recomendadas</h3>"
$html += "<ul style='text-align: left;'>"
$html += "<li><strong>Erro 1, 2, 3, 7, 14:</strong> Reinstale o driver do dispositivo</li>"
$html += "<li><strong>Erro 4, 10, 16:</strong> Execute 'sc stop' e 'sc start' no serviço do driver</li>"
$html += "<li><strong>Erro 5:</strong> Verifique conflitos no Gerenciador de Dispositivos</li>"
$html += "<li><strong>Erro 9:</strong> Atualize o BIOS/UEFI</li>"
$html += "<li><strong>Erro 18, 19, 21:</strong> Verifique assinatura digital e políticas de segurança</li>"
$html += "<li><strong>Drivers antigos (>3 anos):</strong> Considere atualização para melhor desempenho e segurança</li>"
$html += "</ul>"
$html += "</div>"
#endregion

#region 22. Botão Flutuante e Scripts JS
$html += @"
<style>
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
    .stick-to-top {
        bottom: auto !important; top: 20px !important;
        background-color: #2c3e50 !important; opacity: 0.9;
    }
</style>

<a href="https://www.hpinfo.com.br" target="_blank" id="hp-floater">www.hpinfo.com.br</a>

<script>
    window.onscroll = function() { moveButton() };
    function moveButton() {
        var btn = document.getElementById("hp-floater");
        if (document.body.scrollTop > 100 || document.documentElement.scrollTop > 100) {
            btn.classList.add("stick-to-top");
        } else {
            btn.classList.remove("stick-to-top");
        }
    }
</script>
"@
#endregion

#region 23. Finalização e Salvamento
$html += "</body></html>"

$html | Out-File $ReportPath -Encoding UTF8
# USO DE WRITE-OUTPUT PARA STATUS FINAL
Write-Output "Relatório salvo em: $ReportPath"

try { Start-Process $ReportPath } catch {}
# USO DE WRITE-OUTPUT PARA STATUS FINAL
Write-Output "Finalizado."
#endregion
