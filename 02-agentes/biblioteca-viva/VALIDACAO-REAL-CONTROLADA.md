# VALIDACAO-REAL-CONTROLADA — V2 · Validação do Usuário / Teste Real Controlado

**Natureza:** documento histórico da etapa. Registra (a) a implementação mínima
da leitura multiformato **DA4** e (b) o primeiro teste controlado da Biblioteca
Viva sobre uma pasta pessoal real, exclusivamente em modo `simular`.
Cada afirmação aponta para a evidência que a sustenta (log JSONL append-only,
saída de testes ou estado do git). Nenhum código funcional foi alterado nesta
etapa de teste; nenhum arquivo real foi movido, renomeado, copiado ou excluído.

---

## 0. Contexto

| Campo | Valor |
|---|---|
| Projeto | Biblioteca Viva (`02-agentes/biblioteca-viva`) |
| Etapa | V2 — Validação do Usuário / Teste Real Controlado |
| Data | 2026-08-23 |
| Pasta de teste | `G:\Documentos_Todos\Proj_Pasta_Downloads` |
| Modo efetivo | `simular` (nenhum movimento físico autorizado ou realizado) |
| Modelo | `gemma4:12b` via Ollama local (`--modelo` fixado na chamada) |
| Catálogo | `dados/catalogo_exemplo.json` (9 folhas, default V1) |
| Evidência principal | `eventos/eventos_20260823_214011.jsonl` (append-only, não editar) |
| Comando executado | `python entrar.py --entrada "G:\Documentos_Todos\Proj_Pasta_Downloads" --biblioteca "exemplos\Biblioteca_DryRun" --catalogo "dados\catalogo_exemplo.json" --modo simular --modelo gemma4:12b` |

Pré-voo verificado antes da execução (todos positivos):

- pasta existe: `True`;
- 28 arquivos (recursivo; sem subpastas), 3.585,8 MB;
- extensões presentes: `.jpg×6, .txt×4, .py×3, .exe×2, .md×2, .mp4×2,
  .apk/.iso/.m4a/.mp3/.msi/.pdf/.rar/.WAV/.wmv ×1 cada`;
- catálogo carregado e validado: 9 categorias;
- Ollama disponível com `gemma4:12b` presente em `/api/tags`;
- modo efetivo `simular` confirmado pelo aviso do pré-voo
  ("modo SIMULAR: nenhum arquivo sera movido e nenhuma pasta sera criada").

Observação: `.WAV` (maiúsculo) é normalizado para `.wav` pela percepção
(`suffix.lower()`); caiu em metadados, como esperado.

---

## 1. DA4 — Leitura Multiformato Mínima

Implementação anterior ao teste real, validada pela suíte automatizada.

Criados:

- `modulos/modulo_xlsx.py` — leitura somente leitura via `zipfile` +
  `xl/sharedStrings.xml`; extrai textos `<t>…</t>`; trunca em `limite*2`;
  retorna `None` quando não há texto ou o pacote é inválido; nunca executa
  conteúdo; 100% stdlib.
- `modulos/modulo_pptx.py` — idem, iterando `ppt/slides/slideN.xml` em ordem
  numérica (teto `LIMITE_SLIDES = 30`); quebras de parágrafo preservadas;
  mesmas garantias.

Alterados:

- `modulos/__init__.py` — registro dos dois módulos no mapa `MODULOS_LEITURA`
  (import + 2 entradas). Única mudança.
- `testes/gerar_arquivos_teste.py` — fixtures sintéticos
  `orcamento-casa.xlsx` e `apresentacao-projeto.pptx` (mesma técnica zip do
  gerador de `.docx` já existente).
- `testes/teste_qualidade_leitura.py` — verificações 14–19: registro no mapa;
  XLSX lido confiável; PPTX com ordem de slides preservada; ZIP inválido /
  PPTX sem slides → `sem_texto`; `.exe` e `.doc` permanecem em metadados;
  contrato de chaves da percepção intacto.

Resultados de teste:

- `teste_qualidade_leitura.py`: **19/19 OK**, rc=0.
- Suíte determinística completa executada com sucesso (todas rc=0):
  `teste_catalogo_v2` (15/15), `teste_eventos_v2`, `teste_erro_ia`,
  `teste_comparador` (15), `teste_consolidacao` (18/18),
  `teste_executor` (**47 verificações, 0 falhas**);
  sondas: `sonda_ollama` rc=0; `sonda_classificacao` OK após execução no
  diretório correto (gemma4:12b respondeu em 47,9 s; primeira falha foi CWD,
  não código).

