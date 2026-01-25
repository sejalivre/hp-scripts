<#
.SYNOPSIS
    Hub de Automação HP-Scripts - Central de Suporte.
.DESCRIPTION
    Launcher centralizado para scripts de manutenção hospedados no GitHub.
#>

$baseUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main"

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "               HP-SCRIPTS - CENTRAL DE SUPORTE              " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Descrição: Automação técnica e personalização.            " -ForegroundColor Gray
    Write-Host ""

    Write-Host "1. [INFO]   Exibir Informações do PC" -ForegroundColor White
    Write-Host "2. [NET]    Reparar Conexão de Rede" -ForegroundColor White
    Write-Host "3. [PRINT]  Gerenciar Impressoras" -ForegroundColor White
    Write-Host "4. [UPDATE] Atualizar Sistema/Drivers" -ForegroundColor White
    Write-Host "5. [BACKUP] Realizar Backup do Sistema" -ForegroundColor White
    Write-Host "6. [HORA]   Sincronizar Relógio (NTP)" -ForegroundColor White
    Write-Host "7. [LIMP]   Limpeza Profunda do Sistema" -ForegroundColor White
    Write-Host "8. [ACT]    Ativação Windows/Office" -ForegroundColor Yellow
    Write-Host "9. [WALL]   Aplicar Wallpaper HP 4K (Praia)" -ForegroundColor Magenta
    Write-Host "   -> Baixa e define o fundo de tela automaticamente." -ForegroundColor Gray

    Write-Host ""
    Write-Host "Q. [SAIR]   Encerrar Script" -ForegroundColor Red
    Write-Host ""

    $escolha = Read-Host "Digite o número da opção"

    switch ($escolha) { 
        "1" { Write-Host "`nCarregando Info..."; irm "$baseUrl/info.ps1" | iex }
        "2" { Write-Host "`nIniciando reparo de rede..."; irm "$baseUrl/net.ps1" | iex }
        "3" { Write-Host "`nCarregando módulo de impressão..."; irm "$baseUrl/print.ps1" | iex }
        "4" { Write-Host "`nIniciando atualizações..."; irm "$baseUrl/update.ps1" | iex }
        "5" { Write-Host "`nIniciando backup..."; irm "$baseUrl/backup.ps1" | iex }
        "6" { Write-Host "`nSincronizando horário..."; irm "$baseUrl/hora.ps1" | iex }
        "7" { Write-Host "`nIniciando limpeza..."; irm "$baseUrl/limp.ps1" | iex }
        "8" { Write-Host "`nIniciando ativador..."; irm "https://get.activated.win" | iex }
        "9" { 
            Write-Host "`nConfigurando Wallpaper..." -ForegroundColor Magenta
            try {
                $wpUrl = "$baseUrl/tools/4k-praia.jpg"
                $wpPath = "$env:TEMP\4k-praia.jpg"
                Invoke-WebRequest -Uri $wpUrl -OutFile $wpPath -ErrorAction Stop
                
                $code = @'
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
                # Verifica se a classe já existe para evitar erro em múltiplas execuções
                if (-not ([System.Management.Automation.PSTypeName]"Wallpaper").Type) {
                    Add-Type -TypeDefinition $code
                }
                [Wallpaper]::SystemParametersInfo(20, 0, $wpPath, 3)
                Write-Host "[OK] Wallpaper aplicado!" -ForegroundColor Green
            } catch {
                Write-Warning "Falha ao baixar ou aplicar o Wallpaper."
            }
        }
        "Q" { 
            Write-Host "Saindo..." -ForegroundColor Red
            Start-Sleep -Seconds 1
            exit 
        }
        Default { 
            Write-Host "Opção Inválida." -ForegroundColor Red 
            Start-Sleep -Seconds 1
            continue
        }
    }

    

} while ($true)