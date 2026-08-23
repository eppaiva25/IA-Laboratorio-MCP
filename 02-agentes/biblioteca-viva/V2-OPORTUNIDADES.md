# V2 — Oportunidades Registradas (Pós-Baseline)

**Data:** 2026-08-22
**Natureza:** documento de registro apenas. Nenhuma linha de código foi criada,
alterada ou removida nesta etapa. Nenhum processamento foi reexecutado.
A V1 permanece **VALIDADA, CONGELADA e INTACTA** como baseline reproduzível.

**Referência da baseline:**
- Commit de fechamento: `5e424fe` ("fecha Biblioteca Viva como aplicação final")
- Documentação vigente: `BASELINE.md`, `ESTADO-FINAL.md`, `README.md`
- Princípio preservado: `IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA`

**Fonte deste registro:** exclusivamente os logs de eventos já existentes em
`eventos/*.jsonl` (nenhuma nova execução foi feita). Modelo ativo registrado nos
eventos do teste real: `4skl/gemma4-e4b-mtp:latest`, escolhido por detecção
automática (primeiro modelo disponível no Ollama).

---

## 1. Comportamento validado (fatos comprovados nos logs)

Corridas do teste real sobre 45 PDFs (`G:\Documentos_Todos\PDFs\Projeto PDFs`):

| Log | Modo | Resultado |
|---|---|---|
| `eventos_20260822_122512.jsonl` / `_123238.jsonl` | simular (fixtures) | 9/9 simulado, origem intacta |
| `eventos_20260822_124100.jsonl` | simular (PDFs reais) | 44 simulado + 1 `nao_decidido_erro_ia` |
| `eventos_20260822_130907.jsonl` | organizar | 11 movidos, verificação ok; corrida interrompida pelo operador |
| `eventos_20260822_131519.jsonl` | organizar | 34 restantes movidos, verificação ok |

Comprovadamente bem-sucedido:

1. **Percepção completa**: nome, extensão, tamanho, data, módulo de leitura e
   SHA-256 registrados para todos os arquivos processados.
2. **Extração de conteúdo funcionou** na maioria dos PDFs reais (texto recuperado
   e enviado à IA).
3. **Decisão pela IA em JSON estrito** com `categoria`, `confianca` e `motivo`.
4. **Validação determinística contra o catálogo**: proposta de categoria
   inexistente foi REJEITADA e nada foi movido (`Visita Natal Junho 2014_6.pdf`
   recebeu proposta `Documentos/Viagens`, fora das 9 categorias válidas; status
   `nao_decidido_erro_ia`; arquivo permaneceu na origem e foi processado com
   sucesso na corrida seguinte).
5. **Movimentação e verificação posterior: 100%.** Nos dois trechos em modo
   `organizar`, os 45 arquivos movidos passaram na verificação tripla:
   destino existente + origem vazia + hash SHA-256 idêntico (45/45 `verificar=ok`,
   status `movido`).
6. **Registro JSONL completo** (`versao_esquema: 1`) de todo o ciclo, incluindo o
   evento de erro de IA.
7. **Erro de IA isolou-se**: uma falha de decisão não interrompeu a corrida nem
   moveu o arquivo.
8. **Retomada após interrupção**: reexecutar o comando processou apenas os 34
   arquivos restantes na origem.
9. **Dry-run padrão seguro** confirmado novamente nas fixtures (nada criado nem
   movido).

## 2. Limitações observadas (fatos identificados durante a execução)

**L1 — Estrutura de categorias insuficiente.** No dry-run real, 27 de 45 decisões
(60%) foram para `Outros`; na organização final, 19 de 34 (56%). Faltaram
categorias para viagens/passagens (caso concreto rejeitado), material
acadêmico/científico, manuais e digitalizados genéricos.

**L2 — Confiança baixa sem tratamento dedicado.** No dry-run real, 25 propostas
tiveram confiança abaixo de 60% e todas resultaram em `Outros` executado
normalmente, sem marcação de revisão. Detalhe factual importante: o ajuste pelo
limiar (`ajuste_do_sistema`) **nunca disparou** em nenhuma corrida real
(0 ocorrências), pois a própria IA já propunha `Outros` quando insegura.

**L3 — Leitura inadequada/binária.** A extração nativa de PDF produziu texto
corrompido (mojibake) em documento digitalizado (`Visita Natal Junho 2014_6.pdf`)
e esse ruído foi integralmente enviado à IA como percepção. Imagens e vídeos
decidem apenas por metadados (comportamento por desenho, documentado no README).

**L4 — Classificações semanticamente discutíveis + não-determinismo.** Os mesmos
arquivos receberam propostas diferentes entre corridas mesmo com `temperature=0`
(exemplos registrados): `Coima Carro Centauro.pdf` (`Outros` 20% ->
`Documentos/Financeiro` 90%), `manual.pdf` (`Outros` 30% -> `Financeiro` 95%),
`TesePolimeros.pdf` (`Outros` 30% -> `Documentos/Pessoal` 90%). Propostas de
confiança alta com destino discutível foram executadas sem qualquer revisão.

**L5 — Operação de corridas longas.** A corrida `130907` foi interrompida após
11/45 arquivos; a retomada exigiu comando manual novo e não há relatório
consolidado entre corridas parciais.

Limitações adicionais já registradas na baseline original constam de
`BASELINE.md` (seção "Limitações e defeitos conhecidos") e permanecem válidas.

## 3. Oportunidades para V2 (derivar das limitações acima — NÃO implementadas)

- **O1 (de L1):** ampliar/refinar a taxonomia do catálogo (viagens, acadêmico,
  manuais, digitalizados) — exige decidir se o catálogo atual passa a conviver
  com versões alternativas.
- **O2 (de L2):** tratamento mais seguro para baixa confiança (ex.: marcar,
  reter em fila de revisão ou exigir confirmação antes de mover `Outros`).
- **O3 (de L3):** detectar explicitamente extração de texto inutilizável e sinalizar
  isso na percepção enviada à IA.
- **O4 (de L4):** mecanismo de revisão pós-execução para classificações de alta
  confiança porém discutíveis.
- **O5 (de L5):** consolidação/retomada formal de corridas parciais.

Cada oportunidade acima é derivada de um fato registrado na seção 2; nenhuma foi
implementada ou testada.

## 4. Ideias futuras ainda NÃO validadas (hipóteses — não tratar como fatos)

As ideias abaixo são apenas hipóteses levantadas durante a análise. Nenhuma tem
evidência experimental neste projeto até o momento:

- OCR/exif para imagens e vídeos ampliarem a percepção.
- Uso de um segundo modelo (ou segunda passada) como revisor cruzado das propostas.
- Reprocessamento automático periódico do que está em `Outros`.
- Memória persistente entre corridas para estabilizar decisões repetidas.
- Estratégia mais segura para movimentação entre volumes distintos (risco latente
  de cópia+exclusão já anotado na `BASELINE.md`; nunca foi observado em teste).

---

## Regra vigente

Qualquer evolução destes pontos exige autorização explícita e nova rodada de
validação completa. Até lá, a V1 aqui referenciada é a única implementação
válida e reproduzível do projeto.
