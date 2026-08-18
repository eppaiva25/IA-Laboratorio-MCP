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
*Registro permanente das decisões estruturais do Laboratório de IA.*
