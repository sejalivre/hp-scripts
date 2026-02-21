[![Qualidade do Código](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml)
[![Documentação](https://img.shields.io/badge/docs-online-blue)](https://docs.hpinfo.com.br)

# HP-Scripts – Kit de Automação e Manutenção para Windows

Coleção de scripts PowerShell para automação de TI, manutenção, diagnóstico e configuração de sistemas Windows.

**Documentação Completa:** [docs.hpinfo.com.br](https://docs.hpinfo.com.br)

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell 5.1+"/>
  <img src="https://img.shields.io/badge/Windows-10%2F11-success?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10+"/>
  <img src="https://img.shields.io/github/license/sejalivre/hp-scripts?style=for-the-badge" alt="MIT License"/>
</p>

---

## 🚀 Instalação Rápida (execução direta – sem baixar nada)

```powershell
# Menu completo de ferramentas
irm get.hpinfo.com.br/menu | iex

# Ou execute scripts individuais diretamente
irm get.hpinfo.com.br/scripts/check    | iex    # Diagnóstico rápido
irm get.hpinfo.com.br/scripts/sfc      | iex    # Diagnóstico e Reparação Completa
irm get.hpinfo.com.br/scripts/winforge | iex    # Instalação de Apps + Otimizações
irm get.hpinfo.com.br/scripts/net      | iex    # Rede
irm get.hpinfo.com.br/scripts/print    | iex    # Impressão
irm get.hpinfo.com.br/scripts/update   | iex    # Atualizações
irm get.hpinfo.com.br/scripts/limp     | iex    # Limpeza
irm get.hpinfo.com.br/scripts/backup   | iex    # Backup
irm get.hpinfo.com.br/scripts/hora     | iex    # Sincronização de horário
irm get.hpinfo.com.br/scripts/wallpaper| iex    # Wallpaper corporativo
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

### Opção 1: Pelo Menu HP-Scripts (Recomendado)
Execute o menu principal e selecione a opção **🔓 POLICY** (15):
```powershell
irm get.hpinfo.com.br/menu | iex
```

### Opção 2: Manualmente
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
| 4  | ⚙️ WINFORGE                  | Instalação de apps (Chrome, 7-Zip, Reader) + otimizações do sistema                |
| 5  | 🧹 LIMPEZA                   | Limpeza agressiva (temp, cache, update, lixeira, otimização de disco)               |
| 6  | 🔄 UPDATE                    | Limpeza + instalação + atualização automática do Windows Update                   |
| 7  | ⏰ HORA                      | Configura NTP BR + tarefa agendada para manter horário correto                      |
| 8  | 🌐 REDE                      | Reset completo de rede, DNS, serviços, IP, winsock, proxy...                        |
| 9  | 🖨️ PRINT                     | Reparo de spooler, limpeza de filas, ajustes de compatibilidade                     |
| 10 | 💾 BACKUP                    | Backup de Wi-Fi, impressoras, programas, certificados, papel de parede...           |
| 11 | 🔑 ATIVADOR                  | Link para ativação (get.activated.win)                                              |
| 12 | 🎨 WALLPAPER                 | Aplica wallpaper corporativo padrão automaticamente                                 |
| 13 | 🛡️ NEXTDNS                   | Instalação, reparo, remoção e gerenciamento completo do NextDNS                     |
| 14 | 🛠️ TOOLS                     | Menu de ferramentas portáteis (CoreTemp, CrystalDiskInfo, etc.)                     |
| 15 | 🔓 POLICY                    | Libera política de execução do PowerShell (Unrestricted)                            |

## Scripts que você pode chamar diretamente

```powershell
irm get.hpinfo.com.br/scripts/check    | iex
irm get.hpinfo.com.br/scripts/backup   | iex
irm get.hpinfo.com.br/scripts/sfc      | iex
irm get.hpinfo.com.br/scripts/repair   | iex
irm get.hpinfo.com.br/scripts/limp     | iex
irm get.hpinfo.com.br/scripts/update   | iex
irm get.hpinfo.com.br/scripts/hora     | iex
irm get.hpinfo.com.br/scripts/net      | iex
irm get.hpinfo.com.br/scripts/print    | iex
irm get.hpinfo.com.br/scripts/wallpaper| iex
irm get.hpinfo.com.br/scripts/winforge | iex
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
| **install.ps1** | Instalação completa com configuração de ID | `irm get.hpinfo.com.br/tools/nextdns/install | iex` |
| **reparar_nextdns.ps1** | Auto-reparo (roda automaticamente) | `irm get.hpinfo.com.br/tools/nextdns/reparar_nextdns | iex` |
| **nextdns.ps1** | Menu interativo de gerenciamento | `irm get.hpinfo.com.br/tools/nextdns/nextdns | iex` |
| **dns_padrão.ps1** | Restaurar DNS para DHCP | `irm get.hpinfo.com.br/tools/nextdns/dns_padrão | iex` |
| **remover_hpti.ps1** | Desinstalação completa | `irm get.hpinfo.com.br/tools/nextdns/remover_hpti | iex` |

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

- **Windows 10 / 11**  
- **PowerShell 5.1+** (padrão no Windows 10/11)  
- Direitos de administrador  
- Internet (para baixar ferramentas e atualizações)

## Características principais

- Execução direta via URL (sem clonar repositório)  
- Relatórios visuais em HTML com gráficos  
- Manutenção automática via tarefas agendadas  
- Logging detalhado de todas as ações  
- Compatível com ambientes corporativos e domésticos

## 📂 Estrutura do Projeto

```
hp-scripts/
├── scripts/                # Scripts principais
│   ├── check.ps1           # Diagnóstico rápido de integridade
│   ├── sfc.ps1             # Diagnóstico e reparação completa
│   ├── backup.ps1          # Backup de configurações
│   ├── limp.ps1            # Limpeza de arquivos temporários
│   ├── update.ps1          # Atualizações do Windows
│   ├── hora.ps1            # Sincronização de horário (NTP)
│   ├── net.ps1             # Reset de rede e conectividade
│   ├── print.ps1           # Reparo de impressão
│   ├── wallpaper.ps1       # Configuração de wallpaper
│   ├── winforge.ps1        # Instalação e otimização

├── tools/                  # Ferramentas portáteis
│   ├── nextdns/            # Módulo NextDNS
│   │   ├── install.ps1
│   │   ├── nextdns.ps1
│   │   ├── reparar_nextdns.ps1
│   │   ├── dns_padrão.ps1
│   │   └── remover_hpti.ps1
│   └── *.7z                # Ferramentas compactadas (7z, CoreTemp, etc.)
├── portable/               # Versão offline para pendrive
│   ├── INICIAR.cmd         # Launcher executável
│   ├── menu.ps1            # Menu portable
│   └── menu_tools.ps1      # Menu de ferramentas portable
├── docs/                   # Documentação MkDocs
├── .github/workflows/      # Pipeline CI/CD
│   └── ci.yml              # Verificação de qualidade
├── installps1.cmd          # Instalador PowerShell 7+
├── menu.ps1                # Menu principal (v1.5)
└── menu_tools.ps1          # Menu de ferramentas
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

```powershell
irm get.hpinfo.com.br/menu | iex
```

*Isso baixará e executará o orquestrador que gerencia todas as ferramentas abaixo.*

---

## 📂 Catálogo de Scripts

| Script | Descrição |
|--------|-----------|  
| **`check.ps1`** | Diagnóstico rápido de integridade do sistema |
| **`sfc.ps1`** | Diagnóstico e reparação completa (DISM, SFC, memória, processos) |
| **`backup.ps1`** | Backup de configurações (Wi-Fi, impressoras, certificados, wallpaper) |
| **`limp.ps1`** | Limpeza agressiva de arquivos temporários e cache |
| **`update.ps1`** | Limpeza e instalação de atualizações do Windows |
| **`hora.ps1`** | Sincronização automática de horário com NTP brasileiro |
| **`net.ps1`** | Reset completo de rede, DNS, testes e relatórios |
| **`print.ps1`** | Reparo de spooler e fila de impressão |
| **`wallpaper.ps1`** | Aplicação de wallpaper corporativo padrão |
| **`repair.ps1`** | Diagnóstico e reparo automático modular (Rede, Disco, Updates, Segurança) |
| **`winforge.ps1`** | Instalação de aplicativos + otimizações do sistema |

---

## 🛠️ Execução Manual (Download)

Se você clonou o repositório (`git clone`), use os comandos abaixo:

### 1. Diagnóstico Completo
```powershell
.\scripts\check.ps1
```

### 2. Backup de Configurações
```powershell
.\scripts\backup.ps1
```

### 3. Limpeza e Otimização
```powershell
.\scripts\limp.ps1
```

### 4. Reparo Completo do Windows
```powershell
.\scripts\sfc.ps1
```

### 5. Atualizações do Windows
```powershell
.\scripts\update.ps1
```




---

## ⚠️ Requisitos
* **Windows 10 ou 11**.
* **PowerShell 5.1+**.
* PowerShell executando como **Administrador**.
* Política de execução liberada:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```



---

Uma iniciativa [HP Info](https://hpinfo.com.br).
