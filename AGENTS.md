# AI Knowledge & Skills: HP-Scripts

Este documento serve como a **Fonte da Verdade** para agentes de IA que auxiliam no desenvolvimento, manutenção e expansão do repositório `hp-scripts`. Ele consolida a filosofia do projeto, diretrizes técnicas e um mapa detalhado das capacidades (skills) disponíveis.

## 🎯 Visão Geral e Contexto
**HP-Scripts** é um kit de ferramentas "tudo-em-um" para automação, manutenção e diagnóstico de sistemas Windows (10 e 11).
- **Público-Alvo**: Técnicos de TI e SysAdmins.
- **Distribuição**: Execução remota via URL (`irm | iex`), eliminando a necessidade de download manual.
- **Objetivo**: Padronização, eficiência e robustez na preparação e reparo de máquinas.

## 🧠 Mentalidade e Princípios de Desenvolvimento
Para manter a integridade do projeto, o Agente de IA deve aderir aos seguintes pilares:

### 1. Filosofia de Código
- **Modularidade**: Cada script em `/scripts` deve ser independente. Funções universais ficam no núcleo (`menu.ps1`).
- **Segurança**: 
  - Validar privilégios de Administrador (`#Requires -RunAsAdministrator`).
  - Entender riscos de `iex` (Invoke-Expression).
- **Resiliência**: Uso obrigatório de `try/catch` em operações de sistema (Registro, Serviços, Disco).
- **Feedback Visual**: Uso padronizado de cores para clareza em terminais remotos:
  - `Green`: Sucesso.
  - `Yellow`: Aviso/Aguardando.
  - `Red`: Falha Crítica.
  - `Cyan`: Informação.

### 2. Padrões Técnicos
- **Compatibilidade**: Scripts devem rodar em **PowerShell 5.1** (padrão Win10) com suporte a **PowerShell 7+**.
- **Instalação Silenciosa**: Priorizar `winget` ou flags `/S /quiet`.
- **Não-Interatividade**: Automatizar prompts (`-Force`, `-Confirm:$false`) sempre que possível.
- **Verificação de Estado**: "Check before act" (ex: verificar versão instalada antes de baixar update).

## 📂 Estrutura do Repositório (Mapa Mental)
```text
hp-scripts/
├── scripts/           # CORE: Scripts de automação independentes
│   ├── check.ps1      # Diagnóstico
│   ├── sfc.ps1        # Reparo de Sistema
│   └── [outros].ps1   # Módulos específicos
├── tools/             # SUBSISTEMAS e Ferramentas Complexas
│   └── nextdns/       # Suíte completa de gestão NextDNS
├── portable/          # VERSÃO OFFLINE (Pendrive)
│   ├── INICIAR.cmd    # Launcher Batch
│   └── menu.ps1       # Menu adaptado
├── docs/              # Documentação MkDocs
└── menu.ps1           # ORQUESTRADOR (Ponto de entrada remoto)
```

## 🛠️ Habilidades Específicas (The Skills)

Esta seção detalha as capacidades técnicas que o Agente deve saber manipular e expandir.

### 🛡️ Manutenção e Reparo (`sfc.ps1`)
- **DISM Avançado**: Execução de `CheckHealth`, `ScanHealth` e `RestoreHealth`.
- **Integridade**: `SFC /scannow` com tratamento de logs.
- **Serviços**: Reset de componentes do Windows Update e Criptografia.

### 🧹 Otimização e Limpeza (`limp.ps1`)
- **Limpeza Profunda**: `cleanmgr /sagerun` (automação do Disk Cleanup).
- **Arquivos Temporários**: Esvaziamento seguro de `%TEMP%`, `Prefetch`, `Local AppData`.
- **Update Delivery**: Otimização de cache de entrega.

### 🌐 Redes e Conectividade (`net.ps1`)
- **Reset de Stack**: Winsock, IP (`ipconfig /flushdns /renew`), Tabela ARP.
- **Hora (NTP)**: Configuração forçada de servidores NTP brasileiros (`a.st1.ntp.br`, etc.).
- **Diagnóstico**: Testes de ping, traceroute e resolução DNS.

### 📦 Instalação e Configuração (`winforge.ps1`)
- **Gerenciamento de Pacotes**: Instalação em lote via Winget/Chocolatey.
- **Tweaks de Registro**: Otimizações de UI, privacidade e performance.
- **Bloatware**: Remoção de Apps pré-instalados do Windows.

### 💾 Backup e Migração (`backup.ps1`)
- **Wi-Fi**: Exportação de perfis WLAN para XML (reimportável nativamente).
- **Printers**: Backup de drivers e filas de impressão.
- **Drivers**: Exportação de drivers de terceiros (`dism /online /export-driver`).

### 🔄 Segurança e DNS (`tools/nextdns/`)
- Módulo complexo com ciclo de vida próprio:
  1. **Install**: Configuração de ID, Nome do Device, HTTPS.
  2. **Repair**: Tarefas agendadas para auto-cura do serviço.
  3. **Uninstall**: Limpeza total de vestígios.

### 🖨️ Impressão (`print.ps1`)
- Reinicialização robusta do Spooler.
- Limpeza forçada da pasta de spool (`system32\spool\PRINTERS`).

## 🚀 Workflow de Contribuição para IA
1. **Análise**: Antes de codar, analisar `menu.ps1` para entender dependências.
2. **Features**: Novas funcionalidades devem ser scripts `.ps1` separados em `/scripts`.
3. **Teste**: 
   - Simular execução remota.
   - Validar compatibilidade com Windows 10 limpo.
4. **Documentação**: Atualizar comentários `Get-Help` no topo do script e este arquivo se novas skills forem adicionadas.
5. **Logs**: Garantir que todo erro gere output legível para o técnico.

---

