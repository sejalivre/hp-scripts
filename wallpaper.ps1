# wallpaper.ps1 - Configuração de Wallpaper Padrão HPCRAFT
# Versão: 1.1.0 | Foco: Asset Abstraction

$baseUrl = "http://get.hpinfo.com.br"

try {
    Write-Host "Atualizando papel de parede corporativo..." -ForegroundColor Cyan
    
    # Nome genérico para facilitar a troca no repositório sem mexer no código
    $wpUrl = "$baseUrl/tools/wallpaper.jpg"
    $wpPath = "$env:TEMP\wallpaper.jpg"
    
    # Download do arquivo
    Invoke-WebRequest -Uri $wpUrl -OutFile $wpPath -ErrorAction Stop

    # Definição da Classe C# para aplicação imediata 
    $code = @'
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
'@

    # Injeta o tipo se não existir na sessão atual
    if (-not ([System.Management.Automation.PSTypeName]"Wallpaper").Type) {
        Add-Type -TypeDefinition $code
    }

    # Aplica o Wallpaper (20 = SPI_SETDESKWALLPAPER)
    [Wallpaper]::SystemParametersInfo(20, 0, $wpPath, 3)

    Write-Host "[OK] Wallpaper atualizado com sucesso!" -ForegroundColor Green

} catch {
    Write-Warning "Não foi possível aplicar o wallpaper. Verifique a conexão ou o arquivo no servidor."
}