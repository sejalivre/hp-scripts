param(
    [Parameter(Mandatory=$true)]
    [string]$Destino
)

# Criar pasta de backup com timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFolder = Join-Path $Destino ("Backup_Sistema_" + $timestamp)
New-Item -ItemType Directory -Path $backupFolder | Out-Null

# Função para registrar log
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Output $logMessage
    Add-Content -Path "$backupFolder\backup.log" -Value $logMessage
}

Write-Log "Iniciando backup do sistema..."
Write-Log "Pasta de backup: $backupFolder"

# 1. INFORMAÇÕES BÁSICAS DO SISTEMA
Write-Log "Coletando informações básicas do sistema..."
$systemInfo = @{
    DataHora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    NomeComputador = $env:COMPUTERNAME
    NomeUsuario = $env:USERNAME
    Dominio = $env:USERDOMAIN
    SistemaOperacional = (Get-WmiObject Win32_OperatingSystem).Caption
    Arquitetura = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
}

$systemInfo | ConvertTo-Json | Out-File "$backupFolder\01_sistema_info.json"
Write-Log "Informações básicas salvas"

# 2. CONFIGURAÇÕES DE REDE
Write-Log "Coletando configurações de rede..."
$networkInfo = Get-NetIPConfiguration -All | Select-Object InterfaceAlias, InterfaceIndex, IPv4Address, IPv6Address, DNSServer
$networkInfo | Export-Csv "$backupFolder\02_configuracoes_rede.csv" -NoTypeInformation -Encoding UTF8

# 3. SENHAS DE WIFI (requer elevação)
Write-Log "Coletando informações de redes WiFi..."
$wifiProfiles = netsh wlan show profiles
$wifiProfiles | Out-File "$backupFolder\03_wifi_profiles.txt"

$wifiDetails = @()
$profiles = ($wifiProfiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() })

foreach ($profile in $profiles) {
    try {
        $profileInfo = netsh wlan show profile name="$profile" key=clear
        $wifiDetails += "`n=== Perfil: $profile ==="
        $wifiDetails += $profileInfo
    }
    catch {
        Write-Log "Erro ao acessar perfil WiFi: $profile"
    }
}

$wifiDetails -join "`n" | Out-File "$backupFolder\03_wifi_detalhes.txt"
Write-Log "Informações WiFi salvas"

# 4. IMPRESSORAS INSTALADAS
Write-Log "Coletando informações de impressoras..."
$printers = Get-Printer | Select-Object Name, Type, PortName, DriverName, Shared, ShareName
$printers | Export-Csv "$backupFolder\04_impressoras.csv" -NoTypeInformation -Encoding UTF8

# Backup dos drivers de impressora
$printerDrivers = Get-PrinterDriver | Select-Object Name, Manufacturer, DriverVersion
$printerDrivers | Export-Csv "$backupFolder\04_impressoras_drivers.csv" -NoTypeInformation -Encoding UTF8

# 5. PASTAS COMPARTILHADAS
Write-Log "Coletando informações de pastas compartilhadas..."
$sharedFolders = Get-SmbShare | Where-Object { $_.Path -ne $null } | Select-Object Name, Path, Description
$sharedFolders | Export-Csv "$backupFolder\05_pastas_compartilhadas.csv" -NoTypeInformation -Encoding UTF8

# 6. PROGRAMAS INSTALADAS
Write-Log "Coletando lista de programas instalados..."
# Programas de 64-bit
$programs64 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Where-Object { $_.DisplayName -ne $null } | 
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

# Programas de 32-bit
$programs32 = Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Where-Object { $_.DisplayName -ne $null } | 
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

$allPrograms = $programs64 + $programs32 | Sort-Object DisplayName
$allPrograms | Export-Csv "$backupFolder\06_programas_instalados.csv" -NoTypeInformation -Encoding UTF8

# 7. CERTIFICADOS DIGITAIS
Write-Log "Coletando informações de certificados digitais..."
try {
    $certificates = Get-ChildItem Cert:\CurrentUser\My | Select-Object Subject, Issuer, Thumbprint, NotBefore, NotAfter
    $certificates | Export-Csv "$backupFolder\07_certificados_usuario.csv" -NoTypeInformation -Encoding UTF8
}
catch {
    Write-Log "Não foi possível acessar os certificados do usuário"
}

try {
    $machineCerts = Get-ChildItem Cert:\LocalMachine\My | Select-Object Subject, Issuer, Thumbprint, NotBefore, NotAfter
    $machineCerts | Export-Csv "$backupFolder\07_certificados_maquina.csv" -NoTypeInformation -Encoding UTF8
}
catch {
    Write-Log "Não foi possível acessar os certificados da máquina"
}

# 8. ÍCONES DA ÁREA DE TRABALHO
Write-Log "Copiando atalhos da área de trabalho..."
$desktopPath = [Environment]::GetFolderPath("Desktop")
$desktopBackup = Join-Path $backupFolder "Desktop_Icons"
New-Item -ItemType Directory -Path $desktopBackup | Out-Null

if (Test-Path $desktopPath) {
    Get-ChildItem -Path $desktopPath -Filter "*.lnk" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $desktopBackup -Force
    }
    Write-Log "Atalhos da área de trabalho copiados"
}

