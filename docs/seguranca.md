# 🛡️ Política de Segurança

Informações sobre segurança, privacidade e boas práticas ao usar o HP Scripts.

---

## Compromisso com Segurança

O HP Scripts foi desenvolvido com segurança em mente:

✅ **Código aberto** - Todo código é auditável no GitHub  
✅ **Sem telemetria** - Nenhum dado é enviado para servidores externos  
✅ **Sem instalação permanente** - Scripts são temporários  
✅ **Execução transparente** - Você pode ler o código antes de executar  
✅ **Sem backdoors** - Código verificável e auditável  

---

## O que os Scripts Fazem

### Acessos e Permissões

Os scripts podem realizar as seguintes ações **quando executados com privilégios de administrador**:

| Ação | Scripts | Justificativa |
|------|---------|---------------|
| **Leitura de sistema** | Todos | Diagnóstico e verificação |
| **Modificação de rede** | `net.ps1`, `hora.ps1` | Reset TCP/IP, DNS, NTP |
| **Limpeza de arquivos** | `limp.ps1` | Remover temporários e cache |
| **Modificação de serviços** | `print.ps1`, `update.ps1` | Reiniciar spooler, Windows Update |
| **Backup de dados** | `backup.ps1` | Salvar configurações Wi-Fi |
| **Download de arquivos** | `update.ps1`, `installps1.cmd` | Atualizações e instaladores |
| **Modificação de registro** | `nextdns`, `wallpaper.ps1` | Configurações de DNS e papel de parede |

### O que os Scripts NÃO Fazem

❌ **Não coletam dados pessoais**  
❌ **Não enviam informações para servidores externos**  
❌ **Não instalam malware ou adware**  
❌ **Não modificam arquivos do usuário**  
❌ **Não abrem portas de rede**  
❌ **Não desabilitam antivírus**  
❌ **Não criam contas de usuário**  

---

## Execução Segura

### Verificar Código-Fonte

Antes de executar qualquer script, você pode visualizar o código:

**Método 1: GitHub**
```
https://github.com/sejalivre/hp-scripts/blob/main/[script].ps1
```

**Método 2: Download e Inspeção**
```powershell
# Baixar sem executar
Invoke-RestMethod https://get.hpinfo.com.br/check -OutFile check.ps1

# Abrir no Notepad
notepad check.ps1

# Executar após verificar
.\check.ps1
```

**Método 3: Visualizar no Terminal**
```powershell
Invoke-RestMethod https://get.hpinfo.com.br/check
```

### Política de Execução

O PowerShell possui proteções nativas:

