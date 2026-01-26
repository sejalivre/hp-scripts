# ==========================================
# PERF.ps1 - Diagnóstico Profissional 
# HP Scripts | https://www.hpinfo.com.br
# ==========================================

# -------------------------------
# Admin Check 
# -------------------------------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "[❌] Este script precisa ser executado como Administrador." -ForegroundColor Red
    Pause
    Exit 1
}



# -------------------------------
# Paths
# -------------------------------
$basePath = "C:\ProgramData\HPInfo"
$historyFile = "$basePath\perf-history.json"
New-Item -ItemType Directory -Force -Path $basePath | Out-Null

# -------------------------------
# Functions
# -------------------------------
function Get-PerfSnapshot {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu  = (Get-Counter '\\Processor(_Total)\\% Processor Time').CounterSamples.CookedValue
    $disk = (Get-Counter '\\PhysicalDisk(_Total)\\% Disk Time').CounterSamples.CookedValue

    $memTotal = $os.TotalVisibleMemorySize
    $memFree  = $os.FreePhysicalMemory
    $ramUsed  = (($memTotal - $memFree) / $memTotal) * 100

    [pscustomobject]@{
        CPU  = [math]::Round($cpu,1)
        RAM  = [math]::Round($ramUsed,1)
        DISK = [math]::Round($disk,1)
    }
}

function Get-Score {
    param($snap)
    $s = 100
    $s -= [math]::Min($snap.CPU,40)
    $s -= [math]::Min($snap.RAM,30)
    $s -= [math]::Min($snap.DISK,30)
    if ($s -lt 0) { $s = 0 }
    [math]::Round($s,0)
}

function Get-ScoreColor {
    param($score)
    if ($score -ge 80) { "green" }
    elseif ($score -ge 60) { "orange" }
    else { "red" }
}

# -------------------------------
# BEFORE
# -------------------------------
$before = Get-PerfSnapshot
$scoreBefore = Get-Score $before
$colorBefore = Get-ScoreColor $scoreBefore

# -------------------------------
# LIMP integration
# -------------------------------
try { irm get.hpinfo.com.br/limp | iex } catch {}

Start-Sleep 5

# -------------------------------
# AFTER
# -------------------------------
$after = Get-PerfSnapshot
$scoreAfter = Get-Score $after
$colorAfter = Get-ScoreColor $scoreAfter

# -------------------------------
# History
# -------------------------------
$hostname = $env:COMPUTERNAME
$entry = [pscustomobject]@{
    Date = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    Before = $scoreBefore
    After  = $scoreAfter
}

$history = @{}
if (Test-Path $historyFile) {
    $history = Get-Content $historyFile | ConvertFrom-Json
}

$history.$hostname += @($entry)
$history | ConvertTo-Json -Depth 5 | Out-File $historyFile -Encoding UTF8

# -------------------------------
# HTML Report
# -------------------------------
$report = "$env:TEMP\PERF_Report_$hostname.html"

$html = @"
<html>
<head>
<title>Relatório de Performance</title>
<style>
body { font-family:Segoe UI; }
.score { font-size:26px; font-weight:bold; }
.green{color:#2e7d32;} .orange{color:#f9a825;} .red{color:#c62828;}
.bar { height:22px; background:#ddd; margin:5px 0; }
.fill { height:100%; }
@media print {
  body { background:#fff; }
}
</style>
</head>
<body>

<h1>Relatório de Performance</h1>
<b>Host:</b> $hostname<br>
<b>Data:</b> $(Get-Date)

<h2>Score</h2>
<p class="score $colorBefore">Antes: $scoreBefore / 100</p>
<p class="score $colorAfter">Depois: $scoreAfter / 100</p>

<h2>Gráfico Comparativo</h2>

CPU
<div class="bar"><div class="fill" style="width:$($after.CPU)%;background:#4caf50"></div></div>
RAM
<div class="bar"><div class="fill" style="width:$($after.RAM)%;background:#2196f3"></div></div>
DISK
<div class="bar"><div class="fill" style="width:$($after.DISK)%;background:#f44336"></div></div>

<h2>Conclusão Técnica</h2>
<ul>
<li>Score abaixo de 60 indica gargalo crítico</li>
<li>Disco alto sugere HD degradado</li>
<li>RAM alta sugere upgrade</li>
</ul>

<hr>
HP Scripts – Diagnóstico Profissional

</body>
</html>
"@

$html | Out-File $report -Encoding UTF8
Start-Process $report

Write-Host "Relatório gerado com sucesso."
Pause
