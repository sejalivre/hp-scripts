Markdown# 🖥️ HP-Scripts

> **Suíte de automação para administração de sistemas Windows**

[![GitHub license](https://img.shields.io/github/license/hpinfo/hp-scripts?style=flat-square)](https://github.com/hpinfo/hp-scripts/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/hpinfo/hp-scripts?style=flat-square)](https://github.com/hpinfo/hp-scripts/issues)
[![GitHub stars](https://img.shields.io/github/stars/hpinfo/hp-scripts?style=flat-square)](https://github.com/hpinfo/hp-scripts/stargazers)

Coleção de scripts **PowerShell** práticos e prontos para uso, focados em simplificar tarefas diárias de administração de estações Windows (suporte técnico, TI corporativa, manutenção de frota, etc.).

---

## 📋 Ferramentas Disponíveis

| Script       | Função Principal                              | Principais Recursos                                                                 | Indicado para                     |
|--------------|-----------------------------------------------|--------------------------------------------------------------------------------------|------------------------------------|
| `info.ps1`   | Inventário completo de hardware               | CPU, RAM, discos (S.M.A.R.T.), drivers, logs de erro → relatório HTML bonito       | Auditoria, inventário, diagnóstico |
| `print.ps1`  | Resolver problemas de impressão               | Reinicia Spooler, limpa fila, corrige permissões no registro ("Acesso Negado")      | Help desk, suporte a usuário       |
| `net.ps1`    | Restaurar conectividade de rede               | Reset TCP/IP, flush DNS, reinicia serviços, ajusta firewall                         | Falhas de internet, VPN, domínio   |

---

## 🚀 Começando

### 1. Pré-requisitos

Execute **como Administrador** uma única vez (por usuário):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Dica de segurança: se preferir mais restrição, use AllSigned e assine os scripts.
2. Como usar

Baixe o script desejado (ou clone o repositório inteiro)
Abra o PowerShell como Administrador
Navegue até a pasta do script
Execute:

PowerShell.\info.ps1     # Inventário de hardware
.\print.ps1    # Correção de impressora
.\net.ps1      # Reset de rede


✨ Funcionalidades em destaque

Relatórios em HTML limpos e fáceis de compartilhar
Correções seguras e reversíveis sempre que possível
Pouca ou nenhuma dependência externa
Mensagens claras em português com códigos de erro quando aplicável


🛠️ Contribuindo

Fork o projeto
Crie sua feature branch (git checkout -b feature/melhor-log-de-erros)
Commit suas mudanças (git commit -m 'Adiciona log detalhado de erros no info.ps1')
Push para a branch (git push origin feature/melhor-log-de-erros)
Abra um Pull Request

Pull requests com:

novas ferramentas
melhorias de robustez
tradução / documentação
correção de bugs

são muito bem-vindos!
→ Abra uma issue para discutir ideias ou reportar bugs.

📄 Licença
MIT License — sinta-se à vontade para usar, modificar e distribuir.

❤️ Agradecimentos / Mantido por

Última atualização: Janeiro 2026
Gostou? Dê uma ⭐ * **📂 Repositório:** [GitHub - hp-scripts](https://github.com/sejalivre/hp-scripts)

Visite nosso site principal: [hpinfo.com.br](https://www.hpinfo.com.br)
<footer> <p><em>Mantido por <a href="https://www.hpinfo.com.br/" style="color: #58a6ff;">HP Info</a>. Última atualização: 2026.</em></p> </footer><style> /* Estilos para modo escuro (compatível com GitHub) */ @media (prefers-color-scheme: dark) { body { color: #c9d1d9; background-color: #0d1117; } h1, h2, h3 { color: #58a6ff; } a { color: #58a6ff; } code { background-color: #161b22; color: #8b949e; border: 1px solid #30363d; } blockquote { color: #8b949e; border-left-color: #3b434b; } table { border-color: #30363d; } th, td { border-color: #30363d; } } </style>

