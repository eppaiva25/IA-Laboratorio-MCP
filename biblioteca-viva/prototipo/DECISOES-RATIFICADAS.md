# DECISÕES RATIFICADAS — BIBLIOTECA V1
Origem: revisão manual do protótipo pelo usuário · Data: 2026-08-21 · Status: RATIFICADAS · Commit: PENDENTE

## D1 — Coerção numérica — RATIFICADA
Operadores `maior_igual` e `menor_igual` convertem valores numericamente com cultura invariante.
Valor não numérico não casa a regra. Sem inferências ou conversões heurísticas.
Estado do protótipo: já conforme (TryParse + InvariantCulture; não-numérico => predicado falso).

## D2 — Comparação textual — RATIFICADA
Operadores `igual`, `diferente`, `contem` e `em` são case-insensitive (PDF = pdf; Financeiro = financeiro).
Estado do protótipo: já conforme (ToLowerInvariant).

## D3 — Campo ausente — RATIFICADA (ALTERA comportamento atual)
Campo ausente nunca satisfaz comparação de conteúdo; só casa com o operador `vazio`.
Tabela ratificada:
- igual / diferente / contem / em / maior_igual / menor_igual => FALSO quando ausente
- vazio => VERDADEIRO
- nao_vazio => FALSO
Estado do protótipo: NÃO conforme — hoje `diferente` CASA com campo ausente (texto vazio difere do esperado) e `igual` casaria se o esperado também fosse vazio. Requer correção no avaliador.

## D4 — Taxonomia — RATIFICADA (decisão de arquitetura)
Nesta V1/protótipo: validar apenas que a Biblioteca declara `taxonomia.origem = "config"`.
Cruzamento dos valores das regras contra a taxonomia oficial fica para a etapa de integração com o ambiente real, a ser especificada posteriormente.
Estado do protótipo: já conforme.

## D5 — Portão de aprovação — RATIFICADA
Somente Biblioteca com `meta.status = "aprovada"` pode ser utilizada pelo avaliador para classificação operacional. Biblioteca em `rascunho` deve ser recusada.
Estado do protótipo: NÃO conforme — nenhum portão existe hoje. Requer inclusão no carregamento.
