Aqui está o arquivo `README.md` completo e formatado corretamente. Pode copiar e colar tudo no seu editor:

```markdown
[![Verificacao de Qualidade](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/sejalivre/hp-scripts/actions/workflows/ci.yml)

# HP-Scripts (Automação e Gerenciamento)

-> **Documentação Oficial:** [docs.hpinfo.com.br](https://docs.hpinfo.com.br)

Coleção de scripts PowerShell voltados para inventário de hardware, manutenção de rede e solução de problemas de impressão.

## 🚀 Como Começar

Para utilizar estes scripts, você precisa clonar este repositório ou baixar o arquivo ZIP.

### 🔓 Habilitando a Execução de Scripts
Por padrão, o Windows bloqueia a execução de scripts baixados da internet por segurança. Para permitir o uso, abra o PowerShell como **Administrador** e execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

```

Isso permite rodar scripts criados localmente e scripts assinados baixados da internet.

---

## 📂 Catálogo de Scripts

### 1. Inventário do Sistema (`info.ps1`)

Gera um relatório HTML rico e detalhado sobre a estação de trabalho.

* **O que faz:** Coleta dados de CPU (incluindo temperatura via CoreTemp), Saúde do Disco (S.M.A.R.T via CrystalDiskInfo), RAM, Drivers com falha e atualizações do Windows.
* **Como usar:**

```powershell
.\info.ps1

```

*O relatório será salvo na sua Área de Trabalho.*

### 2. Reset de Impressão (`print.ps1`)

Soluciona problemas comuns de impressoras travadas ou spooler parado.

* **O que faz:** Para o serviço Spooler, limpa a fila de impressão travada, aplica correções de registro (RPC Auth/PointAndPrint) e reinicia o serviço.
* **Como usar:** (Executar como Administrador)

```powershell
.\print.ps1

```

### 3. Reset de Rede (`net.ps1`)

Ferramenta para diagnóstico e reparo de conectividade.

* **O que faz:** Reseta configurações de IP (winsock/int ip), limpa o cache DNS, libera firewall e garante que serviços críticos de rede (DHCP, DNS Client) estejam ativos.
* **Como usar:** (Executar como Administrador)

```powershell
.\net.ps1

```

---

## 🛠️ Instalação (Git)

Se você tem o Git instalado:

```bash
git clone [https://github.com/sejalivre/hp-scripts.git](https://github.com/sejalivre/hp-scripts.git)
cd hp-scripts

```

## ⚠️ Isenção de Responsabilidade

Estes scripts alteram configurações do sistema (Registro do Windows e Serviços). Recomenda-se analisar o código antes de executar em ambiente de produção.

---

Uma iniciativa [hpinfo.com.br](https://hpinfo.com.br)

```

```