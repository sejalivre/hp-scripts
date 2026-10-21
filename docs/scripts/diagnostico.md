# Diagnóstico Técnico Completo (`Diagnostico.ps1`)

## 📋 Visão Geral

O `scripts/Diagnostico.ps1` é o diagnóstico técnico completo do HP-Scripts. Ele varre a máquina, classifica cada achado (OK, aviso, crítico, erro) e **gera arquivos** que o técnico leva embora:

- Relatório completo em texto (`Relatorio_*.txt`);
- Script de reparo em PowerShell (`Reparo_*.ps1`);
- Script de reparo em batch (`Reparo_*.cmd`);
- Lista de itens que exigem atenção manual (`NaoConsertado_*.txt`);
- Lista de itens de inicialização (`StartupItems_*.txt`).

## 🚀 Como executar

```powershell
# Via menu principal (recomendado)
irm get.hpinfo.com.br/menu | iex     # Opção 03 (SFC) > 2 (Diagnóstico Técnico Completo)

# Ou direto
irm get.hpinfo.com.br/scripts/Diagnostico | iex
```

No modo portable: `portable\INICIAR.cmd` → opção `03` → `2`.

## ⚙️ Menu do HP-Scripts: opção 03 (SFC)

| Opção | Item |
|-------|------|
| `1` | Diagnóstico e Reparação Completa (`sfc.ps1`) |
| `2` | Diagnóstico Técnico Completo (`Diagnostico.ps1`) |
| `0` | Voltar ao menu principal |

## 📂 Arquivos gerados

Tudo é gravado em **`C:\DiagTecnico`**:

| Arquivo | Conteúdo |
|---------|----------|
| `Relatorio_<PC>_<data>.txt` | Relatório completo com todos os achados e o resumo |
| `Reparo_<PC>_<data>.ps1` | Script PowerShell para aplicar as correções sugeridas |
| `Reparo_<PC>_<data>.cmd` | Versão batch do script de reparo |
| `NaoConsertado_<PC>_<data>.txt` | Itens que precisam de intervenção manual |
| `StartupItems_<PC>_<data>.txt` | Itens de inicialização do Windows |

Os logs internos do HP-Scripts continuam em `C:\Program Files\HPTI`.

## 🔧 Requisitos

- Windows 10 / 11;
- **Executar como Administrador** (`#Requires -RunAsAdministrator`);
- PowerShell 5.1 ou superior.

## 🔁 Comportamento dentro do menu

- O script **não encerra a sessão do menu**: ao final, basta pressionar qualquer tecla para voltar ao submenu SFC;
- Sem privilégios de administrador ele avisa e devolve o controle ao menu (não aborta a sessão);
- Os `pause`/`exit` do script de reparo **gerado** são mantidos: aqueles arquivos rodam sozinhos, fora do menu.

## 🛠️ Notas para manutenção

- A lógica de diagnóstico é a do autor original e deve ser preservada; alterações no HP-Scripts se limitam à casca de entrada/saída (mensagens, cores, checagem de admin e devolução do controle ao menu);
- Cor: `Green` sucesso, `Yellow` aviso, `Red` falha, `Cyan` informação — padrão do projeto (`AGENTS.md`).

## 📞 Suporte

- 📖 Documentação: [docs.hpinfo.com.br](https://docs.hpinfo.com.br)
- 🐛 Issues: [GitHub](https://github.com/sejalivre/hp-scripts/issues)
