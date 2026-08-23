# V2 — Validação da Etapa 3 (O3 — Qualidade de Leitura / DA4)

**Data:** 2026-08-22
**Natureza:** registro de implementação e validação experimental da O3.
**Princípio preservado:** `IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA`
A heurística não move, não retém e não classifica nada. Ela apenas enriquece a
percepção e sinaliza à IA que o texto extraído não é confiável.

---

## 1. Hipótese avaliada

**H2** (de `V2-ARQUITETURA.md`): uma heurística simples distingue texto
inutilizável (mojibake) com poucos falsos negativos em português.

## 2. Método

1. Calibração SEM código novo: métricas determinísticas calculadas sobre os
   textos extraídos dos 45 PDFs reais registrados no log `124100` (mesma via de
   extração V1), com rótulos manuais derivados dos motivos da própria IA
   (`conteudo binário ilegível`, `corrompido`) — 10 arquivos ruins conhecidos.
2. Busca por separação unidimensional: %letras, %vogais/letras,
   %tokens-sem-vogal, %tokens<=2, tamanho — todas com sobreposição entre bons e
   ruins. Conclusão honesta: separação perfeita é impossível com métricas
   simples neste corpus (par-gêmeo: `Visita Natal` ruim × `2014 Docs Multas
   Seguro` bom, estatisticamente idênticos).
3. Regra conservadora multi-sinal otimizada para ZERO falso negativo nos casos
   conhecidos, aceitando colaterais documentados.
4. Implementação aditiva (DA4): campos novos na percepção + montagem do pedido
   à IA. Núcleo intocado.

## 3. Limiares definidos (determinísticos, independentes de modelo/categoria/confiança)

| Sinal | Regra | Justificativa empírica |
|---|---|---|
| `sem_texto` | 0 caracteres | Novo_Layout, ziperes_ipiranga |
| `texto_insuficiente` | n < 50 | menor texto bom real tem 78 chars (`Vacina Gripe`) |
| `mojibake_esparso` | %tokens<=2 ≥ 90 E %vogais/letras < 42 | Visita Natal (93,3%; 40,4); poupa Vacina (100%; 46,5) e Quinoa (93,8%; 44,0) |
| `estatistica_atipica` | %vogais/letras < 34 E %tokens_sem_vogal ≥ 20 E %letras ≤ 50 | cluster Cemitério/Coima/JOSUE/Digitalizado×3/sermão (V 27–33); poupa CERTIDAO (V 19,6 mas T 9,1) |

Valores observados e tabela completa de classificação ficam no script de
calibração reproduzível (seção 7).

## 4. Implementação (diff mínimo)

- `modulos/__init__.py`: nova função pública `avaliar_qualidade(texto)` +
  constantes de limiar; `perceber()` ganha 3 campos ADITIVOS:
  `conteudo_caracteres`, `conteudo_confivel`, `conteudo_sinalizacao`.
  O `conteudo` original continua gravado no evento (auditoria integral).
- `modelos_ia.py`: `propor()` monta o pedido via nova `percepcao_para_pedido()`:
  se não confiável, envia `conteudo=null` + `aviso_extracao="<codigo>"`.
  Percepção confiável segue byte-idêntica ao padrão anterior.
- `nucleo.py`: **ZERO diff nesta etapa** (verificado por `git diff`).
- `modulo_pdf.py`: intocado (avaliação é pós-extração).

## 5. Resultados

### Testes determinísticos (`testes/teste_qualidade_leitura.py`)
16/16 OK — cobre os 13 casos exigidos, incluindo PDF sem texto extraível
(fixture mínimo válido), caso Visita Natal lido do ARQUIVO REAL na biblioteca,
preservação dos 7 campos anteriores, aditividade tipada, sinalização no pedido
da IA, validação determinística intacta e ausência das heurísticas no núcleo.

### Experimento A/B isolado (V1 × V1+O3, mesmo catálogo `catalogo_exemplo.json`)
- Perna A: `eventos_20260822_193119.jsonl` (código pré-O3, percepção original).
- Perna C: `eventos_20260822_201923.jsonl` (código O3), origem idêntica,
  modelo idêntico (`4skl/gemma4-e4b-mtp:latest`).

