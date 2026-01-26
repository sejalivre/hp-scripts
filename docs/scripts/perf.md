# ⚡ PERF – Diagnóstico e Score de Performance

O **PERF.ps1** é um script PowerShell projetado para avaliar, registrar e comparar a **performance real do Windows**, antes e depois de processos de otimização e limpeza (como o `limp.ps1`).

Ele gera um **Score de Performance (0–100)** e cria um **relatório HTML visual**, ideal para diagnóstico técnico, comprovação de serviço e histórico por máquina.

---

## ▶ Execução Direta (One-liner)

```powershell
irm https://get.hpinfo.com.br/perf | iex
