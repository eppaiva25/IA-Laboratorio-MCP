# Estado Atual — Laboratório de IA

**Última atualização:** 18/08/2026 (etapa Claude Code + Git)

## Objetivo

Construir um laboratório prático para aprender e experimentar Claude Code, agentes de IA, MCP, n8n e Python de forma gradual, segura e compreensível.

## Onde estamos

Estamos utilizando Git como controle de versões e como mecanismo de memória persistente do laboratório.

O repositório Git local está em:

V:\Claude Code\Laboratorio-IA

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

Aprofundar a prática combinada dos dois caminhos de revisão: aceitar e rejeitar alterações feitas por agentes de IA.

Após consolidar essa etapa, considerar:

1. Repetir o ciclo de aceitação em um arquivo e o ciclo de rejeição em outro, na mesma sessão.
2. Experimentar `git restore --staged <arquivo>` para tirar uma alteração da Staging Area sem perdê-la.
3. Treinar alterações em múltiplos arquivos antes de um único commit e revisar o diff consolidado.
4. Evoluir para cenários que envolvam criação e exclusão de arquivos.
5. Preparar o terreno para a próxima etapa do laboratório (Claude Code em conjunto com MCP, n8n ou Python).

## Regra de continuidade

Ao iniciar uma nova sessão, consultar primeiro:

1. memoria/ESTADO-ATUAL.md
2. memoria/DECISOES.md
3. sessão mais recente em memoria/SESSOES/

O objetivo é recuperar rapidamente o contexto sem depender da memória da sessão anterior da API.

---

*Estado mantido como referência operacional do Laboratório de IA.*
