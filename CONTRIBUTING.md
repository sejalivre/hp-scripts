# Como Contribuir para o HP-Scripts

Obrigado por dedicar seu tempo para contribuir! 

Seguimos algumas diretrizes para manter o projeto organizado e seguro.

##  Como Relatar Bugs
Use a aba **Issues** para relatar erros. Inclua:
- Versão do Windows/PowerShell.
- O erro exato (print ou texto).
- Passos para reproduzir o problema.

##  Sugerindo Novas Features
Abra uma **Issue** com a label \enhancement\. Explique o problema que o script resolve e como ele deve funcionar.

##  Desenvolvimento e Pull Requests
1. **Nunca** faça commit direto na branch \main\.
2. Crie uma branch para sua tarefa: \git checkout -b feature/nome-da-feature\.
3. Certifique-se de que seu código passa no **PSScriptAnalyzer** (nossa automação vai checar isso!).
   - Evite \Write-Host\. Use \Write-Output\ ou \Write-Warning\.
4. Envie o Pull Request descrevendo suas alterações.

##  Estilo de Código
- Use **UTF-8** para codificação dos arquivos.
- Comente o código onde a lógica for complexa.
- Use nomes de variáveis claros em inglês ou português (mantenha consistência).

Obrigado!
