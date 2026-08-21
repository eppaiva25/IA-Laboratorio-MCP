# Decisões do Laboratório de IA

## 2026-08-18 — Git como controle de versões e memória

### Decisão

O Laboratório de IA utilizará um repositório Git local como mecanismo de controle de versões e como parte da memória persistente do projeto.

### Motivo

O Git permite registrar estados conhecidos do laboratório, acompanhar alterações e retornar a versões anteriores quando necessário.

A pasta .git é mantida dentro do próprio repositório e contém o histórico e as informações necessárias para o controle de versões.

---

## 2026-08-18 — Markdown como formato principal

### Decisão

O formato principal para documentação, memória, decisões, instruções e registros do laboratório será Markdown (.md).

### Motivo

Markdown é simples, legível diretamente no terminal, adequado para Git e fácil de utilizar com Claude Code e outras ferramentas de desenvolvimento.

PDF e DOCX poderão ser utilizados como formatos derivados quando houver necessidade de impressão, compartilhamento ou apresentação, mas não serão o formato principal da documentação.

---

## 2026-08-18 — Memória organizada em três níveis

### Decisão

A memória do laboratório será dividida em:

- ESTADO-ATUAL.md — situação atual e próximo passo.
- DECISOES.md — decisões estruturais e seus motivos.
- SESSOES/ — histórico cronológico das sessões.

### Motivo

Separar estado, decisões e histórico evita transformar a memória em um único arquivo grande e difícil de consultar.

---

## 2026-08-18 — Princípio de não poluição

### Decisão

O repositório deve conter somente arquivos relevantes para o funcionamento, aprendizado, documentação ou memória do Laboratório de IA.

Arquivos temporários, rascunhos descartáveis e materiais criados apenas para leitura não devem ser adicionados automaticamente ao Git.

### Motivo

O objetivo do repositório é preservar conhecimento e evolução do projeto, e não armazenar tudo que for produzido durante uma sessão.

---

## 2026-08-18 — Segurança antes de automação

### Decisão

Antes de permitir que Claude Code ou qualquer agente execute alterações no laboratório, devemos compreender e testar primeiro o mecanismo de controle de versões.

### Motivo

O Git deve funcionar como uma camada de segurança e histórico antes de começarmos a delegar tarefas de modificação a agentes de IA.

---

## 2026-08-18 — Continuidade entre sessões

### Decisão

Ao iniciar uma nova sessão de trabalho, a primeira referência deverá ser a memória persistente do laboratório, especialmente ESTADO-ATUAL.md.

### Motivo

Sessões de API podem terminar e o contexto conversacional pode não estar disponível posteriormente. A memória armazenada no próprio laboratório permite recuperar o estado do projeto de forma independente da sessão anterior.

---

## 2026-08-19 — Arquitetura de execução de modelos

### Decisão

Três caminhos para execução de modelos foram considerados: OpenRouter, Ollama Cloud e Ollama Local.

- **OpenRouter** está configurado no Claude Code através do loader PowerShell e foi testado com `openrouter/free` — funcionamento confirmado.
- **Ollama Local** está disponível em `localhost:11434` com os modelos `gemma4:26b`, `gemma4:12b` e `4skl/gemma4-e4b-mtp:latest` — funcionamento confirmado via `ollama run`.
- **Ollama Cloud** já foi utilizado anteriormente com `minimax/m3:cloud`, mas sua integração com o Claude Code não está documentada como funcional. Em teste anterior houve HTTP 429 devido ao limite semanal da conta. Endpoint, token e secret store **não** são configurações confirmadas.

Não existe atualmente um mecanismo unificado de alternância. OpenRouter é executado através do loader PowerShell e os modelos locais podem ser executados diretamente com `ollama run`.

A questão de preservar o contexto/memória ao trocar de backend ainda está em investigação.

A fonte persistente de documentação do projeto é `V:\Claude Code\Laboratorio-IA`. A documentação detalhada sobre os backends e comandos de diagnóstico está em `memoria/EXECUCAO-ARQUITETURA.md`.

### Motivo

Registrar a arquitetura atual de execução de modelos, distinguindo o que foi testado e confirmado do que ainda é apenas considerado, e deixar explícito que a alternância entre backends será objeto de estudo futuro.

