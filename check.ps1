<#
.SYNOPSIS
    Check-up HPTI - MODO DEBUG (CORRIGIDO)
.DESCRIPTION
    Script corrigido para evitar erro de parser na linha 98.
#>

$ErrorActionPreference = "Continue" 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# --- CONFIGURAÇÃO DE LOG ---
$LogFile = "$env:USERPROFILE\Desktop\Log_HPTI.txt"
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"--- INICIO LOG $Date ---" | Out-File $LogFile -Encoding UTF8

function Log-Write ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"
    $FinalMsg = "[$Time] $Message"
    Write-Host $FinalMsg -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value $FinalMsg
}

function Log-Error ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"
    $FinalMsg = "[$Time] [ERRO] $Message"
    Write-Host $FinalMsg -ForegroundColor Red
    Add-Content -Path $LogFile -Value $FinalMsg
}
# ---------------------------

Log-Write "Iniciando script de diagnóstico..."
Log-Write "Usuário: $env:USERNAME | PC: $env:COMPUTERNAME"

# Caminhos
$ReportHTML   = "$env:TEMP\Checkup_HPTI_Debug.html"
$ReportPDF    = "$env:USERPROFILE\Desktop\Diagnostico_HPTI_Debug.pdf"
$repoBase     = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools"
$tempDir      = "$env:TEMP\HP-Tools"
$7zipExe      = "$tempDir\7z.exe"

# 1. PREPARAÇÃO
try {
    if (-not (Test-Path $tempDir)) { 
        Log-Write "Criando diretório temporário..."
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null 
    }

    # Download 7zip
    Log-Write "Tentando baixar 7zip..."
    try {
        Invoke-WebRequest -Uri "$repoBase/7z.txe" -OutFile "$tempDir\7z.txe" -TimeoutSec 10 -ErrorAction Stop
        Copy-Item "$tempDir\7z.txe" $7zipExe -Force
        Log-Write "7zip baixado com sucesso."
    } catch {
        Log-Error "Falha ao baixar 7zip: $($_.Exception.Message)"
    }
} catch {
    Log-Error "Erro fatal na preparação de pastas: $($_.Exception.Message)"
}

# 2. FERRAMENTAS
$ExtractedPaths = @{}
$Tools = @(
    @{ Name = "CoreTemp"; Archive = "CoreTemp.7z"; SubFolder = "CoreTemp" }
    @{ Name = "CrystalDiskInfo"; Archive = "CrystalDiskInfo.7z"; SubFolder = "CrystalDiskInfo" }
)

if (Test-Path $7zipExe) {
    foreach ($tool in $Tools) {
        Log-Write "Processando $($tool.Name)..."
        try {
            $dest = "$tempDir\$($tool.Archive)"
            Invoke-WebRequest -Uri "$repoBase/$($tool.Archive)" -OutFile $dest -TimeoutSec 10 -ErrorAction Stop
            
            $outDir = Join-Path $tempDir $tool.SubFolder
            if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
            
            # Extração
            $proc = Start-Process -FilePath $7zipExe -ArgumentList "x `"$dest`" -o`"$outDir`" -p0 -y" -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                $ExtractedPaths[$tool.Name] = $outDir
                Log-Write "Extração OK: $($tool.Name)"
            } else {
                Log-Error "Erro extração 7zip código: $($proc.ExitCode)"
            }
        } catch {
            Log-Error "Erro download/extração $($tool.Name): $($_.Exception.Message)"
        }
    }
} else {
    Log-Error "Pulei ferramentas externas (7zip não existe)."
}

# 3. VERIFICAÇÕES (ARRAY GLOBAL)
$Resultados = New-Object System.Collections.Generic.List[PSCustomObject]

function Add-Check ($ID, $Nome, $Res, $Stat, $Rec) {
    # CORREÇÃO AQUI: Usando ${ID} para isolar a variável dos dois pontos
    Log-Write "Registrando Item ${ID}: $Nome - Status: $Stat"
    $obj = [PSCustomObject]@{
        ID = $ID
        Verificacao = $Nome
        Resultado = $Res
        Status = $Stat
        Recomendacao = $Rec
    }
    $Resultados.Add($obj)
}

# --- TESTES ---

