```markdown
# Bem-vindo ao HP-Scripts

O **HP-Scripts** é uma suíte de automação desenvolvida para simplificar a rotina de administração de sistemas Windows. Aqui você encontra a documentação oficial de cada ferramenta.

---

## 🛠️ Ferramentas Disponíveis

### 1. Inventário de Hardware (`info.ps1`)
Gera um relatório HTML completo sobre a saúde e especificações da máquina.
* **Dados coletados:** Processador, Memória RAM, Discos (incluindo S.M.A.R.T), Drivers e Logs de Erro.
* **Ideal para:** Auditoria de máquinas e diagnóstico prévio de manutenção.

### 2. Solução de Impressão (`print.ps1`)
Resolve os problemas mais comuns de filas de impressão travadas.
* **Funções:** Reinicia o Spooler, limpa arquivos temporários de impressão e aplica correções de registro para erros de "Acesso Negado".

### 3. Diagnóstico de Rede (`net.ps1`)
Restaura a conectividade da estação de trabalho.
* **Funções:** Reseta a pilha TCP/IP, libera cache de DNS, reinicia serviços de rede (DHCP, DNS Client) e ajusta regras de firewall.

---

## 🚀 Guia Rápido de Uso

### Pré-requisitos
Para executar qualquer script desta coleção, é necessário liberar a política de execução do PowerShell. Execute o comando abaixo como **Administrador**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Como Executar
Baixe a ferramenta desejada e execute via terminal:

```powershell
.\nome-do-script.ps1
```

---

## 🆘 Suporte e Contribuição

Este é um projeto Open Source.

- **Repositório:** [GitHub - hp-scripts](https://github.com/hp-scripts)
- **Reportar Erros:** Utilize a aba Issues no GitHub.

---

<footer>
  <p><em>Mantido por HP Info. Última atualização: 2026.</em></p>
</footer>
```
