<#
.SYNOPSIS
    Script de Manutenção e Autocorreção HPTI - NextDNS
.DESCRIPTION
    1. Verifica se o serviço NextDNS está rodando. Se não, inicia.
    2. Reaplica os DNS IPv4 e IPv6 nas placas ativas.
    3. Garante que o NextDNS esteja oculto no Painel de Controle.
    4. Limpa o cache DNS.
#>

# --- VERIFICAÇÃO DE ADM ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute como ADMINISTRADOR!"
    Start-Sleep -Seconds 3
    
}

# --- DADOS DO PERFIL HPTI ---
$DNS_IPv4 = @("45.90.28.122", "45.90.30.122")
$DNS_IPv6 = @("2a07:a8c0::3a:495c", "2a07:a8c1::3a:495c")
$All_DNS  = $DNS_IPv4 + $DNS_IPv6

Write-Host "--- INICIANDO VERIFICAÇÃO DE SAÚDE HPTI ---" -ForegroundColor Cyan

# --- 1. VERIFICAR SERVIÇO ---
# --- 1. VERIFICAR SERVIÇO (BUSCA INTELIGENTE) ---
# Procura qualquer serviço que tenha "NextDNS" no nome ou na descrição
$Service = Get-Service | Where-Object { $_.DisplayName -like "*NextDNS*" -or $_.Name -like "*NextDNS*" } | Select-Object -First 1

if ($Service) {
    Write-Host " -> Serviço encontrado: $($Service.Name) ($($Service.DisplayName))" -ForegroundColor Gray
    
    if ($Service.Status -ne "Running") {
        Write-Host "[CORREÇÃO] O serviço estava parado. Iniciando..." -ForegroundColor Yellow
        Start-Service -InputObject $Service
        Write-Host " -> Serviço iniciado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "[OK] O serviço NextDNS está rodando." -ForegroundColor Green
    }
} else {
    # Se caiu aqui, é porque o EXE foi instalado, mas NÃO criou o serviço (modo usuário apenas)
    Write-Error "[ALERTA] O executável está instalado, mas o SERVIÇO do Windows não foi encontrado."
    Write-Warning "Sugestão: Reinstale usando o comando '/S' para garantir que vire um serviço do sistema."
}

# --- 2. FORÇAR DNS NAS PLACAS ATIVAS ---
<# Write-Host "`n[VERIFICAÇÃO] Validando configurações de DNS..." -ForegroundColor Cyan
try {
    # Pega adaptadores conectados
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

    foreach ($nic in $Adapters) {
        # Em vez de apenas comparar, nós REAPLICAMOS para garantir que nada saia do padrão
        Write-Host " -> Reforçando DNS na interface: $($nic.Name)" -ForegroundColor Gray
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ServerAddresses $All_DNS -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] DNS IPv4 e IPv6 estão configurados." -ForegroundColor Green
} catch {
    Write-Error "Erro ao configurar DNS: $_"
}
#>

# ==========================================
# 8. GARANTIR REDE LIMPA (DHCP)
# ==========================================
# Em vez de chumbar IP, vamos deixar automatico para o Agente NextDNS assumir.
# Isso garante que o HOSTNAME apareca nos logs.

Write-Host "Definindo placas de rede para Automático (DHCP)..." -ForegroundColor Yellow

try {
    # Pega apenas adaptadores conectados (Status = Up)
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

    foreach ($nic in $Adapters) {
        Write-Host "    - Limpando DNS da interface: $($nic.Name)" -ForegroundColor Gray
        
        # O parâmetro -ResetServerAddresses remove qualquer DNS estático (IPv4 e IPv6)
        Set-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
} catch {
    Write-Warning "Não foi possível resetar o DNS para DHCP: $_"
}

# --- 3. GARANTIR QUE ESTÁ OCULTO ---
Write-Host "`n[VERIFICAÇÃO] Validando ocultação do programa..." -ForegroundColor Cyan
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $uninstallPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path | ForEach-Object {
            $displayName = Get-ItemProperty -Path $_.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue
            
            # Se encontrar NextDNS
            if ($displayName.DisplayName -like "*NextDNS*") {
                # Verifica se a chave de ocultação existe
                $isHidden = Get-ItemProperty -Path $_.PSPath -Name "SystemComponent" -ErrorAction SilentlyContinue
                
                if (-not $isHidden -or $isHidden.SystemComponent -ne 1) {
                    Write-Host "[CORREÇÃO] Ocultando NextDNS que estava visível..." -ForegroundColor Yellow
                    New-ItemProperty -Path $_.PSPath -Name "SystemComponent" -Value 1 -PropertyType DWORD -Force | Out-Null
                } else {
                     Write-Host "[OK] NextDNS está oculto (Chave encontrada em $($_.PSChildName))." -ForegroundColor Green
                }
            }
        }
    }
}


# --- ATUALIZAR IP VINCULADO (DDNS) ---
Write-Host "Atualizando IP vinculado no painel..." -ForegroundColor Cyan
try {
    # O parametro -UseBasicParsing garante compatibilidade com Windows antigos
    # O | Out-Null esconde o output para não sujar a tela
    Invoke-WebRequest -Uri "https://link-ip.nextdns.io/3a495c/97a2d3980330d01a" -UseBasicParsing | Out-Null
    Write-Host "[OK] IP atualizado no NextDNS." -ForegroundColor Green
} catch {
    Write-Warning "Não foi possível atualizar o IP vinculado (Sem internet?)."
}

# --- INSTALAR CERTIFICADO ---
$CertPath = Join-Path $PSScriptRoot "NextDNS.cer"
if (Test-Path $CertPath) {
    Write-Host "Instalando certificado raiz..." -ForegroundColor Yellow
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
}
# --- 4. FLUSH FINAL ---
Write-Host "`n[MANUTENÇÃO] Limpando Cache DNS..." -ForegroundColor Cyan
Invoke-Expression -Command "ipconfig /flushdns"

Write-Host "`n--- VERIFICAÇÃO CONCLUÍDA ---" -ForegroundColor White
Start-Sleep -Seconds 3