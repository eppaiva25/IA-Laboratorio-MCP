# V2 — Proposta Arquitetural (Biblioteca Viva)

**Data:** 2026-08-22
**Natureza:** PROPOSTA apenas. Nenhum código foi criado ou alterado nesta etapa.
Nenhuma organização foi reexecutada.
**Referências:** baseline V1 (`commit 5e424fe`, `BASELINE.md`, `ESTADO-FINAL.md`)
e registro de oportunidades (`V2-OPORTUNIDADES.md`).

---

## 0. Invariantes inegociáveis (herdados da V1, válidos para toda a V2)

```
IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA
```

- **I1** A IA apenas propõe; jamais executa, move, apaga ou decide sozinha.
- **I2** A movimentação de arquivos é responsabilidade exclusiva e determinística
  do código — inclusive nas políticas novas de V2 (quarentena e revisão movem
  tão deterministicamente quanto a V1).
- **I3** Dry-run por padrão; pré-voo bloqueante antes de qualquer ação.
- **I4** Nunca sobrescrever (sufixo `-1`, `-2`…); nunca apagar nada.
- **I5** Auditoria append-only; o filesystem é a fonte do estado real, os eventos
  são o histórico.
- **I6** Desacoplamento de fornecedor: o agente depende só do contrato
  `propor(percepcao, categorias)` (`modelos_ia.py`).
- **I7** Somente biblioteca padrão como dependência obrigatória (`pypdf` segue opcional).
- **I8** Toda corrida V2 deve ser reproduzível e comparável contra a baseline V1.

---

## 1. REQUISITOS (o que a V2 deve cumprir)

| ID | Requisito |
|---|---|
| R1 | Preservar integralmente o princípio central e os invariantes I1–I8 |
| R2 | Incorporar O1–O5 sem alterar garantias de execução segura da V1 |
| R3 | Cada oportunidade implementada isoladamente, com validação própria, antes da seguinte |
| R4 | Comportamento padrão da V2 em modo `organizar` deve ser equivalente ao da V1; novidades ativadas por opção explícita (opt-in), preservando comparabilidade |
| R5 | Novos campos de auditoria devem ser aditivos: logs V1 permanecem legíveis pelos leitores V2 e vice-versa |
| R6 | Nenhuma fonte dupla de verdade: estado real = filesystem; log = auditoria/relatório |
| R7 | Políticas novas (quarentena, revisão) definidas por configuração explícita e registradas em cada evento |

## 2. DECISÕES ARQUITETURAIS PROPPOSTAS (sujeitas a validação experimental)

| ID | Decisão | Justificativa (contra requisitos, não conveniência) | Alternativa descartada |
|---|---|---|---|
| DA1 | Eventos passam a `versao_esquema: 2` **aditiva**: só campos novos opcionais; leitor/verificador passa a aceitar v1 e v2 | R5; permite registrar catálogo usado, política aplicada e sinalizações de revisão sem invalidar a história V1 | Quebrar esquema (invalidaria comparação com baseline) |
| DA2 | Catálogo tratado como **dado versionado**: hash do catálogo gravado em cada evento; expansão feita por edição do JSON, sem código novo; o campo `--catalogo` já existente serve de mecanismo de perfis | O1 é um problema de conteúdo, não de arquitetura; hash garante reprodutibilidade (I8) | Codificar taxonomia no programa (violaría desacoplamento) |
| DA3 | Nova fase determinística **POLÍTICA DE RISCO** entre DECIDIR e AGIR, configurável: `executar` (padrão = comportamento V1) \| `marcar` \| `reter`; registrada no evento | R4+R7; resolve L2 sem mudar o comportamento default; decisão permanece 100% em código (I2) | Enviar dúvida de volta à IA (violava I1/I2) |
| DA4 | Qualidade de leitura como **campo aditivo da percepção** (`conteudo_confivel`, heurística determinística de legibilidade); sem OCR nesta versão | Resolve L3 no ponto certo (antes da proposta); heurística é testável e stdlib | OCR (hipótese cara, dependência nova, adiado para ideias futuras) |
| DA5 | Revisão pós-execução começa **analítica e offline**: ferramenta que lê eventos e destaca casos suspeitos; runtime permanece não-interativo | Não introduz pausas nem poder extra à IA; aproveita que todos os fatos já estão no JSONL (I5) | Modo interativo confirmar-antes-de-mover (complexidade + fadiga; adiado) |
| DA6 | Retomada/consolidação baseada no **filesystem** (origem vazia = processado); log usado apenas para relatório consolidado | R6; evita confiar cegamente no log para decidir o que mover | Estado derivado só do log (criaria segunda fonte de verdade) |
| DA7 | **Comparador V1×V2** fora do runtime: cruza dois logs por `hash_sha256` e reporta divergências de decisão | Instrumento de R4/I8; é pré-condição para validar qualquer etapa da V2 | Comparação manual (não escalável, sujeita a erro) |

