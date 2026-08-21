# RASCUNHO — ARQUITETURA BIBLIOTECA V1

> NÃO IMPLEMENTAR.
> NÃO APROVADO.
> Documento de trabalho para preservar a análise arquitetural.

---

*Conteúdo abaixo preservado exatamente como produzido na execução original, do início da proposta até o ponto da interrupção (item 12, incompleto). Itens 13 a 18 e seções finais ainda NÃO foram redigidos.*

---

# PROPOSTA FORMAL DE ARQUITETURA — BIBLIOTECA V1

**Modo: ANALISAR → PROPOR. Nenhum arquivo criado ou modificado. Nenhum script, teste, PDF ou chamada de IA executado. Nenhum commit.**

Legenda usada em todo o documento:
- **[DECIDIDO]** — já bloqueado pelas Fases A/B/C (commits `1a37dd8`, `3695524`, `254b399` e DECISOES.md)
- **[PROPOSTA V1]** — decisão nova que esta proposta recomenda, sujeita à sua aprovação
- **[PENDENTE]** — precisa de decisão humana explícita antes de implementar
- **[FORA DA V1]** — explicitamente excluído desta fase

---

## 1. DEFINIÇÃO FORMAL

**A Biblioteca é:** um **artefato declarativo, versionável e aprovável** de política organizacional que responde, de forma determinística e auditável, à pergunta:

> *"Dado o conjunto de atributos registrados de um arquivo no catálogo, qual é o seu destino lógico correto?"*

**A Biblioteca não é:**

| Não é | Motivo |
|---|---|
| O acervo | Os arquivos existem independentemente dela |
| O catálogo | Ela consome estado; não o produz nem o descreve |
| A classificação | Ela não interpreta conteúdo; usa interpretação já registrada |
| A taxonomia | Ela referencia o vocabulário; não o define (na V1) |
| Um módulo | Ela não sabe ler PDF, JPG ou DOCX |
| A árvore física | Diretórios são projeção dela, criados só na execução futura |
| A aplicação | Ela não executa nada; é o objeto sobre o qual se opera |

**Responsabilidade arquitetural única:** ser a **fonte aprovada da intenção organizacional**, de modo que toda execução futura seja consequência mecânica e verificável dela — nunca improviso operacional.

**Princípio regente [DECIDIDO, herdado]:** *"O agente propõe a Biblioteca; a aplicação opera a Biblioteca; o usuário aprova."* O agente escreve propostas de artefato; a aplicação avalia e registra; só o humano autoriza efeitos.

---

## 2. MODELO CONCEITUAL

A Biblioteca V1 contém **exatamente cinco objetos**. Cada um existe por uma necessidade específica — nenhum foi incluído por completude.

### 2.1 meta

Identidade e ciclo de vida do documento:

| Campo | Função | Justificativa |
|---|---|---|
| nome | identidade da biblioteca | permite múltiplas bibliotecas e auditoria |
| versao | inteiro incremental | toda proposta precisa ser referenciável |
| status | 'rascunho' ou 'aprovada' | mecanismo fail-closed: rascunho não opera |
| criada_em / aprovada_em | datas do ciclo | registro mínimo do fluxo proposta→aprovação |
| base_versao | versão anterior de onde derivou | torna o diff comparável e a linhagem rastreável |
| descricao | texto livre curto | aprovação humana precisa entender o que está aprovando |

### 2.2 taxonomia (referência, não cópia)

```
"taxonomia": { "origem": "config", "versao_esquema": 1 }
```

Justificativa: o validador precisa conferir compatibilidade entre as regras da Biblioteca e o vocabulário ativo sem duplicar a fonte (evita drift entre `config.ps1` e o artefato). Embutir a taxonomia criaria duas fontes de verdade — violaria princípio já estabelecido.

### 2.3 nos

Nós da árvore lógica: `{ id, caminho, descricao }`.

- `id` — referência estável usada pelas regras (desacopla regras de eventuais renomeações de caminho);
- `caminho` — caminho lógico relativo ("Financeiro/Extratos"), define a hierarquia por aninhamento de prefixo;
- `descricao` — auxilia o humano na aprovação da estrutura.

Justificativa: a árvore lógica é o alvo dos destinos; sem nós com identidade própria, as regras teriam que citar caminhos literais e qualquer reorganização de pastas invalidaria todas as regras.

