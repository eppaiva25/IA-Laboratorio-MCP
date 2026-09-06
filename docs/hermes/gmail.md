# Gmail — Hermes Agent

> Documentação funcional do laboratório IA-Laboratorio-MCP.
> Voltada para **consulta futura e recuperação**: se o container Hermes for
> perdido e restaurado, este documento deve permitir entender a arquitetura,
> refazer a configuração e repetir os testes funcionais.
>
> Foco no que **funciona**. Nenhum segredo aparece aqui (tokens, client
> secrets, API keys, Chat IDs, e-mails pessoais). Valores específicos usam
> **placeholders**.
>
> Convenção de status usada ao longo do documento:
> - **[validado]** — confirmado por teste executado no laboratório.
> - **[a confirmar]** — ainda não confirmado por teste/código nesta sessão;
>   deve ser verificado na instalação (ex.: com `--help` / `--list` da CLI).

---

## 1. Objetivo

Permitir ao Hermes **consultar o Gmail em modo somente leitura**, identificar
e-mails **não lidos** e enviar um **resumo** pelo **Telegram**, de forma
manual e **agendada** (cron).

Escopo fixado desde o início:

- Ler mensagens e metadados (remetente, assunto, trecho/corpo).
- **Não** alterar nenhum estado do Gmail (seção 8).
- Entregar o resumo em um chat Telegram específico (seção 9).
- Rodar de forma agendada sem intervenção humana (seção 10).
- Ser **reproduzível** após perda/restauração do ambiente (seções 13–17).

---

## 2. Arquitetura

```
Google OAuth
   → google-workspace  (skill)
      → Gmail
         → Hermes Agent
            → modelo/provider  (omniroutePaiva · auto/best-free)
               → Telegram
```

Leitura da figura, em uma frase:

> O Hermes autentica a API do Gmail por OAuth (via skill `google-workspace`),
> consulta e-mails somente leitura, pede ao modelo/provider configurado que
> produza um resumo e entrega o resultado no destino Telegram.

![Arquitetura] — ver representação em texto acima; não há diagrama de imagem.

---

## 3. Google Workspace / OAuth

Configuração funcional **[validado]**:

- **Skill oficial `google-workspace`** — autenticação OAuth + operações de
  Gmail.
- **Token OAuth** persistido em `/opt/data/google_token.json`.
- **Client secret** (credencial do projeto Google) em
  `/opt/data/google_client_secret.json`.
- **Autenticação:** a primeira execução negocia a autorização (consentimento)
  do escopo de leitura e grava o token no caminho persistente.
- **Renovação automática:** o fluxo OAuth renova o access token via refresh
  token quando expira — confirmado por consultas posteriores sem nova
  autenticação manual.
- **Persistência em `/opt/data`:** é a área persistente do container; um
  rebuild/reinstalação que preserve a pasta mantém o token (ver seção 15).

> ⚠ Tokens e client secrets **nunca** vão para o Git. O `.gitignore` do
> repositório já protege `google_token*.json` e `client_secret*.json`.

---

## 4. Permissões do token

**Descoberta importante da validação** **[validado]**:

- O Gateway/skill executa os processos com o usuário **`hermes`** (UID **1000**,
  GID **1000**).
- O token precisa ter **proprietário e permissões compatíveis** com UID/GID
  1000 para ser lido no contexto de execução do Hermes.

**Ajuste válido NO HOST** (não dentro do container) — caminho do volume
persistido no host:

```sh
sudo chown 1000:1000 /home/eppaiva/homelab/umbrel/app-data/hermes-agent/data/hermes/google_token.json
sudo chmod 600 /home/eppaiva/homelab/umbrel/app-data/hermes-agent/data/hermes/google_token.json
```

Explicação: o UID/GID 1000 dentro do container corresponde ao usuário
`hermes`. O `chown` com `hermes:hermes` **não funciona no host** porque o
usuário `hermes` só existe dentro do container — usa-se diretamente
`1000:1000` (uid/gid numéricos).

---

## 5. Skill oficial Google Workspace

- **Nome:** `google-workspace`
- **Caminho (validado):**
  `/opt/data/skills/productivity/google-workspace/`
- **Versão identificada:** não registrada nesta documentação (não capturada na
  validação).
