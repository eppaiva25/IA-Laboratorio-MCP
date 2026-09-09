# Guia de Aprendizado — Laboratório de IA

> **Ponto permanente de partida e continuidade do Laboratório de IA.**
> Qualquer sessão nova — humana ou de agente de IA — deve começar por aqui.

---

## 1. Objetivo do Guia

Este é o **documento mestre** de aprendizado e continuidade do Laboratório de IA.

Ele existe para que:

- Um **humano** possa retomar o trabalho a qualquer momento, mesmo após pausas longas.
- Um **agente de IA** possa entender o estado do projeto, o que já foi feito, o que está pendente e qual é a próxima ação.
- Uma **ferramenta de código** possa navegar o contexto do projeto sem depender de memória de sessão.
- O **histórico** do laboratório seja preservado de forma legível e versionada.

O Guia não substitui os arquivos de memória (`ESTADO-ATUAL.md`, `DECISOES.md`, `SESSOES/`). Ele os complementa, oferecendo uma visão transversal e atualizada.

> **Nota sobre `DECISOES.md`:** O arquivo completo de decisões está em `V:\Claude Code\Laboratorio-IA\memoria\DECISOES.md` (fora deste repositório). Ele contém o histórico detalhado das decisões estruturais com suas justificativas. Este Guia contém uma síntese dessas decisões (seção 13) para fins de continuidade. A movimentação ou duplicação do `DECISOES.md` para este repositório não será feita agora — seu destino será decidido durante a futura consolidação estrutural dos repositórios.

---

## Regra de evidência

Este Guia diferencia cinco níveis de evidência:

| Nível | Significado |
|-------|-------------|
| **CONFIRMADO** | Foi observado, executado ou validado. Há evidência direta. |
| **DOCUMENTADO** | Existe registro em documentação, mas não necessariamente foi validado novamente na sessão atual. |
| **PLANEJADO** | Foi decidido ou proposto, mas ainda não implementado. |
| **PENDENTE** | Ainda precisa ser executado ou validado. |
| **NÃO CONFIRMADO** | Existe uma hipótese ou informação que ainda precisa ser verificada. |

> **Regra:** O Guia nunca deve transformar uma intenção, capacidade teórica, documentação antiga ou hipótese em fato confirmado sem evidência.

Esta regra orienta também futuras atualizações feitas por agentes de IA.

---

## 2. Como usar este Guia

Ao iniciar uma sessão:

1. **Leia este Guia** — ele dá o panorama geral.
2. **Leia o estado atual** — a seção mais recente da linha do tempo ou o `ESTADO-ATUAL.md` do repositório ativo.
3. **Leia as decisões** — `DECISOES.md` ou a seção de decisões deste Guia.
4. **Identifique o próximo passo** — procure por "PENDENTE" ou "próximo ponto de retomada".
5. **Trabalhe em etapas pequenas** — testando tudo.
6. **Registre no Guia** — ao final da sessão, atualize o que foi aprendido, o que foi executado, as decisões tomadas e o estado atual.

### O que deve ser registrado

| Tipo de registro | Exemplo |
|------------------|---------|
| O que foi aprendido | "O OmniRoute roteia modelos e controla o limite de contexto via config.yaml" |
| O que foi realmente executado | "Reiniciamos o container do Hermes e validamos context_length: 128000" |
| Decisões tomadas | "Mantivemos o limite em 128000 tokens para auto/best-free" |
| Motivo da decisão | "O provider Groq tem limite de 8000 TPM; 128k evita HTTP 503" |
| Estado atual | "Hermes está rodando com contexto limitado; Google OAuth autenticado" |
| Problemas conhecidos | "Três repositórios apontam para o mesmo remote — consolidar futuramente" |
| Conceitos que precisam de revisão | "OAuth com token root-owned — não resolvido" |
| Próximo ponto de retomada | "Consolidar repositórios após validar o Guia V1" |

---

## 3. Método de trabalho

O Laboratório segue um ciclo disciplinado:

```
entender → inspecionar → analisar → decidir → modificar → validar → registrar no Guia → refletir no repositório
```

**Princípios:**

- **Entender** o problema antes de agir.
- **Inspecionar** o estado atual (ler arquivos, logs, configurações).
- **Analisar** opções e consequências.
- **Decidir** de forma registrada, com motivo explícito.
- **Modificar** apenas após aprovação e com reversibilidade.
- **Validar** com testes ou conferência manual.
- **Registrar** no Guia e na memória do repositório.
- **Refletir** no Git (commit) para preservar o histórico.

**Regra de ouro:** o agente propõe — a decisão é humana.

---

## 4. Linha do tempo do Laboratório

### Fundamentos (18/08/2026)

- Git instalado, configurado e praticado (init, add, commit, restore, diff, log).
- Conceitos fundamentais: repositório, commit, branch, working directory, staging area.
- Primeiro commit: `4c63ef8 — chore: inicializa Laboratório de IA`.
- Markdown definido como formato oficial da documentação.
- Memória organizada em três níveis: ESTADO-ATUAL, DECISOES, SESSOES.

### Modelos, Ferramentas e Agentes (18–19/08/2026)

- Conceitos de modelo, ferramenta (tool), agente e MCP estudados.
- Ollama instalado localmente com três modelos: gemma4:12b, gemma4:26b, 4skl/gemma4-e4b-mtp:latest.
- OpenCode 1.18.18 configurado com provider OpenCode Free.
- 9Router v0.5.55 instalado e validado em http://localhost:20128.
- Combo ProjetoLab criado e testado no 9Router.
- Duas frentes de execução definidas e validadas:
  - Frente 1: OpenCode → 9Router → provedores
  - Frente 2: Claude Code → OpenRouter → openrouter/free

### Segurança e Chaves (20/08/2026)

- Chave OpenRouter armazenada em cofre DPAPI (`%USERPROFILE%\.openrouter\key.sec`).
- Wrapper `Start-ClaudeCode` criado: descriptografa sob demanda, injeta variáveis, limpa ao finalizar.
- Rotação da chave validada ponta a ponta.
- Regra estabelecida: segredos nunca entram no repositório.

