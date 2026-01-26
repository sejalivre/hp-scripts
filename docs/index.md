# HP Scripts – Documentação Técnica

## Visão Geral

O **HP Scripts** é um conjunto modular de scripts PowerShell projetado para **automação de suporte técnico**, **manutenção preventiva**, **diagnóstico avançado** e **padronização de ambientes Windows**.

O projeto segue o modelo *remote execution*, onde os scripts são versionados em repositório GitHub e distribuídos via endpoint HTTP seguro, permitindo **execução sempre atualizada**, sem necessidade de download manual.

---

## Arquitetura do Projeto

### Modelo de Execução

```text
Técnico
  │
  ├── PowerShell (Admin)
  │     └── irm get.hpinfo.com.br | iex
  │
  └── Servidor HTTP (get.hpinfo.com.br)
        ├── menu.ps1
        ├── check.ps1
        ├── info.ps1
        ├── rede.ps1
        ├── print.ps1
        ├── update.ps1
        ├── limp.ps1
        ├── backup.ps1
        ├── hora.ps1
        └── wallpaper.ps1
```

### Princípios de Design

- **Single Entry Point**: `menu.ps1`
- **Execução sob demanda** via `Invoke-RestMethod`
- **Baixo acoplamento** entre módulos
- **Atualização centralizada**
- **Sem dependência de instalação local**

---

## Requisitos Técnicos

- Windows 10 ou Windows 11
- PowerShell 5.1 ou superior (recomendado PowerShell 7+)
- Execução como **Administrador**
- Política de execução liberada:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Ponto Único de Entrada (Launcher)

### menu.ps1

Responsável por:
- Apresentar interface interativa
- Carregar e executar módulos remotamente
- Controlar fluxo de execução
- Garantir padronização operacional

Execução:
```powershell
irm get.hpinfo.com.br | iex
```

---

## Execução Direta de Módulos

Cada módulo pode ser executado de forma **independente**, útil para automações, scripts externos ou execução rápida.

| Módulo | Endpoint | Finalidade |
|------|--------|-----------|
| CHECK | `/check` | Diagnóstico rápido |
| INFO | `/info` | Coleta técnica completa |
| REDE | `/rede` | Reset e correção de rede |
| PRINT | `/print` | Correção de impressão |
| UPDATE | `/update` | Reset do Windows Update |
| LIMP | `/limp` | Limpeza e otimização |
| BACKUP | `/backup` | Backup preventivo |
| HORA | `/hora` | Sincronização de horário |
| WALL | `/wall` | Padronização visual |

Exemplo:
```powershell
irm get.hpinfo.com.br/print | iex
```

---

## installps1.cmd – PowerShell Core

Script auxiliar para **instalação e atualização do PowerShell 7**.

### Execução
```cmd
certutil -urlcache -f https://get.hpinfo.com.br/installps1.cmd install.cmd && install.cmd
```

### Lógica Interna

1. Detecta presença do Winget
2. Caso ausente, utiliza instalador alternativo (MSI)
3. Caso presente:
   - Atualiza PowerShell 7 existente
   - Ou instala silenciosamente
4. Retorno com códigos de erro e mensagens padronizadas

---

## Segurança

- Scripts exigem **privilégios administrativos**
- Nenhuma informação é enviada externamente sem ação explícita
- Relatórios são gerados localmente
- Recomenda-se uso apenas em máquinas autorizadas

---

## Logs e Diagnóstico

Alguns módulos geram logs locais para auditoria e troubleshooting:

- Windows Update: `C:\Windows\Logs`
- Relatórios INFO: pasta temporária do usuário
- Operações críticas exibem status em tempo real

---

## Versionamento

- Versionamento semântico (SemVer)
- Alterações críticas refletem no menu principal
- CI valida integridade antes de publicação

---

## Público-Alvo

- Técnicos de informática
- MSPs (Managed Service Providers)
- Assistências técnicas
- Administradores de sistemas Windows

---

## Links Oficiais

- 🌐 Site: https://www.hpinfo.com.br
- 🐙 Repositório: https://github.com/sejalivre/hp-scripts
- 📘 Documentação: https://docs.hpinfo.com.br
- 🛠️ Issues: https://github.com/sejalivre/hp-scripts/issues

---

**HP Scripts** é projetado para ser **simples de executar**, **difícil de quebrar** e **fácil de manter**.

