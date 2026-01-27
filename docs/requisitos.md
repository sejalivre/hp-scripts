# ⚙️ Requisitos de Sistema

Requisitos mínimos e recomendados para executar o HP Scripts.

---

## Requisitos Mínimos

### Sistema Operacional

| Componente | Requisito |
|------------|-----------|
| **Windows** | Windows 7 SP1 ou superior |
| **Arquitetura** | x64 (64 bits) ou x86 (32 bits) |
| **Build** | Qualquer versão suportada pela Microsoft |

✅ **Testado em:**
- Windows 7 SP1
- Windows 8.1
- Windows 10 (todas as versões)
- Windows 11
- Windows Server 2012 R2+

### PowerShell

| Versão | Status | Observações |
|--------|--------|-------------|
| **PowerShell 2.0** | ⚠️ Limitado | Funciona com fallbacks |
| **PowerShell 3.0** | ✅ Suportado | Mínimo recomendado |
| **PowerShell 4.0** | ✅ Suportado | Bom desempenho |
| **PowerShell 5.1** | ✅ Recomendado | Melhor compatibilidade |
| **PowerShell 7+** | ✅ Ideal | Performance máxima |

### Privilégios

- **Usuário padrão**: Alguns scripts funcionam sem privilégios
- **Administrador**: Recomendado para funcionalidade completa
- **Elevação automática**: Scripts solicitam UAC quando necessário

### Conectividade

| Modo | Requisito |
|------|-----------|
| **Execução remota** | Conexão com internet (HTTPS) |
| **Execução local** | Sem internet (após clonar repositório) |
| **Downloads** | Necessário para `update.ps1` e `installps1.cmd` |

---

## Requisitos Recomendados

Para melhor experiência e performance:

### Hardware

- **RAM**: 4 GB ou mais
- **Disco**: 10 GB de espaço livre (para limpeza e atualizações)
- **Processador**: Dual-core ou superior

### Software

- **PowerShell 5.1** ou superior
- **Windows 10/11** atualizado
- **.NET Framework 4.5+** (geralmente já instalado)

### Rede

- **Conexão estável** para downloads
- **Acesso HTTPS** não bloqueado
- **DNS funcional** (scripts podem corrigir se necessário)

---

## Verificar Compatibilidade

### Verificar Versão do PowerShell

```powershell
$PSVersionTable.PSVersion
```

**Saída esperada:**
```
Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      19041  1320
```

### Verificar Privilégios de Administrador

```powershell
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

**Saída:**
- `True` = Executando como administrador
- `False` = Executando como usuário padrão

### Verificar Versão do Windows

```powershell
[System.Environment]::OSVersion.Version
```

### Verificar Conectividade

```powershell
Test-NetConnection -ComputerName get.hpinfo.com.br -Port 443
```

---

## Dependências Externas

### Scripts que Requerem Internet

| Script | Motivo |
|--------|--------|
| **update.ps1** | Download de atualizações do Windows |
| **installps1.cmd** | Download do PowerShell 7 |
| **NextDNS** | Download e configuração do cliente |
| **wallpaper.ps1** | Download de imagem (se URL remota) |

### Scripts que Funcionam Offline

| Script | Funcionalidade |
|--------|----------------|
| **check.ps1** | Diagnóstico completo |
| **limp.ps1** | Limpeza de sistema |
| **hora.ps1** | Sincronização NTP (requer rede) |
| **net.ps1** | Reset de rede |
| **print.ps1** | Reparo de impressão |
| **backup.ps1** | Backup local |

---

## Limitações Conhecidas

### PowerShell 2.0

- ❌ Sem suporte a `Invoke-RestMethod`
- ❌ Sem suporte a `ConvertTo-Json`
- ⚠️ Performance reduzida
- ✅ Fallbacks implementados quando possível

### Windows 7

- ⚠️ TLS 1.2 pode precisar ser habilitado manualmente
- ⚠️ Algumas APIs modernas não disponíveis
- ✅ Maioria dos scripts funciona normalmente

### Ambientes Corporativos

- ⚠️ Políticas de execução podem bloquear scripts
- ⚠️ Proxy pode interferir em downloads
- ⚠️ Antivírus pode bloquear execução remota
- ✅ Use execução local se necessário

---

## Solução de Problemas

### Erro: "Execução de scripts está desabilitada"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Erro: "Não foi possível conectar ao servidor remoto"

1. Verificar firewall
2. Verificar proxy corporativo
3. Usar execução local (clonar repositório)

### Erro: "Requer privilégios de administrador"

1. Clicar com botão direito no PowerShell
2. Selecionar "Executar como administrador"
3. Executar o comando novamente

### Erro TLS em Windows 7

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

---

## Instalação de Dependências

### Atualizar PowerShell para 5.1

**Windows 7/8.1:**
1. Instalar [.NET Framework 4.5+](https://dotnet.microsoft.com/download/dotnet-framework)
2. Instalar [WMF 5.1](https://www.microsoft.com/download/details.aspx?id=54616)

**Windows 10/11:**
- PowerShell 5.1 já incluído

### Instalar PowerShell 7

Use nosso instalador automático:

```powershell
irm get.hpinfo.com.br/installps1.cmd | cmd
```

Ou baixe manualmente:
- [PowerShell 7 - Releases](https://github.com/PowerShell/PowerShell/releases)

---

## Ambientes Especiais

### Windows PE / WinRE

- ⚠️ Funcionalidade limitada
- ✅ Scripts básicos funcionam
- ❌ Sem acesso a algumas APIs

### Windows Server

- ✅ Totalmente compatível
- ⚠️ Server Core pode ter limitações
- ✅ Recomendado para automação

### Máquinas Virtuais

- ✅ Funciona normalmente
- ⚠️ Performance pode variar
- ✅ Ideal para testes

---

## Próximos Passos

- 🚀 Veja o [guia de início rápido](quickstart.md)
- 🛡️ Leia a [política de segurança](seguranca.md)
- 📖 Consulte a [documentação completa](index.md)

---

**[← Voltar para Documentação Principal](index.md)**
