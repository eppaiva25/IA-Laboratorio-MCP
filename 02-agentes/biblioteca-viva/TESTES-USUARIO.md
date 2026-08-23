# TESTES-USUARIO — Registro Histórico da Fase de Testes (Biblioteca Viva V2)

**Natureza:** documento histórico e operacional. Registra o caminho completo
`V1 baseline → primeiros testes → erros observados → O1–O5 → arquitetura V2 →
DA1/DA7 → O5 → O1 → O3 → início dos testes do usuário`, baseado exclusivamente
em commits, logs, testes executados e documentos existentes no repositório.
Conclusões não derivam de expectativa do agente: cada afirmação aponta para a
evidência que a sustenta. Conflitos entre relatório e evidência são registrados
como conflito.

---

## 1. Identificação da fase

| Campo | Valor |
|---|---|
| Projeto | Biblioteca Viva (`02-agentes/biblioteca-viva`) |
| Fase atual | V2, pós-Etapa 3 — **início dos TESTES DO USUÁRIO** |
| Data | 2026-08-22 |
| Baseline V1 | commit `5e424fe` ("fecha Biblioteca Viva como aplicação final") |

Princípio arquitetural preservado em todas as etapas:

```
IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA
```

Estado atual da V2: Etapas 0 (DA1+DA7), 1 (O5), 2 (O1) e 3 (O3) implementadas e
validadas com experimentos próprios. O2 e O4 **não iniciadas**. Nenhuma corrida
real foi reprocessada; todos os experimentos V2 usaram cópias em diretório
temporário e modo `simular`.

## 2. Baseline V1

- Commit `5e424fe`. Documentos que a definem: `BASELINE.md`, `ESTADO-FINAL.md`,
  `README.md`.
- Garantias (formalizadas depois como I1–I8): dry-run por padrão; pré-voo
  bloqueante antes de agir; nunca sobrescrever (sufixo `-1`,`-2`…); nunca apagar;
  auditoria JSONL append-only; movimentação 100% determinística; IA restrita ao
  contrato `propor(percepcao, categorias)`; só stdlib obrigatória (`pypdf`
  permanece opcional).
- Movimentação: `_mover_sem_sobrescrever()` (`nucleo.py`) via `shutil.move`,
  colisão resolvida por sufixo numérico.
- Validação: `_validar_proposta()` normaliza a categoria, casa contra a lista
  exata de folhas (`_casar_com_catalogo`), rejeita categoria inexistente e aplica
  limiar de confiança (default 60%) rebaixando para `Outros`.
- Verificação pós-movimento (tripla): destino existe + origem vazia +
  SHA-256 idêntico; falha ⇒ `falha_verificacao`; nada é apagado.
- Auditoria: evento JSONL por arquivo (`arquivo_processado`) com ciclo
  PERCEBER/DECIDIR/AGIR/VERIFICAR + início/fim e erro de IA isolado (erro de IA
  nunca move arquivo).
- Modelo usado nos testes da baseline (registrado nos eventos):
  `4skl/gemma4-e4b-mtp:latest`, por detecção automática no Ollama local.
- Reproduzir: `git checkout 5e424fe` + comandos de `ESTADO-FINAL.md`; porta
  única `entrar.py --entrada <pasta> --biblioteca <pasta>
  --catalogo dados/catalogo_exemplo.json --modo simular|organizar`
  (default seguro: `simular`).

## 3. Problemas encontrados nos primeiros testes (L1–L5 → O1–O5)

Fonte primária: `V2-OPORTUNIDADES.md` (baseado nos logs reais dos 45 PDFs em
`G:\Documentos_Todos\PDFs\Projeto PDFs`; nenhum número reinterpretado).

| ID | Problema observado | Evidência registrada | Impacto | Oportunidade | Estado |
|---|---|---|---|---|---|
| L1 | Taxonomia insuficiente | 27/45 (60%) `Outros` no dry-run; 19/34 (56%) no organizar; proposta válida `Documentos/Viagens` REJEITADA (`Visita Natal`) | maioria genérica; caso válido perdido | **O1** ampliar/refinar taxonomia | Implementada e validada (Etapa 2) |
| L2 | Baixa confiança sem tratamento dedicado | 25 propostas <60% viraram `Outros` executado sem marcação; `ajuste_do_sistema` nunca disparou (0 ocorrências) | movimento discutível sem sinalização | **O2** política de risco (`marcar`/`reter`/`executar`) | Não iniciada |
| L3 | Extração inutilizável enviada à IA | mojibake de `Visita Natal Junho 2014_6.pdf` enviado integralmente como percepção | ruído como insumo de decisão | **O3** detectar extração inutilizável e sinalizar | Implementada e validada (Etapa 3) |
| L4 | Decisões discutíveis + não-determinismo | mesmos arquivos, destinos diferentes entre corridas mesmo com `temperature=0` (`Coima Carro Centauro` 20%→90%; `manual.pdf`; `TesePolimeros`) | arrependimento sem revisão | **O4** revisão analítica pós-execução | Não iniciada |
| L5 | Operação de corridas longas | corrida `130907` interrompida em 11/45; retomada manual nova; sem consolidação entre logs | incidente operacional | **O5** consolidação de parciais | Implementada e validada (Etapa 1) |

