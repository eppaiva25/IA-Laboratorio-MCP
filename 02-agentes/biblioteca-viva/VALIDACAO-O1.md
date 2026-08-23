# V2 — Validação da Etapa 2 (O1 — Taxonomia Expandida)

**Data:** 2026-08-22
**Natureza:** registro de validação experimental. A implementação de O1 é
**apenas de dado** (DA2): um novo arquivo `dados/catalogo_v2.json`, ativado por
`--catalogo` (opt-in). **Nenhuma linha de código do runtime foi alterada.**
O catálogo original `dados/catalogo_exemplo.json` permanece intocado como baseline.

**Princípio preservado:** `IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA`

---

## 1. Mudança entregue

`dados/catalogo_v2.json` — 9 folhas → 13 folhas; `Outros` mantido.

| Folha nova | Lastro no log real `124100` |
|---|---|
| `Documentos/Viagens` | proposta válida rejeitada por categoria inexistente (`Visita Natal Junho 2014_6.pdf`) + 2 arquivos de viagem mal alocados |
| `Documentos/Acadêmico` | ~12 arquivos acadêmicos/científicos parados em `Outros` |
| `Documentos/Digitalizados` | ~9 arquivos ilegíveis/mojibake (`Digitalizado_*` etc.) |
| `Tecnologia/Manuais` | ~4–5 manuais de produto/software em `Outros` |

Recusados deliberadamente (risco H1 de dispersão; evidência de arquivo único):
`Receitas`, `Jurídico`.

## 2. Meta declarada ANTES do experimento

1. Primária: `%Outros executado ≤ 45%` no replay com catálogo v2 (baseline 60%).
2. Guarda 1: `nao_decidido_erro_ia ≤ 1`.
3. Guarda 2: zero propostas rejeitadas por categoria inexistente.
4. Guarda 3: modo simular ⇒ origem intacta, nada movido/apagado.

## 3. Método (reprodutível)

1. Origem temporária reconstruída por cópia a partir dos `destino_real` dos logs
   `130907`/`131519`, com SHA-256 conferido contra o log `124100`: **45/45 ok**.
   A biblioteca real e os logs históricos não foram tocados.
2. Replay A (controle): `entrar.py --modo simular --catalogo dados/catalogo_exemplo.json`
3. Replay B (teste): idêntico com `--catalogo dados/catalogo_v2.json`
4. Modelo fixado nos dois: `4skl/gemma4-e4b-mtp:latest` (o mesmo da baseline).
5. Logs gerados: `eventos/eventos_20260822_193119.jsonl` (A) e
   `eventos/eventos_20260822_193807.jsonl` (B). Um primeiro A parcial
   (`eventos_20260822_191511.jsonl`, interrompido em 43/45) foi descartado e
   reexecutado do zero.

## 4. Resultados vs meta

| Métrica | Baseline | Replay A | Replay B | Meta | Veredito |
|---|---|---|---|---|---|
| `%Outros` executado | 60,0% (27/45) | 60,0% | **6,7% (3/45)** | ≤45% | **ATENDIDA** |
| `nao_decidido_erro_ia` | 1 | 1 | **0** | ≤1 | ATENDIDA |
| Propostas c/ categoria inexistente | 1 | 1 | **0** | 0 | ATENDIDA |
| Origem intacta | — | ✓ | ✓ (45/45) | intacta | ATENDIDA |

Distribuição do replay B: Acadêmico 14, Financeiro 10, Manuais 7,
Digitalizados 5, Viagens 3, Outros 3, Pessoal 2, Fotos/Família 1.
Caso-known: `Visita Natal Junho 2014_6.pdf → Documentos/Viagens (95%)`
(era a proposta rejeitada na baseline).

Comparador DA7 (A×B): 16 mesma_decisão, 28 decisão_diferente (todas por
categoria), 1 informação_insuficiente, 0 somente_A/B. Nas divergências de
confiança predominou **alta** (sem sinal de dispersão — H1 não se manifestou).
Os 3 `Outros` restantes são resíduos honestos: 2 ilegíveis + 1 receita.

## 5. Testes determinísticos e regressão

- Novo `testes/teste_catalogo_v2.py`: **15/15 OK** (validade no leitor V1,
  folhas, Outros, casamento exato/curto, anti-traversal intacto, materialização,
  limiar de confiança intacto).
- Bateria V1+V2 anterior toda verde após O1:
  `teste_erro_ia`, `teste_comparador`, `teste_eventos_v2`,
  `teste_consolidacao` (18/18), `verificar_resultado` sobre log real (34/34).

## 6. Escopo

- Runtime V1/V2: **zero diff** nesta etapa.
- O2, O3, O4: não iniciados.
- Limitação conhecida mantida: replay depende do modelo local (não-determinismo
  entre corridas persiste, mensurável via comparador — L4 segue aberta para O4).
