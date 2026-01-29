# Script para gerar relatório do sistema + senhas Wi-Fi + softwares + restore script
# Executar como administrador
# Compatível com: PowerShell 5.1+ (Windows 10/11)

# Importações Removidas

# Verifica administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: Execute como ADMINISTRADOR!" -ForegroundColor Red
    Write-Host "Clique direito → Executar com PowerShell → Executar como administrador" -ForegroundColor Yellow
    pause
    exit
}

# Pastas de destino
$basePath = "C:\Program Files\HPTI\Backups"
$reportFile = Join-Path $basePath "RelatorioSistema.txt"
$wifiExportPath = Join-Path $basePath "WiFiProfiles"
$restoreFile = Join-Path $basePath "restore.ps1"

# Cria pastas se não existirem
if (-not (Test-Path $basePath)) { New-Item -Path $basePath -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $wifiExportPath)) { New-Item -Path $wifiExportPath -ItemType Directory -Force | Out-Null }

# Função para adicionar seção
function Add-Section {
    param ([string]$Title, [string]$Content)
    Add-Content -Path $reportFile -Value "`n=== $Title ===" -Encoding UTF8
    Add-Content -Path $reportFile -Value $Content -Encoding UTF8
}

# Limpa relatório anterior
if (Test-Path $reportFile) { Remove-Item $reportFile -Force }
New-Item -Path $reportFile -ItemType File -Force | Out-Null

# Nome da máquina
$oldHostname = $env:COMPUTERNAME
Add-Section "Nome da Máquina" $oldHostname

# Configurações de rede
# Configurações de rede
try {
    $netConfigs = Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -match 'Wi-Fi|Ethernet|WiFi' } | Select-Object @{N = 'InterfaceAlias'; E = { $_.InterfaceAlias } }, @{N = 'IPv4Address'; E = { $_.IPv4Address.IPAddress } }, @{N = 'PrefixLength'; E = { $_.IPv4Address.PrefixLength } }, @{N = 'IPv4DefaultGateway'; E = { $_.IPv4DefaultGateway.NextHop } }, @{N = 'DNSServer'; E = { $_.DNSServer.ServerAddresses } }
    $networkConfigsStr = $netConfigs | Format-List | Out-String
    Add-Section "Configurações de Rede" $networkConfigsStr
}
catch {
    Write-Host "Aviso: Não foi possível obter configurações de rede" -ForegroundColor Yellow
    Add-Section "Configurações de Rede" "Erro ao obter configurações: $($_.Exception.Message)"
    $netConfigs = @()
}

# Captura comandos de restore apenas para interfaces com IP estático (não DHCP)
$netRestoreCommands = @()
foreach ($config in $netConfigs) {
    $alias = $config.InterfaceAlias
    if (-not $alias) { continue }

    $ipv4If = Get-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $dhcpEnabled = if ($ipv4If) { $ipv4If.Dhcp -eq 'Enabled' } else { $true }

    if (-not $dhcpEnabled -and $config.IPv4Address -and $config.IPv4Address -notmatch '^169\.254|^0\.0\.0\.') {
        $ip = $config.IPv4Address
        # Prefixo padrão /24 se não disponível
        $prefix = if ($config.PrefixLength) { $config.PrefixLength } else { 24 }
        $gw = $config.IPv4DefaultGateway
        $dns = if ($config.DNSServer) { "'$($config.DNSServer -join "','")'" } else { $null }

        $netRestoreCommands += "# Restaurando IP estático na interface '$alias'"
        if ($gw) {
            $netRestoreCommands += "netsh interface ip set address name='$alias' static $ip 255.255.255.0 $gw"
        }
        else {
            $netRestoreCommands += "netsh interface ip set address name='$alias' static $ip 255.255.255.0"
        }
        if ($dns) {
            $netRestoreCommands += "netsh interface ip set dns name='$alias' static $($config.DNSServer[0])"
        }
        $netRestoreCommands += ""
    }
}

# === Wi-Fi ===
Write-Host "Exportando perfis Wi-Fi..." -ForegroundColor Cyan