- **Scripts relevantes (caminhos validados):**
  - `/opt/data/skills/productivity/google-workspace/scripts/setup.py`
  - `/opt/data/skills/productivity/google-workspace/scripts/google_api.py`
- **Fallback Python:** o ambiente **utiliza o fallback Python oficial**
  (client `google-api-python-client`) quando o CLI `gws` **não** está
  instalado — via funcional exercitada na validação.
- **Comandos funcionais utilizados:** os comandos exatos validados da seção 6.

---

## 6. Gmail — comandos funcionais

Comandos **exatos** validados no laboratório. Use `ID_DA_MENSAGEM` como
placeholder do ID real da mensagem. Não há wrapper `gmail` genérico — o
comando invoca diretamente o script Python da skill.

### 6.1 Pesquisar não lidos da caixa de entrada (com limite) — [validado]

```bash
docker exec -u hermes hermes-agent_web_1 sh -c 'HERMES_HOME=/opt/data /opt/data/.venv/bin/python /opt/data/skills/productivity/google-workspace/scripts/google_api.py gmail search "in:inbox is:unread" --max 10'
```

- `--max 10` limita a quantidade de resultados (placeholder: ajuste conforme
  necessidade).
- A string de busca `"in:inbox is:unread"` é verbatim.

### 6.2 Obter uma mensagem específica — [validado]

```bash
docker exec -u hermes hermes-agent_web_1 sh -c 'HERMES_HOME=/opt/data /opt/data/.venv/bin/python /opt/data/skills/productivity/google-workspace/scripts/google_api.py gmail get ID_DA_MENSAGEM'
```

Retorna a mensagem completa (metadados + corpo) pelo ID.

---

## 7. Prompts funcionais

Prompts em texto natural que **funcionaram** no Hermes. Reutilizáveis,
com dados pessoais substituídos por placeholders.

### 7.1 Consulta de uma mensagem específica

Padrão que **obriga uma nova busca** no Gmail, localiza a mensagem pelo assunto,
lê o conteúdo completo e retorna os campos esperados:

```text
Faça uma nova busca no Gmail em busca da mensagem com o assunto
"<ASSUNTO>" (usando uma consulta atual, não dados da conversa anterior).
Localize a mensagem pelo assunto, leia o conteúdo completo e responda:

- Remetente
- Assunto
- Resumo
- Ação necessária

Importante: apenas leitura. NÃO modifique o Gmail (não marque como lido,
não altere etiquetas, não mova, não exclua, não envie e-mail).
```

Regra embutida: a informação atual exige **nova consulta** no Gmail — não
depender só do contexto anterior da conversa (o estado do Gmail muda entre
execuções).

### 7.2 Monitoramento Gmail → Telegram

Prompt de monitoramento dos não lidos, com os 3 mais recentes, resumo e
entrega via Telegram:

```text
Consulte no Gmail: in:inbox is:unread.
Selecione os 3 e-mails mais recentes, leia o conteúdo de cada um e produza
um resumo com:

- Remetente
- Assunto
- Resumo
- Ação necessária

Envie o resultado pelo Telegram para o destino:
telegram:TELEGRAM_CHAT_ID

Regras obrigatórias:
- NÃO marcar como lido;
- NÃO alterar etiquetas;
- NÃO mover mensagens;
- NÃO excluir mensagens;
- NÃO modificar e-mails;
- NÃO enviar e-mail.
Somente leitura.
```

> `TELEGRAM_CHAT_ID` é placeholder (o valor real não é registrado).

---

## 8. Segurança — somente leitura

A automação atua **exclusivamente em leitura**. Proibido à tarefa:

- ❌ marcar como lido;
- ❌ alterar labels/etiquetas;
- ❌ mover mensagens;
- ❌ excluir mensagens;
- ❌ enviar e-mail;
- ❌ modificar mensagens.

Regra de ouro: **consulta → resume → entrega**. Nenhuma operação de escrita ou
mudança de estado no Gmail.

---

## 9. Telegram

Formato funcional do destino **[validado]**:

```
telegram:TELEGRAM_CHAT_ID
```