### Agente Explorador (18/08/2026)

- Especificação do Agente Explorador criada em `docs/01-aprendizado-agente-explorador.md`.
- Conceito documentado como estudo inicial de agentes de IA.

### Biblioteca Viva V1 / PowerShell (20–21/08/2026)

- Construção de uma biblioteca documental que localiza, lê e responde sobre documentos.
- Núcleo com dois modos de operação: MIGRAÇÃO/LOTE e MANUTENÇÃO/INCREMENTAL.
- Pipeline: descobridor → reconciliação → catálogo → módulos → classificação → aprovação humana → execução → pré-voo.
- CLI com 4 opções: listar, pesquisar, perguntar à IA, sair.
- Camada de IA desacoplada: `Invoke-BvChamadaOpencode` como único ponto de contato.
- Fluxo testado: PDF → extração de texto → opencode → 9Router/OpenRouter → modelo → resposta.
- Incidente registrado: destruição de estado local em `dados/` por suítes de teste (21/08/2026).

### Evolução da Biblioteca Viva (21/08/2026)

- Fase B aprovada: descobridor, reconciliação, roteador, módulo PDF, diário JSONL.
- Fase C aprovada: extração de conteúdo, classificação com IA, três camadas (técnica, conteúdo, semântica).
- OpenCode/9Router promovido a provedor padrão da classificação.
- Taxonomia fechada de 9 categorias definida.

### DSH — Análise Biblioteca Viva (21–23/08/2026)

- `DSH-Analise-Biblioteca-Viva` criado como linha de análise/snapshot.
- Análise preliminar produzida (`ANALISE-PRELIMINAR.md`).
- Validações O1/O3/DA4 documentadas.

### Biblioteca Viva — Proposta V2 (22/08/2026)

- Arquitetura V2 proposta (não implementada nesta data): eventos v2, catálogo versionado, política de risco, qualidade de leitura, revisão pós-execução.
- Oportunidades registradas: O1 (taxonomia), O2 (confiança), O3 (extração), O4 (revisão), O5 (consolidação).
- **Status:** PROPOSTA — nenhuma implementação nesta etapa.

### Biblioteca Viva — Implementação V2 / Python (22–25/08/2026)

- Reescrita completa em Python puro (stdlib).
- Princípio central preservado: `IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA`.
- Ciclo do agente: PERCEBER → DECIDIR → AGIR → VERIFICAR → REGISTRAR.
- Porta única: `entrar.py`.
- Catálogo como fonte de verdade (JSON com 9 categorias).
- Dry-run obrigatório por padrão.
- Pré-voo bloqueante antes de qualquer ação.
- Nunca sobrescrever (sufixo `-1`, `-2`…).
- Auditoria append-only em JSONL.
- Estado final: FECHADA E APROVADA PARA USO (22/08/2026).

### Validações da Biblioteca Viva V2 (22–23/08/2026)

**CONFIRMADO:**
- Testes sobre fixtures (9 arquivos): 9/9 simulado.
- Testes sobre 45 PDFs reais (simular): 44 simulado + 1 erro_ia.
- Organização real de 45 PDFs: movidos e verificados com sucesso (validação histórica).
- O1 — Taxonomia expandida: 14 folhas (era 9).
- O3/DA4 — Qualidade de leitura: heurística determinística.
- O5 — Consolidação: ferramenta offline.

**IMPORTANTE:** A validação de movimentação dos 45 PDFs é um registro histórico. O incidente de 21/08/2026 afetou o estado/catalogação dos dados locais. O catálogo real atualmente requer re-inventário (ver seção 8 — Pendências). Não devemos assumir que os 45 PDFs continuam organizados exatamente como naquela validação.

### Hermes Agent (04–05/09/2026)

> **Rigor de evidência:** as execuções descritas nesta seção e na seção 10 são **atividades documentadas como executadas em Docker** — o Git contém a documentação produzida pelo próprio projeto, não evidência independente de execução. Onde esta distinção existe, ela está marcada.