## 3. HIPÓTESES (ainda NÃO validadas — não tratar como fatos)

- **H1** Uma taxonomia maior reduzirá o percentual de `Outros` sem aumentar
  propostas inválidas (pode ocorrer o oposto: mais opções -> mais dispersão).
- **H2** Uma heurística simples distingue texto inutilizável (mojibake) com poucos
  falsos negativos em português.
- **H3** Arquivos retidos em quarentena serão efetivamente revisados pelo operador
  (risco comportamental: fila cresce sem dono).
- **H4** `marcar`/`reter` reduzirão arrependimentos de execução sem paralisar
  corridas grandes.
- **H5** Um segundo modelo como revisor cruzado agregaria valor (custo/benefício
  desconhecido; fora da V2).

---

## 4. Análise por oportunidade

### O1 — Ampliar/refinar a taxonomia (resolve L1)

- **Problema:** 56–60% dos PDFs reais foram para `Outros`; faltavam categorias
  (viagens, acadêmico, manuais, digitalizados); uma proposta válida foi rejeitada
  por categoria inexistente.
- **Comportamento esperado:** catálogo expandido (mantendo `Outros` obrigatório);
  queda mensurável de `Outros` sem aumento de `nao_decidido_erro_ia`.
- **Componentes V1:** `dados/catalogo_exemplo.json`, `catalogo.py` (validação),
  `pre_voo.py` (materialização), `modelos_ia.py` (a lista de categorias já é
  enviada dinamicamente à IA), `nucleo._casar_com_catalogo`.
- **Alterações arquiteturais:** nenhuma obrigatória no código (DA2: é dado);
  registrar hash do catálogo no evento via DA1.
- **Riscos:** mais opções podem dispersar/confundir o modelo; muitas pastas vazias
  materializadas; catálogo grande dificulta leitura humana.
- **Impacto na segurança:** neutro — a validação determinística contra a lista
  exata continua sendo a única barreira; normalização anti-traversal inalterada.
- **Validação experimental:** replay em `simular` dos mesmos 45 PDFs com catálogo
  antigo vs. novo; comparador (DA7) mede `%Outros`, erros de IA e divergências
  por hash; meta declarada antes do experimento.

### O2 — Tratamento seguro de baixa confiança (resolve L2)

- **Problema:** 25 propostas <60% viraram `Outros` executado sem marcação; o
  ajuste por limiar jamais disparou (a IA já propõe `Outros` quando insegura),
  logo o mecanismo atual não cobre o risco real.
- **Comportamento esperado:** com `--politica-risco reter`, propostas de baixa
  confiança (ou destino `Outros`) ficam na origem com status próprio de
  quarentena; com `marcar`, movem com flag de revisão no evento; padrão
  (`executar`) = V1.
- **Componentes V1:** `nucleo._validar_proposta`, `Agente.processar` (AGIR/
  REGISTRAR), schema de eventos.
- **Alterações arquiteturais:** DA3 (fase de política) + DA1 (status e campos
  novos); pasta de quarentena, se adotada, reusa `_mover_sem_sobrescrever`.