- `TELEGRAM_CHAT_ID` é **placeholder** do Chat ID real (não registrado).
- Destino explícito garante entrega no chat correto, independentemente de onde
  a tarefa foi criada.

---

## 10. Cron

O cron **executa a tarefa** agendada, consulta o Gmail (busca atual), usa o
provider/modelo configurado e entrega a resposta **diretamente ao destino
Telegram** — tudo processado pelo Gateway.

### 10.1 Exemplo funcional de cron Gmail → Telegram

```text
agendamento  : <expressão cron>                     ex.: 0 */2 * * *
tarefa       : <prompt de monitoramento, seção 7.2>
destino      : telegram:TELEGRAM_CHAT_ID
```

O formato de entrega validado foi:

```
telegram:TELEGRAM_CHAT_ID
```

O teste funcional Cron → OmniRoute → Telegram foi **confirmado** [validado].

### 10.2 Operações de cron

Verbos **validados** no laboratório:

| Operação | Comando (validado) |
|---|---|
| Criar cron | `hermes cron create` |
| Listar crons | `hermes cron list` |
| Verificar status | `hermes cron status` |
| Consultar execuções | `hermes cron runs` |
| Consultar histórico | `hermes cron history` |
| Remover cron | `hermes cron remove` |

A sintaxe completa dos argumentos deve ser consultada com `--help`:

```sh
hermes cron --help
hermes cron create --help
```

As formas acima são os **verbos exatos** validados; a estrutura de argumentos
depende da versão instalada.

---

## 11. OmniRoute / Provider

Configuração funcional utilizada **[validado]**:

| Item | Valor funcional |
|---|---|
| provider | `omniroutePaiva` |
| model | `auto/best-free` |

- Provider: `omniroutePaiva`.
- Modelo: `auto/best-free` (seleção automática definida na configuração).
- **Nenhuma credencial** é registrada aqui.
- Esta seção registra **apenas a configuração funcional** — não é histórico de
  falhas nem auditoria de disponibilidade dos modelos gratuitos.

---

## 12. Descobertas sobre o funcionamento do Hermes

Somente descobertas confirmadas por teste/código/documentação disponível:

- **Gateway responsável pelos cron jobs** **[validado]** — o processo que
  dispara os agendamentos é o Gateway (confirmado pela execução funcional do
  cron).
- **Execução como usuário `hermes` (UID 1000)** **[validado]** — confirmado
  pela necessidade de dono/permissões no token de Gmail.
- **Persistência em `/opt/data`** **[validado]** — token e client secret ficam
  em `/opt/data/`, área persistente do container.
- **Skill Google Workspace** **[validado]** — funciona com fallback Python
  oficial quando `gws` não está instalado.
- **Associação provider/modelo × cron** **[validado]** — a tarefa agendada usa
  o provider/modelo configurado (`omniroutePaiva` / `auto/best-free`).
- **Mecanismo de entrega Telegram** **[validado]** — o destino
  `telegram:<CHAT_ID>` direciona a resposta para o chat especificado.
- **Diferença `telegram:<CHAT_ID>` × `origin`** — *hipótese*: destino explícito
  entrega no chat indicado; `origin` entregaria na origem da conversa/tarefa.
  **Não confirmada pelo código disponível nesta sessão.**

---

## 13. Operação do container

Comandos de operação do container Hermes. O nome de referência atual é
`hermes-agent_web_1`, mas **pode mudar após uma reinstalação** — confirme
sempre com `docker ps`.

### 13.1 Verificar containers — [validado]

```sh
docker ps
docker ps -a             # inclui parados
```

### 13.2 Entrar no container — [validado]

```sh
docker exec -it hermes-agent_web_1 sh
```

### 13.3 Executar um comando dentro do container — [validado]

```sh
docker exec hermes-agent_web_1 sh -c 'COMANDO'
```

Exemplo: `docker exec hermes-agent_web_1 sh -c 'hermes config get model.default'`.

### 13.4 Consultar logs — [validado]

```sh
docker logs -f hermes-agent_web_1          # segue o log
docker logs --tail 100 hermes-agent_web_1  # últimas 100 linhas
```

### 13.5 Reiniciar o container — [validado]

```sh
docker restart hermes-agent_web_1
```

### 13.6 Verificar se o Gateway está funcionando — [a confirmar]

