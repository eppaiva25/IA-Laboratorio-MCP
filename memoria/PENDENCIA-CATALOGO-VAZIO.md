---
name: pendencia-catalogo-vazio
description: "Catálogo real (catalogo.csv) contém apenas o cabeçalho — 0 linhas — apesar do diário registrar 45 inventários. Bloqueia o uso da CLI V0/V1."
metadata:
  node_type: memory
  type: project
  modified: 2026-08-21T20:55:00.000Z
---

# Pendência — Catálogo real está vazio (apenas cabeçalho)

**Data de detecção:** 2026-08-21
**Sessão:** retomada do desenvolvimento da Biblioteca Viva (após commit `c589c74`)

## Fato observado

- `biblioteca-viva/dados/catalogo.csv` tem **340 bytes** e contém **apenas o cabeçalho** (1 linha: 26 colunas).
- `Get-BvCatalogo` retorna 0 linhas.
- `biblioteca-viva/dados/diario.jsonl` (8322 bytes) **tem** registros de inventário de 2026-08-21 18:38 — pelo menos as 45 entradas `arquivo_novo`/`inventariado` dos 45 PDFs.
- `biblioteca-viva/dados/extracoes/` e `classificacoes/` ainda contêm a `smoke-1`.

## Consequência

A CLI V0/V1 — e qualquer leitura do catálogo real — não tem linhas para exibir. O pipeline de inventário que produziu o `diario.jsonl` não persistiu o `catalogo.csv` correspondente, ou o `catalogo.csv` foi sobrescrito por um wipe posterior (consistente com o registrado em `INCIDENTE-2026-08-21`).

## Por que é pendência e não tarefa deste incremento

O usuário foi explícito nesta sessão:

1. **Não continuar investigando o incidente** (`INCIDENTE-2026-08-21-DESTRUICAO-DADOS.md`).
2. Recuperar o catálogo real é **passo 1** das pendências combinadas e estava marcado como **PENDENTE — aguardando ordem**.

A CLI V0/V1 implementada está correta; o que falta é o insumo de dados.

## O que foi feito no incremento

- `biblioteca-viva/cli/cli.ps1` reescrito: 6 opções, todas funcionais.
- `biblioteca-viva/testes/teste-cli.ps1` reescrito: 19 testes, dos quais **6 passaram** e **13 falharam** por causa desta pendência (todos os 13 que dependem de linhas do catálogo).
- Núcleo intocado.
- Protótipo intocado.
- Nenhuma escrita destrutiva.

## Como resolver (decisão do usuário)

Existem pelo menos 3 caminhos, todos dependem de uma ordem explícita:

1. **Re-executar o inventário** das Fases A/B (com sandbox) para regenerar `catalogo.csv` a partir dos 45 PDFs em `G:\Documentos_Todos\PDFs\Projeto PDFs`. Reaproveita o `diario.jsonl` já existente; o `catalogo.csv` será re-derivado a partir dele ou re-inventariado.
2. **Re-derivar `catalogo.csv` do `diario.jsonl`** (lendo os eventos `arquivo_novo` e complementando com metadados de cada PDF). Requer SHA-256 e tamanho_bytes de cada arquivo.
3. **Autorizar o usuário a executar a suíte apropriada** fora desta sessão (a sessão atual está rodando sob Ollama/Claude Code; o usuário decide o ritmo).

**Nenhuma destas opções será executada sem autorização explícita**, conforme a regra de não investigar o incidente.

## Como aplicar

- Toda nova leitura de `catalogo.csv` que retorne 0 não é bug da CLI; é esta pendência.
- Antes de prosseguir com Etapa B/C/D da Biblioteca Viva, **esta pendência precisa ser resolvida**.
- O incremento de CLI está **pronto** — quando o catálogo tiver linhas, os 19 testes devem passar sem novo código.