| Métrica | A | C |
|---|---|---|
| confiáveis / sinalizados | — | 27 / 18 (6 esparso, 10 atípico, 2 sem_texto) |
| casos conhecidos detectados | 0 | **10/10** |
| decisões idênticas (comparador DA7) | — | 40/45 mesma_decisao |
| desfechos diferentes entre A e C | — | 5 arquivos = 3 `decisao_diferente` (categoria) + 2 `informacao_insuficiente`; os outros 40/45 são `mesma_decisao` |
| retidos por erro de IA | Visita Natal (proposta `Documentos/Viagens` fora do catálogo) | BilhetePaivaEuro2016 (proposta `Documentos/Viagens` fora do catálogo) |

Controle retroativo: aplicando a MESMA heurística sobre as percepções V1 da
perna A, exatamente 18/45 seriam sinalizados — igual à perna C. Heurística 100%
determinística e independente da resposta do modelo.

Desfechos diferentes entre A e C — 5 arquivos, conferidos hash a hash nos dois
logs e classificados pelo comparador DA7 (3 `decisao_diferente` +
2 `informacao_insuficiente`):
1. `Amostras Turquia`: Financeiro→Outros [sinalizado] [`decisao_diferente`] — IA mais cautelosa sem o texto ruim.
2. `Recibo_Consulta_Celia`: Financeiro→Pessoal [sinalizado] [`decisao_diferente`] — decisão por metadados.
3. `Comprovantes de votação`: Financeiro→Pessoal [sinalizado] [`decisao_diferente`] — idem.
4. `Visita Natal`: retido(A)→Fotos/Viagens 85% executada(C) [sinalizado]
   [`informacao_insuficiente`: sem decisão em A] —
   texto lixo não enviado; IA propôs pelo NOME do arquivo (motivo registrado:
   "O nome do arquivo sugere uma visita...").
5. `BilhetePaivaEuro2016`: Pessoal(A)→retido(C) [NÃO sinalizado]
   [`informacao_insuficiente`: sem decisão em C] — não-determinismo
   puro do modelo (mesma armadilha da categoria inexistente; não decorre da O3).

## 6. Falsos positivos / falsos negativos

- **Falso negativo: 0** nos 10 casos ruins conhecidos.
- **Sinalizações colaterais (8)**: Multas Seguro, Aspirado×2, Amostras Turquia,
  Fotos Antigas, Comprovantes, Power Bank, Recibo_Consulta — extrações
  fragmentadas que a baseline decidiu bem via nome/metadata. Custo benigno: a
  sinalização não impede proposta nem execução.
- **Limite fundamental documentado**: `Recibo/Comprovantes/Power Bank`
  (escaneados legítimos) são indistinguíveis por estatística simples do cluster
  de mojibake; e o par Visita Natal × Multas Seguro é estatisticamente gêmeo.

## 7. Reprodutibilidade

Origem temporária reconstruída com SHA-256 conferido 45/45; logs históricos e
biblioteca real somente leitura; verificador V1 (`git show 5e424fe`) produz saída
byte-idêntica ao verificador atual sobre o log `124100`.

## 8. Limitações

1. Separação perfeita impossível sem OCR/semântica (fora do escopo da V2).
2. Colaterais ~23% do corpus bom (8/35), todos benignos.
3. Heurística calibrada para português/PDFs deste corpus; outros idiomas podem
   deslocar os limiares de vogais.
4. Não-determinismo do modelo permanece (L4/O4).

## 9. Conclusão sobre H2

**H2 PARCIALMENTE SUSTENTADA.** A heurística distingue os textos inutilizáveis
conhecidos com zero falso negativo e melhorou o insumo no caso-canônico
(Visita Natal passou de erro de categoria para execução válida por metadados).
Porém, com poucos falsos negativos vêm falsos positivos não desprezíveis
(8 colaterais), e a separação ideal exigiria recursos além do escopo da V2.
Não se declara H2 plenamente confirmada.
