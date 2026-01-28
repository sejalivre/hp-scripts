# SFC - Diagnóstico e Reparação Completa do Windows

## 📋 Visão Geral

O `sfc.ps1` é um script abrangente de diagnóstico e reparação do Windows que executa múltiplas verificações e correções para resolver problemas comuns de sistema, incluindo alto uso de memória, processos travados, arquivos corrompidos e serviços problemáticos.

## 🚀 Execução Rápida

```powershell
# Execução direta (recomendado)
irm get.hpinfo.com.br/sfc | iex

# Ou via menu principal
irm get.hpinfo.com.br/menu | iex  # Opção 2
```

## ⚙️ Funcionalidades

### 1. 💾 Análise e Otimização de Memória

- **Verifica uso de memória RAM** (total, usado, livre)
- **Detecta uso crítico** (> 80%)
- **Libera memória automaticamente** quando necessário:
  - Limpa cache DNS
  - Otimiza working set de processos
  - Força coleta de lixo .NET

**Exemplo de saída:**
```
Memória Total: 16.00 GB
Memória Usada: 13.50 GB (84.38%)
Memória Livre: 2.50 GB
[WARNING] Uso de memória crítico! Liberando memória...
```

### 2. 🔍 Análise de Processos

- **Identifica processos com alto consumo**:
  - Top 10 por uso de CPU
  - Top 10 por uso de memória
- **Detecta processos suspeitos** (múltiplas instâncias)
- **Exibe tabelas detalhadas** com métricas

**Exemplo de saída:**
```
Top 10 Processos por CPU:
Name          CPU    Memory(MB)
----          ---    ----------
chrome        245.3  1024.50
explorer      89.2   512.30
```

### 3. 🧹 Limpeza de Arquivos Temporários

Remove arquivos desnecessários de:
- `%TEMP%` (pasta temporária do usuário)
- `%WINDIR%\Temp` (pasta temporária do sistema)
- `%LOCALAPPDATA%\Temp`
- `%WINDIR%\Prefetch` (cache de pré-carregamento)
- **Lixeira** (esvaziada automaticamente)

**Benefícios:**
- Libera espaço em disco
- Melhora performance
- Remove arquivos corrompidos temporários

### 4. 🛠️ DISM - Deployment Image Servicing

Verifica e repara a integridade da imagem do Windows:

```powershell
# Comandos executados:
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth
DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

**O que faz:**
- Verifica corrupção na imagem do Windows
- Repara componentes corrompidos
- Limpa componentes antigos e obsoletos
- Prepara o sistema para SFC

### 5. 🔧 SFC - System File Checker

Verifica e repara arquivos do sistema corrompidos:

```powershell
sfc /scannow
```

**Possíveis resultados:**
- ✅ Nenhum problema encontrado
- ✅ Arquivos corrompidos reparados com sucesso
- ⚠️ Problemas detectados (veja CBS.log)

**Log detalhado:** `C:\Windows\Logs\CBS\CBS.log`

### 6. 💿 Verificação de Disco

Para cada volume/partição:
- **Analisa espaço livre** (GB e %)
- **Alerta quando < 10% livre**
- **Executa verificação de erros** (chkdsk)
- **Recomenda reparação** se necessário

**Exemplo de saída:**
```
Analisando disco C:
  Espaço livre: 45.23 GB de 250.00 GB (18.09%)
  Disco C: está saudável
```

### 7. ⚙️ Otimização de Serviços

Verifica e inicia serviços críticos do Windows:

| Serviço | Nome | Função |
|---------|------|--------|
| `wuauserv` | Windows Update | Atualizações automáticas |
| `BITS` | Background Intelligent Transfer | Downloads em segundo plano |
| `CryptSvc` | Cryptographic Services | Assinaturas digitais |
| `TrustedInstaller` | Windows Modules Installer | Instalação de componentes |
| `Dhcp` | DHCP Client | Configuração automática de IP |
| `Dnscache` | DNS Client | Resolução de nomes |
| `EventLog` | Windows Event Log | Registro de eventos |
| `Winmgmt` | WMI | Gerenciamento do Windows |

### 8. 🔄 Reparação do Windows Update

Corrige problemas comuns do Windows Update:

**Processo:**
1. Para serviços relacionados (`wuauserv`, `cryptSvc`, `bits`, `msiserver`)
2. Renomeia pastas de cache:
   - `SoftwareDistribution` → `SoftwareDistribution.old`
   - `catroot2` → `catroot2.old`
3. Reinicia os serviços
4. Windows Update recria as pastas automaticamente

**Resolve:**
- Atualizações travadas
- Erros de download
- Cache corrompido
- Serviços não iniciando

### 9. 🖥️ Verificação de Drivers

- **Identifica dispositivos com problemas**
- **Exibe código de erro** do Device Manager
- **Recomenda atualização** de drivers problemáticos

**Códigos de erro comuns:**
- `0` = Funcionando corretamente
- `1` = Configuração incorreta
- `10` = Dispositivo não pode iniciar
- `28` = Driver não instalado

### 10. 🗂️ Otimização do Registro

Limpeza segura e básica:
- **Remove cache de ícones** (`IconCache.db`)
- **Limpa histórico de execução** (RunMRU)
- **Não toca em chaves críticas** (seguro)

### 11. 🛡️ Verificação de Segurança

**Windows Defender:**
- Verifica se está ativo
- **Atualiza definições de vírus**
- **Executa verificação rápida** (Quick Scan)
- Alerta se estiver desativado

## 📊 Relatório Final

Ao final da execução, o script exibe:

```
╔═══════════════════════════════════════════════════════════════╗
║              DIAGNÓSTICO CONCLUÍDO COM SUCESSO                ║
╚═══════════════════════════════════════════════════════════════╝

