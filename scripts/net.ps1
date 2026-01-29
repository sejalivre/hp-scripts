# net.ps1 - Diagnóstico e Reset de Rede
# Executar como ADMINISTRADOR

# Importa módulo de compatibilidade
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "CompatibilityLayer.ps1")

# ============================================================
# CONFIGURAÇÃO DE DIRETÓRIOS E LOGGING
# ============================================================

$HPTIBase = "C:\Program Files\HPTI"
$BackupDir = Join-Path $HPTIBase "NetworkBackups"
$LogDir = Join-Path $HPTIBase "Logs"
$ReportsDir = Join-Path $HPTIBase "Reports"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "network_backup_$timestamp.ps1"
$LogFile = Join-Path $LogDir "net_$(Get-Date -Format 'yyyyMMdd').log"

# Criar diretórios se não existirem
if (-not (Test-Path $HPTIBase)) { New-Item -Path $HPTIBase -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $ReportsDir)) { New-Item -Path $ReportsDir -ItemType Directory -Force | Out-Null }

# Variável global para armazenar resultados dos testes
$global:TestResults = @{
    DNS           = @()
    Ping          = @()
    DownloadSpeed = @{}
    SharedFolders = @()
    SystemInfo    = @{}
}

# Função de logging
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $logTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$logTimestamp] [$Type] $Message"
    $logMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    switch ($Type) {
        "ERROR" { Write-Warning $Message }
        "SUCCESS" { Write-Output $Message }
        default { Write-Output $Message }
    }
}

# ============================================================
# FUNÇÕES DE TESTE DE REDE
# ============================================================

function Test-DNS {
    Write-Host "`n=== TESTANDO DNS ===" -ForegroundColor Cyan
    Write-Log "Iniciando testes de DNS"
    
    $dnsServers = @(
        @{Name = "Google DNS"; IP = "8.8.8.8" },
        @{Name = "Cloudflare DNS"; IP = "1.1.1.1" },
        @{Name = "OpenDNS"; IP = "208.67.222.222" }
    )
    
    $testDomains = @("google.com", "microsoft.com", "github.com", "uol.com.br")
    
    foreach ($domain in $testDomains) {
        Write-Host "  Testando: $domain" -ForegroundColor Yellow
        $startTime = Get-Date
        
        try {
            $result = [System.Net.Dns]::GetHostAddresses($domain)
            $endTime = Get-Date
            $responseTime = ($endTime - $startTime).TotalMilliseconds
            
            if ($result) {
                $ip = $result[0].IPAddressToString
                Write-Host "    ✓ Resolvido: $ip (${responseTime}ms)" -ForegroundColor Green
                $global:TestResults.DNS += @{
                    Domain       = $domain
                    Status       = "Success"
                    IP           = $ip
                    ResponseTime = [math]::Round($responseTime, 2)
                }
            }
        }
        catch {
            Write-Host "    ✗ Falha ao resolver $domain" -ForegroundColor Red
            Write-Log "Falha DNS: $domain - $($_.Exception.Message)" "ERROR"
            $global:TestResults.DNS += @{
                Domain       = $domain
                Status       = "Failed"
                IP           = "N/A"
                ResponseTime = 0
                Error        = $_.Exception.Message
            }
        }
    }
    
    # Testar servidores DNS
    Write-Host "`n  Testando servidores DNS:" -ForegroundColor Yellow
    foreach ($dns in $dnsServers) {
        $pingResult = Test-Connection -ComputerName $dns.IP -Count 2 -Quiet -ErrorAction SilentlyContinue
        if ($pingResult) {
            Write-Host "    ✓ $($dns.Name) ($($dns.IP)) - Acessível" -ForegroundColor Green
        }
        else {
            Write-Host "    ✗ $($dns.Name) ($($dns.IP)) - Inacessível" -ForegroundColor Red
        }
    }
}