# 9. PAPEL DE PAREDE ATUAL
Write-Log "Salvando configuração do papel de parede..."
try {
    $wallpaperPath = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper).Wallpaper
    if (Test-Path $wallpaperPath) {
        $wallpaperBackup = Join-Path $backupFolder "wallpaper"
        New-Item -ItemType Directory -Path $wallpaperBackup | Out-Null
        Copy-Item -Path $wallpaperPath -Destination $wallpaperBackup -Force
        
        # Salvar também o registro
        $wallpaperReg = @{
            Wallpaper = $wallpaperPath
            TileWallpaper = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper).TileWallpaper
            WallpaperStyle = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle).WallpaperStyle
        }
        $wallpaperReg | ConvertTo-Json | Out-File "$wallpaperBackup\wallpaper_settings.json"
        Write-Log "Papel de parede salvo"
    }
}
catch {
    Write-Log "Não foi possível salvar o papel de parede"
}

# 10. CONFIGURAÇÕES ADICIONAIS DO USUÁRIO
Write-Log "Salvando configurações adicionais..."

# Favoritos do Internet Explorer/Edge
$favoritesPath = [Environment]::GetFolderPath("Favorites")
if (Test-Path $favoritesPath) {
    $favBackup = Join-Path $backupFolder "Favoritos"
    Copy-Item -Path $favoritesPath -Destination $favBackup -Recurse -Force
    Write-Log "Favoritos copiados"
}

# Documentos importantes
$myDocs = [Environment]::GetFolderPath("MyDocuments")
if (Test-Path $myDocs) {
    # Copiar apenas alguns tipos de arquivos importantes
    $docTypes = @("*.doc", "*.docx", "*.xls", "*.xlsx", "*.pdf", "*.txt")
    $docsBackup = Join-Path $backupFolder "Documentos"
    New-Item -ItemType Directory -Path $docsBackup | Out-Null
    
    foreach ($type in $docTypes) {
        Get-ChildItem -Path $myDocs -Filter $type -Recurse -ErrorAction SilentlyContinue | 
            ForEach-Object {
                $relativePath = $_.FullName.Substring($myDocs.Length + 1)
                $destPath = Join-Path $docsBackup $relativePath
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $destPath -Force
            }
    }
    Write-Log "Documentos importantes copiados"
}

# 11. GERAR RELATÓRIO RESUMIDO
Write-Log "Gerando relatório resumido..."

$report = @"
RELATÓRIO DE BACKUP DO SISTEMA
===============================
Data/Hora: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Computador: $($env:COMPUTERNAME)
Usuário: $($env:USERNAME)

RESUMO:
- Informações do Sistema: $(if (Test-Path "$backupFolder\01_sistema_info.json") {"OK"} else {"Falhou"})
- Configurações de Rede: $(if (Test-Path "$backupFolder\02_configuracoes_rede.csv") {"OK"} else {"Falhou"})
- Redes WiFi: $(if (Test-Path "$backupFolder\03_wifi_detalhes.txt") {"OK"} else {"Falhou"})
- Impressoras: $(($printers | Measure-Object).Count) impressora(s)
- Pastas Compartilhadas: $(($sharedFolders | Measure-Object).Count) pasta(s)
- Programas Instalados: $(($allPrograms | Measure-Object).Count) programa(s)
- Certificados: $(($certificates | Measure-Object).Count + ($machineCerts | Measure-Object).Count) certificado(s)
- Ícones Área de Trabalho: $(if (Test-Path $desktopBackup) {"OK"} else {"Falhou"})
- Papel de Parede: $(if (Test-Path $wallpaperPath) {"OK"} else {"Falhou"})

LOCAL DO BACKUP: $backupFolder

INSTRUÇÕES PARA RESTAURAÇÃO:
1. Após instalar o Windows, execute o script de restauração
2. Configure primeiro as redes WiFi
3. Instale os programas da lista
4. Configure as impressoras
5. Restaure os certificados
6. Configure o papel de parede e ícones

"@

$report | Out-File "$backupFolder\00_relatorio_resumo.txt" -Encoding UTF8

Write-Log "Backup completo concluído!"
Write-Log "=================================="
Write-Log "Todos os arquivos foram salvos em: $backupFolder"
Write-Log "Verifique o arquivo '00_relatorio_resumo.txt' para instruções de restauração"

# Criar script de restauração básico
$restoreScript = @'
# Script de restauração básico
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFolder
)

Write-Host "Script de restauração" -ForegroundColor Green
Write-Host "Local do backup: $BackupFolder" -ForegroundColor Yellow

# Aqui você pode adicionar lógica de restauração
# 1. Ler CSV de programas e reinstalar
# 2. Configurar impressoras
# 3. Restaurar papel de parede
# etc.

Write-Host "`nUse os arquivos no backup para restaurar manualmente:" -ForegroundColor Cyan
Write-Host "1. Programas: programas_instalados.csv"
Write-Host "2. Redes WiFi: wifi_detalhes.txt"
Write-Host "3. Impressoras: impressoras.csv"
Write-Host "4. Papel de parede: pasta wallpaper/"
Write-Host "`nBackup completo em: $BackupFolder" -ForegroundColor Green
'@

$restoreScript | Out-File "$backupFolder\restaurar.ps1" -Encoding UTF8

Write-Host "`n" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host "BACKUP CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host "Local: $backupFolder" -ForegroundColor Yellow
Write-Host "`nArquivos criados:" -ForegroundColor Cyan
Get-ChildItem $backupFolder | ForEach-Object { Write-Host "  - $($_.Name)" }
Write-Host "`nExecute como Administrador para informações completas de WiFi" -ForegroundColor Yellow