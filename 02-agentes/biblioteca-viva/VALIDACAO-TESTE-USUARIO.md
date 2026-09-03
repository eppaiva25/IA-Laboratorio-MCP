# VALIDACAO-TESTE-USUARIO — Teste Físico pelo Usuário (Biblioteca Viva V2)

**Natureza:** documento histórico da etapa. Registra o primeiro TESTE FÍSICO
conduzido pelo usuário sobre uma pasta de teste criada especificamente para
isso, após os testes controlados anteriores (`VALIDACAO-REAL-CONTROLADA.md`,
commit `d21324f`). Cada afirmação aponta para evidência existente no
repositório (log JSONL append-only, fotografia SHA-256 ou estado do
filesystem). Nenhum código funcional, catálogo ou regra de classificação foi
alterado nesta etapa.

---

## 1. Contexto e objetivo

| Campo | Valor |
|---|---|
| Commit base | `d21324f` — "feat(biblioteca-viva): valida DA4 e primeiro teste fisico" |
| Execução | 2026-08-23/24 |
| Objetivo | Validar o ciclo físico completo conduzido pelo usuário em pasta própria de teste |
| Entrada de teste | `exemplos\Teste_Usuario_20260823` (9 arquivos sintéticos, 15.639 bytes) |
| Biblioteca de destino | `exemplos\Teste_Usuario_20260823_Biblioteca` (criada vazia) |
| Modo | `organizar` (único modo físico do contrato; `executar` não existe em `entrar.py`) |
| Modelo | `gemma4:12b` via Ollama local |
| Catálogo | `dados\catalogo_exemplo.json` (SHA `5c69f540af6b1daa…`, 9 folhas) |
| Log de auditoria | `eventos\eventos_20260823_235454.jsonl` (append-only, não editar) |

A pasta de entrada recebeu 9 arquivos de teste gerados pelo gerador existente
(`testes/gerar_arquivos_teste.py`) com cópia seletiva — **nenhum arquivo da
pasta pessoal real (`G:\Documentos_Todos\Proj_Pasta_Downloads`) foi copiado,
tocado ou usado neste teste**. Fotografia pré-execução:
`exemplos\Teste_Usuario_20260823_fotografia.csv`.

Comando efetivamente executado (após autorização explícita na etapa de
preparação):

```
python entrar.py --entrada "exemplos\Teste_Usuario_20260823" --biblioteca "exemplos\Teste_Usuario_20260823_Biblioteca" --catalogo "dados\catalogo_exemplo.json" --modo organizar --modelo gemma4:12b
```

Pré-voo anterior à execução: OK (9 arquivos detectados; entrada × biblioteca
distintas e não aninhadas; catálogo validado; modelo disponível).

## 2. Arquivos utilizados

| Arquivo | Tipo exercido | Categoria executada | Confiança |
|---|---|---|---|
| anotacoes-jardim.txt | texto simples | Documentos/Pessoal | 95% |
| apresentacao-projeto.pptx | leitor DA4 PPTX | Documentos/Pessoal | 90% |
| receita-bolo.docx | DOCX | Documentos/Pessoal | 95% |
| contrato-aluguel.pdf | PDF com texto | Documentos/Financeiro | 95% |
| orcamento-casa.xlsx | leitor DA4 XLSX | Documentos/Financeiro | 100% |
| linux-curso.pdf | PDF | Tecnologia/Linux | 100% |
| aula-python.mp4 | metadados | Tecnologia/Programação | 100% |
| fotos-ferias.jpg | metadados | Fotos/Viagens | 100% |
| filme-familia.mp4 | metadados | Vídeos/Família | 95% |

## 3. Resultado da classificação e árvore final

Ciclo PERCEBER → DECIDIR → VALIDAR → AGIR → VERIFICAR → REGISTRAR completo nos
9/9 arquivos. Árvore final da biblioteca de destino:

```
Teste_Usuario_20260823_Biblioteca/
|-- Documentos/
|  |-- Financeiro/
|  |  |-- contrato-aluguel.pdf
|  |  `-- orcamento-casa.xlsx
|  `-- Pessoal/
|     |-- anotacoes-jardim.txt
|     |-- apresentacao-projeto.pptx
|     `-- receita-bolo.docx
|-- Fotos/Viagens/fotos-ferias.jpg
|-- Outros/               (vazio — nenhum arquivo)
|-- Tecnologia/
|  |-- Linux/linux-curso.pdf
|  `-- Programação/aula-python.mp4
`-- Vídeos/Família/filme-familia.mp4
```

## 4. Resultado da movimentação física

- **9/9 `status=movido`** (log: `Counter({'movido': 9})`).
- **0 `erro_da_ia`; 0 `ajuste_do_sistema`.**
- Ciclo VERIFICAR: **ok ×9** ("destino existe, origem vazia, hash identico").
- Entrada final: **0 arquivos** (esvaziada pelos movimentos).
- Destino final: **9 arquivos**, conforme árvore acima.

## 5. Verificação oficial (verificar_resultado.py)

Interface consultada no próprio script (argv[1] = caminho do log).

```
python testes\verificar_resultado.py eventos\eventos_20260823_235454.jsonl
```

Resultado informado pelo usuário e coerente com o log: **11 linhas totais,
9 arquivos, iniciada=1, concluida=1, falhas_auditoria=0**.

## 6. Verificação independente por SHA-256

Re-executada na documentação desta etapa contra a fotografia pré-execução:

- **9/9 hashes idênticos** entre fotografia e arquivos no destino;
- nenhuma divergência de hash;
- 9 caminhos distintos no destino (nenhum arquivo extra);
- único hash repetido: o par `aula-python.mp4` ≡ `filme-familia.mp4`
  (**byte-idênticos por construção das fixtures**, pré-existente ao teste e já
  registrado na preparação); cada um existe exatamente uma vez no destino,
  em categorias diferentes.

## 7. Integridade e segurança

- Nenhum arquivo fora de `exemplos\Teste_Usuario_*` foi movido, renomeado ou
  alterado.
- `G:\Documentos_Todos\Proj_Pasta_Downloads`: não utilizada neste teste.
- Catálogo inalterado (SHA `5c69f540…` igual ao de todas as corridas V2).
- Log append-only preservado sem edição.
- Nada foi apagado; artefatos dos testes anteriores permanecem intactos.

## 8. Conclusão formal da etapa

**CONCLUÍDA — primeiro teste físico pelo usuário aprovado.**

O usuário conduziu sozinho o ciclo físico completo (comando → revisão do plano
→ autorização → execução → verificação), reproduzindo o comportamento validado
nos testes controlados: decisões coerentes com conteúdo e nome, movimentação
determinística, verificação tríade ok em 9/9, auditoria íntegra.

## 9. Limitações e observações constatadas

1. Fixtures sintéticos: `.mp4` são marcadores de bytes (sem vídeo real); a
   proposta para `aula-python.mp4` (Programação, 100%) baseou-se no nome —
   comportamento esperado para arquivos sem conteúdo legível.
2. Par byte-idêntico no lote (característica do gerador, não do sistema).
3. `apresentacao-projeto.pptx` (leitor DA4) proposto como Documentos/Pessoal
   (90%) a partir do texto extraído — primeira decisão física registrada
   consumindo um dos leitores DA4; `orcamento-casa.xlsx` (leitor DA4) →
   Financeiro (100%), também com conteúdo confiável.
4. Amostra pequena (9 arquivos, ~15 KB); sem valor estatístico — objetivo era
   validar operação, não precisão de taxonomia.
