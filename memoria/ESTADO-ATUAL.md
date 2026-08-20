# Estado Atual — Laboratório de IA

**Última atualização:** 19/08/2026 (etapa arquitetura de agentes IA)

## Objetivo

Construir um laboratório prático para aprender e experimentar Claude Code, agentes de IA, MCP, n8n e Python de forma gradual, segura e compreensível.

## Onde estamos

Evoluímos da etapa de Git para arquitetura de agentes IA com múltiplos provedores configurados e validados.

O repositório Git local está em:

V:\Claude Code\Laboratorio-IA

Arquitetura atual validada:
- **OpenCode:** 1.18.18
- **Provedores locais:** Ollama (gemma4:12b, gemma4:26b, 4skl/gemma4-e4b-mtp:latest)
- **Provedores cloud:** OpenCode Free (opencode/mimo-v2.5-free) + 9Router
- **9Router:** v0.5.55 rodando em http://localhost:20128
- **ProjetoLab:** combo disponível via 9Router, testado com sucesso

## Já concluído

- Git instalado e funcionando.
- Identidade do Git configurada.
- Repositório Git local inicializado.
- .gitignore criado.
- Primeiro commit realizado.
- Estrutura inicial de memória criada.
- Aprendemos a consultar git status.
- Aprendemos a consultar git log.
- Aprendemos a consultar git diff.
- Aprendemos a consultar git diff --staged.
- Aprendemos o conceito de Working Directory.
- Aprendemos o conceito de Staging Area.
- Entendemos a função da pasta .git.
- Aprendemos a descartar alterações com git restore.
- Aprendemos a preparar alterações e exclusões com git add e git add -u.
- Aprendemos a revisar alterações antes do commit.
- Realizamos ciclos completos de alteração, revisão, staging e commit.
- Aprendemos que arquivos Untracked não fazem parte do histórico até serem adicionados.
- Aprendemos que arquivos já versionados, quando removidos, aparecem como deleted.
- Aprendemos a registrar exclusões no histórico com git add -u seguido de git commit.
- Definimos Markdown (.md) como formato principal da documentação.
- Removemos do repositório formatos derivados que não precisam ser mantidos como fonte oficial.
- Claude Code foi executado dentro do repositório V:\Claude Code\Laboratorio-IA.
- O Claude Code identificou o diretório como um repositório Git local.
- Aprendemos que o agente pode ler e modificar arquivos do projeto quando autorizado.
- Fizemos uma alteração controlada no README.md a partir do Claude Code.
- Usamos git diff para revisar a alteração ainda no Working Directory.
- Usamos git add para colocar a alteração na Staging Area.
- Usamos git diff --staged para revisar novamente antes do commit.
- Criamos o commit dd9b69d com a mensagem "docs: atualiza README sobre Claude Code e Git".
- Confirmamos com git status que o Working Directory voltou a ficar limpo após o commit.
- Consolidamos o princípio de que o Git funciona como camada de segurança e revisão para alterações realizadas por agentes de IA.
- Praticamos a rejeição de uma alteração proposital feita pelo Claude Code no README.md usando `git restore`.
- Usamos `git status` para identificar o arquivo modificado antes da rejeição.
- Usamos `git diff -- README.md` para revisar a alteração que estava no Working Directory.
- Usamos `git restore README.md` para descartar a alteração ainda fora do staging.
- Confirmamos com `git status` que o Working Directory voltou a ficar limpo (nothing to commit, working tree clean).
- Confirmamos com `git diff -- README.md` que não havia mais nenhuma diferença em relação ao último commit.
- Consolidamos a diferença entre aceitar uma alteração (`git add` → `git diff --staged` → `git commit`) e rejeitar uma alteração (`git restore`).
- Entendemos que `git restore` neste exercício descartou uma alteração ainda não commitada, voltando o arquivo ao estado do último commit.
- Configuramos arquitetura de agentes IA com OpenCode 1.18.18.
- Instalamos Ollama localmente com três modelos: gemma4:12b, gemma4:26b e 4skl/gemma4-e4b-mtp:latest.
- Configuramos OpenCode Free com opencode/mimo-v2.5-free como provider cloud.
- Instalamos e validamos 9Router v0.5.55 em http://localhost:20128.
- Configuramos provider 9router no opencode.json usando http://127.0.0.1:20128/v1.
- Ativamos autenticação do 9Router através do mecanismo de credenciais do OpenCode.
- Disponibilizamos combo ProjetoLab como 9router/ProjetoLab.
- Testamos ProjetoLab com sucesso usando prompts de validação ('Responda apenas: PROJETOLAB + 9ROUTER + OPENCODE OK' e 'Responda apenas OK').
- Verificamos no painel do 9Router que chamadas foram feitas para claude-haiku-4.5.
- Validamos modelos locais mas identificamos que são lentos no hardware atual.
- Definimos estratégia: cloud (mimo-v2.5-free + 9Router) será priorizado para desenvolvimento de agentes; Ollama mantido para testes locais.
- Estratégia de combo ProjetoLab ainda será avaliada entre Fallback, Round Robin e Fusion.