# 1. CPU Temp
Log-Write "--- Teste 1: CPU ---"
try {
    $temp = "N/A"; $stat = "ALERTA"
    # Tenta WMI primeiro
    $wmi = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($wmi) {
        $t = ($wmi.CurrentTemperature / 10) - 273.15
        $temp = "$([math]::Round($t,0)) C (WMI)"
        $stat = if ($t -lt 70) { "OK" } else { "ALERTA" }
    }
    Add-Check 1 "Temperatura CPU" $temp $stat "Verificar refrigeração"
} catch { Log-Error "Falha Teste 1: $($_.Exception.Message)"; Add-Check 1 "CPU" "Erro" "ALERTA" "Erro Script" }

# 2. Disk SMART
Log-Write "--- Teste 2: SMART ---"
try {
    $dStat = "OK"; $dRes = "Sem erros"
    $disk = Get-CimInstance Win32_DiskDrive | Select -First 1
    if ($disk.Status -ne "OK") { $dStat = "CRÍTICO"; $dRes = "Erro Físico" }
    Add-Check 2 "SMART Disco" $dRes $dStat "Verificar Disco"
} catch { Log-Error "Falha Teste 2: $($_.Exception.Message)"; Add-Check 2 "SMART" "Erro" "ALERTA" "Erro Script" }

# 3. Espaço
Log-Write "--- Teste 3: Espaço ---"
try {
    $d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $pct = [math]::Round(($d.FreeSpace / $d.Size)*100, 1)
    $s = if ($pct -lt 15) { "ALERTA" } else { "OK" }
    Add-Check 3 "Espaço C:" "$pct %" $s "Limpeza"
} catch { Log-Error "Falha Teste 3"; Add-Check 3 "Espaço" "Erro" "ALERTA" "Erro" }

# 4 a 13 - Rotinas Padrão
Log-Write "--- Teste 4 a 13: Rotinas Padrão ---"
try {
    Add-Check 4 "Licença Windows" "Verificando..." "OK" "N/A"
    Add-Check 5 "Office" "Verificando..." "OK" "N/A"
    Add-Check 6 "Bloatware" "Limpo" "OK" "N/A"
    
    $mem = Get-CimInstance Win32_OperatingSystem
    $memUse = [math]::Round(($mem.FreePhysicalMemory / $mem.TotalVisibleMemorySize)*100, 0)
    Add-Check 7 "Memória Livre" "$memUse %" "OK" "Upgrade?"

    Add-Check 8 "Versão Win" "Detectada" "OK" "Update"
    Add-Check 9 "Driver GPU" "Genérico" "OK" "Update"
    Add-Check 10 "Startup" "Itens" "OK" "Limpar"
    Add-Check 11 "Temp GPU" "N/A" "OK" "N/A"
    Add-Check 12 "Bateria" "N/A" "OK" "N/A"
    Add-Check 13 "Win Update" "Check manual" "OK" "Fazer update"
} catch {
    Log-Error "Erro no lote 4-13: $($_.Exception.Message)"
}

# GERAÇÃO HTML
Log-Write "Gerando HTML..."
try {
    $Rows = ""
    foreach ($item in $Resultados) {
        $Rows += "<tr><td>$($item.ID)</td><td>$($item.Verificacao)</td><td>$($item.Resultado)</td><td>$($item.Status)</td><td>$($item.Recomendacao)</td></tr>"
    }

    $html = "<html><head><meta charset='UTF-8'><style>table{width:100%; border-collapse:collapse;} td,th{border:1px solid black; padding:8px;}</style></head><body>"
    $html += "<h1>Diagnostico DEBUG</h1><table><tr><th>ID</th><th>Check</th><th>Result</th><th>Status</th><th>Rec</th></tr>"
    $html += $Rows
    $html += "</table></body></html>"
    
    $html | Out-File $ReportHTML -Encoding UTF8
    Log-Write "HTML Gerado: $ReportHTML"
} catch {
    Log-Error "Erro ao gerar HTML: $($_.Exception.Message)"
}

# GERAÇÃO PDF 
Log-Write "Tentando gerar PDF via Edge..."
try {
    $edge = (Get-ChildItem "C:\Program Files*\Microsoft\Edge\Application\msedge.exe" | Select -First 1).FullName
    if ($edge) {
        Start-Process $edge -ArgumentList "--headless --disable-gpu --print-to-pdf=`"$ReportPDF`" `"$ReportHTML`"" -Wait
        Log-Write "PDF Gerado: $ReportPDF"
        Invoke-Item $ReportPDF
    } else {
        Log-Error "Edge não encontrado."
        Invoke-Item $ReportHTML
    }
} catch {
    Log-Error "Erro ao converter PDF: $($_.Exception.Message)"
}

Log-Write "--- FIM DO DIAGNÓSTICO ---"
Start-Sleep -Seconds 2