- **Riscos:** acúmulo de retidos sem revisão (H3); interação com retomada
  (retido continua na origem -> seria reprocessado na próxima corrida; precisa de
  regra explícita de idempotência); critério de corte é arbitrário.
- **Impacto na segurança:** positivo (menos movimento automático discutível);
  retenção não apaga nem sobrescreve; decisão segue 100% determinística (I2).
- **Validação experimental:** teste determinístico estilo `teste_erro_ia.py`
  (stub propondo confiança baixa) provando retenção íntegra (hash conferido,
  nada movido); dry-run real comparando as três políticas.

### O3 — Detecção de extração inutilizável (resolve L3)

- **Problema:** texto corrompido (mojibake) de PDF digitalizado foi enviado à IA
  como percepção legítima (`Visita Natal Junho 2014_6.pdf`).
- **Comportamento esperado:** `perceber()` avalia qualidade do texto
  (proporção de caracteres/palavras legíveis, tamanho mínimo) e sinaliza
  `conteudo_confivel=false`; nesse caso a IA recebe só metadados + aviso
  explícito, e o fato fica registrado.
- **Componentes V1:** `modulos/__init__.py` (`perceber`), `modulo_pdf.py`,
  `modelos_ia.propor` (montagem do pedido), evento `ciclo.perceber`.
- **Alterações arquiteturais:** DA4 — contrato de percepção aditivo; nenhum
  fluxo de execução muda.
- **Riscos:** falsos negativos descartam texto bom e empobrece a proposta (H2);
  heurística frágil multilíngue; limite de caracteres já truncando conteúdo.
- **Impacto na segurança:** neutro/positivo — afeta apenas o insumo da proposta;
  validação/execução inalteradas.
- **Validação experimental:** rotular manualmente amostra dos 45 PDFs reais
  (Visita Natal = positivo conhecido de ruído) e medir concordância da heurística;
  replay comparando propostas com e sem o filtro.

### O4 — Revisão pós-execução de alta confiança (mitiga L4)

- **Problema:** propostas de alta confiança semanticamente discutíveis foram
  executadas sem revisão; não-determinismo produziu destinos diferentes entre
  corridas para os mesmos arquivos.
- **Comportamento esperado:** ferramenta offline (DA5) que lê logs e destaca:
  divergências entre corridas por hash, propostas `Outros` de confiança alta,
  motivos muito curtos, mudanças de categoria entre corridas. Saída = lista de
  auditoria humana; nada é movido automaticamente por ela.
- **Componentes V1:** `nucleo._resumo`, `testes/verificar_resultado.py` (padrão
  de ferramenta offline), eventos JSONL.
- **Alterações arquiteturais:** nenhuma no runtime nesta fase (DA5); campos
  adicionais do DA1 enriquecem a análise.
- **Riscos:** fadiga de revisão (volume de alertas); critérios de "suspeito"
  arbitrários; expectativa errada de que a ferramenta "corrige" (ela só aponta).
- **Impacto na segurança:** positivo — dá visibilidade sem transferir poder à IA;
  qualquer correção posterior continua sendo execução determinística de código.
- **Validação experimental:** rodar sobre os logs V1 existentes (`124100` x
  `131519`) e verificar que os 3 casos conhecidos de divergência são destacados
  (ground truth já documentado no `V2-OPORTUNIDADES.md`).

### O5 — Consolidação/retomada de corridas parciais (resolve L5)

- **Problema:** corrida interrompida após 11/45 exigiu comando manual novo; sem
  visão consolidada entre logs.
- **Comportamento esperado:** ferramenta que consolida N logs em um relatório de
  estado (movidos/retidos/restantes) cruzando eventos com o filesystem atual;
  opcionalmente a porta única ganha `--relatorio` (nunca decide pelo log).
- **Componentes V1:** `entrar.py`, `pre_voo.listar_arquivos`, eventos JSONL.
- **Alterações arquiteturais:** DA6 — nenhuma no caminho crítico de execução;
  ferramenta externa seguindo o padrão de `testes/`.