### 2.4 regras

Lista ordenada de mapeamentos `{ id, descricao, quando, entao.destino }`:

- `id` — rastreabilidade (qual regra gerou qual proposta);
- `descricao` — legibilidade humana;
- `quando` — condição declarativa avaliável deterministicamente;
- `entao.destino` — id de nó lógico;
- **a ordem no array É a prioridade** (primeira correspondência vence).

Justificativa: usar a ordem como prioridade elimina um campo redundante sujeito a inconsistência; uma única fonte de ordenação.

### 2.5 fallback

Desfecho terminal explícito quando nenhuma regra corresponde:

```
"fallback": { "sem_regra": { "acao": "nenhuma", "registrar_como": "pendente_de_regra" } }
```

Justificativa: proibição de organização silenciosa — coerente com o princípio [DECIDIDO] de que nada acontece sem proposição + aprovação.

**Elementos deliberadamente EXCLUÍDOS da V1** (e por quê):

| Excluído | Motivo |
|---|---|
| Campo numérico de prioridade | redundante com a ordem do array |
| Operador OR explícito | componível com múltiplas regras |
| Templates de renomeação (nome_sugerido) | renomeação fora de escopo da primeira fase organizacional |
| Múltiplas ações por regra | V1 só conhece 'mover' (execução futura) e 'nenhuma' |
| Permissões, usuários, agendamento | sem necessidade atual |
| Múltiplas raízes físicas | raiz física é parâmetro de ambiente, decisão pendente |
| Metadados extras por nó | nada os consumiria ainda |

---

## 3. FORMATO DECLARATIVO

**Proposta: JSON** (`UTF-8`, um arquivo por versão, pretty-printed).

Justificativa:
- PowerShell 7 possui `ConvertFrom-Json` nativo → zero dependência nova (o projeto autorizou apenas pypdf até agora);
- validação estrita mecânica possível (schema via validador próprio);
- pretty-printed JSON produz diffs Git perfeitamente legíveis;
- agentes escrevem JSON de forma confiável (contrato já usado na classificação).

Alternativas consideradas e rejeitadas:
- **YAML** — exigiria módulo terceiro (`powershell-yaml`) = nova dependência a aprovar; spec ambígua (múltiplas formas de expressar o mesmo documento);
- **Markdown** — legível, mas não estritamente validável sem parser customizado; pior relação esforço/garantia;
- **PowerShell (.ps1 de dados)** — acoplaria política a código executável, violando "declarativo".

[PENDENTE] confirmação do formato pelo usuário.

---

## 4. ÁRVORE LÓGICA

Representação: nós com `id` estável + `caminho` lógico relativo usando `/` como separador. Hierarquia implícita pelo prefixo do caminho ("Financeiro" é pai de "Financeiro/Extratos").

Distinção fundamental:

| Conceito | Onde vive | Quando materializa |
|---|---|---|
| Árvore lógica | dentro do artefato Biblioteca | nunca (é declaração) |
| Árvore física | disco | somente na fase de execução futura |

Resolução físico-futura:

```
caminho_físico = RAIZ_FÍSICA (parâmetro de ambiente) + caminho_lógico do nó
ex.: {raiz}\Financeiro\Extratos
```

Consequências práticas:
1. `destino_proposto` no catálogo armazena o CAMINHO LÓGICO ("Financeiro/Extratos"), não o absoluto → se a raiz mudar, propostas permanecem válidas;
2. regras nunca citam caminhos, apenas ids de nós;
3. renomear uma pasta futuramente = alterar `caminho` numa nova versão da Biblioteca; regras intactas;
4. a aplicação resolve lógico→físico apenas no pré-voo/execução, nunca antes.

[DECISÃO PENDENTE] onde mora a raiz física (config aditivo vs parâmetro da aplicação).

---

## 5. REGRAS DE ORGANIZAÇÃO

Estrutura declarativa:

```json
{
  "id": "r_001",
  "descricao": "...",
  "quando": {
    "todos": [
      { "campo": "categoria", "operador": "igual", "valor": "financeiro" },
      { "campo": "confianca", "operador": "maior_igual", "valor": 0.8 }
    ]
  },
  "entao": { "destino": "n_fin_extratos" }
}
```

