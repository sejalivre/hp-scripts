# ==========================================================
# HP Scripts - PERF.ps1
# Análise de Performance do Sistema
# ==========================================================

param (
    [switch]$AfterClean
)

# ---------------- ADMIN CHECK ----------------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "[❌] Execute como Administrador." -ForegroundColor Red
    Pause
    Exit 1
}

Write-Host "`n[🚀] Iniciando PERF..." -ForegroundColor Cyan

# ---------------- PATHS ----------------
$BaseDir   = "$env:ProgramData\HPInfo\PERF"
$HistDir   = "$BaseDir\history"
$ReportDir = "$BaseDir\reports"

New-Item -ItemType Directory -Force -Path $HistDir, $ReportDir | Out-Null

$Computer = $env:COMPUTERNAME
$Now      = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$JsonFile = "$HistDir\$Computer.json"
$HtmlFile = "$ReportDir\PERF_$Computer_$Now.html"

# ---------------- COLLECT METRICS ----------------

# CPU
$CpuUsage = (Get-CimInstance Win32_Processor |
    Measure-Object LoadPercentage -Average
).Average

# Memory
$OS = Get-CimInstance Win32_OperatingSystem
$MemTotal = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 1)
$MemFree  = [math]::Round($OS.FreePhysicalMemory / 1MB, 1)
$MemUsed  = [math]::Round((($MemTotal - $MemFree) / $MemTotal) * 100, 1)

# Disk IO
$DiskIO = (Get-Counter '\PhysicalDisk(_Total)\Disk Transfers/sec' -SampleInterval 1 -MaxSamples 2
).CounterSamples[-1].CookedValue

$DiskUsage = [math]::Min(100, [math]::Round(($DiskIO / 200) * 100, 1))

# ---------------- SCORE ----------------
$Score = [math]::Round(
    100 -
    ($CpuUsage * 0.4) -
    ($MemUsed  * 0.3) -
    ($DiskUsage * 0.3)
)

if ($Score -lt 0) { $Score = 0 }

# ---------------- COLOR ----------------
if ($Score -ge 75) {
    $Color = "green"
} elseif ($Score -ge 50) {
    $Color = "orange"
} else {
    $Color = "red"
}

# ---------------- SNAPSHOT ----------------
$Snapshot = [PSCustomObject]@{
    Date       = Get-Date
    CPU        = $CpuUsage
    Memory     = $MemUsed
    Disk       = $DiskUsage
    Score      = $Score
    Mode       = if ($AfterClean) { "AFTER" } else { "BEFORE" }
}

# ---------------- HISTORY ----------------
$History = @()
if (Test-Path $JsonFile) {
    $History = Get-Content $JsonFile | ConvertFrom-Json
}

$History += $Snapshot
$History | ConvertTo-Json -Depth 5 | Set-Content $JsonFile

# ---------------- COMPARE ----------------
$Before = $History | Where-Object { $_.Mode -eq "BEFORE" } | Select-Object -Last 1
$After  = $History | Where-Object { $_.Mode -eq "AFTER"  } | Select-Object -Last 1

# ---------------- HTML ----------------
$Html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>HP Info - Performance Report</title>
<style>
body { font-family: Segoe UI; background:#f4f4f4; padding:20px }
.card { background:white; padding:20px; border-radius:8px; box-shadow:0 0 10px #ccc }
.bar { height:20px; border-radius:5px }
</style>
</head>
<body>

<h1>HP Info - Performance Report</h1>
<h3>Máquina: $Computer</h3>
<p>Data: $(Get-Date)</p>

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
<h2>Comparação Antes vs Depois</h2>
<table border="1" cellpadding="5">
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

# ---------------- OUTPUT ----------------
Write-Host "[✔] Score: $Score/100" -ForegroundColor Green
Write-Host "[📄] Relatório gerado: $HtmlFile" -ForegroundColor Cyan

Start-Process $HtmlFile
