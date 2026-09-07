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

- Hermes Agent instalado e configurado em Docker.
- Interface: Telegram.
- Container: `hermes-agent_web_1` (imagem `ghcr.io/getumbrel/hermes-agent-umbrel:v2026.8.19`).
- Dados persistentes em `/opt/data/`.
- OmniRoute como roteador de modelos (http://omniroute:20128).
- Modelo customizado: `auto/best-free`.
- Limite de contexto corrigido: 128000 tokens (era 1000000, causava HTTP 503).
- Sistema de alertas e lembretes validado (Fase 1): criação, execução, notificação, cancelamento, fuso horário, prevenção de duplicação.

### Google Workspace (05/09/2026)

- OAuth validado: `AUTHENTICATED` e `LIVE_CHECK_OK`.
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
- Testes de alertas e lembretes realizados.

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

> **Nota sobre a validação dos 45 PDFs:** A movimentação e verificação dos 45 PDFs é um registro histórico validado em 22/08/2026. O incidente de 21/08/2026 (destruição de estado local) afetou o catálogo real. O estado atual dos 45 PDFs pode não corresponder ao resultado daquela validação. O catálogo real requer re-inventário antes de qualquer operação nova.

### Pendências

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

**CONFIRMADO:**
- Autenticação OAuth validada via `setup.py --check`: resultado `AUTHENTICATED`.
- Verificação ao vivo via `setup.py --check-live`: resultado `LIVE_CHECK_OK`.
- Setup executado dentro do container do Hermes.

### Google Calendar

**CONFIRMADO:**
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

### Estado atual — Setembro de 2026

| Item | Status |
|------|--------|
| `IA-Laboratorio-MCP` | Fonte de verdade escolhida (provisória) |
| `V:\Claude Code` | Repositório pai/guarda-chuva local (não é fonte de verdade) |
| Guia de Aprendizado | Criado neste repositório |
| Repositórios duplicados | Existentes, consolidação NÃO realizada |
| HTML antigo | Preservado em `materiais-de-estudo/` |
| Reorganização estrutural | NÃO realizada nesta etapa |
| Biblioteca Viva V2 | Funcional e aprovada (validações históricas preservadas) |
| Hermes Agent | Operacional com OmniRoute |
| Google OAuth | CONFIRMADO: autenticado |
| Google Calendar | CONFIRMADO: leitura validada (3 eventos / 7 dias) |
| Google Calendar (escrita) | PENDENTE: não testado |
| Google Gmail | PENDENTE: validação completa não realizada |
| Alertas do Hermes | Fase 1 validada |
| Git | Funcional nos subdiretórios; problema estrutural no nível pai |

### O que está confirmado

- `IA-Laboratorio-MCP` é, por enquanto, a fonte de verdade escolhida (provisória).
- `V:\Claude Code` é o repositório pai/guarda-chuva local, não a fonte de verdade.
- O Guia será mantido neste repositório.
- Existem repositórios duplicados/concorrentes.
- A consolidação ainda NÃO foi realizada.
- O HTML antigo continua preservado.
- Nenhuma reorganização estrutural foi feita nesta etapa.
- OAuth Google está autenticado (CONFIRMADO).
- Calendar leitura está validada (CONFIRMADO).
- Calendar escrita está pendente (PENDENTE).
- Gmail está pendente de validação completa (PENDENTE).

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

---

## 13. Decisões importantes

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
- Biblioteca Viva: princípio central, ciclo do agente, validações.
- Hermes Agent: instalação, configuração, alertas, OAuth.

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

> **Próximo passo:** Revisar este Guia V1, validar se ele representa corretamente o conhecimento acumulado e somente depois iniciar a consolidação estrutural dos repositórios.

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

---

*Este Guia é o ponto de partida permanente do Laboratório de IA. Toda sessão nova deve começar por aqui.*
