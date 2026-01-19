<style>
/* Estilo Dark Mode Personalizado - HP Info */
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    background-color: #0d1117 !important;
    color: #c9d1d9 !important;
    line-height: 1.6;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}
a { color: #58a6ff !important; text-decoration: none; }
a:hover { text-decoration: underline; }

/* Títulos */
h1, h2, h3 { color: #ffffff !important; border-bottom: 1px solid #21262d; padding-bottom: 0.3em; }

/* Tabelas */
table { border-collapse: collapse; width: 100%; margin: 20px 0; background-color: #0d1117 !important; }
th {
    background-color: #161b22 !important;
    color: #ffffff !important;
    font-weight: bold;
    text-align: left;
    border: 1px solid #30363d !important;
    padding: 10px;
}
td {
    background-color: #0d1117 !important;
    color: #c9d1d9 !important;
    border: 1px solid #30363d !important;
    padding: 10px;
}
/* Efeito zebrado */
tr:nth-child(even) td { background-color: #12161c !important; }

/* Códigos */
code {
    background-color: #1f2937 !important;
    color: #ff7b72 !important;
    padding: 0.2em 0.4em;
    border-radius: 6px;
    font-family: monospace;
}
pre {
    background-color: #161b22 !important;
    padding: 16px;
    overflow: auto;
    border-radius: 6px;
    border: 1px solid #30363d;
}
pre code {
    background-color: transparent !important;
    color: #c9d1d9 !important;
    padding: 0;
}

/* Outros */
blockquote { border-left: 4px solid #1f6feb; color: #8b949e; padding-left: 15px; margin-left: 0; }
hr { border: 0; border-top: 1px solid #30363d; margin: 24px 0; }
footer { margin-top: 50px; font-size: 0.8em; text-align: center; color: #8b949e; border-top: 1px solid #30363d; padding-top: 20px; }
</style>

# 🖥️ HP-Scripts Documentation

> **Suíte profissional de automação para Windows.**

Bem-vindo à documentação oficial. Aqui você aprende a utilizar nossos scripts para agilizar o suporte técnico.

---

## 🚀 O jeito mais fácil (Menu Principal)

Não precisa baixar nada. Abra o PowerShell como **Administrador** e cole:

    irm get.hpinfo.com.br/menu | iex

Isso abrirá nossa Central de Suporte interativa, baixando as ferramentas necessárias sob demanda.

---

## 📦 Ferramentas Disponíveis

| Ferramenta | Script | O que faz? |
| :--- | :--- | :--- |
| **Info System** | `info.ps1` | Relatório HTML completo (Hardware, Temperatura, S.M.A.R.T). |
| **Rede Fix** | `net.ps1` | Resolve "Sem Internet", limpa DNS e reseta adaptadores. |
| **Print Fix** | `print.ps1` | Destrava impressoras e limpa spooler. |
| **Update Mgr** | `update.ps1` | Força atualizações e corrige erros do Windows Update. |
| **Backup Pro** | `backup.ps1` | Salva dados e configurações antes da formatação. |

---

## 💾 Backup e Migração (`backup.ps1`)

Esta ferramenta foi desenhada para técnicos que precisam formatar computadores mas não podem perder as configurações do cliente.

### O que é salvo?
1.  **Rede:** Senhas de Wi-Fi salvas (incluindo as chaves de segurança) e IPs.
2.  **Impressoras:** Lista de filas instaladas e drivers.
3.  **Arquivos:** Documentos, Planilhas, PDFs e Favoritos.
4.  **Personalização:** Papel de Parede atual e ícones da Área de Trabalho.
5.  **Programas:** Lista completa de softwares instalados (para referência futura).

### Como usar
Este script requer que você defina uma **pasta de destino**. Recomenda-se baixar o repositório e executar localmente:

```powershell
# Exemplo de uso
.\backup.ps1 -Destino "C:\Backups"
```

> **Nota:** O script criará uma pasta com o nome `Backup_Sistema_DATA_HORA` dentro de `C:\Backups` e gerará um arquivo `restaurar.ps1` dentro dela para ajudar na recuperação manual.

---

## 🔄 Windows Update (`update.ps1`)

O "Cura Tudo" para atualizações travadas.

1.  Para os serviços de update (`wuauserv`, `bits`).
2.  Limpa as pastas `SoftwareDistribution` e `catroot2`.
3.  Executa correções do sistema (`DISM` e `SFC`).
4.  Baixa e instala atualizações pendentes automaticamente.

**Uso Web:**
```powershell
irm get.hpinfo.com.br/update | iex
```

---

<footer>
    <p>Mantido por <a href="https://hpinfo.com.br">HP Info</a>. <br>Documentação gerada via GitHub Pages.</p>
</footer>