# INCIDENTE 2026-08-21 — DESTRUIÇÃO DO ESTADO LOCAL EM `dados/`

**Status:** REGISTRADO · RECUPERAÇÃO PENDENTE DE AUTORIZAÇÃO
**Registrado em:** 2026-08-21 ~18:2x · Sessão CLI V0 · HEAD no momento do registro: `c589c74` (tree limpa)

---

## O que aconteceu

Durante a regressão da CLI V0, executei as suítes antigas (`teste-v01`, `teste-fase-b`, `teste-fase-c`) contra o repositório real. Essas suítes foram escritas quando `biblioteca-viva/dados/` era estado local descartável e **operam destrutivamente sobre os caminhos reais**:

| Suíte | Evidência | Ação destrutiva |
|---|---|---|
| `teste-fase-b.ps1` | linhas 61–64 (setup) e 250–251 (limpeza) | apaga o **`catalogo.csv`** e o **`diario.jsonl` reais** via `Get-BvArquivoCatalogo/Diario` |
| `teste-fase-c.ps1` | `Remove-BvDadosLocais`, linhas 49–56, chamada na 69 | apaga catálogo, diário e as pastas reais `extracoes\` e `classificacoes\` |
| `teste-v01.ps1` | teste 05 | espera catálogo **vazio** no caminho real (falhou com 45 linhas na 1ª rodada; "passou" após o wipe) |

Ordem executada às ~18:11–18:13: v01 → fase-b → fase-c. O wipe ocorreu às **18:12:29** (mtime de `catalogo.csv`).

## Dano

**Perdido (sem backup — `dados/` é gitignored):**
- `catalogo.csv` com 45 linhas (27 inventariado, 16 _REVISAR, 1 _PROBLEMAS, 1 classificado)
- `diario.jsonl` com 46 eventos (inventário de 2026-08-21 01:48 + evento `classificado`)
- `extracoes/ecd9dca366af.txt` + `.json`
- `classificacoes/lote-smoke-1.jsonl`

**Intacto:**
- Os 45 PDFs originais em `G:\Documentos_Todos\PDFs\Projeto PDFs` (jamais tocados pelo pipeline)
- Todo o código versionado em Git (núcleo A/B/C, protótipo, CLI V0, especificação V1)
- `esquema.json`

## Recuperabilidade (análise, nada executado)

1. **Catálogo**: ids são prefixo SHA-256 (12 primeiros chars) → re-inventário via pipeline A/B existente reproduz os **mesmos ids** e metadados técnicos; statuses `_REVISAR`/`_PROBLEMAS` devem ser re-derivados pelas mesmas regras do inventário original.
2. **Classificação smoke-1** (`ecd9dca366af` → `academico_tecnico`, confiança 0.98): recuperável integralmente — registro completo preservado nesta sessão; cache de extração se regenera do PDF.
3. **Irrecuperável**: linha do tempo histórica do diário (timestamps originais dos eventos).

## Próximos passos combinados (PENDENTES — aguardando ordem)

1. **Recuperar o catálogo real** a partir dos 45 PDFs (re-inventário) e conferir 45/45 ids idênticos.
2. Reaplicar a classificação `smoke-1`.
3. **Corrigir o isolamento das suítes** (fase-a/b/c): injetar sandbox de config (padrão já existente nos mocks) para que nenhuma suite jamais aponte para `dados/` real.
4. Registrar evento de incidente/recuperação como primeiro(s) evento(s) do novo diário.

## Regra nova decorrente (a ratificar)

Nenhuma suíte de teste pode executar `Get-*`/`Save-*`/`Remove-*` contra `biblioteca-viva/dados/` real. Toda suíte recebe config de sandbox injetada. Antes de qualquer regressão futura: auditar os setups à procura de caminhos reais.

---
*Nenhum comando foi executado além da leitura para este registro. Nenhum commit feito.*