Limitações adicionais herdadas de `BASELINE.md` permanecem válidas.

## 4. Arquitetura V2 (resumo de `V2-ARQUITETURA.md`)

### Invariantes

- **I1** IA apenas propõe; jamais executa, move, apaga ou decide sozinha.
- **I2** Movimentação exclusiva e determinística do código.
- **I3** Dry-run por padrão; pré-voo bloqueante antes de qualquer ação.
- **I4** Nunca sobrescrever (`-1`,`-2`…); nunca apagar.
- **I5** Auditoria append-only; filesystem é a fonte do estado real.
- **I6** Desacoplamento de fornecedor: contrato único `propor(percepcao, categorias)`.
- **I7** Somente biblioteca padrão obrigatória.
- **I8** Toda corrida V2 reproduzível e comparável contra a baseline.

### Requisitos

- **R1** preservar princípio central + I1–I8 · **R2** incorporar O1–O5 sem perder
  garantias da V1 · **R3** cada oportunidade isolada, validação própria antes da
  seguinte · **R4** default V2 = comportamento V1; novidades opt-in · **R5**
  auditoria aditiva (leitores v1↔v2 compatíveis) · **R6** nenhuma fonte dupla de
  verdade · **R7** políticas novas por configuração explícita registrada em evento.

### Decisões

- **DA1** eventos `versao_esquema: 2` aditivos; `catalogo_sha256` por evento;
  verificador lê v1 e v2. *(implementada)*
- **DA2** catálogo = dado versionado; expansão por edição de JSON; `--catalogo`
  como perfis. *(implementada via O1)*
- **DA3** fase determinística POLÍTICA DE RISCO entre DECIDIR e AGIR
  (`executar` \| `marcar` \| `reter`). *(planejada para O2 — não implementada)*
- **DA4** qualidade de leitura como campo aditivo da percepção, sem OCR.
  *(implementada via O3)*
- **DA5** revisão pós-execução começa analítica/offline. *(O4 — não implementada)*
- **DA6** consolidação baseada no filesystem; log só para relatório.
  *(implementada via O5)*
- **DA7** comparador V1×V2 fora do runtime por `hash_sha256`. *(implementada)*

### Hipóteses (formulação original)

**H1** taxonomia maior reduz `%Outros` sem aumentar propostas inválidas ·
**H2** heurística simples distingue texto inutilizável com poucos falsos negativos
em português · **H3** retidos em quarentena serão efetivamente revisados ·
**H4** `marcar`/`reter` reduzem arrependimentos sem paralisar corridas ·
**H5** segundo modelo revisor agregaria valor (fora da V2).

### Ordem planejada e justificativa

```
DA1 + DA7 → O5 → O1 → O3 → O2 → O4
```

Primeiro instrumentar medição (sem comparador nada é comparável à baseline);
depois operação segura (consolidação destrava experimentos longos); depois
melhorar o insumo da decisão (O1/O3 alteram propostas e precedem políticas que
consomem confiança); só então alterar comportamento de execução (O2 — primeira
mudança real de movimento físico); por último a revisão (O4 amadurece sobre
eventos reais das etapas 2–4).

## 5. Etapa 0 — DA1 + DA7

### DA1 (eventos V2 aditivos)

- `pre_voo.py`: calcula e devolve `catalogo_sha256` (+8 linhas).
- `nucleo.py`: eventos novos com `"versao_esquema": 2`; `_evento()` injeta
  `catalogo_sha256` centralmente (+12/−4 linhas).
- `testes/verificar_resultado.py`: aceita `{1,2}` — leitor único v1/v2 (R5).
- Compatibilidade: apenas campos novos; verificador atual produz saída
  byte-idêntica à do commit `5e424fe` sobre o log `124100` (conferido na Etapa 3).
- Testes: `python -u testes/teste_eventos_v2.py` → OK (8 verificações;
  `linhas totais=4 arquivos=2 iniciada=1 concluida=1 falhas_auditoria=0`).
- Log real: `python -u testes/verificar_resultado.py eventos/eventos_20260822_131519.jsonl`
  → rc=0 (34/34).

### DA7 (comparador fora do runtime)

