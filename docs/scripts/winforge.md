# WinForge - Instalação e Otimização do Sistema

## Visão Geral

O **WinForge** é um script PowerShell abrangente que automatiza a instalação de aplicativos essenciais e aplica otimizações de sistema para padronizar máquinas Windows após formatação. Ideal para técnicos que precisam configurar múltiplas máquinas com um padrão consistente de performance e usabilidade.

## Execução Rápida

```powershell
# Execução direta (recomendado)
irm get.hpinfo.com.br/winforge | iex

# Ou via menu principal
irm get.hpinfo.com.br/menu | iex  # Opção 4
```

## Características Principais

### 📦 Instalação Automática de Aplicativos

- **Google Chrome** - Navegador principal
- **7-Zip** - Compactador de arquivos
- **Adobe Acrobat Reader** - Leitor de PDF

O script detecta automaticamente o melhor gerenciador de pacotes:
- **Winget** (primeira opção - nativo no Windows 10/11)
- **Chocolatey** (fallback automático se Winget não disponível)

### ⚙️ Otimizações do Sistema

#### Performance e Energia
- ✅ Plano de energia configurado para **Alto Desempenho**
- ✅ Prefetch otimizado automaticamente (SSD=0, HDD=3)
- ✅ Modern Standby desabilitado
- ✅ Performance de rede otimizada (TCP, chimney, DCA, NetDMA)

#### Interface e Experiência
- ✅ **Dark Mode** habilitado (sistema e apps)
- ✅ Transparência desabilitada
- ✅ Animações e efeitos visuais desabilitados
- ✅ Delay de menus removido (0ms)
- ✅ Ícone "Computador" na área de trabalho
- ✅ Widgets desabilitados na barra de tarefas
- ✅ Ícone de chat/meet now oculto (Windows 10)

#### Privacidade e Recursos Desnecessários
- ✅ **Copilot** desabilitado
- ✅ **Recall** desabilitado
- ✅ **Cortana** desabilitado
- ✅ News & Interests desabilitado
- ✅ Game DVR desabilitado
- ✅ Sugestões de apps no menu Iniciar desabilitadas
- ✅ Sticky Keys desabilitado (5x SHIFT)

#### Navegação
- ✅ Google configurado como mecanismo de busca padrão
- ✅ Anúncios e feed MSN no Edge desabilitados

#### Bloatware Removido
- 3DBuilder
- BingFinance
- BingNews
- Getstarted
- MicrosoftOfficeHub
- MicrosoftSolitaireCollection
- OneNote
- SkypeApp
- XboxApp
- ZuneMusic
- ZuneVideo
- WindowsFeedbackHub
- YourPhone
- People
- Pasta "3D Objects" removida do Explorer

#### Recursos Avançados
- ✅ **Caminhos longos habilitados** (LongPathsEnabled)
- ✅ Otimizações de registro para performance

## Funcionamento Interno

### 1. Detecção de Gerenciador de Pacotes

```powershell
function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}
```

O script primeiro verifica se o Winget está disponível. Se não estiver, tenta usar o Chocolatey ou instalá-lo automaticamente.

### 2. Instalação de Aplicativos

Cada aplicativo é instalado silenciosamente com tratamento de erros:

```powershell
# Exemplo com Winget
winget install --id Google.Chrome --silent --accept-package-agreements

# Exemplo com Chocolatey (fallback)
choco install googlechrome -y
```

### 3. Aplicação de Otimizações

Cada otimização é aplicada individualmente com try-catch para garantir que falhas em uma não afetem as outras:

```powershell
function Enable-LongPaths {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
                         -Name "LongPathsEnabled" -Value 1 -Force
        Write-Log "Caminhos longos habilitados" "SUCCESS"
    } catch {
        Write-Log "Erro: $_" "ERROR"
    }
}
```

### 4. Detecção Automática de Tipo de Disco

O script detecta se o disco do sistema é SSD ou HDD e ajusta o Prefetch automaticamente:

```powershell
$DriveType = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | 
             Select-Object -ExpandProperty MediaType

if ($DriveType -eq "SSD") {
    # Desabilita Prefetch para SSD
    Set-ItemProperty ... -Name "EnablePrefetcher" -Value 0
} else {
    # Habilita Prefetch para HDD
    Set-ItemProperty ... -Name "EnablePrefetcher" -Value 3
}
```

## Logs e Relatórios

### Localização dos Arquivos

- **Logs**: `C:\Program Files\HPTI\Logs\winforge_YYYYMMDD_HHMMSS.log`
- **Relatórios**: `C:\Program Files\HPTI\Reports\winforge_YYYYMMDD_HHMMSS.html`

### Relatório HTML

O script gera automaticamente um relatório HTML visual com:

- **Estatísticas**: Total de apps instalados, otimizações aplicadas, erros encontrados
- **Lista de Aplicativos**: Todos os apps instalados com sucesso
- **Lista de Otimizações**: Todas as configurações aplicadas
- **Erros**: Problemas encontrados durante a execução

O relatório é aberto automaticamente ao final da execução.

## Requisitos