- Hermes Agent instalado e configurado em Docker.
- Interface: Telegram.
- Container: `hermes-agent_web_1` (imagem `ghcr.io/getumbrel/hermes-agent-umbrel:v2026.8.19`).
- Dados persistentes em `/opt/data/`.
- OmniRoute como roteador de modelos (http://omniroute:20128).
- Modelo customizado: `auto/best-free`.
- Limite de contexto corrigido: 128000 tokens (era 1000000, causava HTTP 503).
- Sistema de alertas e lembretes documentado como executado e validado no ambiente Docker (Fase 1): criação, execução, notificação, cancelamento, fuso horário, prevenção de duplicação.

### Google Workspace (05/09/2026)

- OAuth validado (documentado como executado em Docker): `AUTHENTICATED` e `LIVE_CHECK_OK`.
- Google Calendar testado em modo somente leitura (próximos 3 eventos / 7 dias).
- Pendência: token parece root-owned; skill google-workspace pode tentar renová-lo.
- Hermes contornou via API direta.

### Ollama

- Três modelos instalados localmente: gemma4:12b, gemma4:26b, 4skl/gemma4-e4b-mtp:latest.
- Modelos funcionais, mas **lentos** no hardware atual.
- Decisão: cloud priorizado para desenvolvimento; Ollama mantido para testes offline.

### OmniRoute

- Serviço de roteamento/agregação de modelos.
- Endpoint interno: `http://omniroute:20128`.
- Combo ProjetoLab configurado.
- Limite de contexto controlado por `config.yaml` e `context_length_cache.yaml`.

### Ferramentas, Memória e Automações

- Wrapper `Start-ClaudeCode` para carregamento seguro de chaves.
- Sistema de memória persistente do laboratório (ESTADO-ATUAL, DECISOES, SESSOES).
- Sistema de alertas do Hermes (Fase 1 validada).

### Docker

- Hermes Agent rodando em container Docker.
- Dados persistentes em `/opt/data/`.
- OmniRoute como container independente na mesma rede.
- Procedimento de diagnóstico e restart validado.

### Telegram

- Interface do Hermes Agent.
- Comunicação via bot.
- Testes de alertas e lembretes realizados (documentados como executados em Docker).

### Ponte do Período 8 (25/08/2026)

- Commit `49afbc5` (25/08 00:29), filho direto do fechamento do Período 8 (`d21324f`, 23/08): **evolução direta da mesma base de código confirmada** — compatibilidade determinística por extensão em `nucleo.py` (mapas `EXTENSAO_PARA_TIPO`/`TIPO_PARA_CATEGORIA_BASE` e `_categoria_base_compativel()`), folha "Áudio" no catálogo (13→14) e teste novo (`teste_compatibilidade_extensao.py`, 123 linhas).
- Conteúdo interno remete ao trabalho de 23–24/08 (sessão `SESSOES/2026-08-23.md`, corrida de eventos de 24/08). Decisão de fronteira registrada: 25/08 é **fronteira administrativa**, não ruptura histórica comprovada; `49afbc5` é **ponte/extensão tardia do Período 8**.

### Período 9 (03–07/09/2026)

Trabalho inequivocamente novo após o Período 8. Classificação A/B aplicada: artefatos produzidos no período (A) versus patrimônio histórico anterior apenas descoberto durante a investigação (B).

- **03/09 — Proteção de dados locais** (`b736852`): primeiro `.gitignore` do repositório (`.env`, chaves, `dados/`, mídias de teste, `eventos/*.jsonl`) + `VALIDACAO-TESTE-USUARIO.md` registrando a validação do teste físico de 23/08 (9/9 arquivos, hashes íntegros).
- **04–05/09 — Hermes: alertas e contexto** (documentação em `Laboratorio-IA`, commits `0cdcf66`/`25c3529`/`026c49a`): Fase 1 de alertas e diagnóstico/correção do limite de contexto OmniRoute — atividade documentada como executada em Docker (falha HTTP 503 com ~106.879 tokens contra TPM 8.000 do Groq; correção `context_length: 128000` em `/opt/data/config.yaml`).
- **06/09 — Hermes: Gmail e Calendar** (commits `4e16c33`/`ac0e967`): documentação [validado] das integrações, incluindo proteção de `google_token*.json`/`client_secret*.json`.
- **07/09 — Consolidação do conhecimento** (commits `d2df579`/`bb3dbcf`/`0cf64e1`): este Guia (V1.1) + referências + registro da localização do `DECISOES.md`.
- **07–09/09 — Investigação forense e transferência histórica:** Período 9 investigado, corrigido e transferido para `V:\LABORATORIO_IA\99-HISTORICO\` (commit `8c488f7`), com `METADADOS-ORIGEM.md` preservando proveniência (GIT CONFIRMADO / WORKTREE / DADOS INSUFICIENTES PARA VERIFICAR).

### Segurança

- Chaves em cofre DPAPI, nunca no repositório.
- Wrapper com limpeza de ambiente.
- Regra: segredos nunca em texto puro.
- Pré-voo bloqueante na Biblioteca Viva.
- Dry-run por padrão.

### Situação Atual (Setembro de 2026)

- Laboratório com múltiplos repositórios Git (estrutura a ser consolidada).
- Biblioteca Viva V2 funcional e aprovada.
- Hermes Agent operacional com OmniRoute.
- Google OAuth/Calendar autenticado.
- Alertas do Hermes validados (Fase 1).
- Guia de Aprendizado estabelecido como ponto de partida permanente.

---

## 5. Fundamentos

### Modelo

Um **modelo** é a "inteligência" que gera respostas. É o componente que recebe um texto de entrada e produz um texto de saída.

**Exemplos estudados:**
- `gemma4:12b`, `gemma4:26b` (Ollama local)
- `anthropic/claude-haiku-4.5` (OpenRouter)
- `openrouter/free` (gateway)
- `auto/best-free` (OmniRoute)
- `opencode/nemotron-3.5-lightning-free` (OpenCode)

**Como funciona:** O modelo recebe um prompt (pergunta/instrução) e retorna uma resposta. Cada modelo tem capacidades, custos e limites diferentes.

### Tool / Ferramenta

Uma **ferramenta** (tool) é uma capacidade que o agente pode executar no mundo real: ler um arquivo, escrever um arquivo, rodar um comando, consultar uma API, enviar uma mensagem.

**Exemplos estudados:**
- Leitura de arquivos (o agente lê o conteúdo de um PDF)
- Escrita de arquivos (o agente cria ou modifica um arquivo)
- Execução de comandos (o agente roda um comando no terminal)
- Google Calendar (o agente consulta eventos)
- Gmail (o agente lê/envia e-mails — pendente de validação completa)

**Princípio:** a ferramenta é o elo entre o pensamento do agente e a ação no mundo real.

### Agente

Um **agente** é um programa que usa um modelo + ferramentas para executar tarefas de forma autônoma (sob supervisão humana).

**Exemplos estudados:**
- Claude Code (agente de programação no terminal)
- OpenCode (agente alternativo no terminal)
- Hermes Agent (agente pessoal via Telegram)
- Biblioteca Viva (agente de organização de arquivos)

**Princípio do Laboratório:** o agente propõe — a decisão é humana.

### MCP (Model Context Protocol)

O **MCP** é um protocolo para conectar agentes de IA a ferramentas externas de forma padronizada.

**O que sabemos:** MCP está no objetivo do laboratório, mas **ainda não foi estudado em profundidade**. É uma etapa futura.

### Relação entre eles

```
Usuário → Agente → Modelo (pensamento) → Ferramenta (ação) → Resultado → Modelo (processamento) → Usuário
```

**Exemplo prático (Hermes → Gmail):**

1. Usuário envia mensagem no Telegram: "Quais são minhas últimas 3 do Gmail?"
2. Hermes (agente) recebe a mensagem.
3. Hermes envia ao modelo (via OmniRoute): "Leia as 3 últimas do Gmail."
4. Modelo responde: use a ferramenta Gmail com parâmetros X, Y, Z.
5. Hermes executa a ferramenta Gmail → obtém as 3 .
6. Hermes envia ao modelo: "Aqui estão as 3 : [resultado]."
7. Modelo responde formatando a lista para o usuário.
8. Hermes envia a resposta no Telegram.

---

## 6. Git

### Conceitos

- **Repositório:** pasta vigiada pelo Git, com todo o histórico de alterações.
- **Commit:** "foto" do projeto num momento, com mensagem e código único.
- **Branch:** linha de desenvolvimento paralela (ex.: `main`, `master`).
- **Remote:** repositório remoto no GitHub (ou outro serviço).
- **Clone:** cópia de um repositório remoto para a máquina local.
- **Histórico:** sequência de todos os commits.
- **Merge:** junção de duas branches.
- **Gitlink:** referência de um repositório dentro de outro (submódulo).

### O ciclo do Git

```
status → diff → add → diff --staged → commit → status
```

- `git status` — o que está modificado?
- `git diff` — o que mudou?
- `git add` — preparar para commit.
- `git diff --staged` — revisar antes de commitar.
- `git commit` — registrar no histórico.
- `git restore <arquivo>` — descartar alteração.

### Proveniência: o que o Git confirma (e o que não confirma)

Aprendido na investigação histórica do Período 9. Duas igualdades que **não** são verdadeiras:

1. **Arquivo existente ≠ arquivo versionado.** Um arquivo pode existir no disco (worktree) sem nunca ter sido commitado.
2. **Hash igual ≠ existência de um blob Git correspondente.** O SHA-256 de um arquivo do worktree pode bater com o do destino de uma cópia, mas isso não prova que o conteúdo existe como objeto Git (blob) em nenhum repositório. Para isso é preciso verificar o objeto no banco do Git (`git cat-file`, `git show`).

> **Importante prático:** `git rev-parse --verify <hash>` pode dar falso-positivo para hashes de 40 dígitos hexadecimais em algumas versões do Git. Use `git cat-file -t <hash>` para confirmar a existência real de um objeto.

**Classificação de proveniência usada no laboratório:**

| Categoria | Significado |
|-----------|-------------|
| **Commit** | Foto registrada no histórico, com hash, autor e data imutáveis. |
| **Arquivo rastreado** | Sob vigiação do Git; alterações aparecem em `git status`/`git diff`. |
| **Arquivo não rastreado** | No disco, fora do Git; sem histórico, sem hash, sem proveniência. |
| **Arquivo ignorado** | Excluído deliberadamente do Git por `.gitignore` (dados locais, segredos, logs). |
| **Patrimônio histórico** | Artefato cujo valor é documentar o que aconteceu; merece preservação com proveniência registrada. |
| **Dado operacional** | Necessário para operar agora, mas sem valor histórico em si (logs, caches, backups). |
| **Dado pessoal** | Conteúdo privado (ex.: inventário da biblioteca pessoal); nunca versionado sem decisão explícita. |
| **Evidência documental** | Registro criado pelo próprio projeto sobre algo que aconteceu fora do Git — **documenta, mas não prova independentemente**. |

**Convenção adotada** (em `V:\LABORATORIO_IA\99-HISTORICO\`): cada transferência registra origem, commit, data, SHA-256 e status de proveniência em `METADADOS-ORIGEM.md`, com três níveis: **GIT CONFIRMADO**, **WORKTREE** (nunca commitado) e **DADOS INSUFICIENTES PARA VERIFICAR**. Motivo: a primeira transferência do Período 8 copiou arquivos sem preservar proveniência de commit, e o objeto `d21324f` não existe no repositório de destino.

### Situação atual do Laboratório

> ⚠️ **PROBLEMA ESTRUTURAL CONHECIDO — NÃO RESOLVIDO NESTA ETAPA**

**Arquitetura Git atual:**

| Diretório | Git | Remote | Branch | Função | Observação |
|-----------|-----|--------|--------|--------|------------|
| `V:\Claude Code` | Sim | **Sem remote** | main | Repositório pai/guarda-chuva local | Contém os subdiretórios; não é fonte de verdade do projeto |
| `IA-Laboratorio-MCP` | Sim | `github.com/eppaiva25/IA-Laboratorio-MCP` | main | **Fonte de verdade atual (provisória)** | Repositório escolhido para manter o Guia e a documentação principal |
| `Laboratorio-IA` | Sim | `github.com/eppaiva25/IA-Laboratorio-MCP` | **master** | Repositório com mais conteúdo histórico | Mesmo remote, branch diferente, alterações pendentes |
| `DSH-Analise-Biblioteca-Viva` | Sim | `github.com/eppaiva25/IA-Laboratorio-MCP` | main | Repositório de análise/snapshot | Mesmo remote, histórico independente |

**Problemas:**
1. Três repositórios apontam para o mesmo remote GitHub.
2. Históricos independentes competem pelo mesmo destino.
3. Não há `.gitmodules` — os diretórios não são submódulos Git.
4. O repositório pai não tem remote configurado.

**Nota sobre `V:\Claude Code`:** Este é o repositório pai/guarda-chuva local. Ele contém os subdiretórios, mas **não é a fonte de verdade do projeto**. A fonte de verdade atual (provisória) é `IA-Laboratorio-MCP`. Esta situação será revisada durante a futura consolidação estrutural.

---

## 7. Docker

### Conceitos

- **Imagem:** template imutável com tudo necessário para rodar um programa (código, dependências, configurações).
- **Container:** instância em execução de uma imagem. É isolado do sistema host.
- **Volume:** mecanismo para persistir dados além do ciclo de vida do container.
- **Configuração:** arquivos que definem como o programa se comporta (ex.: `config.yaml`).
- **Persistência:** dados que sobrevivem à destruição/reinício do container.

### Como usado no Laboratório

- **Hermes Agent:** container `hermes-agent_web_1` com dados em `/opt/data/`.
- **OmniRoute:** container na mesma rede Docker, acessível via `http://omniroute:20128`.
- **Dados persistentes:** configuração, cache de contexto, backups ficam em `/opt/data/` e sobrevivem a restarts.
- **Diagnóstico:** `docker ps`, `docker restart`, `docker exec` para conferir configuração.

### Procedimento de diagnóstico validado

```bash
docker ps                                    # verificar estado
docker restart hermes-agent_web_1            # reiniciar container
docker exec hermes-agent_web_1 cat /opt/data/config.yaml  # conferir config
```

---

## 8. Biblioteca Viva

### Evolução

| Fase | Tecnologia | Status |
|------|------------|--------|
| V1 | PowerShell | Fechada e aprovada (21/08/2026) |
| DSH | Análise/snapshot | Concluída |
| V2 (proposta) | Python | Proposta registrada, não implementada |
| V2 (implementada) | Python | Fechada e aprovada (22/08/2026) |

### Princípio central (preservado em todas as versões)

```
IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA
```

### O que a Biblioteca Viva faz

Organiza arquivos de uma pasta de entrada dentro de uma biblioteca categorizada, usando IA apenas para propor categorias — toda execução é determinística e verificada.

### Ciclo do agente

1. **PERCEBER** — hash SHA-256, nome, extensão, tamanho, conteúdo.
2. **DECIDIR** — IA propõe `{categoria, confianca, motivo}`; código valida contra catálogo.
3. **AGIR** — move sem nunca sobrescrever (sufixo `-1`, `-2`…).
4. **VERIFICAR** — destino existe + origem vazia + hash idêntico.
5. **REGISTRAR** — linha JSONL append-only com todo o ciclo.

### Garantias

- Dry-run obrigatório por padrão.
- Pré-voo bloqueante antes de qualquer ação.
- Nunca sobrescrever; nunca apagar.
- Erro da IA não move nada.
- Confiança abaixo de 60% vai para `Outros`.
- Auditoria append-only de tudo.

### Validações realizadas (histórico)

| Validação | Status | Observação |
|-----------|--------|------------|
| Testes sobre fixtures (9 arquivos) | ✅ 9/9 simulado | CONFIRMADO |
| Testes sobre 45 PDFs reais (simular) | ✅ 44 simulado + 1 erro_ia | CONFIRMADO |
| Organização real (45 PDFs) | ✅ 45/45 movidos e verificados | VALIDAÇÃO HISTÓRICA — ver nota abaixo |
| O1 — Taxonomia expandida | ✅ 14 folhas (era 9) | CONFIRMADO |
| O3/DA4 — Qualidade de leitura | ✅ Heurística determinística | CONFIRMADO |
| O5 — Consolidação | ✅ Ferramenta offline | CONFIRMADO |
| Compatibilidade determinística por extensão (`49afbc5`, 25/08) | ✅ `_categoria_base_compativel()` + teste dedicado (123 linhas) | CONFIRMADO (código commitado e lido; execução do teste: DOCUMENTADO) |

> **Nota sobre a validação dos 45 PDFs:** A movimentação e verificação dos 45 PDFs é um registro histórico validado em 22/08/2026. O incidente de 21/08/2026 (destruição de estado local) afetou o catálogo real. O estado atual dos 45 PDFs pode não corresponder ao resultado daquela validação. O catálogo real requer re-inventário antes de qualquer operação nova.

> **Divergência documentada (descoberta na investigação do Período 9 — NÃO resolvida):** a pendência "catálogo vazio" foi registrada em `Laboratorio-IA\memoria\PENDENCIA-CATALOGO-VAZIO.md` (21/08 20:55), mas o arquivo `biblioteca-viva/dados/catalogo.csv` desse repositório foi preenchido com dados reais (~14,5 KB, 46 PDFs) às 21:24 do mesmo dia — 29 minutos depois, sem registro commitado. O arquivo contém **dados pessoais** (saúde, finanças, nomes) e é gitignored por política ("catálogo e diário nunca são versionados"). O re-inventário continua pendente; a divergência entre o registro da pendência e o estado real do arquivo permanece documentada, não corrigida. O mesmo vale para `diario.jsonl` (registro real de execução com dados pessoais, nunca versionado).

### Pendências

- **O2 — Política de confiança/risco** — PENDENTE desde a proposta V2. Ausente também da lista de pendências desta seção até a revisão V1.2 (divergência corrigida aqui).
- **O4 — Revisão pós-execução** — PENDENTE desde a proposta V2. Ausente também da lista de pendências desta seção até a revisão V1.2 (divergência corrigida aqui).
- **Catálogo real vazio** — `catalogo.csv` tem apenas cabeçalho (consequência do incidente 21/08/2026). Requer re-inventário dos 45 PDFs.
- **Incidente 21/08/2026** — suítes de teste destruíram estado local. Pendente: recuperar catálogo, corrigir isolamento das suítes.

---

## 9. Hermes Agent

### O que é

Agente pessoal que conversa via Telegram, rodando em Docker, usando OmniRoute para roteamento de modelos.

### Ambiente

| Item | Valor |
|------|-------|
| Container | `hermes-agent_web_1` |
| Imagem | `ghcr.io/getumbrel/hermes-agent-umbrel:v2026.8.19` |
| Interface | Telegram |
| Dados | `/opt/data/` (dentro do container) |
| Modelo | `auto/best-free` |
| Endpoint | `http://omniroute:20128` |
| Contexto | 128000 tokens |

### Configuração

- **Modelo customizado** registrado em `config.yaml` com `context_length: 128000`.
- **Cache de contexto** em `context_length_cache.yaml` (parte do funcionamento do Hermes; não apagar).
- **Backup** em `config.yaml.bak.before-context-limit`.

### Ferramentas

- **Sistema de alertas e lembretes** — Fase 1 validada (criação, execução, notificação, cancelamento, fuso horário, prevenção de duplicação).
- **Google Calendar** — leitura validada (próximos 3 eventos / 7 dias).
- **Google Gmail** — pendente de validação completa.

### Automações

- Lembretes agendados via cronjob interno do Hermes.
- Prompt v1 para prevenção de duplicação.
- Fuso horário `America/Sao_Paulo` utilizado explicitamente.

### Segurança

- Container roda como usuário `hermes`.
- Dados persistentes isolados em `/opt/data/`.
- Backup de configuração antes de alterações.
- Não expor tokens ou credenciais.

### Configuração em Windows

- Docker Desktop rodando no Windows.
- Container acessível via comandos `docker exec`, `docker restart`.

### Configuração em Linux/Umbrel

- Hermes Agent integrado ao Umbrel (plataforma de auto-hospedagem).
- OmniRoute como serviço na mesma rede Docker.

### Limitações e problemas encontrados

- **Limite de contexto:** corrigido de 1000000 para 128000 tokens (causava HTTP 503).
- **Provider Groq:** limite de 8000 TPM — conversas longas esgotam o limite.
- **Token Google:** parece root-owned; skill google-workspace pode tentar renová-lo.
- **UTC no container:** timezone do sistema é UTC; Hermes usa `America/Sao_Paulo` explicitamente.
- **Duplicação de lembretes:** observada em testes simples; resolvida com Prompt v1.

---

## 10. Google Workspace

### OAuth

**DOCUMENTADO (atividade documentada como executada em Docker; sem verificação independente):**
- Autenticação OAuth validada via `setup.py --check`: resultado `AUTHENTICATED`.
- Verificação ao vivo via `setup.py --check-live`: resultado `LIVE_CHECK_OK`.
- Setup executado dentro do container do Hermes.

### Google Calendar

**DOCUMENTADO (atividade documentada como executada em Docker; sem verificação independente):**
- Leitura testada em modo somente leitura.
- Próximos 3 eventos / 7 dias validados.
- Nenhum evento foi criado, editado ou excluído.
- Skill utilizada: `google-workspace`.

**PENDENTE:**
- Escrita no Calendar (criação/edição/exclusão de eventos).
- Testes de operações de escrita.

### Gmail

**DOCUMENTADO:** Integração com Hermes está prevista/registrada na documentação do projeto.

**NÃO CONFIRMADO:** Nenhuma operação específica do Gmail foi validada nos documentos consultados.

**PENDENTE:** Validação completa do Gmail (leitura de e-mails, envio de e-mails, qualquer operação específica).

### Fluxo de autenticação

1. OAuth configurado dentro do container do Hermes.
2. Token armazenado em `/opt/data/`.
3. Hermes usa API direta para contornar limitações da skill `google-workspace`.

### Integração com Hermes

- Hermes pode acessar Google Calendar via skill `google-workspace` ou via API direta.
- Funcionalidade de Gmail está documentada mas não detalhada nos registros consultados.

### Problemas já encontrados

- Token Google parece root-owned.
- Skill `google-workspace` pode tentar renovar token de forma inesperada.

### Soluções já tentadas

- Hermes contornou via API direta para Calendar, sem depender da renovação pela skill.

### Pontos ainda pendentes

- Validação completa do Gmail.
- Resolução do problema de ownership do token.
- Teste de escrita no Calendar (criação/edição/exclusão de eventos).
- Renovação automática do token pela skill (comportamento a investigar).

---

## 11. Estado atual

### Estado atual — Setembro de 2026 (após consolidação do Período 9)

| Item | Status |
|------|--------|
| `IA-Laboratorio-MCP` | Fonte de verdade escolhida (provisória) |
| `V:\Claude Code` | Repositório pai/guarda-chuva local (não é fonte de verdade) |
| Guia de Aprendizado | Criado neste repositório; V1.2 consolidado com o Período 9 |
| Períodos históricos 1–9 | Investigados e transferidos para `V:\LABORATORIO_IA\99-HISTORICO\` (P8: `d75794b`; P9: `8c488f7`) com proveniência em `METADADOS-ORIGEM.md` |
| Push do repositório histórico (`V:\LABORATORIO_IA`) | PENDENTE (não autorizado até o momento) |
| Repositórios duplicados | Existentes, consolidação NÃO realizada |
| HTML antigo | Preservado em `materiais-de-estudo/` |
| Reorganização estrutural | NÃO realizada nesta etapa |
| Biblioteca Viva V2 | Funcional e aprovada (validações históricas preservadas); compatibilidade por extensão adicionada em `49afbc5` |
| Hermes Agent | Operacional com OmniRoute (atividade documentada como executada em Docker) |
| Google OAuth | DOCUMENTADO: autenticado (`AUTHENTICATED`/`LIVE_CHECK_OK`, execução em Docker) |
| Google Calendar | DOCUMENTADO: leitura validada (3 eventos / 7 dias, execução em Docker) |
| Google Calendar (escrita) | PENDENTE: não testado |
| Google Gmail | PENDENTE: validação completa não realizada |
| Alertas do Hermes | Fase 1 documentada como executada e validada em Docker |
| Git | Funcional nos subdiretórios; problema estrutural no nível pai |

### O que está confirmado

- `IA-Laboratorio-MCP` é, por enquanto, a fonte de verdade escolhida (provisória).
- `V:\Claude Code` é o repositório pai/guarda-chuva local, não a fonte de verdade.
- O Guia será mantido neste repositório.
- Existem repositórios duplicados/concorrentes.
- A consolidação ainda NÃO foi realizada.
- O HTML antigo continua preservado.
- Nenhuma reorganização estrutural foi feita nesta etapa.
- OAuth Google está autenticado (DOCUMENTADO — execução em Docker, sem verificação independente).
- Calendar leitura está validada (DOCUMENTADO — execução em Docker, sem verificação independente).
- Calendar escrita está pendente (PENDENTE).
- Gmail está pendente de validação completa (PENDENTE).
- O patrimônio dos Períodos 1–9 está preservado em `V:\LABORATORIO_IA\99-HISTORICO\` (commits `d75794b` e `8c488f7`), com hash SHA-256 e proveniência por arquivo; os repositórios de origem não foram alterados pela transferência.

---

## 12. Problemas conhecidos / pendências

| # | Pendência | Status | Prioridade |
|---|-----------|--------|------------|
| 1 | Consolidar `Laboratorio-IA` em `IA-Laboratorio-MCP` | PENDENTE | Alta |
| 2 | Resolver os três remotes apontando para o mesmo GitHub | PENDENTE | Alta |
| 3 | Decidir o destino do `DSH-Analise-Biblioteca-Viva` | PENDENTE | Média |
| 4 | Decidir o destino de `materiais-de-estudo` | PENDENTE | Média |
| 5 | Avaliar o papel do repositório pai `V:\Claude Code` | PENDENTE | Média |
| 6 | Preservar históricos importantes durante futura consolidação | PENDENTE | Alta |
| 7 | Recuperar catálogo real da Biblioteca Viva (re-inventário dos 45 PDFs) | PENDENTE | Média |
| 8 | Corrigir isolamento das suítes de teste (evitar acesso a `dados/` real) | PENDENTE | Média |
| 9 | Validar completamente o Gmail no Hermes (leitura, envio, qualquer operação) | PENDENTE | Média |
| 10 | Resolver problema de ownership do token Google | PENDENTE | Média |
| 11 | Testar escrita no Google Calendar (criação/edição/exclusão de eventos) | PENDENTE | Baixa |
| 12 | Investigar renovação automática do token pela skill google-workspace | PENDENTE | Baixa |
| 13 | O2 — Política de confiança/risco da Biblioteca Viva (pendente desde a proposta V2) | PENDENTE | Média |
| 14 | O4 — Revisão pós-execução da Biblioteca Viva (pendente desde a proposta V2) | PENDENTE | Média |
| 15 | Autorizar/realizar push do repositório histórico `V:\LABORATORIO_IA` | PENDENTE | Baixa |
| 16 | Definir destino/proveniência dos artefatos de teste de agosto em `Laboratorio-IA` (`sandbox.ps1`, `resposta_inicial.txt`, suítes `.ps1` modificadas — sem proveniência Git) | PENDENTE | Baixa |
| 17 | Decidir a preservação histórica de `catalogo.csv`/`diario.jsonl` (dados pessoais reais; exigem decisão explícita) | PENDENTE | Média |

---

## 13. Decisões importantes

### 2026-09-09 — Fronteira entre o Período 8 e o Período 9

**Decisão:** `49afbc5` (25/08/2026) é classificado como **ponte/extensão tardia do Período 8**, não como início do Período 9. O trabalho inequivocamente novo do Período 9 começa em `b736852` (03/09/2026).

**Motivo:** `49afbc5` é filho direto do fechamento do Período 8 (`d21324f`, 23/08) e seu conteúdo interno remete ao trabalho de 23–24/08 (sessão de 23/08, corrida de eventos de 24/08). A data de 25/08 é fronteira administrativa, não ruptura histórica comprovada.

### 2026-09-09 — Proveniência obrigatória em transferências históricas

**Decisão:** toda transferência de patrimônio para `V:\LABORATORIO_IA\99-HISTORICO\` deve registrar origem, commit, data, SHA-256 e status de proveniência (GIT CONFIRMADO / WORKTREE / DADOS INSUFICIENTES PARA VERIFICAR) em `METADADOS-ORIGEM.md`.

**Motivo:** a primeira transferência (Período 8, commit `d75794b`) copiou arquivos sem preservar a proveniência de commit — o objeto `d21324f` não existe no repositório de destino. A transferência do Período 9 (commit `8c488f7`) já seguiu a convenção.

### 2026-09-07 — Não reorganizar agora

**Decisão:** Não reorganizar os repositórios nesta etapa. Primeiro estabelecer o Guia como memória mestre e fonte de continuidade.

**Motivo:**
- A reorganização de repositórios é uma operação de risco que pode causar perda de histórico.
- Antes de mover qualquer coisa, é necessário ter um ponto de referência claro e estável.
- O Guia de Aprendizado serve exatamente como esse ponto de referência.
- Com o Guia estabelecido, a reorganização pode ser planejada e executada de forma controlada, com cada etapa documentada.

### 2026-08-18 — Git como controle de versões e memória

**Decisão:** O Laboratório de IA utilizará um repositório Git local como mecanismo de controle de versões e como parte da memória persistente do projeto.

### 2026-08-18 — Markdown como formato principal

**Decisão:** O formato principal para documentação será Markdown (.md). PDF e DOCX poderão ser gerados como derivados, mas não são fontes paralelas.

### 2026-08-18 — Memória organizada em três níveis

**Decisão:** A memória será dividida em: ESTADO-ATUAL.md, DECISOES.md, SESSOES/.

### 2026-08-18 — Segurança antes de automação

**Decisão:** Antes de permitir que agentes executem alterações, devemos compreender e testar o mecanismo de controle de versões.

### 2026-08-18 — Continuidade entre sessões

**Decisão:** Ao iniciar nova sessão, a primeira referência deve ser a memória persistente do laboratório.

### 2026-08-19 — Arquitetura de execução de modelos

**Decisão:** Três caminhos para execução: OpenRouter, Ollama Cloud, Ollama Local. Cloud priorizado para desenvolvimento; Ollama para testes offline.

### 2026-08-20 — Segredos fora do repositório

**Decisão:** Chaves de API ficam exclusivamente em cofre DPAPI, carregadas sob demanda pelo wrapper. O repositório nunca contém a chave.

### 2026-08-20 — Duas frentes de execução

**Decisão:** OpenCode → 9Router → provedores (Frente 1) e Claude Code → OpenRouter → openrouter/free (Frente 2).

---

## 14. Nível de aprendizado

### Conceitos já compreendidos

- Git: init, add, commit, restore, diff, log, status, branch, remote.
- Modelos de IA: conceito, execução local (Ollama) e cloud (OpenRouter, 9Router).
- Agentes: conceito, Claude Code, OpenCode, Hermes Agent.
- Ferramentas: conceito, leitura/escrita de arquivos, execução de comandos.
- Docker: imagens, containers, volumes, diagnóstico.
- Segurança: DPAPI, wrappers, limpeza de ambiente.
- Biblioteca Viva: princípio central, ciclo do agente, validações, compatibilidade determinística por extensão.
- Hermes Agent: instalação, configuração, alertas, OAuth.
- Contexto e limites: contexto disponível versus contexto necessário; TPM de providers (Groq: 8.000); diagnóstico de HTTP 503; configuração de `context_length` (documentado em 05/09).
- Proveniência: arquivo existente ≠ arquivo versionado; hash igual ≠ blob Git; commit / rastreado / não rastreado / ignorado; evidência documental ≠ prova independente (ver seção 6).

### Conceitos em consolidação

- OmniRoute: roteamento de modelos, limite de contexto.
- Google Workspace: OAuth (CONFIRMADO), Calendar leitura (CONFIRMADO).
- Git avançado: repositórios concorrentes, consolidação.

### Conceitos que precisam de revisão

- MCP: ainda não estudado em profundidade.
- n8n: ainda não estudado.
- Python: usado na Biblioteca V2, mas não sistematizado.
- Git: problema estrutural dos três repositórios precisa ser resolvido.

---

## 15. Regra para pausas longas

Após uma pausa (semana, mês, ou mais):

1. **Leia este Guia** — ele contém o panorama atualizado.
2. **Leia `ESTADO-ATUAL.md`** do repositório ativo (`IA-Laboratorio-MCP`).
3. **Leia `DECISOES.md`** — decisões estruturais e seus motivos.
4. **Leia a sessão mais recente** em `SESSOES/`.
5. **Identifique o próximo passo** — procure por "PENDENTE" neste Guia.
6. **Trabalhe em etapas pequenas** — testando tudo.
7. **Registre** o que fizer no Guia e na memória do repositório.

**Nunca presuma** que o contexto da sessão anterior ainda está disponível. Tudo que importa deve estar documentado.

---

## 16. Referências técnicas

### Locais do laboratório (referências vivas — não duplicar)

| Local | Conteúdo |
|-------|----------|
| `V:\LABORATORIO_IA\99-HISTORICO\` | Patrimônio histórico dos Períodos 1–9, com `METADADOS-ORIGEM.md` por transferência (P8: commit `d75794b`; P9: commit `8c488f7`) |
| `V:\LABORATORIO_IA\99-HISTORICO\IA-Laboratorio-MCP\2026-08-25\` | Código do `49afbc5` (compatibilidade por extensão), memória de sessão de 23/08 e corrida de eventos de 24/08 |
| `V:\LABORATORIO_IA\99-HISTORICO\IA-Laboratorio-MCP\2026-09-03\` | `VALIDACAO-TESTE-USUARIO.md` e o primeiro `.gitignore` (`b736852`) |
| `V:\LABORATORIO_IA\99-HISTORICO\IA-Laboratorio-MCP\2026-09-06\` e `2026-09-07\` | Documentação Gmail/Calendar do Hermes e este Guia (versão `0cf64e1`) |
| `V:\LABORATORIO_IA\99-HISTORICO\Laboratorio-IA\2026-09-04\` e `2026-09-05\` | Documentação Hermes: alertas (Fase 1), diagnóstico OmniRoute/OAuth/Calendar |
| `docs/hermes/gmail.md` e `docs/hermes/calendar.md` (neste repositório) | Documentação [validado] das integrações do Hermes |
| `02-agentes/biblioteca-viva/VALIDACAO-TESTE-USUARIO.md` (neste repositório) | Validação do teste físico de 23/08 |
| `memoria/ESTADO-ATUAL.md` (neste repositório) | Estado operacional corrente |
| `V:\Claude Code\Laboratorio-IA\hermes-agent\docs\` | Documentação Hermes original: `alertas/fase-1.md` e `omniroute-contexto/00–03` |
| `V:\Claude Code\Laboratorio-IA\memoria\DECISOES.md` | Decisões estruturais completas (ver nota na seção 1) |
| `V:\Claude Code\Laboratorio-IA\biblioteca-viva\dados\` | Dados reais da Biblioteca Viva PowerShell — gitignored, contêm dados pessoais; não versionar sem decisão |

### Git

- Documentação oficial: https://git-scm.com/doc
- Pro git (livro completo): https://git-scm.com/book/

### MCP (Model Context Protocol)

- Especificação: https://spec.modelcontextprotocol.io
- Documentação: https://modelcontextprotocol.io

### Claude Code

- Documentação: https://docs.anthropic.com/claude-code

### Docker

- Documentação oficial: https://docs.docker.com/

### Ollama

- Documentação: https://ollama.com/docs

### OpenRouter

- Documentação: https://openrouter.ai/docs

### Google Workspace

- OAuth 2.0: https://developers.google.com/identity/protocols/oauth2
- Calendar API: https://developers.google.com/calendar
- Gmail API: https://developers.google.com/gmail/api

### Python

- Documentação: https://docs.python.org/3/

---

## 17. Próximo ponto de retomada

> **Próximo passo:** a consolidação do conhecimento está feita (Guia V1.2) e o patrimônio dos Períodos 1–9 está preservado em `99-HISTORICO`. A etapa lógica seguinte é a **consolidação estrutural dos repositórios** (resolver os três remotes, o destino do `DSH-Analise-Biblioteca-Viva` e o papel do repositório pai), sempre preservando históricos e proveniência. As pendências das seções 8 e 12 permanecem abertas — nenhuma foi resolvida nesta revisão.

**Antes de qualquer reorganização:**
1. Confirmar que este Guia está completo e correto.
2. Listar todos os arquivos importantes em cada repositório.
3. Planejar a ordem de movimentação (preservando históricos).
4. Executar movimentação com supervisão humana.
5. Validar que nada foi perdido.

---

## 18. Histórico de atualizações do Guia

| Data | Versão | Alteração |
|------|--------|-----------|
| 2026-09-07 | V1 | Criação do Guia mestre e registro da situação estrutural atual |
| 2026-09-07 | V1.1 | Revisão de evidências, correção da arquitetura Git, contextualização da Biblioteca Viva e maior precisão sobre Google Workspace |
| 2026-09-09 | V1.2 | Reparo da corrupção da linha 1; consolidação do Período 9 (ponte 25/08, período 03–07/09); seção de proveniência Git; rigor de evidência Hermes/Google (documentado ≠ confirmado); pendências O2/O4 e novas pendências; decisões de fronteira e proveniência; referências ao `99-HISTORICO` |

---

*Este Guia é o ponto de partida permanente do Laboratório de IA. Toda sessão nova deve começar por aqui.*