---

## 2026-08-20 — Segredos fora do repositório: DPAPI + wrapper

### Decisão

Chaves de API (OpenRouter) ficam exclusivamente em cofre DPAPI
(`%USERPROFILE%\.openrouter\key.sec`), carregadas sob demanda pelo wrapper
`Start-ClaudeCode` no perfil PowerShell, que define variáveis de ambiente
apenas durante a execução e as remove ao finalizar. O repositório nunca contém
a chave, nem em texto puro, nem criptografada.

### Motivo

DPAPI vincula o segredo ao usuário/máquina; o wrapper garante que o segredo
exista em memória somente enquanto o Claude Code roda; o Git permanece como
camada de segurança sem nunca versionar credenciais.

---

## 2026-08-20 — Duas frentes de execução de modelos

### Decisão

O laboratório opera duas frentes independentes e já validadas:
(1) OpenCode → 9Router → provedores (combo ProjetoLab);
(2) Claude Code → OpenRouter → `openrouter/free` via wrapper `Start-ClaudeCode`.

### Motivo

Separar o ecossistema OpenCode (agentes/multi-provider) do uso direto do
Claude Code com gateway OpenRouter permite validar cada caminho isoladamente
antes de estudar alternância unificada entre backends.

---

## 2026-08-20 — Biblioteca Viva: dois modos de operação (MIGRAÇÃO/LOTE e MANUTENÇÃO/INCREMENTAL)

### Decisão

A Biblioteca Viva terá um único núcleo compartilhado com dois modos de operação,
selecionados por parâmetro de estratégia de varredura, sem duplicar lógica:

- **MIGRAÇÃO/LOTE** — varredura ampla do acervo completo (migração inicial e grandes lotes).
- **MANUTENÇÃO/INCREMENTAL** — pequenos lotes de arquivos novos ou alterados (ex.: Downloads),
  com detecção de delta e nenhum reprocessamento de arquivos já conhecidos e inalterados.

Regras que sustentam os dois modos:

1. **Detecção barata** por `caminho_atual + tamanho_bytes + modificado_em`: decide apenas quem é
   IGNORADO na varredura (conhecido e inalterado); nunca autoriza ação.
2. **Hash SHA-256 somente para arquivos novos ou suspeitos** (metadados divergentes),
   calculado em fluxo.
3. **Identidade do conteúdo = SHA-256**; **identidade da ocorrência catalogada =
   (sha256 + caminho_atual)**, com unicidade validada pela porta única do catálogo.
4. **Pipeline compartilhado**: descobridor → reconciliação → catálogo → módulos → classificação →
   proposta → aprovação humana → execução → pré-voo. O modo altera somente a descoberta.
5. **Pré-voo obrigatório** antes de qualquer execução: re-stat + re-hash + existência,
   independente do que a detecção barata concluiu.
6. Conteúdo alterado gera linha nova com `substituido_por` ligando à antiga (histórico preservado);
   arquivo não localizado recebe status `desaparecido`, nunca é apagado do catálogo.

O catálogo nasce com esquema versão 1, 26 colunas universais + gaveta `detalhes`,
em `biblioteca-viva/dados/` (fora do Git).

### Motivo

O uso normal da aplicação após a migração inicial será incremental (pequenos lotes acumulados).
Tratar o modo incremental como requisito da V0.1 evita retrabalho futuro; a detecção barata por
metadados torna a varredura viável para milhares de arquivos sem enfraquecer a segurança, pois
nenhuma ação jamais se baseia em metadados — apenas o pré-voo com hash autoriza execução.

---

## 2026-08-20 — Biblioteca Viva: arquitetura da Fase B (descoberta, reconciliação, roteamento e módulo PDF)

### Decisão

A Fase B acrescenta cinco componentes ao núcleo, aprovados antes da implementação:

- **diario.ps1** — componente de primeira classe: diário JSONL append-only em `dados/`,
  registrando cada transição (`arquivo_novo`, `movido_externamente`, `duplicata_detectada`,
  `metadados_atualizados`, `conteudo_substituido`, `desaparecido`, `erro_identificacao`).