Limitações registradas (sem correção nesta etapa): XLSX só com inline strings
retorna `None` (rede de segurança `sem_texto`); entidades XML não decodificadas
(idêntico ao `modulo_docx` pré-existente); notas de apresentador e slides além
do 30º não são lidos.

**Os formatos XLSX/PPTX foram implementados e validados, mas NÃO apareceram na
pasta do teste real** (0 ocorrências entre os 28 arquivos) — sua eficácia em
dados reais segue sem evidência prática até novo teste que os contenha.

---

## 2. Teste real controlado — Proj_Pasta_Downloads

Todos os números abaixo derivam diretamente do JSONL
`eventos/eventos_20260823_214011.jsonl`.

- 28 arquivos encontrados; 3,59 GB.
- **28/28 processados**, todos com ciclo completo
  PERCEBER → DECIDIR → VALIDAÇÃO → AGIR(simulado) → VERIFICAR → REGISTRAR.
- **28/28 com `proposta_da_ia` registrada** → **28 chamadas reais ao
  `gemma4:12b`** comprovadas pelo log (campo `modelo=gemma4:12b` em todos).
- **0 `erro_da_ia`.**
- **28/28 `status=simulado`.**
- Duração entre o primeiro e o último `arquivo_processado`:
  **844 s (14,1 min)** (21:40:55 → 21:54:59).
- Latência entre registros consecutivos: mínimo **24 s**, máximo **57 s**,
  média **31,3 s**, mediana **27 s** (~**30,1 s/arquivo**).

Distribuição por extensão (B/C):

| Ext. | Qtd | Com conteúdo | Só metadados | Sinalização |
|---|---|---|---|---|
| .jpg | 6 | 0 | 6 | sem_texto |
| .txt | 4 | 4 | 0 | confivel |
| .py | 3 | 0 | 3 | sem_texto |
| .exe | 2 | 0 | 2 | sem_texto |
| .md | 2 | 2 | 0 | confivel |
| .mp4 | 2 | 0 | 2 | sem_texto |
| .apk | 1 | 0 | 1 | sem_texto |
| .iso | 1 | 0 | 1 | sem_texto |
| .m4a | 1 | 0 | 1 | sem_texto |
| .mp3 | 1 | 0 | 1 | sem_texto |
| .msi | 1 | 0 | 1 | sem_texto |
| .pdf | 1 | 1 | 0 | confivel |
| .rar | 1 | 0 | 1 | sem_texto |
| .wav | 1 | 0 | 1 | sem_texto |
| .wmv | 1 | 0 | 1 | sem_texto |

Confiança (H): média **71,2%**; distribuição 30%×8, 40%×2, 60%×2, 85%×1,
90%×1, 95%×4, 100%×10. Padrão observado: conteúdo legível ⇒ 90–100%;
somente nome/extensão ⇒ 30–85%.

---

## 3. Resultado das decisões

Propostas/executadas (D/E):

- Tecnologia/Programação: **14**
- Outros: **13**
- Tecnologia/Linux: **1**

- **Propostas e categorias executadas foram IDÊNTICAS** (14/13/1 nos dois
  conjuntos).
- **Ajustes/rebaixos do sistema (`ajuste_do_sistema`): 0** — diferentemente do
  log histórico `223745` (44 PDFs), onde 12 propostas foram rebaixadas pelo
  limiar; aqui o único PDF teve texto extraído e proposta aceita como veio.
- Limiar aplicado: 60% (default). Casos abaixo do limiar já foram propostos
  como `Outros` pela própria IA (sem intervenção do sistema).

Casos `Outros` (F): 6 fotos `IMG_*`, 3 áudios (.mp3/.wav/.m4a), 2 vídeos
(.mp4), 1 vídeo .wmv (costura), 1 cookies.txt (proposto direto como Outros 90%).

---

## 4. Conteúdo recuperado

- **7/28** arquivos tiveram conteúdo recuperável e considerado confiável:
  **4 TXT + 2 MD + 1 PDF** (todos `conteudo_confivel=true`,
  `leitura_por` = módulos texto simples / PDF).
- **21/28** ficaram somente com metadados (`sem_texto`) — extensões binárias
  sem leitor de conteúdo no escopo atual (imagens, áudios, vídeos, instaladores,
  compactadores, scripts sem leitor dedicado).
