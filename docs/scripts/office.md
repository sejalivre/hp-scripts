# 📦 OFFICE - Gerenciamento Microsoft Office

## Visão Geral

O **office.ps1** é um módulo completo para o ciclo de vida do Microsoft Office, permitindo instalação automatizada, reparo de problemas comuns e remoção completa da suíte.

## Execução Rápida

```powershell
irm https://get.hpinfo.com.br/scripts/office | iex
```

---

## Funcionalidades

### 1. Instalação Automatizada
Baixa e executa o script oficial de instalação da HP-Scripts.
- **URL**: `https://get.hpinfo.com.br/tools/office/install.ps1`

### 2. Reparo e Manutenção
- **Limpeza de Cache**: Remove arquivos temporários em `%LocalAppData%\Microsoft\Office\16.0\OfficeFileCache`.
- **Reparo Rápido**: Aciona o `OfficeClickToRun.exe` com o cenário `QuickRepair`.
- **Encerramento de Processos**: Garante que Word, Excel e outros estejam fechados antes da manutenção.

### 3. Remoção Completa
- Desinstalação total do Office usando a ferramenta nativa `ClickToRun`.
- **Segurança**: Requer confirmação explícita do usuário antes de iniciar.

---

## Detalhamento Técnico

### Localização do Executável ClickToRun
O script busca automaticamente o `OfficeClickToRun.exe` nos caminhos padrão:
- `C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeClickToRun.exe`
- `C:\Program Files (x86)\Common Files\microsoft shared\ClickToRun\OfficeClickToRun.exe`

### Comandos Utilizados

#### Reparo Rápido
```powershell
Start-Process -FilePath $ctrPath -ArgumentList "scenario=Repair RepairType=QuickRepair platform=x64 culture=pt-br DisplayLevel=True" -Wait
```

#### Desinstalação
```powershell
Start-Process -FilePath $ctrPath -ArgumentList "scenario=Uninstall platform=x64 culture=pt-br DisplayLevel=True" -Wait
```

---

## Compatibilidade

- **Windows 10 / 11**
- **PowerShell 5.1+**
- **Arquitetura**: x64 (padrão)
- **Idioma**: pt-br (padrão)

---

## Casos de Uso

### Instalação em Máquinas Novas
Use a opção **[01] INSTALAR** para implantar o Office rapidamente seguindo os padrões da empresa.

### Correção de Erros de Documentos ou Performance
Use a opção **[02] REPARAR** quando o Office estiver lento, travando ou apresentando erros ao abrir arquivos.

### Limpeza de Licença ou Reinstalação
Use a opção **[03] REMOVER** para limpar instalações anteriores antes de uma nova ativação ou mudança de versão.

---

## Segurança

- **Confirmação**: A remoção exige que o usuário digite "S" para confirmar.
- **Privilégios**: Requer execução como Administrador.
- **Logging**: Todas as ações são registradas no log centralizado do HP-Scripts.
