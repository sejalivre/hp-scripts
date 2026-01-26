Perfeito, Hugo 👌
Abaixo está um **DOCS completo**, já estruturado, pronto para você colocar em `/docs` (Markdown padrão). Ele já inclui o **PERF.ps1** integrado, com linguagem técnica, clara e organizada.

Você pode usar **do jeito que está** ou adaptar para MkDocs / Docusaurus depois sem dor.

---

# 📘 Documentação — HPINFO Scripts de Diagnóstico e Otimização Windows

Esta documentação descreve os scripts PowerShell utilizados para **diagnóstico, limpeza, otimização e validação de performance do Windows**, voltados para uso técnico profissional.

Os scripts foram projetados para execução rápida, padronizada e com **resultado mensurável**, facilitando diagnóstico, comprovação de serviço e histórico por máquina.

---

## 📌 Visão Geral

O conjunto de scripts tem como objetivo:

* Avaliar o estado real do sistema Windows
* Executar limpeza e otimizações seguras
* Medir performance **antes e depois**
* Gerar evidências técnicas em formato visual (HTML)
* Padronizar atendimentos técnicos e manutenções

---

## 🧩 Scripts Disponíveis

| Script     | Função principal                   |
| ---------- | ---------------------------------- |
| `PERF.ps1` | Diagnóstico e Score de Performance |
| `LIMP.ps1` | Limpeza e otimização do Windows    |
| `MENU.ps1` | Interface de execução centralizada |

---

## 🔧 PERF.ps1 — Diagnóstico e Score de Performance do Windows

O **PERF.ps1** é um script PowerShell desenvolvido para **avaliar, registrar e comparar a performance real do Windows**, sendo especialmente útil antes e depois de processos de limpeza e otimização (como o `LIMP.ps1`).

Ele coleta métricas essenciais do sistema, processa esses dados e calcula um **Score de Performance (0–100)**, permitindo uma análise objetiva do estado da máquina.

Ao final da execução, é gerado um **relatório HTML visual**, ideal para documentação técnica e comprovação de serviço.

---

### 🎯 Objetivos do PERF.ps1

* Medir a performance atual do sistema
* Criar um ponto de referência (*baseline*)
* Comparar estado **pré e pós manutenção**
* Apoiar decisões técnicas com dados objetivos
* Registrar histórico por máquina

---

### 📊 Métricas Avaliadas

O PERF.ps1 analisa, entre outros indicadores:

* Uso médio de CPU
* Consumo de memória RAM
* Tipo de armazenamento (HDD / SSD / NVMe)
* Tempo de boot estimado
* Quantidade de processos ativos
* Carga geral do sistema

Essas métricas são consolidadas em um **Score de Performance** variando de **0 a 100**, facilitando a interpretação.

---

### 📈 Score de Performance

Interpretação sugerida do score:

| Score  | Estado do sistema |
| ------ | ----------------- |
| 90–100 | Excelente         |
| 75–89  | Bom               |
| 60–74  | Regular           |
| 40–59  | Ruim              |
| 0–39   | Crítico           |

> ⚠️ O score é uma **referência técnica**, não um benchmark absoluto.

---

### ▶️ Execução do PERF.ps1

#### Execução direta via PowerShell (IRM)

O script pode ser executado diretamente, sem download manual:

```powershell
irm https://get.hpinfo.com.br/perf | iex
```

> ⚠️ Caso a política de execução bloqueie o script:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

### 📄 Saída Gerada

* Relatório HTML automático
* Score de performance numérico
* Informações técnicas detalhadas
* Base para comparação futura

O relatório pode ser usado como:

* Evidência de serviço técnico
* Diagnóstico documentado
* Histórico de performance da máquina

---

## 🧹 LIMP.ps1 — Limpeza e Otimização do Windows

O **LIMP.ps1** é responsável por executar rotinas seguras de limpeza e otimização, como:

* Limpeza de arquivos temporários
* Cache do sistema
* Ajustes básicos de performance
* Preparação do sistema para reavaliação

> Recomenda-se executar o **PERF.ps1 antes e depois** do LIMP.ps1 para comparação objetiva.

---

## 🧠 Fluxo Recomendado de Uso

1. Executar `PERF.ps1` (baseline)
2. Executar `LIMP.ps1`
3. Executar `PERF.ps1` novamente
4. Comparar scores e relatórios

---

## 🖥️ MENU.ps1 — Interface Centralizada

O `MENU.ps1` fornece uma interface simples para execução dos scripts, evitando erros e padronizando o atendimento técnico.

Exemplo de opções:

```
[1] Diagnóstico de Performance (PERF)
[2] Limpeza e Otimização (LIMP)
[9] Executar PERF + LIMP (Ciclo completo)
```

---

## ⚠️ Requisitos

* Windows 10 ou superior
* PowerShell 5.1 ou PowerShell 7+
* Execução como Administrador
* Conexão com a internet (execução via IRM)

---

## 📜 Observações Importantes

* Os scripts **não removem arquivos pessoais**
* Nenhuma alteração crítica é feita sem validação
* Uso recomendado para técnicos e ambientes controlados

---

## 📂 Licença e Uso

Uso permitido para:

* Assistência técnica
* Diagnóstico interno
* Atendimento profissional

Redistribuição ou modificação devem respeitar os termos definidos pelo autor.

---
