# Estado Atual — Laboratório de IA

**Última atualização:** 18/08/2026

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

## Commits de referência

4c63ef8 — chore: inicializa Laboratório de IA

6f19a03 — docs: adiciona memoria e documenta aprendizado do Git

39ba17 — docs: atualiza README sobre evolucao do Git

ec4d3f — docs: atualiza estado do laboratorio

33f5ec2 — docs: remove formatos derivados da documentacao

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

## Organização da documentação

O Markdown (.md) é a fonte oficial da documentação do laboratório.

PDF, DOCX, HTML e TXT podem ser gerados posteriormente quando houver necessidade de impressão, compartilhamento ou apresentação, mas não são mantidos como fontes paralelas dentro do repositório.

## Estado atual do repositório

O Working Directory está limpo.

Último commit:

33f5ec2 — docs: remove formatos derivados da documentacao

## Memória do laboratório

A memória foi organizada em três partes:

- ESTADO-ATUAL.md — situação presente e próximo passo.
- DECISOES.md — decisões estruturais e seus motivos.
- SESSOES/ — histórico cronológico das sessões.

## Próximo passo

Avançar para a utilização do Git no fluxo de trabalho do Claude Code.

Antes de permitir alterações significativas por um agente, compreenderemos:

1. Como o Claude Code identifica o repositório.
2. O que o agente consegue ler e modificar.
3. Como revisar alterações feitas pelo agente com git diff.
4. Como aceitar alterações com Git.
5. Como rejeitar alterações com git restore.
6. Como utilizar commits como pontos de segurança durante experimentos.

## Regra de continuidade

Ao iniciar uma nova sessão, consultar primeiro:

1. memoria/ESTADO-ATUAL.md
2. memoria/DECISOES.md
3. sessão mais recente em memoria/SESSOES/

O objetivo é recuperar rapidamente o contexto sem depender da memória da sessão anterior da API.

---

*Estado mantido como referência operacional do Laboratório de IA.*