## Commits de referência

4c63ef8 — chore: inicializa Laboratório de IA

6f19a03 — docs: adiciona memoria e documenta aprendizado do Git

39ba17 — docs: atualiza README sobre evolucao do Git

ec4d3f — docs: atualiza estado do laboratorio

33f5ec2 — docs: remove formatos derivados da documentacao

d2ac5ba — docs: consolida memoria da etapa Git

dd9b69d — docs: atualiza README sobre Claude Code e Git

## O que aprendemos

O fluxo básico de trabalho com Git:

lteração → git diff → git add → git diff --staged → git commit → git status

Também aprendemos que:

- git diff mostra alterações ainda fora da Staging Area.
- git diff --staged mostra o que está preparado para o próximo commit.
- git restore pode descartar alterações do Working Directory.
- git status mostra a situação atual do repositório.
- git log mostra o histórico de commits.
- git add -u prepara alterações e exclusões de arquivos já rastreados.
- Um arquivo Untracked continua existindo no computador, mas não está sendo acompanhado pelo Git.
- Uma exclusão de arquivo versionado precisa ser registrada em um commit para fazer parte do histórico atual.
- O histórico do Git preserva os estados anteriores, mesmo depois que arquivos são removidos da versão atual.
- O Claude Code identifica o repositório a partir do diretório de trabalho e opera sobre os arquivos do projeto.
- Quando autorizado, o Claude Code consegue ler e modificar arquivos do Working Directory.
- O fluxo "alteração → git diff → git add → git diff --staged → git commit → git status" continua valendo quando a alteração é feita por um agente.
- O Git funciona como camada de segurança e revisão para alterações realizadas por agentes de IA: cada commit pode servir como ponto de retorno.
- Existem dois caminhos complementares para tratar uma alteração feita por um agente: aceitar (`git add` → `git diff --staged` → `git commit`) ou rejeitar (`git restore`).
- Aceitar registra a alteração no histórico do repositório; rejeitar volta o arquivo ao estado do último commit.
- `git restore` age sobre o Working Directory por padrão; quando uma alteração já está na Staging Area, é preciso primeiro `git restore --staged <arquivo>` e depois `git restore <arquivo>`.
- Após uma rejeição bem-sucedida, `git status` deve voltar a indicar working tree clean e `git diff` deve ficar vazio para o arquivo rejeitado.

## Organização da documentação

O Markdown (.md) é a fonte oficial da documentação do laboratório.

PDF, DOCX, HTML e TXT podem ser gerados posteriormente quando houver necessidade de impressão, compartilhamento ou apresentação, mas não são mantidos como fontes paralelas dentro do repositório.

## Estado atual do repositório

O Working Directory está limpo.

Último commit:

dd9b69d — docs: atualiza README sobre Claude Code e Git

## Memória do laboratório

A memória foi organizada em três partes:

- ESTADO-ATUAL.md — situação presente e próximo passo.
- DECISOES.md — decisões estruturais e seus motivos.
- SESSOES/ — histórico cronológico das sessões.

## Próximo passo

Avaliar e definir estratégia de combo ProjetoLab entre:
1. **Fallback** — tentar primeiro cloud, falhar para local se indisponível
2. **Round Robin** — alternar entre cloud e local em cada requisição
3. **Fusion** — combinar respostas de múltiplos provedores

Após decidir estratégia, considerar:

1. Testar cenários de falha e recuperação com a arquitetura atual.
2. Otimizar configuração de hardware ou explorar alternativas para modelos locais.
3. Documentar padrões de uso e recomendações de provider por tipo de tarefa.
4. Integrar agentes práticos (MCP, n8n, Python) com arquitetura validada.
5. Preparar pipeline de validação automatizada para garantir disponibilidade de provedores.

## Regra de continuidade

Ao iniciar uma nova sessão, consultar primeiro:

1. memoria/ESTADO-ATUAL.md
2. memoria/DECISOES.md
3. sessão mais recente em memoria/SESSOES/

O objetivo é recuperar rapidamente o contexto sem depender da memória da sessão anterior da API.

---

*Estado mantido como referência operacional do Laboratório de IA.*