try {
    $profileLines = netsh wlan show profiles 2>&1
    
    # Verificar se há adaptador Wi-Fi
    if ($profileLines -match "não há nenhuma interface|no wireless|AutoConfig.*not running") {
        Write-Host "Aviso: Nenhum adaptador Wi-Fi encontrado ou serviço desabilitado" -ForegroundColor Yellow
        $wifiProfiles = @()
    }
    else {
        $wifiProfiles = @()
        foreach ($line in $profileLines) {
            if ($line -match ':\s*(.+)$') {
                $name = $matches[1].Trim()
                if ($name -and $name -ne '<Nenhum>' -and $name -notmatch '^(\s*|-|política|group)') {
                    $wifiProfiles += $name
                }
            }
        }
        Write-Host "Perfis encontrados: $($wifiProfiles.Count)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Erro ao listar perfis Wi-Fi: $($_.Exception.Message)" -ForegroundColor Yellow
    $wifiProfiles = @()
}

$wifiInfo = ""
$exportCount = 0

foreach ($profile in $wifiProfiles) {
    $exportResult = netsh wlan export profile name="$profile" folder="$wifiExportPath" key=clear
    if ($exportResult -match "exportado|êxito|exported|successfully") { $exportCount++ }
}

# Lê senhas dos XML
$xmlFiles = Get-ChildItem -Path $wifiExportPath -Filter "*.xml" -File
foreach ($xmlFile in $xmlFiles) {
    try {
        [xml]$xml = Get-Content $xmlFile.FullName -Encoding UTF8
        $name = $xml.WLANProfile.name
        $pass = $xml.WLANProfile.MSM.security.sharedKey.keyMaterial
        if ($name -and $pass) {
            $wifiInfo += "Rede: $name`nSenha: $pass`n`n"
        }
    }
    catch { }
}

Add-Section "Perfis WiFi (Nomes e Senhas)" $wifiInfo
Add-Section "Perfis WiFi Exportados" "Exportados: $exportCount`nPasta: $wifiExportPath"

# === Softwares  Instalados ===
Write-Host "Listando softwares..." -ForegroundColor Cyan

$apps = @()
$apps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" `
| Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher
$apps += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
| Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher

$apps = $apps | Sort-Object DisplayName -Unique
$appsStr = $apps | Format-Table -AutoSize | Out-String
Add-Section "Softwares Instalados" $appsStr

# Lista de nomes aproximados suportados pelo Ninite (baseado na lista atual do site)
$niniteSupported = @(
    "7-Zip", "Adobe Acrobat", "AnyDesk", "Audacity", "Brave", "CCleaner", "Chrome", "Discord", "Dropbox",
    "Everything", "FileZilla", "Firefox", "Foxit Reader", "GIMP", "Git", "Google Drive", "Greenshot",
    "HandBrake", "Inkscape", "IrfanView", "Java", "KeePass", "Krita", "LibreOffice", "Malwarebytes",
    "Notepad++", "OneDrive", "Paint.NET", "PuTTY", "Python", "qbittorrent", "ShareX", "Spotify",
    "Steam", "SumatraPDF", "TeamViewer", "Thunderbird", "VLC", "VS Code", "WinDirStat", "WinSCP",
    "Zoom"
    # Adicione mais se souber de outros comuns no seu ambiente
)

# Filtra apps instalados que batem (aproximado, case-insensitive)
$appsForNinite = $apps | Where-Object {
    $dn = $_.DisplayName -replace '\s*\(.*?\)|\s*-\s*.*$', '' -replace '\s+$', ''
    $niniteSupported -contains $dn -or $niniteSupported -match [regex]::Escape($dn)
} | ForEach-Object { $_.DisplayName -replace '\s', '+' -replace '[^a-zA-Z0-9+]', '' } | Sort-Object -Unique

$niniteAppsParam = $appsForNinite -join '&'
$niniteUrl = if ($niniteAppsParam) { "https://ninite.com/$niniteAppsParam/ninite.exe" } else { "https://ninite.com/" }

# Pastas compartilhadas e Impressoras (mantido)
Add-Section "Pastas Compartilhadas" (Get-SmbShare | Format-List | Out-String)
Add-Section "Impressoras Instaladas" (Get-Printer | Format-List | Out-String)

# Final relatório
Add-Content -Path $reportFile -Value "`n=== Relatório gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') ===" -Encoding UTF8

# === Gera restore.ps1 ===
$restoreContent = @"
# restore.ps1 - Restauração básica (hostname, IP estático se aplicável, Wi-Fi, Ninite)
# Execute como ADMINISTRADOR

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Execute como ADMINISTRADOR!' -ForegroundColor Red
    pause
    exit
}

# 1. Hostname
Rename-Computer -NewName '$oldHostname' -Force -Restart:`$false
Write-Host 'Hostname definido para: $oldHostname' -ForegroundColor Green

# 2. Configurações de IP estático (somente se aplicável)
$($netRestoreCommands -join "`n")

# 3. Importa perfis Wi-Fi
`$wifiPath = '$wifiExportPath'
if (Test-Path `$wifiPath) {
    Get-ChildItem -Path `$wifiPath -Filter '*.xml' | ForEach-Object {
        netsh wlan add profile filename="`$(`$_.FullName)"
        Write-Host "Importado: `$(`$_.BaseName)" -ForegroundColor Green
    }
} else {
    Write-Host 'Pasta WiFiProfiles não encontrada em $wifiExportPath' -ForegroundColor Yellow
}

# 4. Abre Ninite com apps sugeridos (clique em "Get Your Ninite" para instalar)
Start-Process '$niniteUrl'
Write-Host 'Abrindo Ninite com apps detectados. Clique em "Get Your Ninite" e execute o download.' -ForegroundColor Cyan
Write-Host 'Instale os programas desejados e reinicie se necessário.' -ForegroundColor Green

Write-Host 'Restauração concluída!' -ForegroundColor Green
pause
"@

Set-Content -Path $restoreFile -Value $restoreContent -Encoding UTF8

# Final
Write-Host ""
Write-Host "Pronto!" -ForegroundColor Green
Write-Host "Relatório:          $reportFile"
Write-Host "Perfis Wi-Fi:       $wifiExportPath"
Write-Host "Restore script:     $restoreFile"
Write-Host "Após formatar → Execute restore.ps1 como admin."