- Criado `testes/comparador_corridas.py`: offline, somente leitura,
  determinístico; identidade por `hash_sha256` (nunca por nome); classes
  `mesma_decisao` (sinaliza divergência de confiança), `decisao_diferente`
  (dimensões `[categoria, destino, confianca, status]`),
  `somente_na_corrida_A/B`, `informacao_insuficiente`; hash completo impresso.
- Testes: `python -u testes/teste_comparador.py` → OK (15 verificações).
- Logs reais: `124100 × 131519` → 33 entradas divergentes, incluindo 6 por
  categoria, 11 `somente_na_corrida_A`, 1 `informacao_insuficiente`.

Modificados na Etapa 0: `nucleo.py`, `pre_voo.py`, `testes/verificar_resultado.py`.
Criados: `testes/comparador_corridas.py`, `testes/teste_comparador.py`,
`testes/teste_eventos_v2.py`.

## 6. Etapa 1 — O5 (consolidação de corridas parciais)

- Objetivo: cruzar N logs históricos com o filesystem atual em um relatório de
  estado (resolve L5). Arquitetura DA6: ferramenta externa em `testes/`, fora do
  caminho crítico; reusa o comparador (correlação por hash),
  `pre_voo.listar_arquivos` e `modulos.calcular_hash`.
- **Princípio: o FILESYSTEM é a única fonte do estado físico.** Evento `movido`
  só vira `movido_confirmado` após a tríade V1 refeita NAQUELE MOMENTO
  (destino existe + origem vazia + SHA-256 idêntico). Classes:
  `movido_confirmado`, `ainda_na_origem`, `retido_na_origem`, `sem_evento`,
  `inconsistente`, `informacao_insuficiente`.
- Comportamento SOMENTE LEITURA: sem rede, sem IA, sem escrita/exclusão
  (auditado por snapshot antes/depois + varredura de tokens proibidos).
- **O5 NÃO EXECUTA RETOMADA AUTOMÁTICA**: não move nada, não chama o agente,
  não decide pelo log; lista pendentes para decisão humana.
- Testes: `python -u testes/teste_consolidacao.py` → **18/18 OK**
  (12 casos exigidos + integridade de disco/logs + ausência de tokens de
  IA/rede/escrita/exclusão).
- Validação real (somente leitura):
  - Consolidando `130907 + 131519`: 45/45 `movido_confirmado`, 0 pendentes,
    0 inconsistências (origem real já vazia; biblioteca intacta).
  - Só `130907`: 11 confirmados, 0 pendentes — a ferramenta não inventa estado
    sobre os 34 arquivos que só aparecem no log seguinte.
  - `Get-FileHash` dos logs antes/depois: idênticos (nenhuma mutação).
- Criados: `testes/consolidar_corrida.py`, `testes/teste_consolidacao.py`.
  Nenhum arquivo rastreado foi modificado nesta etapa.

## 7. Etapa 2 — O1 (taxonomia expandida, DA2)

- Entrega: `dados/catalogo_v2.json` — **apenas dado**, zero diff de código,
  ativação por `--catalogo` (**opt-in**, R4). Catálogo original intocado.
- Expansão **9 → 13 folhas**; **`Outros` preservado** (obrigatório).
- Adicionadas com lastro no log `124100`: `Documentos/Viagens` (proposta válida
  rejeitada na baseline + 2 mal alocados), `Documentos/Acadêmico`
  (~12 acadêmicos/científicos), `Documentos/Digitalizados` (~9 ilegíveis/
  mojibake), `Tecnologia/Manuais` (~4–5 manuais).
- Recusadas (motivo em `VALIDACAO-O1.md`): `Receitas`, `Jurídico` — evidência de
  arquivo único; risco H1 de dispersão.
- Origem dos 45 arquivos para replay: reconstruída em diretório temporário por
  CÓPIA dos `destino_real` dos logs `130907`/`131519`, com **SHA-256 conferido
  45/45** contra o log `124100`. Biblioteca real e logs históricos intocados.
- Modelo fixado nos dois replays: `4skl/gemma4-e4b-mtp:latest` (`--modelo`).
- Replay A (controle, `catalogo_exemplo.json`, log `193119`): **60% Outros** —
  igual à baseline (**60% Outros**); controle confirmado; reproduziu a rejeição
  do caso conhecido (`Visita Natal`). Primeira tentativa interrompida em 43/45
  por timeout (log `191511`, mantido como histórico descartado) e reexecutada
  do zero.