Informações do Sistema:
  Computador: DESKTOP-ABC123
  Sistema Operacional: Microsoft Windows 10 Pro
  Versão: 10.0.19045
  Arquitetura: 64-bit
  Tempo ligado: 5 dias, 12 horas, 34 minutos

Ações Realizadas:
  ✓ Análise e otimização de memória
  ✓ Identificação de processos problemáticos
  ✓ Limpeza de arquivos temporários
  ✓ Verificação e reparação DISM
  ✓ Verificação e reparação SFC
  ✓ Verificação de disco
  ✓ Otimização de serviços
  ✓ Reparação do Windows Update
  ✓ Verificação de drivers
  ✓ Otimização do registro
  ✓ Verificação de segurança

Log completo salvo em:
  C:\Program Files\HPTI\sfc_repair_20260127.log

Recomendações:
  • Reinicie o computador para aplicar todas as correções
  • Execute o Windows Update para instalar atualizações pendentes
  • Considere fazer uma desfragmentação do disco (se HDD)
  • Mantenha o sistema atualizado regularmente
```

## 📝 Sistema de Logs

### Localização
Todos os logs são salvos em:
```
C:\Program Files\HPTI\sfc_repair_YYYYMMDD.log
```

### Formato do Log
```
[2026-01-27 21:00:15] [INFO] Iniciando diagnóstico completo do sistema...
[2026-01-27 21:00:18] [SUCCESS] Memória otimizada com sucesso!
[2026-01-27 21:05:42] [WARNING] Uso de memória crítico!
[2026-01-27 21:10:30] [ERROR] Erro ao verificar disco: Acesso negado
```

### Tipos de Log
- `[INFO]` - Informações gerais (branco)
- `[SUCCESS]` - Operações bem-sucedidas (verde)
- `[WARNING]` - Avisos e alertas (amarelo)
- `[ERROR]` - Erros e falhas (vermelho)

## 🔧 Requisitos

### Sistema Operacional
- ✅ Windows 7 / 8 / 8.1
- ✅ Windows 10 (todas as versões)
- ✅ Windows 11
- ✅ Windows Server 2008 R2+

### PowerShell
- **Mínimo:** PowerShell 3.0
- **Recomendado:** PowerShell 5.1 ou 7+

### Permissões
- ⚠️ **Requer privilégios de Administrador**
- Script verifica automaticamente e aborta se não for admin

### Conectividade
- Não requer internet (executa localmente)
- Exceção: Windows Defender precisa de internet para atualizar definições

## 🎯 Casos de Uso

### 1. Sistema Lento
**Sintomas:**
- Computador demorando para responder
- Aplicativos travando
- Alto uso de CPU/memória

**Solução:**
```powershell
irm get.hpinfo.com.br/sfc | iex
```

### 2. Erros do Windows Update
**Sintomas:**
- Atualizações falhando
- Código de erro 0x80070002, 0x8024402F
- Windows Update travado

**Solução:**
O script repara automaticamente o Windows Update (módulo 8)

### 3. Arquivos do Sistema Corrompidos
**Sintomas:**
- Tela azul (BSOD)
- Aplicativos não abrindo
- Erros de DLL faltando

**Solução:**
DISM + SFC reparam arquivos corrompidos automaticamente

### 4. Disco Cheio
**Sintomas:**
- Pouco espaço livre
- Sistema lento
- Impossível instalar atualizações

**Solução:**
Limpeza de temporários + DISM cleanup liberam espaço

### 5. Pré-Formatação
**Antes de formatar, tente:**
```powershell
# 1. Diagnóstico e reparação completa
irm get.hpinfo.com.br/sfc | iex

# 2. Se melhorar, faça backup
irm get.hpinfo.com.br/backup | iex

