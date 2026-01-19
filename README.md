[![Qualidade do Código](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml)
[![Documentação](https://img.shields.io/badge/docs-online-blue)](https://docs.hpinfo.com.br)

# HP-Scripts (Automação e Gerenciamento)

Coleção de scripts PowerShell voltados para inventário de hardware, manutenção de rede, backups e solução de problemas.

**Documentação Completa:** [docs.hpinfo.com.br](https://docs.hpinfo.com.br)

---

## 🚀 Uso Rápido (Web)

Você pode executar o **Menu Principal** diretamente da internet sem baixar nada. Abra o PowerShell como Administrador e rode:

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