- Replay B (`catalogo_v2.json`, log `193807`): `%Outros`=**6,7%** (3/45);
  `nao_decidido_erro_ia` 0 (A tinha 1); propostas inválidas 0 (A tinha 1);
  origem intacta 45/45; comparador A×B = 16 mesma_decisao / 28
  decisao_diferente(categoria) / 1 informacao_insuficiente; caso conhecido
  resolvido: `Visita Natal → Documentos/Viagens (95%)`. Metas declaradas ANTES
  do experimento (%Outros ≤ 45% etc.) todas atendidas — ver `VALIDACAO-O1.md`.
- Testes: `python -u testes/teste_catalogo_v2.py` → **15/15 verificações OK**
  (leitor V1, folhas, casamento, anti-traversal, materialização, limiar).
- **Registro expresso: `H1 não confirmada`.** Nota para não haver conflito
  silencioso: `VALIDACAO-O1.md` registra meta experimental atendida no único
  replay (60%→6,7%; 0 inválidas). Trata-se de réplica única com modelo
  não-determinístico; a posição operacional vigente é NÃO ampliar taxonomia
  agora, e H1 permanece não confirmada até réplicas independentes. Ambos os
  fatos coexistem neste registro.

## 8. Etapa 3 — O3 / DA4 (qualidade de leitura)

Registro integral em `VALIDACAO-O3.md` (já corrigido conforme seção 9).

- **Hipótese H2**: heurística simples distingue texto inutilizável (mojibake)
  com poucos falsos negativos em português.
- **Calibração sem código novo**: métricas determinísticas sobre os textos dos
  45 PDFs do log `124100` (mesma via de extração da V1); rótulos ruins
  derivados dos motivos registrados pela própria IA — 10 casos ruins conhecidos.
- **Métricas analisadas**: %letras, %vogais/letras, %tokens-sem-vogal,
  %tokens≤2 caracteres, tamanho do texto. Todas com sobreposição bons×ruins.
  Descoberta central: **separação perfeita é impossível com métricas simples**
  — `Visita Natal` (ruim) e `2014 Docs Multas Seguro` (bom) são estatisticamente
  gêmeos; recibos escaneados legítimos imitam a assinatura do mojibake.
  Consequência: regra conservadora multi-sinal otimizada para ZERO falso
  negativo (aceitando falsos positivos sinalizados).
- **Limiares definidos e justificativa empírica**:

| Sinal | Regra determinística | Justificativa empírica |
|---|---|---|
| `sem_texto` | n = 0 caracteres | Novo_Layout, ziperes_ipiranga |
| `texto_insuficiente` | 0 < n < 50 | menor texto bom real tem 78 chars (`Vacina Gripe`) |
| `mojibake_esparso` | %tokens≤2 ≥ 90 E %vogais/letras < 42 | Visita Natal (93,3%; 40,4); poupa Vacina Gripe (100%; 46,5) e Quinoa (93,8%; 44,0) |
| `estatistica_atipica` | %vogais/letras < 34 E %tokens_sem_vogal ≥ 20 E %letras ≤ 50 | cluster Cemitério/Coima/JOSUE/Digitalizado×3/sermão; poupa CERTIDAO (vogais 19,6 mas tokens-sem-vogal 9,1) |

Constantes nomeadas em `modulos/__init__.py`: `MINIMO_CARACTERES_UTEIS = 50`,
`LIMITE_TOKENS_CURTOS = 90.0`, `LIMITE_VOGAIS_ESPARSO = 42.0`,
`LIMITE_VOGAIS_ATIPICO = 34.0`, `LIMITE_TOKENS_SEM_VOGAL = 20.0`,
`LIMITE_LETRAS_ATIPICO = 50.0`.

- **Implementação**: `modulos/__init__.py` (+54 linhas): função pública
  `avaliar_qualidade(texto)` + constantes acima + `percepcao_para_pedido()`;
  `perceber()` ganha 3 campos ADITIVOS (`conteudo_caracteres`,
  `conteudo_confivel`, `conteudo_sinalizacao`); o `conteudo` original continua
  integral no evento (auditoria). `modelos_ia.py` (+4): `propor()` monta o
  pedido via `percepcao_para_pedido()`. **`nucleo.py`: ZERO diff nesta etapa.**
- **Comportamento**: percepção confiável ⇒ pedido idêntico ao padrão anterior;
  não confiável ⇒ `conteudo=null` + aviso para decidir pelo nome/metadados.
  A saída da IA continua sendo apenas proposta; validação/execução intactas;
  nenhum tratamento especial de execução foi criado.
- **Caso Visita Natal** no experimento: sinalizada como `mojibake_esparso`;
  sem conteúdo, a IA decidiu pelo nome do arquivo → propôs `Fotos/Viagens`
  (85%), executada em modo simular. Comportamento coerente com o desenho
  (a IA decide com o que tem; a sinalização torna o risco visível na auditoria).
