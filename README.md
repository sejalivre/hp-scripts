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
irm get.hpinfo.com.br/sfc   | iex    # Diagnóstico e Reparação Completa
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
| 1  | 📊 CHECK                     | Verificações rápidas de integridade do sistema                                      |
| 2  | 🔧 SFC                       | Diagnóstico e reparação completa do Windows (DISM, SFC, memória, processos)         |
| 3  | 🔧 INSTALLPS1                | Instalar ou atualizar PowerShell 7+ (verifica versão automaticamente)              |
| 4  | 🧹 LIMPEZA                   | Limpeza agressiva (temp, cache, update, lixeira, otimização de disco)               |
| 5  | 🔄 UPDATE                    | Limpeza + instalação + atualização automática do Windows Update                   |
| 6  | ⏰ HORA                      | Configura NTP BR + tarefa agendada para manter horário correto                      |
| 7  | 🌐 REDE                      | Reset completo de rede, DNS, serviços, IP, winsock, proxy...                        |
| 8  | 🖨️ PRINT                     | Reparo de spooler, limpeza de filas, ajustes de compatibilidade                     |
| 9  | 💾 BACKUP                    | Backup de Wi-Fi, impressoras, programas, certificados, papel de parede...           |
| 10 | 🔑 ATIVADOR                  | Link para ativação (get.activated.win)                                              |
| 11 | 🎨 WALLPAPER                 | Aplica wallpaper corporativo padrão automaticamente                                 |
| 12 | 🛡️ NEXTDNS                   | Instalação, reparo, remoção e gerenciamento completo do NextDNS                     |

## Scripts que você pode chamar diretamente

```powershell
irm get.hpinfo.com.br/wallpaper | iex
irm get.hpinfo.com.br/hora      | iex
irm get.hpinfo.com.br/backup    | iex
# etc.
```

---

## 🛡️ NextDNS - Bloqueio e Filtragem de Conteúdo

O módulo NextDNS fornece instalação e gerenciamento completo do NextDNS com configuração personalizada por técnico/cliente.

### Instalação Rápida

```powershell
# Menu completo de gerenciamento
irm get.hpinfo.com.br/tools/nextdns/nextdns | iex

# Ou instalação direta
irm get.hpinfo.com.br/tools/nextdns/install | iex
```

### Características Principais

✅ **Configuração por ID**: Cada instalação usa um ID NextDNS específico  
✅ **Auto-Recuperação**: Tarefa agendada verifica e repara automaticamente a cada hora  
✅ **Persistência**: ID salvo em arquivo de configuração para reinstalações  
✅ **Bloqueio HTTPS**: Certificado instalado para bloquear sites em HTTPS  
✅ **Modo Stealth**: Oculto do Painel de Controle para evitar remoção acidental  
✅ **DDNS Integrado**: Vincula IP automaticamente ao painel NextDNS  

### Scripts Disponíveis

| Script | Função | Uso |
|--------|--------|-----|
| **install.ps1** | Instalação completa com configuração de ID | `irm get.hpinfo.com.br/tools/nextdns/install \| iex` |
| **reparar_nextdns.ps1** | Auto-reparo (roda automaticamente) | `irm get.hpinfo.com.br/tools/nextdns/reparar_nextdns \| iex` |
| **nextdns.ps1** | Menu interativo de gerenciamento | `irm get.hpinfo.com.br/tools/nextdns/nextdns \| iex` |
| **dns_padrão.ps1** | Restaurar DNS para DHCP | `irm get.hpinfo.com.br/tools/nextdns/dns_padrão \| iex` |
| **remover_hpti.ps1** | Desinstalação completa | `irm get.hpinfo.com.br/tools/nextdns/remover_hpti \| iex` |

### Como Obter seu ID NextDNS

1. Acesse [my.nextdns.io](https://my.nextdns.io)
2. Faça login na sua conta
3. O ID aparece na URL: `https://my.nextdns.io/abc123/setup`
4. Seu ID é `abc123` (sempre 6 caracteres alfanuméricos)

### Verificar se está Funcionando

```powershell
# Verificar serviço
Get-Service -Name "NextDNS"

# Testar bloqueio (se você bloqueou facebook.com)
nslookup facebook.com
```

### Solução de Problemas

**NextDNS não está bloqueando?**

```powershell
# 1. Verifique o ID configurado
Get-Content "C:\Program Files\HPTI\config.txt"

# 2. Execute o reparo
irm get.hpinfo.com.br/tools/nextdns/reparar_nextdns | iex

# 3. Se necessário, reinstale
irm get.hpinfo.com.br/tools/nextdns/install | iex
```

📖 **Documentação Completa**: [tools/nextdns/README.md](tools/nextdns/README.md)

---

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

🔧 PERF.ps1 — Diagnóstico e Score de Performance do Windows

O PERF.ps1 é um script PowerShell projetado para avaliar, registrar e comparar a performance real do Windows, antes e depois de processos de otimização e limpeza (como o limp.ps1).

Ele coleta métricas essenciais do sistema, calcula um Score de Performance (0–100) e gera um relatório HTML visual, ideal para diagnóstico técnico, comprovação de serviço e histórico por máquina.

▶️ Como usar (execução rápida)

O PERF.ps1 pode ser executado diretamente da internet, sem necessidade de download manual, utilizando o PowerShell como Administrador:

irm https://get.hpinfo.com.br/perf | iex


Esse método permite:

Execução imediata em qualquer máquina

Sempre utilizar a versão mais atual do script

Integração automática com outros módulos do projeto (como o limp.ps1)

💡 Uso em conjunto com limpeza

Quando executado antes e depois do limp.ps1, o PERF identifica automaticamente o cenário e gera a comparação Antes vs Depois, destacando os ganhos reais de performance no relatório HTML.




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
