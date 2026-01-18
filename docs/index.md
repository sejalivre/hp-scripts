```Markdown
<style>
/* Estilo Dark Mode Personalizado */
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    background-color: #0d1117; /* Fundo escuro estilo GitHub Dark */
    color: #c9d1d9; /* Texto claro */
    line-height: 1.6;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}
a { color: #58a6ff; text-decoration: none; }
a:hover { text-decoration: underline; }
h1, h2, h3 { color: #ffffff; border-bottom: 1px solid #21262d; padding-bottom: 0.3em; }
code { background-color: #161b22; color: #ff7b72; padding: 0.2em 0.4em; border-radius: 6px; font-family: monospace; }
pre { background-color: #161b22; padding: 16px; overflow: auto; border-radius: 6px; }
pre code { background-color: transparent; color: #c9d1d9; padding: 0; }
table { border-collapse: collapse; width: 100%; margin: 20px 0; }
th { background-color: #161b22; color: #ffffff; font-weight: bold; text-align: left; border: 1px solid #30363d; padding: 10px; }
td { border: 1px solid #30363d; padding: 10px; }
tr:nth-child(even) { background-color: #12161c; }
blockquote { border-left: 4px solid #1f6feb; color: #8b949e; padding-left: 15px; margin-left: 0; }
hr { border: 0; border-top: 1px solid #30363d; margin: 24px 0; }
footer { margin-top: 50px; font-size: 0.8em; text-align: center; color: #8b949e; border-top: 1px solid #30363d; padding-top: 20px; }
</style>

# 🖥️ HP-Scripts

> **Suíte de automação para administração de sistemas Windows**

[![GitHub license](https://img.shields.io/github/license/sejalivre/hp-scripts?style=flat-square&color=blue)](https://github.com/sejalivre/hp-scripts/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/sejalivre/hp-scripts?style=flat-square&color=green)](https://github.com/sejalivre/hp-scripts/issues)
[![GitHub stars](https://img.shields.io/github/stars/sejalivre/hp-scripts?style=flat-square&color=yellow)](https://github.com/sejalivre/hp-scripts/stargazers)

Coleção de scripts **PowerShell** práticos e prontos para uso. O objetivo é simplificar tarefas repetitivas de TI.

---

## 📋 Ferramentas Disponíveis

| Script | Função | Recursos | Indicado para |
| :--- | :--- | :--- | :--- |
| `info.ps1` | Inventário de hardware | CPU, RAM, discos, relatório HTML | Auditoria, diagnóstico |
| `print.ps1` | Problemas de impressão | Reinicia Spooler, limpa fila | Help desk |
| `net.ps1` | Conectividade de rede | Reset TCP/IP, flush DNS | Falhas de internet |

---

## 🚀 Começando

### 1. Pré-requisitos
Execute o PowerShell como **Administrador** e libere a execução de scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
2. Como usar
Você pode baixar o repositório ou rodar diretamente (se implementarmos o método irm):

PowerShell
.\info.ps1    # Inventário
.\print.ps1   # Impressão
.\net.ps1     # Rede
📄 Licença
MIT License — você pode usar, modificar e distribuir livremente.

<footer> <p><em>Mantido por <a href="https://docs.hpinfo.com.br/">HP Info</a>.


Última atualização: 2026.</em></p> </footer>