- **Experimento A×C** (mesmos 45 arquivos copiados; mesmo modelo):
  - Perna A (controle): reuso do replay `193119` da Etapa 2 — sem reexecução,
    sem custo adicional.
  - Perna C (código atual, log `201923`): 27 percepções confiáveis /
    18 sinalizadas (6 mojibake_esparso, 10 estatistica_atipica,
    2 sem_texto); os 10 casos ruins conhecidos: **10/10 detectados**;
    retro-verificação do controle: 18/45 idêntico ao histórico.
  - Comparador A×C: **40 mesma_decisao**, 3 decisao_diferente(categoria),
    2 informacao_insuficiente — detalhado na seção 9.
- **Falsos positivos colaterais aceitos (8)**: `2014 Docs Multas Seguro`,
  `Aspirador Robô` (×2), `Amostras Turquia`, `Fotos Antigas`, `Comprovantes`,
  `Power Bank`, `Recibo_Consulta` — sinalizados, não bloqueados.
  Falsos negativos: 0.
- **H2**: parcialmente sustentada — separa todos os casos-alvo conhecidos
  (FN=0) ao custo de FPs declarados; separação PERFEITA provada impossível
  nesses dados.
- Testes: `python -u testes/teste_qualidade_leitura.py` → **16/16 verificações
  OK** (casos reais do corpus + fixtures sintéticos + campos aditivos +
  comportamento do pedido).

## 9. Inconsistência detectada e verificada no relatório O3

**O que foi reportado pelo usuário:** em `VALIDACAO-O3.md`, a frase
"40/45 desfechos idênticos entre A e C" implica 5 divergências, mas o texto dizia
"4 divergências de categoria" enquanto enumerava **5 arquivos**.

**Verificação exigida e executada (sem alterar código):**

1. Comparador reexecutado sobre os logs reais `193119` (A) × `201923` (C):
   `40 mesma_decisao`, `3 decisao_diferente`, `2 informacao_insuficiente`
   → soma 45/45; logo são **5 desfechos diferentes**, não 4.
2. Conferência caso a caso por hash SHA-256 (script temporário somente leitura)
   — os 5 casos enumerados no documento estavam todos corretos:
   - `decisao_diferente` (categoria): Amostras Turquia Financiamento BPI
     (`Financeiro→Outros`), Recibo_Consulta (`Financeiro→Pessoal`),
     Comprovantes de Despesas (`Financeiro→Pessoal`).
   - `informacao_insuficiente`: Visita Natal (retida na origem em A / decidida
     para `Fotos/Viagens` em C) e Bilhete Paiva (decidida em A / retida em C).

**Correção aplicada apenas ao documento `VALIDACAO-O3.md`:** a linha da tabela
passou a registrar "5 arquivos = 3 decisao_diferente (categoria) +
2 informacao_insuficiente" e cada item da lista recebeu sua classe real do
comparador. Nenhum `.py`, log ou dado foi alterado.

**Registro do conflito:** o erro era de REDAÇÃO do relatório (contagem),
não dos dados nem das ferramentas — comparador, logs e hashes sempre apontaram
40/3/2.

## 10. Fase atual — testes do usuário

- Componentes disponíveis para uso prático:
  - Porta única: `entrar.py --entrada <pasta> --biblioteca <pasta>
    [--catalogo dados/catalogo_exemplo.json|dados/catalogo_v2.json]
    [--modelo <tag>] [--limiar-confianca N] --modo simular|organizar`
    (default: modo `simular`, catálogo V1 = comportamento V1).
  - Catálogo expandido opt-in: `--catalogo dados/catalogo_v2.json`.
  - Sinalização automática de extração inutilizável (DA4/O3) ativa na
    percepção/auditoria, sem mudar comportamento de execução.
- Ferramentas auxiliares fora do runtime (somente leitura):
  `testes/comparador_corridas.py`, `testes/consolidar_corrida.py`,
  `testes/verificar_resultado.py`.
- Comportamentos V1 preservados por padrão: dry-run, pré-voo bloqueante,
  nunca sobrescrever/apagar, auditoria JSONL append-only.
- Validado automaticamente até aqui: bateria completa de testes (seção 11),
  experimentos controlados A×B (O1) e A×C (O3), retro-verificação byte-a-byte
  contra logs históricos.
- Pendente de avaliação PRÁTICA pelo usuário: utilidade real dos sinais O3 na
  rotina, legibilidade dos relatórios, decisão sobre quando usar
  `catalogo_v2.json`.
- Critérios formais de aceitação do usuário ainda não definidos.
- Próxima etapa arquitetural planejada: **O2 — Política de Risco**
  (`executar|marcar|reter` entre DECIDIR e AGIR). O2 ainda NÃO implementada;
  nada desta fase depende dela.

