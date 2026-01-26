param(
    [switch]$AfterClean
)

# ==========================================================
# ADMIN CHECK
# ==========================================================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "[❌] Execute como Administrador." -ForegroundColor Red
    Pause
    Exit 1
}

Write-Host "`n[🚀] Iniciando PERF..." -ForegroundColor Cyan

# ==========================================================
# PATHS
# ==========================================================
$BaseDir   = "$env:ProgramData\HPInfo\PERF"
$HistDir   = "$BaseDir\history"
$ReportDir = "$BaseDir\reports"

New-Item -ItemType Directory -Force -Path $HistDir, $ReportDir | Out-Null

$Computer = $env:COMPUTERNAME
$Now      = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$JsonFile = "$HistDir\$Computer.json"
$HtmlFile = "$ReportDir\PERF_$Computer_$Now.html"

# ==========================================================
# FUNCTIONS
# ==========================================================

function Get-DiskUsage {
    # Tenta Performance Counter
    try {
        $paths = (Get-Counter -ListSet PhysicalDisk -ErrorAction Stop).Paths
        if ($paths -contains '\PhysicalDisk(_Total)\Disk Transfers/sec') {
            $v = (Get-Counter '\PhysicalDisk(_Total)\Disk Transfers/sec' -SampleInterval 1 -MaxSamples 2
            ).CounterSamples[-1].CookedValue

            return [math]::Min(100, [math]::Round(($v / 200) * 100, 1))
        }
    } catch {}

    # Fallback via CIM
    try {
        $disk = Get-CimInstance Win32_PerfFormattedData_PerfDisk_LogicalDisk |
            Where-Object { $_.Name -eq "_Total" }

        if ($disk) {
            return [math]::Round($disk.PercentDiskTime, 1)
        }
    } catch {}

    # Último recurso
    return 5
}

# ==========================================================
# METRICS
# ==========================================================

# CPU
$CpuUsage = (Get-CimInstance Win32_Processor |
    Measure-Object LoadPercentage -Average
).Average

# Memory
$OS = Get-CimInstance Win32_OperatingSystem
$MemTotal = $OS.TotalVisibleMemorySize
$MemFree  = $OS.FreePhysicalMemory
$MemUsed  = [math]::Round((($MemTotal - $MemFree) / $MemTotal) * 100, 1)

# Disk
$DiskUsage = Get-DiskUsage

# ==========================================================
# SCORE
# ==========================================================
$Score = [math]::Round(
    100 -
    ($CpuUsage * 0.4) -
    ($MemUsed  * 0.3) -
    ($DiskUsage * 0.3)
)

if ($Score -lt 0) { $Score = 0 }

# Color
if ($Score -ge 75) {
    $Color = "green"
} elseif ($Score -ge 50) {
    $Color = "orange"
} else {
    $Color = "red"
}

# ==========================================================
# SNAPSHOT
# ==========================================================
$Snapshot = [PSCustomObject]@{
    Date   = (Get-Date)
    CPU    = $CpuUsage
    Memory = $MemUsed
    Disk   = $DiskUsage
    Score  = $Score
    Mode   = if ($AfterClean) { "AFTER" } else { "BEFORE" }
}

# ==========================================================
# HISTORY
# ==========================================================
$History = @()

if (Test-Path $JsonFile) {
    $data = Get-Content $JsonFile | ConvertFrom-Json

    if ($data -is [System.Array]) {
        $History = $data
    } else {
        $History = @($data)
    }
}

$History += $Snapshot


# ==========================================================
# HTML
# ==========================================================
$Html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>HP Info - Performance Report</title>
<style>
body { font-family: Segoe UI, Arial; background:#f4f4f4; padding:20px }
.card { background:#fff; padding:20px; border-radius:8px; box-shadow:0 0 8px #ccc; margin-bottom:20px }
.bar { height:22px; border-radius:5px }
table { border-collapse: collapse }
td, th { padding:6px 10px; border:1px solid #ccc }
</style>
</head>
<body>

<h1>HP Info - Performance Report</h1>
<p><b>Máquina:</b> $Computer<br>
<b>Data:</b> $(Get-Date)</p>

<div class="card">
<h2>Score Geral</h2>
<div class="bar" style="width:$Score%; background:$Color"></div>
<p><b>$Score / 100</b></p>
</div>

<div class="card">
<h2>Métricas Atuais</h2>
<ul>
<li>CPU: $CpuUsage%</li>
<li>Memória: $MemUsed%</li>
<li>Disco: $DiskUsage%</li>
</ul>
</div>
"@

if ($Before -and $After) {
$Html += @"
<div class="card">
<h2>Antes vs Depois</h2>
<table>
<tr><th></th><th>Antes</th><th>Depois</th></tr>
<tr><td>CPU</td><td>$($Before.CPU)%</td><td>$($After.CPU)%</td></tr>
<tr><td>Memória</td><td>$($Before.Memory)%</td><td>$($After.Memory)%</td></tr>
<tr><td>Disco</td><td>$($Before.Disk)%</td><td>$($After.Disk)%</td></tr>
<tr><td>Score</td><td>$($Before.Score)</td><td>$($After.Score)</td></tr>
</table>
</div>
"@
}

$Html += "</body></html>"

$Html | Set-Content $HtmlFile -Encoding UTF8

# ==========================================================
# OUTPUT 
# ==========================================================
Write-Host "[✔] Score: $Score / 100" -ForegroundColor Green
Write-Host "[📄] Relatório gerado: $HtmlFile" -ForegroundColor Cyan

Start-Process $HtmlFile
