Claro 👍
Segue o **Markdown puro**, **sem bloco de código**, pronto para colar direto no `README.md` do GitHub.

---

[![Qualidade do Código](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml)
[![Documentação](https://img.shields.io/badge/docs-online-blue)](https://docs.hpinfo.com.br)
![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-blue?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-1.0.0-orange)

# 🧰 HP Scripts – Kit de Automação e Suporte Técnico Windows

Conjunto de scripts PowerShell voltados para **suporte técnico, manutenção, diagnóstico e padronização de sistemas Windows**.
Ideal para técnicos de informática, assistências técnicas e ambientes corporativos.

---

## 🚀 Acesso Rápido (One-liner)

### Menu principal

```powershell
irm get.hpinfo.com.br/menu | iex
```

### Acesso direto a módulos específicos

```powershell
irm get.hpinfo.com.br/info | iex
```

---

## 📋 Estrutura do Menu

0. **Menu.ps1** – Launcher principal
1. **[CHECK  ]** Verificações Rápidas e Integridade
2. **[INFO   ]** Coleta de Dados (Hardware / SO)
3. **[REDE   ]** Reparo de Rede e Conectividade
4. **[PRINT  ]** Módulo de Impressão
5. **[UPDATE ]** Atualizações do Sistema
6. **[BACKUP ]** Rotina de Backup de Usuário
7. **[HORA   ]** Sincronização de Horário
8. **[LIMP   ]** Limpeza de Arquivos Temporários
9. **[PERF   ]** Diagnóstico e Score de Performance
10. **[ATIV   ]** Ativação do Windows (get.activated.win)
11. **[WALL   ]** Configuração de Wallpaper Padrão
12. **[NEXTDNS]** Gerenciamento do NextDNS

---

## 🧠 Descrição dos Scripts

> 🔔 **Acesso direto:** todos os módulos podem ser executados individualmente via `Invoke-RestMethod (irm)`.

---

### **menu.ps1**

Launcher principal do pacote (**hub de automação**).

```powershell
irm get.hpinfo.com.br/menu | iex
```

* Menu interativo no PowerShell
* Centralização de todos os módulos
* Execução remota sempre atualizada

---

### **net.ps1**

```powershell
irm get.hpinfo.com.br/rede | iex
```

Reset e correção completa de rede.

* Reset de IP, DNS e Winsock
* Correção pós-update
* Reativação de serviços essenciais

---

### **print.ps1**

```powershell
irm get.hpinfo.com.br/print | iex
```

Correção completa do sistema de impressão.

* Limpeza de spooler
* Correção de filas travadas
* Ajustes de compatibilidade

---

### **update.ps1**

```powershell
irm get.hpinfo.com.br/update | iex
```

Gerenciamento avançado do Windows Update.

* Limpeza de cache
* Reset de serviços
* Geração de logs

---

### **wallpaper.ps1**

```powershell
irm get.hpinfo.com.br/wall | iex
```

Padronização visual do sistema sem logout.

---

### **info.ps1**

```powershell
irm get.hpinfo.com.br/info | iex
```

Relatório técnico completo em HTML com diagnóstico detalhado de hardware, sistema e erros.

---

### **limp.ps1**

```powershell
irm get.hpinfo.com.br/limp | iex
```

Limpeza profunda e otimização do Windows.

* Temporários e cache
* Windows Update
* Navegadores
* Lixeira
* Exibição de espaço recuperado

---

### **perf.ps1**

```powershell
irm get.hpinfo.com.br/perf | iex
```

Diagnóstico avançado e **Score de Performance do Windows**.

* Score automático (0–100)
* Cores por desempenho (verde / amarelo / vermelho)
* Gráfico visual
* Relatório HTML pronto para impressão
* Histórico por máquina
* Comparação **Antes vs Depois** (integrado ao `limp.ps1`)

**Fluxo recomendado:**

```
PERF (Antes) → LIMP → PERF (Depois)
```

---

### **check.ps1**

```powershell
irm get.hpinfo.com.br/check | iex
```

Verificação rápida de integridade do sistema.

---

### **hora.ps1**

```powershell
irm get.hpinfo.com.br/hora | iex
```

Correção e sincronização de data e hora.

---

### **backup.ps1**

```powershell
irm get.hpinfo.com.br/backup | iex
```

Backup automatizado de dados do usuário.

---

### **installps1.cmd**

Instalador / atualizador do PowerShell 7.

```cmd
certutil -urlcache -f https://get.hpinfo.com.br/installps1.cmd install.cmd && install.cmd
```

---

## ✅ Requisitos

* Windows 10 ou 11
* PowerShell como Administrador

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🔐 Security & Disclaimer

Scripts administrativos avançados.
Execute apenas em máquinas autorizadas e com backup prévio.
Uso por sua conta e risco.

---

## 📄 Licença

MIT License — uso comercial permitido, sem garantias.

---

## 🔗 Links Importantes

🌐 Site: [https://www.hpinfo.com.br](https://www.hpinfo.com.br)
🐙 Repositório: [https://github.com/sejalivre/hp-scripts](https://github.com/sejalivre/hp-scripts)
🛠️ Issues: [https://github.com/sejalivre/hp-scripts/issues](https://github.com/sejalivre/hp-scripts/issues)

---

📌 Projeto mantido por **HP Info – Tecnologia e Suporte Técnico**

---