## 11. Registro de comandos (todos executados em pwsh, a partir da raiz do projeto)

```powershell
# Estado do repositório
git status --porcelain -- 02-agentes/biblioteca-viva
git diff -- 02-agentes/biblioteca-viva
git diff 5e424fe --stat -- 02-agentes/biblioteca-viva

# Bateria de testes (todas com rc=0 nas versões atuais)
python -u testes/teste_erro_ia.py
python -u testes/teste_comparador.py            # 15 verificações OK
python -u testes/teste_eventos_v2.py            # 8 verificações OK
python -u testes/teste_consolidacao.py          # 18/18 OK
python -u testes/teste_catalogo_v2.py           # 15/15 OK
python -u testes/teste_qualidade_leitura.py     # 16/16 OK

# Verificação de log (leitor v1/v2)
python -u testes/verificar_resultado.py eventos/eventos_20260822_131519.jsonl   # rc=0 (34/34)
python -u testes/verificar_resultado.py eventos/eventos_20260822_124100.jsonl   # rc=1 CONHECIDO:
#   sinaliza "simulado sem destino" — comportamento idêntico ao verificador da
#   baseline 5e424fe sobre este mesmo log (conferido byte-a-byte na Etapa 3).

# Comparador offline (somente leitura)
python -u testes/comparador_corridas.py eventos/eventos_20260822_124100.jsonl eventos/eventos_20260822_131519.jsonl
python -u testes/comparador_corridas.py eventos/eventos_20260822_193119.jsonl eventos/eventos_20260822_193807.jsonl   # A×B (O1)
python -u testes/comparador_corridas.py eventos/eventos_20260822_193119.jsonl eventos/eventos_20260822_201923.jsonl   # A×C (O3)

# Consolidação (somente leitura)
python -u testes/consolidar_corrida.py --entrada "G:\Documentos_Todos\PDFs\Projeto PDFs" eventos/eventos_20260822_130907.jsonl eventos/eventos_20260822_131519.jsonl

# Integridade de logs
Get-FileHash eventos\eventos_20260822_*.jsonl -Algorithm SHA256

# Corrida real (exemplo; dry-run por padrão é --modo simular)
python -u entrar.py --entrada "<pasta-origem>" --biblioteca "G:\Documentos_Todos\Biblioteca" --catalogo dados/catalogo_v2.json --modo simular
```

Observação: os replays A/B/C foram executados com origem reconstruída por cópia
em `%TEMP%\opencode\o1_replay\entrada` (SHA conferido 45/45 contra o log
`124100`) e `--modelo 4skl/gemma4-e4b-mtp:latest`.

## 12. Estado atual do código

| Componente | V1 (5e424fe) | V2 (atual) | Estado |
|---|---|---|---|
| `nucleo.py` | base | + eventos v2 (`versao_esquema`, `catalogo_sha256`) | Modificado (Etapa 0); intocado desde então |
| `pre_voo.py` | base | + hash do catálogo no pré-voo | Modificado (Etapa 0) |
| `modelos_ia.py` | base | + pedido filtrado por qualidade (`percepcao_para_pedido`) | Modificado (Etapa 3, +4 linhas) |
| `modulos/__init__.py` | base | + `avaliar_qualidade`, constantes O3, campos aditivos da percepção | Modificado (Etapa 3, +54 linhas) |
| `modulo_pdf.py` | extração pypdf opcional | inalterado | Igual à V1 |
| `dados/catalogo_exemplo.json` | catálogo default (9 folhas) | inalterado (default = V1, R4) | Igual à V1 |
| `dados/catalogo_v2.json` | não existia | 13 folhas, opt-in via `--catalogo` | Novo (Etapa 2, apenas dado) |
| `testes/verificar_resultado.py` | leitor v1 | lê esquemas {1,2} | Modificado (Etapa 0) |
| `testes/comparador_corridas.py` | não existia | comparador offline DA7 | Novo |
| `testes/consolidar_corrida.py` | não existia | consolidação O5 (DA6) | Novo |
| Testes automatizados | 1 (`teste_erro_ia`) | +5 suítes novas | Novos |

Diff total rastreado vs baseline: 5 arquivos modificados (~+75/−7 linhas);
resto são arquivos novos (docs, dados, testes, logs).

## 13. Estado das oportunidades

