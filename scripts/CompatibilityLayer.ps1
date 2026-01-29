# CompatibilityLayer.ps1
# Módulo de Compatibilidade para PowerShell 2.0-5.1
# Provides fallback functions for modern cmdlets that don't exist in PowerShell 2.0

<#
.SYNOPSIS
    Camada de compatibilidade para suportar PowerShell 2.0+ (Windows 7+)
    
.DESCRIPTION
    Este módulo detecta a versão do PowerShell e fornece funções que usam
    cmdlets modernos quando disponíveis, com fallback para WMI/métodos legados
    em versões antigas.
    
.NOTES
    Compatível com: PowerShell 2.0, 3.0, 4.0, 5.0, 5.1
    Testado em: Windows 7, 8, 10, 11
#>

# Detecta versão do PowerShell
$script:PSVersion = $PSVersionTable.PSVersion.Major

# Flag para debug
$script:DebugCompat = $false

function Write-CompatDebug {
    param([string]$Message)
    if ($script:DebugCompat) {
        Write-Host "[COMPAT] $Message" -ForegroundColor DarkGray
    }
}

#region CIM/WMI Compatibility

<#
.SYNOPSIS
    Substitui Get-CimInstance com fallback para Get-WmiObject
#>
function Get-CimOrWmi {
    param(
        [string]$ClassName,
        [string]$Namespace = "root\cimv2",
        [string]$Filter,
        [switch]$First
    )
    
    try {
        if ($script:PSVersion -ge 3) {
            Write-CompatDebug "Usando Get-CimInstance para $ClassName"
            
            $params = @{
                ClassName   = $ClassName
                Namespace   = $Namespace
                ErrorAction = 'SilentlyContinue'
            }
            if ($Filter) { $params['Filter'] = $Filter }
            
            $result = Get-CimInstance @params
        }
        else {
            Write-CompatDebug "Usando Get-WmiObject (PS 2.0) para $ClassName"
            
            $params = @{
                Class       = $ClassName
                Namespace   = $Namespace
                ErrorAction = 'SilentlyContinue'
            }
            if ($Filter) { $params['Filter'] = $Filter }
            
            $result = Get-WmiObject @params
        }
        
        if ($First) {
            return $result | Select-Object -First 1
        }
        return $result
    }
    catch {
        Write-CompatDebug "Erro em Get-CimOrWmi: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region Network Compatibility

<#
.SYNOPSIS
    Obtém configuração de rede (substitui Get-NetIPConfiguration)
#>
function Get-NetworkConfig {
    param(
        [string]$InterfaceAlias
    )
    
    try {
        if ($script:PSVersion -ge 3 -and (Get-Command Get-NetIPConfiguration -ErrorAction SilentlyContinue)) {
            Write-CompatDebug "Usando Get-NetIPConfiguration"
            
            if ($InterfaceAlias) {
                return Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue
            }
            return Get-NetIPConfiguration -ErrorAction SilentlyContinue
        }
        else {
            Write-CompatDebug "Usando WMI para configuração de rede (PS 2.0)"
            
            # Usar WMI Win32_NetworkAdapterConfiguration
            $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | 
            Where-Object { $_.IPEnabled -eq $true }
            
            if ($InterfaceAlias) {
                # Filtrar pelo nome do adaptador
                $adapters = $adapters | Where-Object { 
                    $_.Description -match $InterfaceAlias -or $_.Caption -match $InterfaceAlias 
                }
            }
            
            # Converter para formato compatível
            $results = @()
            foreach ($adapter in $adapters) {
                $obj = New-Object PSObject -Property @{
                    InterfaceAlias     = $adapter.Description
                    InterfaceIndex     = $adapter.Index
                    IPv4Address        = $adapter.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1
                    IPv4DefaultGateway = $adapter.DefaultIPGateway | Select-Object -First 1
                    DNSServer          = $adapter.DNSServerSearchOrder
                    DHCPEnabled        = $adapter.DHCPEnabled
                    MACAddress         = $adapter.MACAddress
                }
                $results += $obj
            }
            
            if ($InterfaceAlias) {
                return $results | Select-Object -First 1
            }
            return $results
        }
    }
    catch {
        Write-CompatDebug "Erro em Get-NetworkConfig: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Obtém adaptadores de rede (substitui Get-NetAdapter)
#>
function Get-NetworkAdapter {
    param(
        [string]$Name,
        [string]$Status = "Up"
    )
    
    try {
        if ($script:PSVersion -ge 3 -and (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
            Write-CompatDebug "Usando Get-NetAdapter"
            
            $params = @{ ErrorAction = 'SilentlyContinue' }
            if ($Name) { $params['Name'] = $Name }
            
            $result = Get-NetAdapter @params
            if ($Status) {
                $result = $result | Where-Object { $_.Status -eq $Status }
            }
            return $result
        }
        else {
            Write-CompatDebug "Usando WMI para adaptadores (PS 2.0)"
            
            # Usar WMI Win32_NetworkAdapter
            $adapters = Get-WmiObject Win32_NetworkAdapter -ErrorAction SilentlyContinue |
            Where-Object { $_.NetConnectionStatus -eq 2 } # 2 = Connected
            
            if ($Name) {
                $adapters = $adapters | Where-Object { $_.NetConnectionID -eq $Name -or $_.Name -eq $Name }
            }
            
            # Converter para formato compatível
            $results = @()
            foreach ($adapter in $adapters) {
                $obj = New-Object PSObject -Property @{
                    Name                 = $adapter.NetConnectionID
                    InterfaceDescription = $adapter.Description
                    InterfaceIndex       = $adapter.InterfaceIndex
                    MacAddress           = $adapter.MACAddress
                    Status               = if ($adapter.NetConnectionStatus -eq 2) { "Up" } else { "Disconnected" }
                }
                $results += $obj
            }
            
            return $results
        }
    }
    catch {
        Write-CompatDebug "Erro em Get-NetworkAdapter: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Verifica se interface usa DHCP
#>
function Test-DHCPEnabled {
    param([string]$InterfaceAlias)
    
    try {
        if ($script:PSVersion -ge 3 -and (Get-Command Get-NetIPInterface -ErrorAction SilentlyContinue)) {
            $interface = Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
            return ($interface.Dhcp -eq 'Enabled')
        }
        else {
            $adapter = Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue |
            Where-Object { $_.Description -match $InterfaceAlias } | Select-Object -First 1
            return $adapter.DHCPEnabled
        }
    }
    catch {
        return $false
    }
}

#endregion

#region SMB/Share Compatibility

<#
.SYNOPSIS
    Obtém pastas compartilhadas (substitui Get-SmbShare)
#>
function Get-ShareCompat {
    try {
        if ($script:PSVersion -ge 3 -and (Get-Command Get-SmbShare -ErrorAction SilentlyContinue)) {
            Write-CompatDebug "Usando Get-SmbShare"
            return Get-SmbShare -ErrorAction SilentlyContinue
        }
        else {
            Write-CompatDebug "Usando WMI para compartilhamentos (PS 2.0)"
            return Get-WmiObject Win32_Share -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-CompatDebug "Erro em Get-ShareCompat: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region Printer Compatibility

<#
.SYNOPSIS
    Obtém impressoras (substitui Get-Printer)
#>
function Get-PrinterCompat {
    try {
        if ($script:PSVersion -ge 3 -and (Get-Command Get-Printer -ErrorAction SilentlyContinue)) {
            Write-CompatDebug "Usando Get-Printer"
            return Get-Printer -ErrorAction SilentlyContinue
        }
        else {
            Write-CompatDebug "Usando WMI para impressoras (PS 2.0)"
            return Get-WmiObject Win32_Printer -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-CompatDebug "Erro em Get-PrinterCompat: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region Web Request Compatibility

<#
.SYNOPSIS
    Substitui Invoke-WebRequest com fallback para WebClient
#>
function Invoke-WebRequestCompat {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [int]$TimeoutSec = 30,
        [switch]$UseBasicParsing
    )
    
    try {
        if ($script:PSVersion -ge 3 -and (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue)) {
            Write-CompatDebug "Usando Invoke-WebRequest"
            
            $params = @{
                Uri         = $Uri
                TimeoutSec  = $TimeoutSec
                ErrorAction = 'Stop'
            }
            if ($UseBasicParsing) { $params['UseBasicParsing'] = $true }
            
            return Invoke-WebRequest @params
        }
        else {
            Write-CompatDebug "Usando WebClient (PS 2.0)"
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("user-agent", "PowerShell")
            
            # Configurar timeout
            if ($TimeoutSec) {
                $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
            }
            
            try {
                $content = $webClient.DownloadString($Uri)
                
                # Criar objeto compatível com Invoke-WebRequest
                $response = New-Object PSObject -Property @{
                    Content           = $content
                    StatusCode        = 200
                    StatusDescription = "OK"
                }
                
                return $response
            }
            finally {
                $webClient.Dispose()
            }
        }
    }
    catch {
        Write-CompatDebug "Erro em Invoke-WebRequestCompat: $($_.Exception.Message)"
        throw
    }
}

#endregion

#region Utility Functions

<#
.SYNOPSIS
    Verifica se está rodando como administrador
#>
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
    Obtém versão do PowerShell de forma compatível
#>
function Get-PSVersionCompat {
    return $PSVersionTable.PSVersion.Major
}

#endregion

# Exporta funções
Export-ModuleMember -Function @(
    'Get-CimOrWmi',
    'Get-NetworkConfig',
    'Get-NetworkAdapter',
    'Test-DHCPEnabled',
    'Get-ShareCompat',
    'Get-PrinterCompat',
    'Invoke-WebRequestCompat',
    'Test-Administrator',
    'Get-PSVersionCompat',
    'Write-CompatDebug'
)

Write-CompatDebug "CompatibilityLayer carregado - PowerShell $script:PSVersion"