- **Nenhum caso de mojibake, `texto_insuficiente` ou `estatistica_atipica`
  nessa execução.**

---

## 5. Casos que exigem revisão do catálogo/regra antes do modo real

Problemas encontrados pelo teste — registrados aqui, **sem correção
automática** e sem nenhuma alteração de catálogo/código:

| Caso | Decisão registrada | Problema |
|---|---|---|
| `Electrum-4.5.4.0-arm64-v8a-release.apk` | Tecnologia/Programação 95% | classificação provavelmente inadequada (app Android instalável/carteira); melhor candidato: Outros |
| `mariadb-12.3.2-winx64.msi` | Tecnologia/Programação 95% | instalador de software; sem categoria específica no catálogo |
| `Antigravity IDE.exe` | Tecnologia/Programação 95% | plausível, mas é instalador; mesma lacuna acima |
| `90 FPS Config New_2.rar` | Tecnologia/Programação 85% | decisão baseada principalmente no nome; conteúdo não legível → revisão humana necessária |
| 6 arquivos `IMG_*.jpg` | Outros 30% | faltam evidências (EXIF/visão) para distinguir Família/Viagens |
| `VID-20211012-WA0015_3.mp4`, `VID_20260605.mp4` | Outros 30% | possível conteúdo familiar (vídeo WhatsApp), dados insuficientes |
| áudios .mp3/.wav/.m4a e .wmv | Outros 30–60% | catálogo atual não possui categorias adequadas para áudio e vídeo genérico |

Leitura objetiva: a IA foi conservadora (baixa confiança onde faltou conteúdo),
mas o catálogo de 9 folhas não cobre instaladores/software, áudio e mídia sem
contexto — decisões discutíveis decorrem disso, não do ciclo de execução.

---

## 6. Integridade e segurança

Registrado explicitamente, verificado após a corrida:

- **Nenhum arquivo** de `G:\Documentos_Todos\Proj_Pasta_Downloads` foi movido
  (28/28 ainda presentes na origem).
- **Nenhum arquivo real foi alterado** e **nenhum foi excluído**.
- `exemplos\Biblioteca_DryRun` terminou com **0 arquivos** (modo simulado não
  cria nada).
- **Catálogo permaneceu inalterado** (`dados/catalogo_exemplo.json` intocado).
- SHA-256 do catálogo registrado em todos os eventos da execução:
  `5c69f540af6b1daa9eaddbbe912a67b203376d3d0859ffddf7ff698a11b40a1c`
  (idêntico ao das corridas anteriores — mesma taxonomia de 9 folhas).
- O JSONL desta execução é **evidência histórica append-only** e não deve ser
  editado; integridade conferível por `verificar_resultado.py` e hash.

---

## 7. Conclusão da etapa

**CONCLUÍDA — modo SIMULAR validado.**

- O ciclo PERCEBER → DECIDIR → VALIDAR → AGIR → VERIFICAR → REGISTRAR funcionou
  nos 28/28 arquivos, sem erro de IA e sem exceção não tratada.
- O teste comprova integração real com Ollama/gemma4:12b (28 chamadas
  registradas no log; latência média ~31 s/arquivo).
- O teste revelou lacunas do catálogo (instaladores/software, áudio, vídeo
  genérico, fotos sem contexto) e limites da evidência disponível (sem EXIF,
  sem visão, compactados ilegíveis).
- A execução REAL de movimentação sobre esta pasta **ainda NÃO está
  autorizada**.
- Antes do modo real, devem ser revisadas/documentadas as categorias e regras
  para os casos da seção 5 (inclui avaliar `dados/catalogo_v2.json` e eventuais
  folhas novas — decisão pendente do usuário).
- **Não implementar essas correções agora sem nova autorização.**

## 8. Conformidade

- Documento criado sem alterar nenhum `.py`, dado, log ou catálogo.
- Arquivos de código tocados nesta fase (DA4, anteriores ao teste):
  `modulos/modulo_xlsx.py` e `modulos/modulo_pptx.py` (novos),
  `modulos/__init__.py`, `testes/gerar_arquivos_teste.py`,
  `testes/teste_qualidade_leitura.py` (editados). Núcleo funcional
  (`nucleo.py`, `modelos_ia.py`, `entrar.py`, `executar.py`, `pre_voo.py`,
  `catalogo.py`) e `dados/catalogo_exemplo.json`: intocados.
- Nenhuma nova classificação da pasta real foi executada após a corrida.