| ID | Oportunidade | Prioridade | Esforço | Impacto esperado | Riscos | Dependências | Status |
|---|---|---|---|---|---|---|---|
| O1 | Ampliar/refinar taxonomia | Alta | Baixo (dado) | Reduz `%Outros`; menos genérico | Dispersão se crescer sem critério (H1) | Nenhuma | **Concluída** (Etapa 2; uso opt-in) |
| O2 | Política de risco (`executar/marcar/reter`) | Alta | Médio | Menos arrependimento em baixa confiança | Mudar comportamento de execução; exige configuração explícita (R7); H3/H4 dependem de uso real | DA3; consome confiança e sinais de O1/O3 | **Não iniciada** |
| O3 | Detectar extração inutilizável | Alta | Médio | IA não decide por lixo sem aviso | Falsos positivos sinalizados (8/45 aceitos); separação perfeita impossível | Nenhuma | **Concluída** (Etapa 3) |
| O4 | Revisão pós-execução analítica | Média | Alto | Corrigir não-determinismo pós-fato | Escopo grande; melhor após eventos reais acumulados | DA5; eventos das etapas 2–4 | Não iniciada |
| O5 | Consolidação de corridas parciais | Alta | Médio | Operação segura de corridas longas | Ferramenta somente leitura; não retoma sozinha (por desenho) | DA6; comparador DA7 | **Concluída** (Etapa 1) |

## 14. Estado das hipóteses

| Hipótese | Formulação | Estado atual | Evidência / próximos passos |
|---|---|---|---|
| H1 | Taxonomia maior reduz `%Outros` sem aumentar propostas inválidas | **Não confirmada** (posição operacional vigente) — ver conflito registrado na seção 7 | Único replay: 60%→6,7% Outros, 0 inválidas (`193119`×`193807`); réplica única, modelo não-determinístico. Próximo passo: réplicas independentes antes de ampliar mais a taxonomia |
| H2 | Heurística simples distingue texto inutilizável com poucos falsos negativos | Parcialmente sustentada | 10/10 ruins conhecidos detectados, FN=0; 8 FP colaterais declarados; separação perfeita provada impossível no corpus (`VALIDACAO-O3.md`) |
| H3 | Arquivos retidos em quarentena serão efetivamente revisados | Ainda não testada — dados insuficientes para verificar | Depende do mecanismo `reter` da O2 (não implementada) e de uso real |
| H4 | `marcar`/`reter` reduzem arrependimentos sem paralisar corridas | Ainda não testada — dados insuficientes para verificar | Depende da O2 (não implementada) |
| H5 | Segundo modelo revisor agregaria valor | Fora do escopo da V2; não testada | Reservada para investigação futura |

## 15. Reproducibilidade

- **Baseline**: commit `5e424fe` (`git checkout 5e424fe`; comandos em
  `ESTADO-FINAL.md`).
- **Catálogos**: `dados/catalogo_exemplo.json` (V1, default) e
  `dados/catalogo_v2.json` (13 folhas, opt-in). O hash de cada catálogo vai
  dentro de cada evento (`catalogo_sha256`) — não há ambiguidade sobre qual
  taxonomia produziu cada decisão.
- **Modelo**: `4skl/gemma4-e4b-mtp:latest` via Ollama local (~20 s/arquivo).
  Limitação conhecida: respostas não-determinísticas entre corridas mesmo com
  `temperature=0`.
- **Origem dos replays**: reconstrução por CÓPIA a partir dos `destino_real`
  registrados nos logs `130907`/`131519`, validada por SHA-256 45/45 contra o
  log `124100` (procedimento na seção 11; scripts de apoio ficaram em
  `%TEMP%\opencode` e não fazem parte do repositório).
- **Quantidades**: 45 PDFs; logs históricos `124100`, `130907`, `131519`;
  experimentos `193119` (A/O1), `193807` (B/O1), `201923` (C/O3);
  `191511` = tentativa interrompida, mantida como histórico descartado.
- **Ferramentas**: apenas Python stdlib + git + pwsh; `pypdf` opcional para
  extração.
- **Resultados esperados** ao reproduzir: testes da seção 11 determinísticos
  (mesma saída); experimentos com IA variam nas decisões individuais, mas os
  invariantes (origem intacta, zero sobrescrita/exclusão, auditoria completa)
  devem sempre se manter.
- **Âncoras de integridade** (SHA-256 prefixos no fechamento desta fase):
  log `124100` = `7647003F77BFD74B…`, `193119` = `53273F672182746D…`,
  `201923` = `29686B5E47AE6096…`. Biblioteca real intocada durante toda a V2.

## 16. Proteções vigentes (o que este registro NÃO permite)

- Nenhuma corrida real foi reprocessada pela V2; biblioteca e origem reais são
  somente leitura em todos os procedimentos documentados.
- Logs do diretório `eventos/` são append-only e nunca editados; integridade
  conferível pelos hashes acima.
- Ferramentas V2 (`comparador`, `consolidar`, `verificar_resultado`) são
  somente leitura por desenho e auditadas quanto a isso.
- Modo `organizar` só age após pré-voo bloqueante; default é `simular`.