# 3. Atualize o sistema
irm get.hpinfo.com.br/update | iex
```

## ⏱️ Tempo de Execução

| Módulo | Tempo Estimado |
|--------|----------------|
| Análise de Memória | 5-10 segundos |
| Análise de Processos | 5-10 segundos |
| Limpeza de Temporários | 30-60 segundos |
| **DISM** | **5-15 minutos** ⏳ |
| **SFC** | **5-20 minutos** ⏳ |
| Verificação de Disco | 10-30 segundos |
| Otimização de Serviços | 10-20 segundos |
| Reparação Windows Update | 20-40 segundos |
| Verificação de Drivers | 5-10 segundos |
| Limpeza de Registro | 5 segundos |
| Verificação de Segurança | 2-5 minutos |
| **TOTAL** | **15-45 minutos** |

> ⚠️ **Nota:** DISM e SFC são os módulos mais demorados. Não interrompa o processo!

## 🔍 Solução de Problemas

### Script não inicia
**Erro:** "Execução de scripts está desabilitada"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Erro de permissão
**Erro:** "Este script requer privilégios de administrador"
```powershell
# Clique com botão direito no PowerShell
# Selecione "Executar como Administrador"
```

### DISM falha
**Erro:** "DISM: Alguns problemas não puderam ser corrigidos"
```powershell
# 1. Tente com fonte online da Microsoft
DISM /Online /Cleanup-Image /RestoreHealth /Source:WIM:D:\sources\install.wim:1

# 2. Ou use Windows Update como fonte
DISM /Online /Cleanup-Image /RestoreHealth /Source:WU
```

### SFC não repara arquivos
**Erro:** "SFC encontrou arquivos corrompidos mas não conseguiu reparar"
```powershell
# 1. Execute DISM primeiro (o script já faz isso)
# 2. Reinicie o computador
# 3. Execute SFC novamente
sfc /scannow
```

### Memória não é liberada
**Causa:** Processos do sistema não podem ter memória liberada
**Solução:** Normal. O script libera o que é possível.

## 🔗 Integração com Outros Scripts

### Fluxo Recomendado

```powershell
# 1. Diagnóstico inicial
irm get.hpinfo.com.br/check | iex

# 2. Reparação completa (se problemas detectados)
irm get.hpinfo.com.br/sfc | iex

# 3. Limpeza adicional
irm get.hpinfo.com.br/limp | iex

# 4. Atualizar sistema
irm get.hpinfo.com.br/update | iex

# 5. Verificação final
irm get.hpinfo.com.br/check | iex
```

### Combinações Úteis

**Problema de rede + sistema:**
```powershell
irm get.hpinfo.com.br/sfc | iex
irm get.hpinfo.com.br/net | iex
```

**Preparar máquina para entrega:**
```powershell
irm get.hpinfo.com.br/sfc | iex
irm get.hpinfo.com.br/limp | iex
irm get.hpinfo.com.br/update | iex
irm get.hpinfo.com.br/wallpaper | iex
```

## 📚 Referências Técnicas

### Comandos DISM
- [Microsoft Docs - DISM](https://docs.microsoft.com/windows-hardware/manufacture/desktop/dism-operating-system-package-servicing-command-line-options)

### Comandos SFC
- [Microsoft Docs - SFC](https://support.microsoft.com/en-us/topic/use-the-system-file-checker-tool-to-repair-missing-or-corrupted-system-files-79aa86cb-ca52-166a-92a3-966e85d4094e)

### Códigos de Erro de Dispositivos
- [Microsoft Docs - Device Manager Error Codes](https://support.microsoft.com/en-us/topic/error-codes-in-device-manager-in-windows-524e9e89-4dee-8883-0afa-6bca47456ce6)

## 🛠️ Desenvolvimento

### Estrutura do Código

```powershell
# 1. Cabeçalho e requisitos
#Requires -RunAsAdministrator

# 2. Funções auxiliares
function Show-Header { }
function Write-Log { }
function Test-Admin { }

# 3. Verificação de privilégios
if (-not (Test-Admin)) { exit 1 }

# 4. Módulos de diagnóstico (1-11)
# Cada módulo é independente e pode falhar sem afetar os outros

# 5. Relatório final
```

### Personalização

**Alterar diretório de logs:**
```powershell
# Linha 47-51
$logDir = "C:\Program Files\HPTI"  # Altere aqui
```

**Desabilitar módulos específicos:**
```powershell
# Comente o bloco inteiro do módulo
# Exemplo: desabilitar verificação de segurança
<#
Show-Header "11. VERIFICAÇÃO DE SEGURANÇA"
# ... código do módulo ...
#>
```

**Adicionar verificações customizadas:**
```powershell
# Adicione após o módulo 11
Show-Header "12. MINHA VERIFICAÇÃO CUSTOMIZADA"
try {
    Write-Log "Executando verificação customizada..."
    # Seu código aqui
    Write-Log "Verificação concluída!" -Type "SUCCESS"
} catch {
    Write-Log "Erro: $($_.Exception.Message)" -Type "ERROR"
}
```

## 📞 Suporte

- 📖 **Documentação:** [docs.hpinfo.com.br](https://docs.hpinfo.com.br)
- 🐛 **Issues:** [GitHub Issues](https://github.com/sejalivre/hp-scripts/issues)
- 💬 **Discussões:** [GitHub Discussions](https://github.com/sejalivre/hp-scripts/discussions)

## ⚖️ Licença

MIT License - Veja [LICENSE](../LICENSE) para detalhes.

---

**⚠️ Aviso:** Este script realiza modificações no sistema. Sempre faça backup antes de executar reparações importantes. Use por sua conta e risco.