- **Riscos:** tentação de retomar "pelo log" (criaria fonte dupla — evitada por
  DA6); corridas simultâneas continuam proibidas e devem seguir detectáveis pelo
  pré-voo.
- **Impacto na segurança:** neutro — reforça que a verificação tripla da V1 é o
  critério de "processado".
- **Validação experimental:** interromper deliberadamente uma corrida de fixtures
  em temporário, consolidar e conferir 1:1 contra o disco.

---

## 5. Dependências entre O1–O5

```
Transversais (pré-requisitos):  [DA1: eventos v2]  [DA7: comparador V1xV2]
                                        |
        +---------------+---------------+----------------+
        |               |               |                |
       O1              O3              O5            (independentes entre si)
        |               |               |
        +-------+-------+               |
                |  (propostas estabilizadas)
               O2  (política de risco; depende de O1+O3 p/ calibrar critérios)
                |
               O4  (revisão amadurece sobre eventos gerados por O2; começa analítica)
```

- **O1** e **O3** são independentes entre si, mas **alteram as propostas** da IA
  (categoria e confiança); políticas que consomem confiança (**O2**) só devem ser
  calibradas depois deles.
- **O4** analítico pode ser construído a qualquer momento (lê logs v1), mas só
  faz sentido automatizar algo após **O2** criar os marcadores de revisão.
- **O5** é totalmente independente e recomenda-se cedo porque facilita os
  experimentos das demais (corridas interrompidas deixam de ser incidente).

## 6. Estratégia de reprodutibilidade frente à baseline (I8/R4)

1. Fixtures e comandos idênticos aos documentados no `ESTADO-FINAL.md`.
2. Defaults V2 = comportamento V1; toda novidade é opt-in (`--politica-risco`,
   `--perfil-catalogo`), permitindo A/B limpo.
3. Comparador (DA7) cruza corridas por `hash_sha256` (identidade do conteúdo),
   nunca por nome de arquivo.
4. Esquema de eventos aditivo (DA1): um mesmo verificador lê logs v1 e v2.
5. Cada etapa da V2 só fecha com relatório comparativo contra a baseline.

## 7. ORDEM RECOMENDADA DE IMPLEMENTAÇÃO

| Etapa | Entrega | Justificativa da posição |
|---|---|---|
| 0 | DA1 (eventos v2 aditivos) + DA7 (comparador) | Mensurabilidade primeiro: sem isso, nenhuma etapa seguinte pode ser comparada à baseline com rigor (R4) |
| 1 | O5 (consolidação/retomada) | Zero impacto nas decisões; operacional puro; destrava experimentos longos com segurança |
| 2 | O1 (taxonomia) | É dado, não lógica; maior ganho esperado (queda de `Outros`); deve preceder políticas de confiança para não calibrá-las sobre taxonomia obsoleta |
| 3 | O3 (qualidade de leitura) | Melhora o insumo da decisão; também altera propostas; vem antes de O2 pela mesma razão |
| 4 | O2 (política de risco/quarentena) | Primeira mudança real de comportamento de execução; exige propostas já estabilizadas (O1+O3) e validação mais forte (testes determinísticos + dry-run A/B) |
| 5 | O4 (revisão analítica -> eventual automação) | Por último no runtime: amadurece sobre eventos reais gerados pelas etapas 2–4; automação só com evidência acumulada |

Critério da sequência: primeiro instrumentar medição, depois operação segura,
depois melhorar o insumo da decisão, e só então alterar o comportamento de
execução — concentrando as mudanças de risco (movimento físico) onde já existe
evidência suficiente, com o princípio central intacto em todas as etapas.

## 8. FORA DO ESCOPO DA V2

OCR/exif; segundo modelo revisor; reprocessamento automático de `Outros`;
memória persistente entre corridas; fila/agendamento; interface gráfica;
multiusuário. (Ideias registradas em `V2-OPORTUNIDADES.md` §4; exigiriam
própria proposta + validação.)
