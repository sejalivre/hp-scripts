# wallpaper.ps1 - Configuração de Wallpaper Padrão HPCRAFT
# Versão: 1.1.1 | Fix: Direct URL Download

# URL direta que funcionou no seu teste
$wpUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools/wallpaper.jpg"
$wpPath = "$env:TEMP\wallpaper.jpg"

try {
    Write-Host "Baixando papel de parede corporativo..." -ForegroundColor Cyan
    
    # Download do arquivo
    Invoke-WebRequest -Uri $wpUrl -OutFile $wpPath -ErrorAction Stop

    # Definição da Classe C# para aplicação imediata (SystemParametersInfo)
    $code = @'
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
'@

    # Injeta o tipo se não existir na sessão (evita erro de redefinição)
    if (-not ([System.Management.Automation.PSTypeName]"Wallpaper").Type) {
        Add-Type -TypeDefinition $code
    }

    # Aplica o Wallpaper (20 = SPI_SETDESKWALLPAPER)
    # 3 = Atualiza o arquivo de registro e envia a mudança para todos os processos
    [Wallpaper]::SystemParametersInfo(20, 0, $wpPath, 3)

    Write-Host "[OK] Wallpaper atualizado com sucesso!" -ForegroundColor Green

} catch {
    Write-Warning "Falha ao aplicar o wallpaper: $($_.Exception.Message)"
}