Indícios funcionais (sem endpoint presumido):

```sh
docker ps --filter name=hermes             # serviço web deve estar "Up"
docker logs --tail 50 hermes-agent_web_1   # deve mostrar a inicialização do Gateway sem erros
```

> Um endpoint de health/healthcheck, se existir, deve ser confirmado na
> instalação — não presume-se aqui.

---

## 14. Configuração Hermes — comandos de consulta

Comandos **exatos** validados no laboratório:

```bash
docker exec hermes-agent_web_1 sh -c 'hermes config get model.default'
docker exec hermes-agent_web_1 sh -c 'hermes config get model.provider'
docker exec hermes-agent_web_1 sh -c 'hermes config get display.language'
docker exec hermes-agent_web_1 sh -c 'hermes config get stt.language'
docker exec hermes-agent_web_1 sh -c 'hermes config get tts.provider'
docker exec hermes-agent_web_1 sh -c 'hermes config get tts.edge.voice'
```

Valores funcionais registrados:

| Chave | Valor funcional |
|---|---|
| model.default | `auto/best-free` |
| model.provider | `omniroutePaiva` |
| display.language | `pt-BR` |
| stt.language | `pt-BR` |
| tts.provider | `edge` |
| tts.edge.voice | `pt-BR-BrendaNeural` |

---

## 15. Recuperação após perda do container

Estado honesto: **um procedimento completo de restauração ainda não foi
testado**. Abaixo está o que já sabemos, separado por "o que preservar fora do
Git" × "o que documentar". O desenho final da restauração (ordem de rebuild,
migração de `/opt/data`, nova autenticação) é trabalho **a validar**.

### Dados que NÃO devem ir para o Git

- `google_token.json` e `google_token*.json`;
- `client_secret.json` e `client_secret*.json`;
- API keys e demais credenciais de providers;
- arquivos `.env`;
- Chat IDs de Telegram e e-mails pessoais.

(Proteção de versão já presente no `.gitignore` do repositório.)

### Dados que devem ser preservados/documentados

- Configurações necessárias (provider/modelo — seção 11);
- Caminhos persistentes (`/opt/data` — seções 3 e 4);
- Comandos de operação (seção 13) e de consulta (seção 14);
- Nome das skills (`google-workspace` — seção 5);
- Prompts funcionais (seção 7);
- Procedimento de OAuth (seção 3) e permissões do token (seção 4);
- Testes de validação (seções 6 e 16).

### O que saber para restaurar

Conhecido:
- A área persistente é `/opt/data`; preservá-la conserva token e client secret.
- Se a pasta for preservada, o OAuth pode seguir funcionando sem nova
  autenticação; se for perdida, será necessário reautenticar (seção 3) e
  reaplicar dono/permissões (seção 4).
- O nome do container pode mudar após reinstalação — confirmar com `docker ps`.

A validar futuramente:
- Passos exatos de rebuild/restauração do stack (não executados nesta sessão);
- comportamento da skill e do cron após reinstalação;
- quais volumes/arquivos de configuração além de `/opt/data` precisam ser
  copiados.

---

## 16. Checklist de validação

Usado para confirmar uma instalação ou restauração:

- [ ] Container funcionando
- [ ] Gateway funcionando
- [ ] google-workspace disponível
- [ ] OAuth autenticado
- [ ] Gmail acessível
- [ ] Gmail somente leitura
- [ ] Hermes consegue resumir
- [ ] Telegram funcionando
- [ ] Cron funcionando
- [ ] Entrega Telegram funcionando

---

## 17. Estado da validação

| Componente            | Estado   |
| --------------------- | -------- |
| Google OAuth          | Validado |
| Google Workspace      | Validado |
| Gmail leitura         | Validado |
| Resumo                | Validado |
| Telegram              | Validado |
| Cron                  | Validado |
| Gmail somente leitura | Validado |

> Referências de status: as seções marcadas **[validado]** correspondem a esta
> tabela. O que aparece como **[a confirmar]** não entra nesta tabela até ser
> exercitado em uma nova validação.
>
> Última atualização: 2026-09-06 · Documentação funcional e de recuperação da
> integração Gmail + Hermes Agent + Telegram.