## 17. Próximos passos planejados (não iniciados)

- **O2 — Política de Risco** (DA3): fase determinística entre DECIDIR e AGIR;
  primeira mudança real de comportamento de execução; exige configuração
  explícita registrada em evento (R7). O2 ainda NÃO implementada.
- Em seguida: **O4 — revisão analítica pós-execução** (DA5), amadurecida sobre
  eventos das etapas anteriores.
- Paralelo contínuo: uso prático pelo usuário desta fase de testes e definição
  dos critérios formais de aceitação.

## 18. Conformidade com as regras desta fase

- Documento criado sem alterar nenhum `.py`, nenhum dado, nenhum log.
- Catálogo V1, logs históricos e biblioteca real: intocados.
- O2: não iniciada.
- Nenhum outro documento foi criado nesta fase além deste.

## 19. TESTE FÍSICO REAL DO EXECUTOR — APROVADO (2026-08-23)

Status: **TESTE FÍSICO REAL APROVADO / etapa concluída.**

Contexto: após a implementação do `executar.py` (executor de decisões
simuladas com revisão humana; commits `7126fba` e `d811927`) e da suíte
offline `testes/teste_executor.py` (47/47 verificações, rc=0), o usuário
executou manualmente o primeiro movimento físico real sobre arquivos
pessoais, aprovando item a item pela interface interativa do executor.

### Parâmetros da corrida

- Origem: `G:\Documentos_Todos\ProjetoArgMistos`
- Destino (biblioteca): `G:\Documentos_Todos\Biblioteca-Teste-V2`
- Log de simulação (fonte das decisões): `eventos/eventos_20260822_223745.jsonl`
- Log de execução (produzido nesta etapa):
  `eventos/eventos_20260823_012441_decisoes.jsonl`
- Tentativa anterior da mesma etapa
  (`eventos/eventos_20260823_011821_decisoes.jsonl`): os 44 itens foram
  recusados pelo usuário já na revisão (`quantidade_aprovada=0`,
  `confirmacao=false`) e a execução encerrou sem nenhum movimento físico;
  mantida como histórico descartado — mesmo critério do log `191511`
  (seção 15).

### Fluxo validado ponta a ponta

SIMULAR → REVISAR → APROVAR/RECUSAR → CONFIRMAR → EXECUTAR → VERIFICAR →
REGISTRAR. Pela primeira vez no projeto, o ciclo completo incluiu movimento
físico real precedido de revisão humana por item e confirmação explícita
(default NÃO) registrada em evento antes do primeiro `shutil.move`.

### Resultado

- 44 decisões lidas do log de simulação;
- 42 aprovadas pelo usuário;
- 2 recusadas pelo usuário;
- 0 bloqueios técnicos (`origem_ausente`, `hash_divergente`,
  `fora_da_biblioteca`, `categoria_invalida`, `estrutura_invalida`);
- 42 movimentos físicos realizados.

### Verificação (verificar_resultado.py)

- 42/42 arquivos processados = OK;
- `falhas_auditoria=0`.

### Consolidação (consolidar_corrida.py)

- `movido_confirmado` = 41;
- `sem_evento` = 2;
- `ainda_na_origem` = 0; `inconsistente` = 0; `informacao_insuficiente` = 0;
- 1 hash SHA-256 repetido colapsado na consolidação.

Interpretação objetiva dos dois números não-triviais:

1. Os 2 `sem_evento` são exatamente os 2 arquivos RECUSADOS pelo usuário na
   revisão: nunca receberam evento físico porque nada foi feito com eles.
   Não representam falha — representam a recusa humana funcionando.
2. A diferença entre 42 movimentos físicos e 41 `movido_confirmado` decorre
   do colapso do par de arquivos byte-idênticos (mesmo SHA-256
   `d09b428955…f155226`) na consolidação: 43 hashes únicos no log, dos quais
   42 têm evento físico e um deles cobre os dois caminhos movidos.

### Garantias observadas durante a execução física

- Cada movimento foi verificado fisicamente pela tríade: **destino existe +
  origem vazia + hash idêntico** (mesmo critério do modo ORGANIZAR).
- Nenhuma nova análise da IA ocorreu: todas as decisões vieram
  exclusivamente do log de simulação, reaproveitadas por `hash_sha256`;
  o campo `modelo` dos eventos físicos registra
  `(nao consultada - decisao reaproveitada)`.
- O log da simulação permaneceu separado e somente leitura (append-only,
  intocado); a execução produziu log de auditoria próprio
  (`eventos_20260823_012441_decisoes.jsonl`), mantendo os dois registros
  auditáveis de forma independente.

### Conformidade desta etapa

- Documentação adicionada sem alterar nenhum código funcional.
- O2/O4: não iniciados.