- **Windows**: 7 / 8 / 10 / 11
- **PowerShell**: 5.1 ou superior
- **Privilégios**: Administrador (obrigatório)
- **Internet**: Necessária para download de aplicativos

## Tratamento de Erros

O script foi projetado para **continuar executando** mesmo se operações individuais falharem:

- Cada função possui try-catch individual
- Erros são registrados no log sem interromper o script
- Relatório final mostra quais operações falharam
- `$ErrorActionPreference = "Continue"` garante continuidade

## Exemplo de Uso

### Cenário: Formatação de Máquina

```powershell
# 1. Após formatação, execute como Administrador
irm get.hpinfo.com.br/winforge | iex

# 2. Aguarde a instalação dos aplicativos
# 3. Aguarde a aplicação das otimizações
# 4. Revise o relatório HTML gerado
# 5. Reinicie a máquina para aplicar todas as alterações
```

### Verificação Pós-Execução

```powershell
# Verificar plano de energia
powercfg /getactivescheme

# Verificar caminhos longos
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled"

# Verificar dark mode
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

# Verificar apps instalados
winget list
```

## Personalizações Possíveis

### Adicionar Mais Aplicativos

Edite a array `$Apps` no script:

```powershell
$Apps = @(
    @{Name="Google Chrome"; WingetId="Google.Chrome"; ChocoId="googlechrome"},
    @{Name="VLC Media Player"; WingetId="VideoLAN.VLC"; ChocoId="vlc"},
    @{Name="Notepad++"; WingetId="Notepad++.Notepad++"; ChocoId="notepadplusplus"}
)
```

### Desabilitar Otimizações Específicas

Comente as linhas correspondentes na seção de execução principal:

```powershell
# Enable-LongPaths        # Comentado - não será executado
Remove-MenuDelay          # Será executado normalmente
```

## Alterações que Requerem Reinicialização

Algumas otimizações só terão efeito completo após reiniciar o sistema:

- Plano de energia
- Caminhos longos
- Modern Standby
- Prefetch
- Algumas configurações de registro

> **Recomendação**: Reinicie a máquina após a execução do WinForge para garantir que todas as alterações sejam aplicadas.

## Solução de Problemas

### Winget não está disponível

**Sintoma**: Script tenta instalar Chocolatey automaticamente

**Solução**: 
```powershell
# Instalar Winget manualmente
# Baixe de: https://github.com/microsoft/winget-cli/releases
```

### Chocolatey falha ao instalar

**Sintoma**: Erro ao executar script de instalação do Chocolatey

**Solução**:
```powershell
# Verificar política de execução
Get-ExecutionPolicy

# Ajustar se necessário
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Aplicativos não instalam

**Sintoma**: Apps aparecem como erro no relatório

**Solução**:
1. Verifique conexão com internet
2. Execute manualmente: `winget install --id Google.Chrome`
3. Revise o log em `C:\Program Files\HPTI\Logs\`

### Otimizações não aplicadas

**Sintoma**: Configurações não mudaram após execução

**Solução**:
1. Verifique se executou como Administrador
2. Reinicie a máquina
3. Revise o relatório HTML para ver erros específicos

## Integração com Outros Scripts

O WinForge pode ser combinado com outros scripts do HP-Scripts:

```powershell
# Sequência recomendada pós-formatação
irm get.hpinfo.com.br/winforge | iex  # Instalar apps e otimizar
irm get.hpinfo.com.br/update   | iex  # Atualizar Windows
irm get.hpinfo.com.br/limp     | iex  # Limpar arquivos temporários
irm get.hpinfo.com.br/backup   | iex  # Fazer backup inicial
```

## Segurança

- ✅ Todas as alterações de registro são registradas no log
- ✅ Não remove arquivos do usuário
- ✅ Não modifica configurações de rede
- ✅ Não desabilita recursos de segurança (Windows Defender, Firewall)
- ✅ Código-fonte aberto e auditável

## Referências Técnicas

### Chaves de Registro Modificadas

| Chave | Valor | Propósito |
|-------|-------|-----------|
| `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem` | LongPathsEnabled=1 | Habilita caminhos longos |
| `HKCU:\Control Panel\Desktop` | MenuShowDelay=0 | Remove delay de menus |
| `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize` | AppsUseLightTheme=0 | Dark mode |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot` | TurnOffWindowsCopilot=1 | Desabilita Copilot |

### Comandos PowerCfg Utilizados

```powershell
# Listar planos disponíveis
powercfg -l

# Ativar plano de alto desempenho
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

### Comandos Netsh Utilizados

```powershell
# Otimizar TCP
netsh interface tcp set global autotuninglevel=normal
netsh interface tcp set global chimney=enabled
netsh interface tcp set global dca=enabled
netsh interface tcp set global netdma=enabled
```

## Versionamento

- **Versão Atual**: 1.0
- **Última Atualização**: 2026-01-27
- **Compatibilidade**: Windows 7/8/10/11

## Contribuindo

Para sugerir novos aplicativos ou otimizações, abra uma issue no repositório:
[github.com/sejalivre/hp-scripts/issues](https://github.com/sejalivre/hp-scripts/issues)

## Licença

MIT License - Veja [LICENSE](../../LICENSE) para detalhes.