Operadores whitelist V1: `igual`, `diferente`, `contem`, `em`, `vazio`, `nao_vazio`, `maior_igual`, `menor_igual`.

Campos permitidos (whitelist — todos existem hoje no catálogo):
`categoria`, `confianca`, `tipo`, `nome_original`, `pasta_original`, `status`, `detalhes.<chave>` (ex.: `detalhes.paginas` — presente nos PDFs).

Composição: apenas AND (`todos`). OR obtém-se duplicando regras.

Avaliação: função pura determinística `(linha_do_catálogo, biblioteca) → destino | sem_regra`; primeira correspondência na ordem do array vence; zero IA, zero rede, zero aleatoriedade.

Elegibilidade (nível motor, fora das regras) [PROPOSTA]:
- somente linhas com `status = 'classificado'`;
- jamais linhas substituídas (`substituido_por`) ou `desaparecido`;
- `_PROBLEMAS` nunca elegível;
- não classificadas não são avaliadas → aparecem no relatório como "pendentes de classificação".

Saída da avaliação (escrita pela aplicação via porta única [DECIDIDO]):
`acao_proposta='mover'`, `destino_proposto=<caminho lógico>`, `detalhes.biblioteca={...rastreabilidade...}`, `status='proposto'`.

---

## 6. IDENTIDADE E VERSIONAMENTO

Localização proposta [PROPOSTA, PENDENTE]: `biblioteca-viva/bibliotecas/<nome>/v<N>.json` — versionada no Git (é política, ao contrário de `dados/` que permanece ignorada).

Modelo:
- identidade = nome do diretório;
- versão = inteiro N no nome do arquivo + `meta.versao`;
- versões aprovadas são IMUTÁVEIS (convenção de escrita: agente nunca edita aprovada);
- proposta nova = arquivo NOVO `v(N+1)` com `status: rascunho` e `base_versao: N`;
- aprovação registra evento append-only no diário [DECIDIDO: diário é append-only]: `biblioteca_aprovada { nome, versao, hash_sha256, quando }`;
- integridade: a aplicação recalcula o hash antes de usar → adulteração pós-aprovação é detectada;
- versão atual = maior versão aprovada (convenção) [alternativa: arquivo ponteiro — PENDENTE].

Comparação entre versões: git diff (texto) + diff estrutural apresentado pela futura aplicação (nós adicionados/removidos, regras alteradas).

Rastreabilidade de qual versão gerou qual proposta: `detalhes.biblioteca.versao` em cada linha proposta.

---

## 7. PROPOSTA DO AGENTE

Fluxo conceitual:

```
Biblioteca aprovada vN ──┐
                         ├─→ agente analisa ─→ escreve v(N+1) RASCUNHO (arquivo NOVO)
estatísticas do catálogo ┘        │
                                  ▼
                        validador (fail-closed)
                                  ▼
                     diff estrutural apresentado
                                  ▼
                      APROVAÇÃO HUMANA
                                  ▼
              evento no diário + hash → v(N+1) vira atual
```

Restrições do agente:
- nunca edita versão aprovada (cria arquivo novo);
- nunca cria diretórios, move ou renomeia arquivos;
- nunca escreve no catálogo neste fluxo;
- produz apenas: artefato rascunho + análise/justificativa textual para revisão humana.

O agente pode (e deve) preencher `descricao` de nós/regras com justificativas — é o material que o humano avalia.

---

## 8. APLICAÇÃO (CONSUMO DA BIBLIOTECA)

Pipeline completo, com responsáveis e zonas de escrita:

| Passo | Responsável | Escrita |
|---|---|---|
| 1. carregar (parse JSON) | aplicação | — |
| 2. validar (schema, refs, operadores, campos whitelist) | aplicação | fail-closed: inválida não carrega |
| 3. verificar aprovação + integridade (hash vs diário) | aplicação | — |
| 4. selecionar elegíveis | aplicação | leitura do catálogo |
| 5. avaliar regras (função pura) | aplicação/núcleo | — |
| 6. gerar propostas | aplicação | porta única: acao_proposta, destino_proposto, detalhes.biblioteca, status='proposto' |
| 7. apresentar pré-voo/relatório | aplicação | — |
| 8. registrar aprovação humana | humano decide; aplicação registra | aprovado, status='aprovado', diário |
| 9. executar (FASE FUTURA) | fase D | pré-voo obrigatório [DECIDIDO]; mkdir; mover; caminho_atual; executado_em; diário |
| 10. conferir | aplicação/fase D | verificado |
| 11. registrar tudo | núcleo/aplicação | diário append-only contínuo |

