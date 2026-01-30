# Script de Reparo Automático - repair.ps1

## 📋 Visão Geral

O script `repair.ps1` é uma ferramenta completa de reparo automático para Windows, desenvolvida para técnicos de informática. Ele oferece funcionalidades de diagnóstico e correção em várias categorias, permitindo reparos rápidos e eficientes.

## 🎯 Objetivo

Fornecer uma solução integrada para:
- Diagnóstico automatizado de problemas comuns
- Reparo em categorias específicas (rede, segurança, serviços, etc.)
- Otimização de desempenho do sistema
- Geração de logs detalhados para análise técnica

## 🚀 Funcionalidades Principais

### 1. Menu de Reparo Categorizado
- **Reparo de Rede**: Reset DNS, Winsock, TCP/IP, configuração de adaptadores
- **Limpeza do Sistema**: Arquivos temporários, cache, logs, Prefetch
- **Segurança**: Windows Defender, Firewall, verificação de ativadores ilegais
- **Serviços do Windows**: Verificação e correção de serviços críticos
- **Disco e Sistema de Arquivos**: SFC, DISM, CHKDSK, otimização de discos
- **Windows Update**: Reparo completo do serviço de atualização
- **Otimização de Desempenho**: Ajustes de energia, serviços, prioridades
- **Reparo Completo**: Executa todas as categorias em sequência

### 2. Sistema de Logs
- Logs detalhados em `C:\ProgramData\HP-Scripts\Logs\`
- Timestamp em cada operação
- Status de sucesso/falha para cada ação
- Acesso via menu do script

### 3. Interface Amigável
- Menu colorido com emojis
- Status visual com ícones (✅ ⚠️ ❌)
- Feedback em tempo real
- Opções de diagnóstico integrado

## 📖 Como Usar

### Execução Básica
```powershell
# Executar como Administrador
.\scripts\repair.ps1
```

### Opções do Menu
```
[1] 🔍 Executar Diagnóstico Completo + Sugestões de Reparo
[2] 🌐 Reparo de Rede e Conectividade
[3] 🧹 Limpeza e Otimização do Sistema
[4] 🛡️  Reparo de Segurança e Windows Defender
[5] ⚙️  Reparo de Serviços do Windows
[6] 💾 Reparo de Disco e Sistema de Arquivos
[7] 🔄 Reparo de Windows Update
[8] 🚀 Otimização de Desempenho
[9] 📋 Reparo Completo (Todas as Categorias)

[D] 📊 Verificar Diagnóstico Atual do Sistema
[L] 📝 Ver Log de Reparos Executados
[Q] Sair
```

### Integração com HP-Scripts
O script está integrado ao menu principal do HP-Scripts como opção **REPAIR** (posição 2).

## 🔧 Requisitos Técnicos

- **PowerShell**: 5.1+ (Windows 10/11)
- **Privilégios**: Execução como Administrador
- **Sistema**: Windows 10 ou Windows 11
- **Espaço**: ~10MB para logs e arquivos temporários

## ⚠️ Considerações de Segurança

1. **Execução como Admin**: Necessário para operações de sistema
2. **Backup automático**: Algumas operações criam backups antes de modificar
3. **Logs detalhados**: Todas as ações são registradas para auditoria
4. **Confirmação**: Operações críticas podem requerer confirmação

## 📊 Fluxo de Trabalho Recomendado

1. **Diagnóstico**: Execute `check.ps1` primeiro para identificar problemas
2. **Reparo Específico**: Use as categorias individuais conforme necessário
3. **Reparo Completo**: Para manutenção geral, use a opção 9
4. **Verificação**: Confirme os resultados nos logs e no sistema

## 🐛 Solução de Problemas

### Problemas Comuns

1. **Erro de Permissão**: Execute como Administrador
2. **Serviços não iniciam**: Verifique políticas de grupo
3. **Windows Update falha**: Execute a opção específica de reparo
4. **Logs não gerados**: Verifique permissões em `C:\ProgramData\`

### Logs de Diagnóstico
- Verifique `C:\ProgramData\HP-Scripts\Logs\repair_*.log`
- Use a opção [L] no menu para visualizar logs

## 🔄 Integração com Outros Scripts

### Com check.ps1
- Diagnóstico → Reparo: Use `check.ps1` primeiro, depois `repair.ps1`
- Sugestões automáticas: Em desenvolvimento

### Com outros módulos
- **sfc.ps1**: Complementar para reparo de sistema
- **net.ps1**: Foco específico em rede
- **limp.ps1**: Limpeza básica (repair.ps1 tem versão avançada)

## 📈 Melhorias Futuras

1. **Diagnóstico Integrado**: Sugestões automáticas baseadas em check.ps1
2. **Modo Silencioso**: Para automação em scripts maiores
3. **Relatórios PDF**: Exportação de relatórios completos
4. **Integração Cloud**: Upload de logs para análise remota
5. **Perfis de Reparo**: Configurações pré-definidas para diferentes cenários

## 👥 Contribuição

Para contribuir com o desenvolvimento:
1. Reporte bugs via GitHub Issues
2. Sugira melhorias no repositório
3. Envie pull requests com correções ou novas funcionalidades

## 📞 Suporte

- **Documentação**: docs.hpinfo.com.br
- **GitHub**: github.com/sejalivre/hp-scripts
- **Comunidade**: Grupo de técnicos HPinfo

---

**Versão**: 1.0  
**Última Atualização**: Janeiro 2026  
**Autor**: HP-Scripts Team  
**Compatibilidade**: Windows 10/11, PowerShell 5.1+