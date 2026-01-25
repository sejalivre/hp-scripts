[![Qualidade do Código](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml)
[![Documentação](https://img.shields.io/badge/docs-online-blue)](https://docs.hpinfo.com.br)

# HP-Scripts (Automação e Gerenciamento)

Coleção de scripts PowerShell voltados para inventário de hardware, manutenção de rede, backups e solução de problemas.

**Documentação Completa:** [docs.hpinfo.com.br](https://docs.hpinfo.com.br)

---

Aqui está uma versão bem formatada em Markdown + HTML que fica bonita no README do GitHub (mantendo compatibilidade total com o render do GitHub):

```markdown
# HP-Scripts - Kit de Automação e Manutenção para Windows

Coleção de scripts PowerShell para automação de TI, manutenção, diagnóstico e configuração de sistemas Windows.

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-7+-blue?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell 7+"/>
  <img src="https://img.shields.io/badge/Windows-7/8/10/11-success?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 7+"/>
  <img src="https://img.shields.io/github/license/sejalivre/hp-scripts?style=for-the-badge" alt="MIT License"/>
</p>

## 🚀 Instalação Rápida (execução direta – sem baixar nada)

```powershell
# Diagnóstico completo do sistema
irm get.hpinfo.com.br/info | iex

# Menu completo de ferramentas
irm get.hpinfo.com.br/menu | iex

# Reparos rápidos
irm get.hpinfo.com.br/net   | iex    # Rede
irm get.hpinfo.com.br/print | iex    # Impressão
irm get.hpinfo.com.br/update| iex    # Atualizações
irm get.hpinfo.com.br/limp  | iex    # Limpeza
```

### Instalar PowerShell 7 (recomendado)

```cmd
irm get.hpinfo.com.br/installps1.cmd | cmd
```

ou

```cmd
certutil -urlcache -f https://get.hpinfo.com.br/installps1.cmd install.cmd && install.cmd
```

## ⚠️ Liberar execução de scripts (quando necessário)

```powershell
# Opção mais segura (recomendada)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ou (apenas para esta sessão)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

## 📋 Menu Principal – O que você encontra dentro

| #  | Opção                        | Descrição Principal                                                                 |
|----|------------------------------|--------------------------------------------------------------------------------------|
| 1  | 📊 INFO                      | Relatório HTML completo (hardware, software, saúde de disco, CPU, RAM, BSODs...)    |
| 2  | 🌐 REDE                      | Reset completo de rede, DNS, serviços, IP, winsock, proxy...                        |
| 3  | 🖨️ PRINT                     | Reparo de spooler, limpeza de filas, ajustes de compatibilidade                     |
| 4  | 🔄 UPDATE                    | Limpeza + instalação + atualização automática do Windows Update                   |
| 5  | 💾 BACKUP                    | Backup de Wi-Fi, impressoras, programas, certificados, papel de parede...           |
| 6  | ⏰ HORA                      | Configura NTP BR + tarefa agendada para manter horário correto                      |
| 7  | 🧹 LIMPEZA                   | Limpeza agressiva (temp, cache, update, lixeira, otimização de disco)               |
| 8  | 🔑 ATIVADOR                  | Link para ativação (get.activated.win)                                              |
| 9  | 🎨 WALLPAPER                 | Aplica wallpaper corporativo padrão automaticamente                                 |
| 10 | 🛡️ NEXTDNS                   | Instalação, reparo, remoção e gerenciamento completo do NextDNS                     |

## Scripts que você pode chamar diretamente

```powershell
irm get.hpinfo.com.br/wallpaper | iex
irm get.hpinfo.com.br/hora      | iex
irm get.hpinfo.com.br/backup    | iex
# etc.
```

## Ferramentas e utilitários integrados

- CoreTemp  
- CrystalDiskInfo  
- 7-Zip (extração)  
- Módulo PSWindowsUpdate  
- Ferramentas de diagnóstico de rede  
- NextDNS CLI + certificado

## Requisitos mínimos

- Windows 7 / 8 / 10 / 11  
- PowerShell 5.1 (7+ recomendado)  
- Direitos de administrador  
- Internet (para baixar ferramentas e atualizações)

## Características principais

- Execução direta via URL (sem clonar repositório)  
- Relatórios visuais em HTML com gráficos  
- Manutenção automática via tarefas agendadas  
- Logging detalhado de todas as ações  
- Compatível com ambientes corporativos e domésticos

## Estrutura resumida

```
hp-scripts/
├── main-scripts/       ← menu.ps1, info.ps1, net.ps1, limp.ps1...
├── tools/              ← nextdns, 7z.exe, helpers...
└── docs/
```

## 🤝 Como contribuir

1. Faça fork  
2. Crie sua branch (`git checkout -b feature/nova-funcionalidade`)  
3. Commit (`git commit -m 'Adiciona suporte a ...'`)  
4. Push (`git push origin feature/nova-funcionalidade`)  
5. Abra Pull Request

## 📞 Suporte e contato

🌐 **Site**: [www.hpinfo.com.br](https://www.hpinfo.com.br)  
🐙 **Repositório**: [github.com/sejalivre/hp-scripts](https://github.com/sejalivre/hp-scripts)  
🛠️ **Issues**: [Abrir issue](https://github.com/sejalivre/hp-scripts/issues)

## ⚖️ Licença

[MIT License](LICENSE)

---

**Aviso importante**: Use os scripts por sua conta e risco. Faça backup antes de executar limpezas ou reparos importantes.
```

Essa versão:

- Tem badges bonitinhos no topo  
- Tabela clara com as opções do menu  
- Blocos de código bem destacados  
- Ícones emoji para melhorar a leitura  
- Estrutura limpa e hierárquica  
- Mantém todas as informações importantes do original

Se quiser deixar ainda mais visual (com imagens ou GIF demonstrativo), posso sugerir onde colocar e como nomear os arquivos.

Espero que goste! 🚀

```powershell
irm get.hpinfo.com.br/menu | iex
```

*Isso baixará e executará o orquestrador que gerencia todas as ferramentas abaixo.*

---

## 📂 Catálogo de Scripts

| Script | Função | Descrição |
| :--- | :--- | :--- |
| **`menu.ps1`** | **Launcher** | Menu interativo para baixar e rodar as ferramentas sob demanda. |
| **`info.ps1`** | **Inventário** | Gera relatório HTML com dados de CPU, RAM, S.M.A.R.T, Drivers e CoreTemp. |
| **`backup.ps1`** | **Backup** | Salva Wi-Fi, Impressoras, Atalhos e Documentos antes da formatação. |
| **`net.ps1`** | **Rede** | Reseta pilha TCP/IP, limpa cache DNS e renova configurações. |
| **`print.ps1`** | **Impressão** | Reinicia Spooler, limpa fila travada e ajusta registros RPC. |
| **`update.ps1`** | **Updates** | Repara o Windows Update e instala patches pendentes. |

---

## 🛠️ Execução Manual (Download)

Se você clonou o repositório (`git clone`), use os comandos abaixo:

### 1. Backup e Migração
Este script exige que você defina uma pasta de destino para salvar os dados.

```powershell
.\backup.ps1 -Destino "C:\Backups"
```

### 2. Inventário
```powershell
.\info.ps1
```

### 3. Updates do Windows
```powershell
.\update.ps1
```

---

## ⚠️ Requisitos
* Windows 10 ou 11.
* PowerShell executando como **Administrador**.
* Política de execução liberada:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

Uma iniciativa [HP Info](https://hpinfo.com.br).