A aplicação contém zero política (política = Biblioteca) e zero mecânica de leitura de formatos (mecânica = núcleo/módulos).

---

## 9. RELAÇÃO COM O CATÁLOGO

Tabela precisa de produção de informação:

| Informação | Origem | Observação |
|---|---|---|
| Insumos de regra (categoria, confianca, tipo, nome_original, pasta_original, detalhes) | catálogo (Fases A–C) | somente leitura |
| acao_proposta | aplicação, derivada da regra avaliada | vocabulário V1: 'mover' |
| destino_proposto | aplicação | contém CAMINHO LÓGICO, não absoluto |
| nome_sugerido | ninguém na V1 | intocado — renomeação [FORA DA V1] |
| aprovado | aplicação, somente após aprovação humana registrada | separação classificação ≠ autorização |
| executado_em | fase de execução futura | [FORA DA V1] |
| Identidade, localização, estado técnico, substituição | exclusivos do catálogo | jamais produzidos pela Biblioteca |

A Biblioteca em si não escreve em lugar nenhum além dos seus próprios arquivos-rascunho.

---

## 10. RELAÇÃO COM A CLASSIFICAÇÃO

Separação necessária porque:
1. classificação é fato REVISÁVEL por design ([DECIDIDO]: Reprocessar é legítimo, histórico preserva passado);
2. organização deve ser RE-DERIVÁVEL: `(classificação × biblioteca) → proposta` é cálculo, não decisão gravada;
3. se organização fosse decidida durante a classificação, reclassificar não propagaria limpo;
4. zonas de escrita distintas [DECIDIDO]: classificador escreve camada semântica; propostas são outra zona, escrita pela aplicação.

Rastreabilidade cruzada: cada proposta registra `classificacao_lote` (= `linha.lote`) → responde "qual classificação alimentou esta proposta".

Detecção de obsolescência (consideração para a fase futura): no pré-voo, comparar `processado_em` da linha com `avaliado_em` da proposta → divergente = classificação mudou depois da proposta → reavaliar antes de executar.

A IA nunca autoriza movimento: classificação é insumo; autorização vive exclusivamente no fluxo de aprovação humana.

---

## 11. TAXONOMIA × CLASSIFICAÇÃO × REGRAS × ÁRVORE

Quatro camadas ortogonais:

```
TAXONOMIA      (vocabulário fechado — hoje no config v1)
   │ restringe
   ▼
CLASSIFICAÇÃO  (fato por arquivo — camada semântica do catálogo)
   │ alimenta
   ▼
REGRAS         (mapeamento condicional — Biblioteca)
   │ apontam para
   ▼
NÓS / ÁRVORE LÓGICA (estrutura alvo — Biblioteca)
   │ projeta
   ▼
ÁRVORE FÍSICA  (diretórios — somente execução futura)
```

Não-isomorfismo explícito (anti-meta: "uma categoria = uma pasta"):
- várias categorias podem convergir para um nó;
- uma categoria pode dividir-se em vários nós por condições (tipo, nome, confiança);
- nós podem existir sem nenhuma categoria mapeada (colocação manual futura);
- a categoria `outro` tem nó próprio, mas nada obriga as 9 categorias a virarem 9 pastas.

Taxonomia na V1: por REFERÊNCIA ao config (ver 2.2). Migração da taxonomia para dentro da Biblioteca = decisão futura ligada a multi-bibliotecas [PENDENTE, não urgente].

---

## 12. FALLBACK E CASOS NÃO RESOLVIDOS

Ordem de resolução: (1) regras específicas em ordem; (2) regra da categoria 'outro' se definida; (3) fallback explícito `{acao:'nenhuma', registrar_como:'pendente_de_regra'}` → listado em relatórios, nunca movido silenciosamente.

Casos não organizáveis [PROPOSTA — tratamento explícito]:

Non-organizable classes [

---

*PRESERVAÇÃO ENCERRADA AQUI — texto interrompido exatamente neste ponto na execução original.*
