# 🚀 Acesso Rápido - Guia de Início

Este guia apresenta os comandos essenciais para começar a usar o HP Scripts imediatamente.

---

## Menu Principal

A forma mais rápida de acessar todas as ferramentas:

```powershell
irm https://get.hpinfo.com.br/menu | iex
```

Este comando abre um menu interativo com todas as opções disponíveis.

---

## Scripts Mais Usados

### Diagnóstico Completo

```powershell
irm get.hpinfo.com.br/check | iex
```

Executa 24 verificações do sistema e gera relatório HTML profissional.

### Limpeza do Sistema

```powershell
irm get.hpinfo.com.br/limp | iex
```

Remove arquivos temporários, cache e otimiza o sistema.

### Reparo de Rede

```powershell
irm get.hpinfo.com.br/net | iex
```

Reset completo de TCP/IP, DNS e adaptadores de rede.

### Reparo de Impressão

```powershell
irm get.hpinfo.com.br/print | iex
```

Reinicia spooler e corrige problemas de impressão.

### Sincronização de Horário

```powershell
irm get.hpinfo.com.br/hora | iex
```

Sincroniza horário com servidores NTP brasileiros.

---

## Fluxo de Manutenção Completa

Execute os comandos na ordem para manutenção profissional:

```powershell
# 1. Diagnóstico inicial
irm get.hpinfo.com.br/check | iex

# 2. Limpeza profunda
irm get.hpinfo.com.br/limp | iex

# 3. Atualizar Windows
irm get.hpinfo.com.br/update | iex

# 4. Diagnóstico final (comparar resultados)
irm get.hpinfo.com.br/check | iex
```

---

## Backup e Restore

### Antes da Formatação

```powershell
# Fazer backup de Wi-Fi, drivers e configurações
irm get.hpinfo.com.br/backup | iex

# Copiar pasta C:\Intel para pendrive
```

### Depois da Formatação

```powershell
# 1. Instalar PowerShell 7
irm get.hpinfo.com.br/installps1.cmd | cmd

# 2. Configurar horário
irm get.hpinfo.com.br/hora | iex

# 3. Aplicar wallpaper corporativo
irm get.hpinfo.com.br/wallpaper | iex

# 4. Restaurar backup
C:\Intel\restore.ps1
```

---

## Ferramentas Especializadas

### NextDNS (Bloqueio de Conteúdo)

```powershell
# Instalar NextDNS
irm get.hpinfo.com.br/tools/nextdns/install | iex

# Reparar NextDNS
irm get.hpinfo.com.br/tools/nextdns/reparar | iex

# Desinstalar NextDNS
irm get.hpinfo.com.br/tools/nextdns/desinstalar | iex
```

---

## Dicas Importantes

### Execução com Privilégios

Alguns scripts requerem privilégios de administrador. Se necessário, o script solicitará automaticamente.

### Execução Offline (Portable)

Para usar sem internet, copie o projeto inteiro para um pendrive e use a pasta **portable**:

```powershell
# No pendrive
cd E:\hp-scripts\portable
.\menu.ps1

# Ou clique em INICIAR.cmd
```

A versão portable referencia automaticamente os scripts em `../scripts/` e `../tools/`.

### Verificar Código-Fonte

Todos os scripts são de código aberto. Você pode visualizar antes de executar:

```
https://github.com/sejalivre/hp-scripts
```

---

## Próximos Passos

- 📖 Leia a [documentação completa](index.md)
- 🔧 Veja detalhes de cada [script](index.md#-catálogo-de-scripts)
- 🛡️ Confira a [política de segurança](seguranca.md)
- ⚙️ Verifique os [requisitos de sistema](requisitos.md)

---

**[← Voltar para Documentação Principal](index.md)**