- **descobridor.ps1** — camada barata: varredura por modo usando apenas
  `caminho_atual + tamanho_bytes + modificado_em` contra índices em memória do catálogo;
  produz `{NovosCandidatos, Suspeitos, Inalterados, AusentesDoDisco}`; nunca lê conteúdo,
  nunca calcula hash, nunca grava.
- **reconciliacao.ps1** — camada confiável: hash somente de novos e suspeitos; refinamento em
  novo real / movimento externo / duplicata / só metadados / conteúdo alterado; aplica todas as
  mudanças numa única gravação atômica (checkpoint opcional para lotes grandes); aciona
  roteador+módulo para gerar a ficha técnica; registra cada evento no diário.
- **roteador.ps1** — três estados (`ComModulo` / `ConhecidoSemModulo` / `Desconhecido`);
  registro único extensão→script; carregamento do módulo sob demanda.
- **modulos/modulo_pdf.ps1** — primeiro especialista, somente leitura: valida `%PDF-`/`%%EOF`,
  extrai versão/páginas/fonte/produtor/criptografia por janelas de bytes (leitura integral só
  abaixo do limite de análise leve), devolve a ficha padrão com `Alertas`;
  `AmostraConteudo` permanece vazio na V0.1.

Decisões confirmadas nesta aprovação:

1. `AusentesDoDisco` considera somente linhas dentro do escopo efetivamente varrido
   ("não visto ≠ sumiu").
2. Índices em memória (caminho→linha, hash→linhas) evitam consultas O(n²).
3. Movimentos externos são resolvidos ANTES de marcar desaparecidos.
4. Checkpoint opcional (`-CheckpointACada N`) não altera a semântica do catálogo.
5. Extensões sem módulo ou desconhecidas seguem para `_REVISAR`; nunca geram ação automática.
6. O módulo PDF não executa movimentação, renomeação ou exclusão de arquivos.
7. Status derivado da análise: ilegível → `_PROBLEMAS`; com alertas → `_REVISAR`;
   análise limpa → `inventariado`.
8. Testes da Fase B usam sandbox em `%TEMP%`; nenhuma varredura real em G:\ nesta fase.

### Motivo

Separar detecção barata de identificação confiável mantém a varredura incremental viável para
milhares de arquivos sem enfraquecer o pré-voo; o diário append-only fornece auditoria e base
para rollback futuro; o módulo PDF estabelece na prática o contrato das 5 perguntas que os
próximos módulos replicarão.

---

## 2026-08-21 — Biblioteca Viva: arquitetura da Fase C (extração de conteúdo e classificação com IA)

### Decisão

A Fase C separa o conhecimento sobre os arquivos em três camadas, com zonas de escrita
exclusivas, sem alterar o esquema v1 do catálogo:

1. **Camada técnica** (Fases A/B) — colunas estruturais do catálogo; a IA NUNCA escreve nelas.
2. **Camada de conteúdo** (nova) — texto extraído em sidecars `dados/extracoes/<id>.txt|.json`,
   regenerável, nunca dentro do CSV; `<id>` deriva do hash (estável entre movimentos).
3. **Camada semântica** (nova) — colunas `categoria/confianca/motivo/classificado_por/modelo/
   lote/processado_em` + histórico append-only em `dados/classificacoes/lote-*.jsonl`;
   ÚNICA área escrita pela IA; sobrescrita em reclassificação é legítima porque o histórico
   preserva todas as respostas anteriores.

Componentes aprovados: `externo/extrator_pdf.py` (ponte pypdf, 1 arquivo por chamada),
`nucleo/extrator.ps1` (cache por sha256 + sidecars), `Invoke-BvExtracao` como capacidade nova
dos módulos (mesma mecânica de roteamento da análise), `nucleo/classificador.ps1` (agnóstico
de extensão: prompt, chamada, validação, gravação pela porta única com verificação de
imutabilidade das colunas técnicas).

Contrato da resposta da IA (JSON estrito): `categoria` ∈ taxonomia fechada de 9 categorias
(`financeiro, documento_pessoal, automotivo, academico_tecnico, manual_produto, religioso,
correspondencia, digitalizado_diverso, outro`), `confianca` 0–1, `motivo` obrigatório;
inválido = 1 retry; persistindo a falha, registra `classificacao_recusada` e não grava nada.

