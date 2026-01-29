# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [v1.5] - 2026-01-27

### Adicionado
- **check.ps1**: Script de diagnóstico rápido de integridade do sistema
- **sfc.ps1**: Diagnóstico e reparação completa (DISM, SFC, memória, processos)
- **winforge.ps1**: Instalação automatizada de aplicativos + otimizações do sistema
- **limp.ps1**: Limpeza agressiva de arquivos temporários e cache
- **wallpaper.ps1**: Aplicação automática de wallpaper corporativo
- **hora.ps1**: Sincronização automática de horário com NTP brasileiro
- **CompatibilityLayer.ps1**: Camada de compatibilidade para PowerShell 2.0+
- **NextDNS**: Módulo completo com instalação, reparo e gerenciamento
  - `install.ps1`: Instalação com configuração de ID personalizado
  - `nextdns.ps1`: Menu interativo de gerenciamento
  - `reparar_nextdns.ps1`: Auto-reparo automatizado
  - `dns_padrão.ps1`: Restauração de DNS para DHCP
  - `remover_hpti.ps1`: Desinstalação completa
- **installps1.cmd**: Instalador/atualizador de PowerShell 7+
- **CI/CD Pipeline**: Verificação automática de encoding UTF-8 BOM e PSScriptAnalyzer
- **Versão Portable**: Menu e scripts adaptados para execução sem instalação

### Modificado
- **Unificação da estrutura**: Todos os scripts principais centralizados em `/scripts/`
- **menu.ps1**: Atualizado para v1.5 com compatibilidade Windows 10 antigo (1507+)
- **net.ps1**: Expandido com:
  - Testes de conectividade e diagnóstico de rede
  - Relatórios HTML detalhados
  - Backup automático de configurações de rede antes de reset
  - Salvamento em `C:\Program Files\HPTI\NetworkBackups`
- **update.ps1**: Melhorado com:
  - Reparo completo do Windows Update
  - Instalação automática de atualizações pendentes
  - Logs salvos em `C:\Program Files\HPTI\Logs`
- **backup.ps1**: 
  - Novo destino: `C:\Program Files\HPTI\Backups`
  - Backup de certificados e wallpaper
  - Geração de script de restauração automático
- **print.ps1**: Melhorias em compatibilidade com PowerShell antigo
- **Compatibilidade**: Todos os scripts agora suportam PowerShell 2.0+ com fallbacks
- **Encoding**: Todos os arquivos `.ps1` e `.psm1` convertidos para UTF-8 com BOM

### Removido
- **info.ps1**: Funcionalidade de inventário integrada ao `check.ps1`
- **perf.ps1**: Métricas de performance integradas ao `sfc.ps1`

### Corrigido
- Encoding UTF-8 BOM em todos os scripts para compatibilidade com Windows antigo
- Acentuação em menus e outputs em sistemas legados
- Erros de compatibilidade com PowerShell 2.0-5.1
- Problemas de TLS 1.2 em Windows 10 1507/1511
- NextDNS: Sistema de configuração de ID corrigido e persistente
- Erros "file not found" em `limp.ps1` ao limpar arquivos inexistentes

---

## [v1.0.0] - 2026-01-18

### Adicionado
- Script de Reset de Impressão (`print.ps1`)
- Script de Reset de Rede (`net.ps1`)
- Script de Backup (`backup.ps1`)
- Documentação completa no site `docs` com MkDocs
- Fluxo de Integração Contínua (CI) configurado
- Estrutura inicial do projeto
- Menu interativo (`menu.ps1`)
- README.md com instruções de uso