# RASCUNHO — NÃO IMPLEMENTAR

> **Status: RASCUNHO — NÃO IMPLEMENTAR.**
> Este documento não constitui aprovação para implementação.
> Registro da próxima etapa candidata do Laboratório de IA, criado em 2026-08-21.
> Ponto de partida técnico: commit `254b399` (Fase C fechada).

---

## Próxima etapa (candidata): Aplicação operacional da Biblioteca Viva

### Objetivo

Criar uma interface operacional simples, inicialmente CLI em PowerShell, para utilizar o
motor da Biblioteca Viva sem depender do agente para cada execução.

A aplicação deverá atuar como camada de operação sobre o núcleo existente, preservando
a arquitetura NÚCLEO + MÓDULOS.

### Princípio fundamental

**A aplicação opera o motor; o agente não é o motor.**

O agente continuará sendo utilizado para desenvolvimento, análise, manutenção e evolução
do projeto, mas a operação normal da Biblioteca Viva deverá poder ser iniciada
diretamente pelo usuário.

### Ciclo a preservar

ANALISAR → PROPOR → AGUARDAR APROVAÇÃO → EXECUTAR → CONFERIR → REGISTRAR

### Funções candidatas

- verificar/inventariar o acervo;
- consultar o catálogo;
- executar extrações;
- selecionar arquivos ou lotes;
- apresentar pré-voo;
- solicitar aprovação humana;
- executar classificação;
- acompanhar progresso;
- apresentar resultados;
- consultar pendências e histórico.

### O que já existe no núcleo × lacunas identificadas

| Função candidata | Já existe no núcleo (commit 254b399) | Lacuna (futura casca ou componente novo) |
|---|---|---|
| verificar/inventariar | `Get-BvDescobertas` + `Invoke-BvReconciliacao` | quase toda — wrapper + resumo legível |
| consultar catálogo | `Get-BvCatalogo`, consultas por caminho/hash/status | filtros compostos e formatação |
| executar extrações | `Invoke-BvExtracaoDeLinha` (cache sha256) | seleção em lote + relatório |
| classificar | `Invoke-BvClassificacaoDeLinha` (`-Ids`, `-Reprocessar`, checkpoint) | parâmetros amigáveis |
| progresso | `-CheckpointACada` + diário | apresentação incremental |
| resultados/pendências/histórico | diário JSONL, `lote-*.jsonl`, statuses `_REVISAR`/`_PROBLEMAS` | consultas agregadas |
| selecionar lotes | parcial (só `-Ids`) | seletor por status/categoria/pasta |
| pré-voo | **não existe como componente** | componente novo: simular ações sem executar |
| aprovação humana | manual via agente | componente novo: confirmar + registrar |

### Observações arquiteturais registradas na análise

1. O ciclo de aprovação já tem leito no esquema v1: colunas `acao_proposta`,
   `destino_proposto`, `aprovado`, `executado_em` e statuses `proposto → aprovado →
   executado` foram desenhados na Fase A para isso. Decisão futura: pré-voo persiste
   propostas no catálogo ou permanece efêmero.
2. A aplicação herda as regras do agente: escrita somente pela porta única
   (`Save-BvCatalogo`), diário append-only, unidade transacional = 1 arquivo, nada
   executa sem aprovação registrada.
3. OpenCode funciona fora do agente: a classificação chama o CLI diretamente —
   operação 100% independente do agente já é viável (validado no smoke test).
4. Decisões de projeto a tomar no planejamento: formato (menu interativo vs
   subcomandos `bv.ps1 <verbo>`), localização (`biblioteca-viva/app/`), granularidade
   da aprovação (por arquivo vs por lote).

### Fora do escopo neste momento

- OCR;
- visão;
- movimentação/renomeação;
- Fase D;
- processamento dos 45 PDFs;
- alterações na Fase C já fechada.

---

*Ponto de partida técnico: commit `254b399`. Rascunho sem valor aprovativo.*
