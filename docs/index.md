```markdown
# 🖥️ HP-Scripts

> **Suíte de automação para administração de sistemas Windows**

[![GitHub license](https://img.shields.io/github/license/hpinfo/hp-scripts?style=flat-square)](https://github.com/hpinfo/hp-scripts/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/hpinfo/hp-scripts?style=flat-square)](https://github.com/hpinfo/hp-scripts/issues)
[![GitHub stars](https://img.shields.io/github/stars/hpinfo/hp-scripts?style=flat-square)](https://github.com/hpinfo/hp-scripts/stargazers)

Coleção de scripts **PowerShell** práticos e prontos para uso...

---

## 📋 Ferramentas Disponíveis

| Script | Função | Recursos | Indicado para |
|--------|--------|----------|---------------|
| `info.ps1` | Inventário de hardware | CPU, RAM, discos, relatório HTML | Auditoria, diagnóstico |
| `print.ps1` | Problemas de impressão | Reinicia Spooler, limpa fila | Help desk |
| `net.ps1` | Conectividade de rede | Reset TCP/IP, flush DNS | Falhas de internet |

---

## 🚀 Começando

### 1. Pré-requisitos
Execute como **Administrador**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
2. Como usar
powershell
.\info.ps1    # Inventário
.\print.ps1   # Impressão
.\net.ps1     # Rede
📄 Licença
MIT License — use, modifique e distribua.

<footer> <p><em>Mantido por <a href="https://www.hpinfo.com.br/">HP Info</a>. Última atualização: 2026.</em></p> </footer> ```