Decisões confirmadas nesta aprovação:

1. Taxonomia fechada de 9 categorias aprovada como rascunho definitivo para esta fase.
2. Modelo classe mini/flash via OpenRouter (`ModeloIA` configurável); chave somente em
   variável de ambiente `OPENROUTER_API_KEY`, nunca em arquivo ou repositório.
3. OCR fica FORA do escopo desta fase; scans sem texto recebem marcador
   `sem_texto_para_classificar` e ficam para fase futura.
4. Dependência autorizada: `pip install pypdf`.
5. Modificações ADITIVAS autorizadas em `config.ps1` e `modulos/modulo_pdf.ps1`.
6. Smoke test real (3 PDFs de G:\) autorizado APENAS após suíte automatizada 100% verde;
   testes automatizados usam mock injetável (`-FuncaoChamada`) — zero rede.
7. Status elegível para classificar: `inventariado` e `_REVISAR`; `_PROBLEMAS`,
   `desaparecido` e substituídos jamais são processados; texto < mínimo configurável não
   consome chamada de IA.
8. A Fase C não move, não renomeia, não exclui e não preenche campos de execução
   (`destino_proposto`, `aprovado`) — isso pertence à fase seguinte com aprovação humana.

### Motivo

Manter o catálogo como única verdade com zonas de escrita explícitas permite ganhar a
inteligência da IA sem contaminar a base técnica auditável; o histórico append-only honra o
princípio "nunca sobrescrever silenciosamente"; o contrato injetável de chamada torna todo o
pipeline testável offline e prepara a troca plugável por modelos locais para coleções sensíveis.

---

## 2026-08-21 — Biblioteca Viva: promoção do OpenCode/9Router como provedor padrão da classificação

### Decisão

Após smoke test real bem-sucedido (2 chamadas, JSON válido na primeira tentativa, custo zero,
repositório real intocado), o caminho de IA padrão da Fase C passa a ser o OpenCode autenticado
pelo 9Router:

1. `ProvedorIA = 'opencode'` (chave nova) e `ModeloIA = 'opencode/nemotron-3.5-lightning-free'`
   (id real provedor/modelo);
2. O modelo real passa a ser registrado no catálogo, nos detalhes e no histórico porque a
   configuração agora carrega o id verdadeiro — elimina-se o placeholder
   `google/gemini-2.0-flash-001` sem alterar nenhum dos quatro pontos de escrita;
3. Nova função `Invoke-BvChamadaOpencode`: invoca `opencode run -m <ModeloIA> --format json`,
   extrai o texto dos eventos NDJSON, timeout de 180 s por chamada; nenhuma chave é criada ou
   armazenada (a credencial permanece interna ao OpenCode);
4. Ordem de despacho preservada: `-FuncaoChamada` (testes, offline) → opencode (padrão) →
   OpenRouter (alternativa mantida com `UrlOpenRouter` e `Invoke-BvChamadaIA`, exige chave própria);
5. Regra de consumo confirmada: resposta válida = 1 chamada; inválida = no máximo 1 retry;
   persistindo a falha = `classificacao_recusada`; baixa confiança não gera rechamada; texto
   insuficiente e erro de extração = 0 chamadas; nenhum mecanismo de segunda opinião ou reanálise;
6. Teste 15 adicionado à suíte da Fase C: roteamento para `Invoke-BvChamadaOpencode` validado
   com mock em escopo de script, sem rede.

Fora de escopo (permanece): OCR, visão, múltiplas análises, movimentação, renomeação e qualquer
preparação de Fase D.

### Motivo

Usar o ambiente de IA que o laboratório já opera elimina gestão de chaves e custo marginal;
manter o OpenRouter como alternativa preserva redundância; registrar o modelo real na fonte
única (config) corrige os quatro pontos de escrita de uma vez, sem alterar o esquema v1 nem o
contrato injetável que mantém toda a suíte testável offline.

---

*Registro permanente das decisões estruturais do Laboratório de IA.*
