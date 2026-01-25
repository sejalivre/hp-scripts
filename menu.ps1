# Arquivo: menu.ps1
# Launcher Central - HP-Scripts (v2.3)
Clear-Host

$baseUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "             HP-SCRIPTS - CENTRAL DE SUPORTE              " -ForegroundColor Cyan
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

Switch ($escolha) { 
    "1" { Write-Host "Carregando Info..."; irm "$baseUrl/info.ps1" | iex }
    "2" { Write-Host "Iniciando reparo de rede..."; irm "$baseUrl/net.ps1" | iex }
    "3" { Write-Host "Carregando módulo de impressão..."; irm "$baseUrl/print.ps1" | iex }
    "4" { Write-Host "Iniciando atualizações..."; irm "$baseUrl/update.ps1" | iex }
    "5" { Write-Host "Iniciando backup..."; irm "$baseUrl/backup.ps1" | iex }
    "6" { Write-Host "Sincronizando horário..."; irm "$baseUrl/hora.ps1" | iex }
    "7" { Write-Host "Iniciando limpeza..."; irm "$baseUrl/limp.ps1" | iex }
    "8" { Write-Host "Iniciando ativador..."; irm "https://get.activated.win" | iex }
    "9" { 
        Write-Host "Configurando Wallpaper..." -ForegroundColor Magenta
        $wpUrl = "$baseUrl/tools/4k-praia.jpg"
        $wpPath = "$env:TEMP\4k-praia.jpg"
        
        Invoke-WebRequest -Uri $wpUrl -OutFile $wpPath
        
        $code = @'
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
        Add-Type -TypeDefinition $code
        [Wallpaper]::SystemParametersInfo(20, 0, $wpPath, 3)
        Write-Host "[OK] Wallpaper aplicado!" -ForegroundColor Green
    }
    "Q" { Write-Host "Saindo..."; Exit }
    Default { Write-Host "Opção Inválida." -ForegroundColor Red }
}

# Retorna ao menu ou pausa após a execução de qualquer tarefa
Write-Host "`nTarefa finalizada. Pressione qualquer tecla para voltar ao menu..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
./menu.ps1 # Recarrega o menu automaticamente