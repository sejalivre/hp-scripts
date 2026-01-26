[![Qualidade do Código](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml)
[![Documentação](https://img.shields.io/badge/docs-online-blue)](https://docs.hpinfo.com.br)
![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-blue?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-1.0.0-orange)

# 🧰 HP Scripts – Kit de Automação e Suporte Técnico Windows

Conjunto de scripts PowerShell voltados para **suporte técnico, manutenção, diagnóstico e padronização de sistemas Windows**. Ideal para técnicos de informática, assistências técnicas e ambientes corporativos.

---

## 🚀 Acesso Rápido (One‑liner)

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
9. **[ATIV   ]** Ativação do Windows (get.activated.win)
10. **[WALL   ]** Configuração de Wallpaper Padrão
11. **[NEXTDNS]** Gerenciamento do NextDNS

---

## 🧠 Descrição dos Scripts

> 🔔 **Acesso direto:** todos os módulos podem ser executados individualmente via `Invoke-RestMethod (irm)` conforme indicado em cada seção abaixo.

### **menu.ps1**
Launcher principal do pacote (**hub de automação**).

**Execução direta:**
```powershell
irm get.hpinfo.com.br | iex
```

- Exibe um **menu interativo** no PowerShell
- Centraliza e organiza todos os módulos
- Baixa e executa scripts diretamente do servidor remoto `get.hpinfo.com.br`
- Funciona como **ponto único de entrada** para o técnico

---

### **net.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/rede | iex
```

Script de **reset e correção completa de rede**.
Script de **reset e correção completa de rede**.

- Solicita **elevação para administrador** automaticamente
- Habilita serviços essenciais (DHCP, DNS, Workstation, Server etc.)
- Executa reset de IP, Winsock e DNS
- Corrige problemas de conectividade e falhas pós‑update

---

### **print.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/print | iex
```

Correção completa do **sistema de impressão**.
Correção completa do **sistema de impressão**.

- Reinicia o serviço **Spooler**
- Limpa a fila de impressão (`PRINTERS`)
- Ajustes de registro para compatibilidade
- Resolve impressora travada e erros de spooler

---

### **update.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/update | iex
```

Gerenciador avançado do **Windows Update**.
Gerenciador avançado do **Windows Update**.

- Gera **logs detalhados** em `C:\Windows\Logs`
- Para serviços (WUAUSERV, BITS, CryptSvc)
- Limpa `SoftwareDistribution` e `catroot2`
- Reinicia serviços e força estado limpo

👉 Ideal para Windows Update travado ou com erros recorrentes.

---

### **wallpaper.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/wall | iex
```

Padronização visual do sistema.
Padronização visual do sistema.

- Baixa wallpaper corporativo via GitHub
- Aplica **sem logout**
- Usa API nativa do Windows (`SystemParametersInfo`)

👉 Muito usado em pós‑formatação e padronização visual.

---

### **info.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/info | iex
```

Gera um **relatório técnico completo em HTML**.
Gera um **relatório técnico completo em HTML**.

Inclui:
- Sistema, build, fabricante, modelo
- CPU, RAM, GPU e discos
- Rede (IP, gateway, MAC)
- Temperaturas (Core Temp)
- Saúde de HD/SSD (CrystalDiskInfo)
- Windows Update e drivers
- Processos, serviços, inicialização
- Erros recentes e histórico de BSOD
- BIOS, bateria (notebooks)
- Diagnóstico rápido com alertas

👉 O relatório é salvo e aberto automaticamente no navegador.

---

### **limp.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/limp | iex
```

Limpeza profunda e **otimização do Windows**.
Limpeza profunda e **otimização do Windows**.

- Remove arquivos temporários, logs e cache
- Limpa cache do Windows Update
- Limpa cache de navegadores (Chrome, Edge, Firefox)
- Esvazia a lixeira
- Mostra o espaço recuperado
- Reinicia o Explorer

👉 Ideal para manutenção preventiva ou máquinas lentas.

---

### **check.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/check | iex
```

Verificação rápida do sistema.
Verificação rápida do sistema.

- Checagem de serviços essenciais
- Diagnóstico inicial de problemas simples

👉 Primeiro passo antes de manutenção mais profunda.

---

### **hora.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/hora | iex
```

Correção e sincronização de **data e hora**.
Correção e sincronização de **data e hora**.

- Sincroniza com servidores de horário
- Corrige problemas de certificados, domínio e internet

---

### **backup.ps1**

**Execução direta:**
```powershell
irm get.hpinfo.com.br/backup | iex
```

Backup automatizado do usuário.
Backup automatizado do usuário.

- Cria estrutura de backup
- Copia arquivos importantes
- Previne perda de dados

👉 Recomendado **antes** de qualquer manutenção.

---

### **installps1.cmd**
Instalador / atualizador do **PowerShell 7 (Core)**.

**Execução direta (CMD):**
```cmd
certutil -urlcache -f https://get.hpinfo.com.br/installps1.cmd install.cmd && install.cmd
```

**Fluxo do script:**
- Verifica se o Winget está disponível
- Se não estiver, instala via método alternativo (MSI)
- Se estiver:
  - Atualiza o PowerShell 7 se já instalado
  - Instala silenciosamente se não estiver
- Tratamento completo de erros e mensagens de status

---

## ✅ Requisitos

- Windows 10 ou Windows 11
- PowerShell executado como **Administrador**
- Política de execução liberada:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🔐 Security & Disclaimer

Este repositório contém **scripts administrativos avançados**, capazes de alterar configurações do sistema operacional Windows.

- Execute **somente em máquinas autorizadas** pelo cliente ou pela empresa.
- Alguns scripts exigem **privilégios elevados (Administrador)**.
- Recomenda-se **backup prévio** antes da execução em ambientes produtivos.
- O autor **não se responsabiliza** por danos causados por uso indevido, execução parcial ou alterações manuais posteriores.

Ao utilizar este projeto, você concorda que o uso é **por sua conta e risco**.

---

## 📄 Licença

Este projeto está licenciado sob a **MIT License**.

✔️ Uso comercial permitido  
✔️ Modificação permitida  
✔️ Distribuição permitida  
❌ Nenhuma garantia fornecida

Consulte o arquivo `LICENSE` para mais detalhes.

---

## 🔗 Links Importantes

🌐 **Site:** https://www.hpinfo.com.br  
🐙 **Repositório:** https://github.com/sejalivre/hp-scripts  
🛠️ **Issues:** https://github.com/sejalivre/hp-scripts/issues

---

## ⚠️ Aviso

Alguns scripts **exigem privilégios de administrador**. Utilize com responsabilidade e sempre informe o cliente antes da execução.

---

📌 Projeto mantido por **HP Info – Tecnologia e Suporte Técnico**

