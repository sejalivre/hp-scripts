# wallpaper.ps1 - Configuração de Wallpaper Padrão HPCRAFT
# Versão: 1.5.0 | Compatibilidade Windows 10/11
# Requer: PowerShell 5.1+ (Windows 10/11)

# URL direta que funcionou no seu teste
$wpUrl = "https://raw.githubusercontent.com/sejalivre/hp-scripts/main/tools/wallpaper.jpg"
$wpPath = "C:\Intel\wallpaper.jpg"  # Mudado para local permanente

try {
    Write-Host "Baixando papel de parede corporativo..." -ForegroundColor Cyan
    
    # Criar pasta se não existir
    $wpDir = Split-Path $wpPath
    if (-not (Test-Path $wpDir)) {
        New-Item -Path $wpDir -ItemType Directory -Force | Out-Null
    }
    
    # Download do arquivo com fallback para versões antigas
    # Download do arquivo
    Invoke-WebRequest -Uri $wpUrl -OutFile $wpPath -ErrorAction Stop
    
    # Validar arquivo baixado
    if (-not (Test-Path $wpPath)) {
        Write-Warning "Arquivo não foi baixado corretamente"
        exit
    }
    
    $fileSize = (Get-Item $wpPath).Length
    if ($fileSize -lt 10KB) {
        Write-Warning "Arquivo muito pequeno ($fileSize bytes). Pode estar corrompido."
        exit
    }
    
    Write-Host "Arquivo baixado: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Green

    # Definição da Classe C# para aplicação imediata (SystemParametersInfo)
    $code = @'
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
'@

    # Injeta o tipo se não existir na sessão (evita erro de redefinição)
    try {
        $wallpaperType = [Wallpaper]
    }
    catch {
        Add-Type -TypeDefinition $code -ErrorAction Stop
    }

    # Aplica o Wallpaper (20 = SPI_SETDESKWALLPAPER)
    # 3 = Atualiza o arquivo de registro e envia a mudança para todos os processos
    [Wallpaper]::SystemParametersInfo(20, 0, $wpPath, 3)

    Write-Host "[OK] Wallpaper atualizado com sucesso!" -ForegroundColor Green

}
catch {
    Write-Warning "Falha ao aplicar o wallpaper: $($_.Exception.Message)"
}
