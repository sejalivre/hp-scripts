```markdown
# 🖥️ Bem-vindo ao HP-Scripts

> **Suíte de automação para administração de sistemas Windows**

O **HP-Scripts** é uma coleção de ferramentas PowerShell desenvolvidas para simplificar e automatizar tarefas comuns de administração em ambientes Windows. Toda a documentação oficial está disponível abaixo.

---

## 🛠️ **Ferramentas Disponíveis**

### 🔍 **1. Inventário de Hardware (`info.ps1`)**
Gera um relatório **HTML completo** sobre a saúde e especificações do hardware da máquina.

*   **📊 Dados coletados:** Processador, Memória RAM, Discos (incluindo S.M.A.R.T), Drivers e Logs de Erro.
*   **🎯 Ideal para:** Auditoria de máquinas e diagnóstico prévio de manutenção.

### 🖨️ **2. Solução de Impressão (`print.ps1`)**
Resolve os problemas mais comuns de **filas de impressão travadas**.

*   **⚙️ Funções:** Reinicia o Spooler, limpa arquivos temporários de impressão e aplica correções de registro para erros de "Acesso Negado".

### 🌐 **3. Diagnóstico de Rede (`net.ps1`)**
Restaura a **conectividade da estação de trabalho** com comandos automatizados.

*   **🔧 Funções:** Reseta a pilha TCP/IP, libera cache de DNS, reinicia serviços de rede (DHCP, DNS Client) e ajusta regras de firewall.

---

## 🚀 **Guia Rápido de Uso**

### 📋 **Pré-requisitos**
Para executar qualquer script desta coleção, é necessário liberar a política de execução do PowerShell. Execute o comando abaixo como **Administrador**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ▶️ **Como Executar**
Baixe a ferramenta desejada e execute via terminal PowerShell:

```powershell
.\nome-do-script.ps1
```

---

## 🆘 **Suporte e Contribuição**

Este é um projeto **Open Source** mantido pela comunidade.

*   **📂 Repositório:** [GitHub - hp-scripts](https://github.com/hp-scripts)
*   **🐛 Reportar Erros:** Utilize a aba **Issues** no GitHub.
*   **🤝 Contribuir:** Pull requests são bem-vindos!

---

> **💡 Dica:** Para melhor visualização no GitHub, ative o **modo escuro** nas configurações do seu perfil.

<footer>
  <p><em>Mantido por <a href="https://www.hpinfo.com.br/" style="color: #58a6ff;">HP Info</a>. Última atualização: 2026.</em></p>
</footer>

<style>
  /* Estilos para modo escuro (compatível com GitHub) */
  @media (prefers-color-scheme: dark) {
    body {
      color: #c9d1d9;
      background-color: #0d1117;
    }
    h1, h2, h3 {
      color: #58a6ff;
    }
    a {
      color: #58a6ff;
    }
    code {
      background-color: #161b22;
      color: #8b949e;
      border: 1px solid #30363d;
    }
    blockquote {
      color: #8b949e;
      border-left-color: #3b434b;
    }
    table {
      border-color: #30363d;
    }
    th, td {
      border-color: #30363d;
    }
  }
</style>
```