```powershell
# Verificar política atual
Get-ExecutionPolicy

# Configurar para permitir scripts assinados e locais
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Níveis de segurança:**
- `Restricted` - Nenhum script pode executar (padrão em alguns sistemas)
- `RemoteSigned` - Scripts locais executam, remotos precisam assinatura
- `Unrestricted` - Todos os scripts executam (menos seguro)

---

## Privacidade

### Dados Coletados

**Nenhum dado é enviado para servidores externos.**

Os scripts operam localmente e apenas:
- Leem informações do sistema local
- Modificam configurações locais
- Geram relatórios locais (salvos em `C:\Intel`)

### Relatórios Gerados

O script `check.ps1` gera relatórios HTML contendo:
- Informações de hardware
- Status de serviços
- Uso de disco e memória
- Processos em execução

**Estes relatórios são salvos localmente e nunca enviados automaticamente.**

### NextDNS

O módulo NextDNS se conecta aos servidores NextDNS para:
- Bloquear domínios maliciosos
- Filtrar conteúdo

**Importante:** NextDNS é um serviço de terceiros. Consulte a [política de privacidade do NextDNS](https://nextdns.io/privacy).

---

## Avisos de Segurança

### Execução Remota

> [!WARNING]
> Executar scripts diretamente da internet (`irm ... | iex`) requer confiança na fonte.

**Recomendações:**
1. ✅ Verifique o código-fonte no GitHub primeiro
2. ✅ Use HTTPS (nunca HTTP)
3. ✅ Confirme o domínio correto (`get.hpinfo.com.br`)
4. ⚠️ Evite executar em ambientes de produção críticos sem testes

### Privilégios de Administrador

> [!CAUTION]
> Scripts executados como administrador têm acesso total ao sistema.

**Boas práticas:**
1. Execute apenas scripts de fontes confiáveis
2. Leia o código antes de executar com privilégios elevados
3. Use contas de administrador apenas quando necessário
4. Teste em ambiente controlado primeiro

### Antivírus e Firewall

Alguns antivírus podem bloquear scripts PowerShell:

> [!NOTE]
> Falsos positivos são comuns com scripts de automação.

**Se bloqueado:**
1. Verifique o código-fonte
2. Adicione exceção temporária
3. Execute localmente (clone o repositório)
4. Reporte falso positivo ao fabricante do antivírus

---

## Segurança do Código

### Desenvolvimento

- ✅ Código revisado antes de publicação
- ✅ Testes em múltiplas versões do Windows
- ✅ Sem dependências externas suspeitas
- ✅ Versionamento e histórico completo no Git

### Atualizações

Quando atualizamos scripts:
1. Alterações documentadas no commit
2. Código revisado
3. Testes realizados
4. Publicação no GitHub e servidor

**Você sempre executa a versão mais recente ao usar `irm ... | iex`**

### Reportar Vulnerabilidades

Encontrou um problema de segurança?

**Reporte de forma responsável:**
1. **NÃO** abra issue pública
2. Entre em contato via: [GitHub Security](https://github.com/sejalivre/hp-scripts/security)
3. Descreva o problema detalhadamente
4. Aguarde resposta antes de divulgar publicamente

---

## Ambientes Corporativos

### Políticas de Grupo

Em ambientes corporativos, as políticas de grupo podem:
- Bloquear execução de scripts
- Restringir downloads
- Exigir assinatura digital

**Soluções:**
1. Solicitar exceção ao administrador de TI
2. Usar execução local (clonar repositório)
3. Assinar scripts internamente

### Proxy e Firewall

Scripts que baixam arquivos podem ser bloqueados:

```powershell
# Configurar proxy (se necessário)
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
[System.Net.WebRequest]::DefaultWebProxy = $proxy
```

### Auditoria

Para auditoria corporativa:
1. Clone o repositório localmente
2. Revise todo o código
3. Execute em ambiente de teste
4. Documente aprovação interna
5. Use versão local aprovada

---

## Responsabilidade

### Uso por Sua Conta e Risco

> [!IMPORTANT]
> O HP Scripts é fornecido "como está", sem garantias.

**Você é responsável por:**
- Verificar compatibilidade com seu ambiente
- Testar antes de usar em produção
- Fazer backups antes de modificações importantes
- Entender o que cada script faz

### Licença MIT

O projeto é licenciado sob [MIT License](licenca.md):
- ✅ Uso comercial permitido
- ✅ Modificação permitida
- ✅ Distribuição permitida
- ⚠️ Sem garantias
- ⚠️ Sem responsabilidade do autor

---

## Boas Práticas

### Antes de Executar

1. ✅ Leia a documentação do script
2. ✅ Verifique o código-fonte
3. ✅ Faça backup de dados importantes
4. ✅ Teste em ambiente não-crítico
5. ✅ Entenda o que será modificado

### Durante a Execução

1. ✅ Monitore a saída do script
2. ✅ Não interrompa processos críticos
3. ✅ Aguarde conclusão completa
4. ✅ Leia mensagens de erro

### Após a Execução

1. ✅ Verifique se tudo funcionou
2. ✅ Teste funcionalidades afetadas
3. ✅ Mantenha logs/relatórios
4. ✅ Reporte problemas no GitHub

---

## Contato de Segurança

**Para questões de segurança:**
- GitHub Security: [github.com/sejalivre/hp-scripts/security](https://github.com/sejalivre/hp-scripts/security)
- Issues: [github.com/sejalivre/hp-scripts/issues](https://github.com/sejalivre/hp-scripts/issues)

**Para suporte geral:**
- Documentação: [docs.hpinfo.com.br](https://docs.hpinfo.com.br)
- Site: [hpinfo.com.br](https://hpinfo.com.br)

---

## Próximos Passos

- 🚀 Comece com o [guia rápido](quickstart.md)
- ⚙️ Verifique os [requisitos](requisitos.md)
- 📖 Leia a [documentação completa](index.md)

---

**[← Voltar para Documentação Principal](index.md)**