function Test-NetworkConnectivity {
    Write-Host "`n=== TESTANDO CONECTIVIDADE (PING) ===" -ForegroundColor Cyan
    Write-Log "Iniciando testes de conectividade"
    
    $targets = @(
        @{Name = "Gateway"; Host = $null },
        @{Name = "Google DNS"; Host = "8.8.8.8" },
        @{Name = "Cloudflare"; Host = "1.1.1.1" },
        @{Name = "Servidor BR"; Host = "uol.com.br" }
    )
    
    # Obter gateway
    try {
        $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop
        if ($gateway) {
            $targets[0].Host = $gateway
            Write-Host "  Gateway detectado: $gateway" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Log "Não foi possível detectar gateway" "ERROR"
    }
    
    foreach ($target in $targets) {
        if (-not $target.Host) { continue }
        
        Write-Host "`n  Testando: $($target.Name) ($($target.Host))" -ForegroundColor Yellow
        
        try {
            # Ping com 20 pacotes
            $pingResults = Test-Connection -ComputerName $target.Host -Count 20 -ErrorAction SilentlyContinue
            
            if ($pingResults) {
                $successCount = ($pingResults | Where-Object { $_.StatusCode -eq 0 }).Count
                $packetLoss = [math]::Round((1 - ($successCount / 20)) * 100, 2)
                $avgLatency = [math]::Round(($pingResults | Measure-Object -Property ResponseTime -Average).Average, 2)
                $minLatency = ($pingResults | Measure-Object -Property ResponseTime -Minimum).Minimum
                $maxLatency = ($pingResults | Measure-Object -Property ResponseTime -Maximum).Maximum
                
                Write-Host "    Pacotes: 20 enviados, $successCount recebidos, ${packetLoss}% perda" -ForegroundColor $(if ($packetLoss -eq 0) { "Green" } elseif ($packetLoss -lt 10) { "Yellow" } else { "Red" })
                Write-Host "    Latência: Min=${minLatency}ms, Máx=${maxLatency}ms, Média=${avgLatency}ms" -ForegroundColor Green
                
                $global:TestResults.Ping += @{
                    Target          = $target.Name
                    Host            = $target.Host
                    PacketsSent     = 20
                    PacketsReceived = $successCount
                    PacketLoss      = $packetLoss
                    MinLatency      = $minLatency
                    MaxLatency      = $maxLatency
                    AvgLatency      = $avgLatency
                    Status          = "Success"
                }
            }
            else {
                Write-Host "    ✗ Sem resposta" -ForegroundColor Red
                $global:TestResults.Ping += @{
                    Target     = $target.Name
                    Host       = $target.Host
                    Status     = "Failed"
                    PacketLoss = 100
                }
            }
        }
        catch {
            Write-Host "    ✗ Erro: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "Erro no ping para $($target.Host): $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Traceroute (20 saltos)
    Write-Host "`n  Executando traceroute (20 saltos)..." -ForegroundColor Yellow
    try {
        $traceResult = tracert -h 20 -w 1000 8.8.8.8
        $hopCount = ($traceResult | Where-Object { $_ -match "^\s+\d+" }).Count
        Write-Host "    Saltos até Google DNS: $hopCount" -ForegroundColor Green
        $global:TestResults.Ping += @{
            Target = "Traceroute"
            Host   = "8.8.8.8"
            Hops   = $hopCount
            Status = "Success"
        }
    }
    catch {
        Write-Log "Erro no traceroute: $($_.Exception.Message)" "ERROR"
    }
}

function Test-DownloadSpeed {
    Write-Host "`n=== TESTANDO VELOCIDADE DE DOWNLOAD ===" -ForegroundColor Cyan
    Write-Log "Iniciando teste de velocidade de download"
    
    # URL de teste - arquivo de 10MB de servidor brasileiro
    $testUrls = @(
        "http://speedtest.ftp.otenet.gr/files/test10Mb.db",
        "http://ipv4.download.thinkbroadband.com/10MB.zip"
    )
    
    $testUrl = $testUrls[0]
    $tempFile = Join-Path $env:TEMP "speedtest_$timestamp.tmp"
    
    Write-Host "  Baixando arquivo de teste..." -ForegroundColor Yellow
    Write-Host "  URL: $testUrl" -ForegroundColor Gray
    
    try {
        $startTime = Get-Date
        
        # Download usando WebClient para compatibilidade
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($testUrl, $tempFile)
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if (Test-Path $tempFile) {
            $fileSize = (Get-Item $tempFile).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            $speedMbps = [math]::Round(($fileSize * 8 / $duration) / 1MB, 2)
            
            Write-Host "    ✓ Download concluído!" -ForegroundColor Green
            Write-Host "    Tamanho: ${fileSizeMB} MB" -ForegroundColor Green
            Write-Host "    Tempo: ${duration} segundos" -ForegroundColor Green
            Write-Host "    Velocidade: ${speedMbps} Mbps" -ForegroundColor Green
            
            $global:TestResults.DownloadSpeed = @{
                Status   = "Success"
                FileSize = $fileSizeMB
                Duration = [math]::Round($duration, 2)
                Speed    = $speedMbps
                URL      = $testUrl
            }
            
            # Limpar arquivo temporário
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "    ✗ Erro no download: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Erro no teste de velocidade: $($_.Exception.Message)" "ERROR"
        $global:TestResults.DownloadSpeed = @{
            Status = "Failed"
            Error  = $_.Exception.Message
        }
    }
}

function Test-SharedFolders {
    Write-Host "`n=== VERIFICANDO PASTAS COMPARTILHADAS ===" -ForegroundColor Cyan
    Write-Log "Verificando pastas compartilhadas"
    
    try {
        # Listar compartilhamentos locais
        Write-Host "`n  Compartilhamentos locais:" -ForegroundColor Yellow
        $localShares = Get-WmiObject -Class Win32_Share -ErrorAction SilentlyContinue | Where-Object { $_.Type -eq 0 }
        
        if ($localShares) {
            foreach ($share in $localShares) {
                Write-Host "    ✓ $($share.Name) - $($share.Path)" -ForegroundColor Green
                $global:TestResults.SharedFolders += @{
                    Type        = "Local"
                    Name        = $share.Name
                    Path        = $share.Path
                    Description = $share.Description
                    Status      = "Active"
                }
            }
        }
        else {
            Write-Host "    Nenhum compartilhamento local encontrado" -ForegroundColor Gray
        }
        
        # Verificar sessões SMB ativas
        Write-Host "`n  Sessões de rede ativas:" -ForegroundColor Yellow
        if ($PSVersionTable.PSVersion.Major -ge 3) {
            $smbSessions = Get-SmbSession -ErrorAction SilentlyContinue
            if ($smbSessions) {
                foreach ($session in $smbSessions) {
                    Write-Host "    ✓ Cliente: $($session.ClientComputerName) - Usuário: $($session.ClientUserName)" -ForegroundColor Green
                }
            }
            else {
                Write-Host "    Nenhuma sessão ativa" -ForegroundColor Gray
            }
        }
        else {
            # Fallback para versões antigas
            $netSessions = net session 2>&1
            if ($netSessions -match "Não há entradas|There are no entries") {
                Write-Host "    Nenhuma sessão ativa" -ForegroundColor Gray
            }
            else {
                Write-Host "    Sessões detectadas (use 'net session' para detalhes)" -ForegroundColor Yellow
            }
        }
        
        # Testar acesso a compartilhamentos de rede conhecidos
        Write-Host "`n  Testando acesso a compartilhamentos de rede:" -ForegroundColor Yellow
        $networkPath = "\\localhost\C$"
        if (Test-Path $networkPath -ErrorAction SilentlyContinue) {
            Write-Host "    ✓ Acesso administrativo local funcionando" -ForegroundColor Green
        }
        else {
            Write-Host "    ✗ Sem acesso administrativo local" -ForegroundColor Red
        }
        
    }
    catch {
        Write-Host "    ✗ Erro ao verificar compartilhamentos: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Erro ao verificar compartilhamentos: $($_.Exception.Message)" "ERROR"
    }
}

function Get-SystemInfo {
    Write-Host "`n=== COLETANDO INFORMAÇÕES DO SISTEMA ===" -ForegroundColor Cyan
    
    try {
        $os = Get-WmiObject Win32_OperatingSystem
        $cs = Get-WmiObject Win32_ComputerSystem
        $adapters = Get-NetworkAdapter -Status "Up"
        
        $global:TestResults.SystemInfo = @{
            ComputerName   = $env:COMPUTERNAME
            OS             = $os.Caption
            OSVersion      = $os.Version
            Architecture   = $os.OSArchitecture
            Domain         = $cs.Domain
            Manufacturer   = $cs.Manufacturer
            Model          = $cs.Model
            ActiveAdapters = ($adapters | ForEach-Object { "$($_.Name) ($($_.InterfaceDescription))" }) -join ", "
            TestDate       = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        }
        
        Write-Host "  Computador: $($env:COMPUTERNAME)" -ForegroundColor Green
        Write-Host "  SO: $($os.Caption)" -ForegroundColor Green
        Write-Host "  Adaptadores ativos: $($adapters.Count)" -ForegroundColor Green
    }
    catch {
        Write-Log "Erro ao coletar informações do sistema: $($_.Exception.Message)" "ERROR"
    }
}

function Generate-HTMLReport {
    Write-Host "`n=== GERANDO RELATÓRIO HTML ===" -ForegroundColor Cyan
    Write-Log "Gerando relatório HTML"
    
    $reportPath = Join-Path $ReportsDir "network_test_$timestamp.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Teste de Rede - $($global:TestResults.SystemInfo.ComputerName)</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .system-info {
            background: #f8f9fa;
            padding: 20px 30px;
            border-bottom: 3px solid #667eea;
        }
        .system-info h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.5em;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        .info-item {
            background: white;
            padding: 12px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .info-label {
            font-weight: bold;
            color: #667eea;
            font-size: 0.9em;
            margin-bottom: 5px;
        }
        .info-value {
            color: #333;
            font-size: 1em;
        }
        .section {
            padding: 30px;
            border-bottom: 1px solid #e0e0e0;
        }
        .section:last-child {
            border-bottom: none;
        }
        .section h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.8em;
            display: flex;
            align-items: center;
        }
        .section h2::before {
            content: '';
            width: 5px;
            height: 30px;
            background: #667eea;
            margin-right: 15px;
            border-radius: 3px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #f0f0f0;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .status-success {
            color: #28a745;
            font-weight: bold;
        }
        .status-failed {
            color: #dc3545;
            font-weight: bold;
        }
        .status-warning {
            color: #ffc107;
            font-weight: bold;
        }
        .metric-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            margin: 10px 0;
        }
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
        }
        .metric-label {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
        .grid-2 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Relatório de Teste de Rede</h1>
            <p>Diagnóstico Completo de Conectividade</p>
        </div>
        
        <div class="system-info">
            <h2>Informações do Sistema</h2>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Computador</div>
                    <div class="info-value">$($global:TestResults.SystemInfo.ComputerName)</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Sistema Operacional</div>
                    <div class="info-value">$($global:TestResults.SystemInfo.OS)</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Domínio</div>
                    <div class="info-value">$($global:TestResults.SystemInfo.Domain)</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Data do Teste</div>
                    <div class="info-value">$($global:TestResults.SystemInfo.TestDate)</div>
                </div>
            </div>
        </div>
"@

    # Seção DNS
    if ($global:TestResults.DNS.Count -gt 0) {
        $html += @"
        <div class="section">
            <h2>🌐 Testes de DNS</h2>
            <table>
                <tr>
                    <th>Domínio</th>
                    <th>Status</th>
                    <th>Endereço IP</th>
                    <th>Tempo de Resposta</th>
                </tr>
"@
        foreach ($dns in $global:TestResults.DNS) {
            $statusClass = if ($dns.Status -eq "Success") { "status-success" } else { "status-failed" }
            $statusIcon = if ($dns.Status -eq "Success") { "✓" } else { "✗" }
            $html += @"
                <tr>
                    <td>$($dns.Domain)</td>
                    <td class="$statusClass">$statusIcon $($dns.Status)</td>
                    <td>$($dns.IP)</td>
                    <td>$($dns.ResponseTime) ms</td>
                </tr>
"@
        }
        $html += "</table></div>"
    }

    # Seção Ping
    if ($global:TestResults.Ping.Count -gt 0) {
        $html += @"
        <div class="section">
            <h2>📡 Testes de Conectividade (Ping)</h2>
            <table>
                <tr>
                    <th>Destino</th>
                    <th>Host</th>
                    <th>Pacotes Enviados</th>
                    <th>Pacotes Recebidos</th>
                    <th>Perda de Pacotes</th>
                    <th>Latência Média</th>
                </tr>
"@
        foreach ($ping in $global:TestResults.Ping) {
            if ($ping.Target -eq "Traceroute") { continue }
            $lossClass = if ($ping.PacketLoss -eq 0) { "status-success" } elseif ($ping.PacketLoss -lt 10) { "status-warning" } else { "status-failed" }
            $html += @"
                <tr>
                    <td>$($ping.Target)</td>
                    <td>$($ping.Host)</td>
                    <td>$($ping.PacketsSent)</td>
                    <td>$($ping.PacketsReceived)</td>
                    <td class="$lossClass">$($ping.PacketLoss)%</td>
                    <td>$($ping.AvgLatency) ms</td>
                </tr>
"@
        }
        $html += "</table></div>"
    }

    # Seção Download Speed
    if ($global:TestResults.DownloadSpeed.Status -eq "Success") {
        $html += @"
        <div class="section">
            <h2>⚡ Teste de Velocidade de Download</h2>
            <div class="grid-2">
                <div class="metric-card">
                    <div class="metric-label">Velocidade de Download</div>
                    <div class="metric-value">$($global:TestResults.DownloadSpeed.Speed) Mbps</div>
                </div>
                <div class="metric-card">
                    <div class="metric-label">Tamanho do Arquivo</div>
                    <div class="metric-value">$($global:TestResults.DownloadSpeed.FileSize) MB</div>
                </div>
            </div>
            <p style="margin-top: 15px; color: #666;">Tempo de download: $($global:TestResults.DownloadSpeed.Duration) segundos</p>
        </div>
"@
    }

    # Seção Shared Folders
    if ($global:TestResults.SharedFolders.Count -gt 0) {
        $html += @"
        <div class="section">
            <h2>📁 Pastas Compartilhadas</h2>
            <table>
                <tr>
                    <th>Tipo</th>
                    <th>Nome</th>
                    <th>Caminho</th>
                    <th>Status</th>
                </tr>
"@
        foreach ($share in $global:TestResults.SharedFolders) {
            $html += @"
                <tr>
                    <td>$($share.Type)</td>
                    <td>$($share.Name)</td>
                    <td>$($share.Path)</td>
                    <td class="status-success">✓ $($share.Status)</td>
                </tr>
"@
        }
        $html += "</table></div>"
    }

    $html += @"
        <div class="footer">
            <p><strong>HP Scripts - Ferramentas de Diagnóstico de Rede</strong></p>
            <p>Relatório gerado automaticamente em $($global:TestResults.SystemInfo.TestDate)</p>
            <p>Salvo em: $reportPath</p>
        </div>
    </div>
</body>
</html>
"@

    try {
        Set-Content -Path $reportPath -Value $html -Encoding UTF8
        Write-Host "  ✓ Relatório salvo em: $reportPath" -ForegroundColor Green
        Write-Log "Relatório HTML gerado: $reportPath" "SUCCESS"
        
        # Abrir relatório no navegador padrão
        Write-Host "`n  Abrindo relatório no navegador..." -ForegroundColor Yellow
        Start-Process $reportPath
        
        return $reportPath
    }
    catch {
        Write-Host "  ✗ Erro ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Erro ao gerar relatório HTML: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# ============================================================
# FUNÇÃO DE BACKUP DE CONFIGURAÇÕES DE REDE
# ============================================================

function Backup-NetworkConfiguration {
    Write-Log "=== INICIANDO BACKUP DE CONFIGURAÇÕES DE REDE ===" "SUCCESS"
    
    $backupContent = @"
# Script de Restore de Configurações de Rede
# Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
# Backup criado antes do reset de rede

Write-Host "=== RESTAURANDO CONFIGURAÇÕES DE REDE ===" -ForegroundColor Cyan

"@

    try {
        # 1. Backup de Configurações de IP
        Write-Log "Fazendo backup de configurações de IP..."
        $netConfigs = Get-NetworkConfig | Where-Object { $_.InterfaceAlias -match 'Wi-Fi|Ethernet|WiFi' }
        
        foreach ($config in $netConfigs) {
            $alias = $config.InterfaceAlias
            $adapter = Get-NetAdapter -Name $alias -ErrorAction SilentlyContinue
            if (-not $adapter) { continue }

            $dhcpEnabled = Test-DHCPEnabled -InterfaceAlias $alias

            if (-not $dhcpEnabled -and $config.IPv4Address -and $config.IPv4Address -notmatch '^169\.254|^0\.0\.0\.') {
                $ip = $config.IPv4Address
                $prefix = if ($config.PrefixLength) { $config.PrefixLength } else { 24 }
                $gw = $config.IPv4DefaultGateway
                $dns = if ($config.DNSServer) { \"'$($config.DNSServer -join \"','\")'\" } else { $null }

                $backupContent += @"

# Restaurando IP estático na interface '$alias'
Write-Host "Configurando interface: $alias" -ForegroundColor Yellow
try {
    Remove-NetIPAddress -InterfaceAlias '$alias' -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias '$alias' -Confirm:`$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias '$alias' -IPAddress '$ip' -PrefixLength $prefix -DefaultGateway '$gw' -AddressFamily IPv4 -ErrorAction Stop
    Write-Host "  IP configurado: $ip/$prefix" -ForegroundColor Green

"@
                if ($dns) {
                    $backupContent += @"
    Set-DnsClientServerAddress -InterfaceAlias '$alias' -ServerAddresses $dns -ErrorAction Stop
    Write-Host "  DNS configurado" -ForegroundColor Green

"@
                }
                $backupContent += @"
}
catch {
    Write-Warning "Erro ao configurar '$alias': `$(`$_.Exception.Message)"
}

"@
                Write-Log "  Backup de IP estático: $alias ($ip)"
            }
        }

        # 2. Backup de Perfis Wi-Fi
        Write-Log "Fazendo backup de perfis Wi-Fi..."
        $wifiBackupPath = Join-Path $BackupDir "WiFi_$timestamp"
        if (-not (Test-Path $wifiBackupPath)) { New-Item -Path $wifiBackupPath -ItemType Directory -Force | Out-Null }
        
        $profileLines = netsh wlan show profiles 2>&1
        if ($profileLines -notmatch "não há nenhuma interface|no wireless|AutoConfig.*not running") {
            $wifiProfiles = @()
            foreach ($line in $profileLines) {
                if ($line -match ':\s*(.+)$') {
                    $name = $matches[1].Trim()
                    if ($name -and $name -ne '<None>' -and $name -notmatch '^(\s*|-|política|group)') {
                        $wifiProfiles += $name
                    }
                }
            }
            
            if ($wifiProfiles.Count -gt 0) {
                foreach ($wifiProfile in $wifiProfiles) {
                    netsh wlan export profile name="$wifiProfile" folder="$wifiBackupPath" key=clear 2>&1 | Out-Null
                }
                
                $backupContent += @"

# Restaurando perfis Wi-Fi
Write-Host "`nRestaurando perfis Wi-Fi..." -ForegroundColor Yellow
`$wifiPath = '$wifiBackupPath'
if (Test-Path `$wifiPath) {
    Get-ChildItem -Path `$wifiPath -Filter '*.xml' | ForEach-Object {
        netsh wlan add profile filename="`$(`$_.FullName)" 2>&1 | Out-Null
        Write-Host "  Importado: `$(`$_.BaseName)" -ForegroundColor Green
    }
}
else {
    Write-Warning "Pasta de perfis Wi-Fi não encontrada"
}

"@
                Write-Log "  Backup de $($wifiProfiles.Count) perfis Wi-Fi"
            }
        }

        # 3. Backup de Configurações de Proxy
        Write-Log "Fazendo backup de configurações de proxy..."
        $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
        if ($proxySettings -and $proxySettings.ProxyEnable -eq 1) {
            $proxyServer = $proxySettings.ProxyServer
            $backupContent += @"

# Restaurando configurações de proxy
Write-Host "`nRestaurando proxy..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "$proxyServer"
Write-Host "  Proxy configurado: $proxyServer" -ForegroundColor Green

"@
            Write-Log "  Backup de proxy: $proxyServer"
        }

        # Finalização do script de restore
        $backupContent += @"

Write-Host "`n=== RESTORE CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Recomenda-se reiniciar o computador para aplicar todas as configurações." -ForegroundColor Yellow
pause
"@

        # Salvar arquivo de backup
        Set-Content -Path $BackupFile -Value $backupContent -Encoding UTF8
        Write-Log "Backup salvo em: $BackupFile" "SUCCESS"
        
        # Criar cópia como restore_network.ps1 (sempre o mais recente)
        $latestRestore = Join-Path $BackupDir "restore_network.ps1"
        Copy-Item -Path $BackupFile -Destination $latestRestore -Force
        Write-Log "Cópia de restore criada: $latestRestore" "SUCCESS"
        
        Write-Log "=== BACKUP CONCLUÍDO COM SUCESSO ===" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "ERRO durante backup: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================
# VERIFICAÇÃO DE PRIVILÉGIOS ADMINISTRATIVOS
# ============================================================

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Solicitando privilégios de administrador..."
    $arguments = "& '$PSCommandPath'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

Clear-Host
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║          DIAGNÓSTICO E RESET DE REDE - HP Scripts         ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Escolha uma opção:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] TESTAR - Diagnóstico completo de rede" -ForegroundColor Green
Write-Host "      • Testes de DNS" -ForegroundColor Gray
Write-Host "      • Ping com 20 pacotes (detecção de perda)" -ForegroundColor Gray
Write-Host "      • Teste de velocidade de download" -ForegroundColor Gray
Write-Host "      • Verificação de pastas compartilhadas" -ForegroundColor Gray
Write-Host "      • Relatório HTML automático" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] RESETAR - Reset completo de configurações de rede" -ForegroundColor Red
Write-Host "      • Backup automático de configurações" -ForegroundColor Gray
Write-Host "      • Reset de IP, Winsock e Firewall" -ForegroundColor Gray
Write-Host "      • Configuração de serviços de rede" -ForegroundColor Gray
Write-Host "      • Limpeza de cache DNS" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

do {
    $choice = Read-Host "Digite sua escolha (1 ou 2)"
} while ($choice -ne "1" -and $choice -ne "2")

Write-Host ""

# ============================================================
# EXECUÇÃO BASEADA NA ESCOLHA
# ============================================================

if ($choice -eq "1") {
    # ============================================================
    # MODO TESTE
    # ============================================================
    
    Write-Log "=== MODO TESTE INICIADO ===" "SUCCESS"
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          INICIANDO DIAGNÓSTICO DE REDE                    ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    try {
        # Coletar informações do sistema
        Get-SystemInfo
        
        # Executar testes
        Test-DNS
        Test-NetworkConnectivity
        Test-DownloadSpeed
        Test-SharedFolders
        
        # Gerar relatório HTML
        $reportPath = Generate-HTMLReport
        
        if ($reportPath) {
            Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║          DIAGNÓSTICO CONCLUÍDO COM SUCESSO!               ║" -ForegroundColor Green
            Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "`nRelatório salvo em:" -ForegroundColor Yellow
            Write-Host "  $reportPath" -ForegroundColor White
            Write-Log "Diagnóstico concluído com sucesso" "SUCCESS"
        }
        else {
            Write-Host "`n[AVISO] Diagnóstico concluído, mas houve erro ao gerar relatório HTML" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Log "Erro durante diagnóstico: $($_.Exception.Message)" "ERROR"
        Write-Host "`n[ERRO] Ocorreu um erro durante o diagnóstico" -ForegroundColor Red
    }
    
    Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}
else {
    # ============================================================
    # MODO RESET
    # ============================================================
    
    Write-Log "=== MODO RESET INICIADO ===" "SUCCESS"
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║          INICIANDO RESET DE REDE                          ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Red

    # ============================================================
    # BACKUP DE CONFIGURAÇÕES ANTES DO RESET
    # ============================================================

    Write-Log "`nCriando backup das configurações atuais..." "SUCCESS"
    $backupSuccess = Backup-NetworkConfiguration

    if (-not $backupSuccess) {
        Write-Log "AVISO: Backup falhou, mas continuando com reset..." "ERROR"
        Write-Host "`nDeseja continuar mesmo sem backup? (S/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne 'S' -and $response -ne 's') {
            Write-Log "Operação cancelada pelo usuário" "ERROR"
            exit
        }
    }

    # ============================================================
    # INÍCIO DO RESET DE REDE
    # ============================================================

    try {
        # 1. Serviços a configurar (habilitar automático)
        Write-Log "`nConfigurando serviços..."
    
        $servicesToEnable = @(
            "browser",
            "Dhcp",
            "lanmanserver",
            "lanmanworkstation",
            "Netman",
            "Schedule",
            "Netlogon",
            "NtLmSsp",
            "Dnscache",      # DNS Client - importante para cache DNS funcionar depois
            "Nla",
            "netsvcs"
        )

        foreach ($svc in $servicesToEnable) {
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
                Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
                Write-Log "→ $svc → Automatic"
            }
        }

        # 2. Iniciar os serviços
        Write-Log "`nIniciando serviços..."
    
        foreach ($svc in $servicesToEnable) {
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
                Start-Service -Name $svc -ErrorAction SilentlyContinue
                Write-Log "→ Iniciado: $svc"
            }
        }

        # 3. Ajustes de Registro
        Write-Log "`nAplicando ajustes de registro..."

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Csc\Parameters" `
            -Name "FormatDatabase" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
            -Name "LimitBlankPasswordUse" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
            -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Write-Log "→ Registros atualizados"

        # 4. Reset de rede + Limpeza de cache DNS
        Write-Log "`nExecutando reset de rede e cache DNS..."
    
        # Resets clássicos
        netsh int ip reset | Out-Null
        netsh winsock reset | Out-Null
        netsh advfirewall reset | Out-Null

        # Limpeza do cache DNS
        if ($PSVersionTable.PSVersion.Major -ge 3) {
            Clear-DnsClientCache -ErrorAction Stop
            Write-Log "→ Cache DNS limpo com sucesso"
        }
        else {
            # Fallback para PowerShell 2.0
            ipconfig /flushdns | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "→ Cache DNS limpo com sucesso"
            }
            else {
                Write-Log "Falha ao limpar cache DNS" "ERROR"
            }
        }

        Write-Log "[OK] Reset concluído" "SUCCESS"

    }
    catch {
        Write-Log "`n[ERRO] $($_.Exception.Message)" "ERROR"
    }


    Write-Log "`nConcluído. Recomenda-se reiniciar o computador para aplicar todas as alterações." "SUCCESS"
    Write-Log "Backup salvo em: $BackupDir" "SUCCESS"
    
    Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fim do script
