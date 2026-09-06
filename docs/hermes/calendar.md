# Google Calendar — Hermes Agent

> Documentação funcional do laboratório IA-Laboratorio-MCP.
> Voltada para **consulta futura e recuperação**: se o container Hermes for
> perdido e restaurado, este documento deve permitir entender a arquitetura,
> refazer a configuração e repetir os testes funcionais.
>
> Foco no que **funciona**. Nenhum segredo aparece aqui (tokens, client
> secrets, API keys, e-mails pessoais). Valores específicos usam
> **placeholders**.
>
> Convenção de status usada ao longo do documento:
> - **[validado]** — confirmado por teste executado no laboratório.
> - **[a confirmar]** — ainda não confirmado por teste/código nesta sessão;
>   deve ser verificado na instalação (ex.: com `--help` / `--list` da CLI).

---

## 1. Objetivo

Permitir ao Hermes **consultar o Google Calendar em modo somente leitura**,
listar eventos futuros (ex.: próximos 7 dias) e retornar os dados para uso
em automações ou resumos.

Escopo fixado:

- Ler eventos do calendário principal (ou calendários configurados).
- **Não** criar, alterar, excluir ou mover eventos.
- Não alterar configurações do calendário.
- Funcionar com a mesma autenticação Google Workspace já usada pelo Gmail
  (mesmo token, mesmo client secret).

---

## 2. Arquitetura

```
Google OAuth
   → google-workspace  (skill)
      → Google Calendar API
         → Hermes Agent
            → modelo/provider  (omniroutePaiva · auto/best-free)
```

Leitura da figura, em uma frase:

> O Hermes autentica a API do Google Calendar por OAuth (via skill
> `google-workspace`, mesmo fluxo do Gmail), consulta eventos somente leitura
> e processa o resultado com o modelo/provider configurado.

---

## 3. Google Workspace / OAuth

Configuração funcional **[validado]**:

- **Skill oficial `google-workspace`** — autenticação OAuth + operações de
  Calendar (usa o mesmo token do Gmail).
- **Token OAuth** persistido em `/opt/data/google_token.json`.
- **Client secret** em `/opt/data/google_client_secret.json`.
- **Autenticação:** já realizada durante a configuração do Gmail; não é
  necessário novo consentimento se os escopos de Calendar estiverem incluídos
  no token existente.
- **Escopos necessários:** `https://www.googleapis.com/auth/calendar.readonly`
  é o escopo apropriado para leitura. A validação funcional da API já
  demonstrou que a autorização necessária estava operacional.
- **Renovação automática:** igual ao Gmail — refresh token renova o access
  token quando expira.
- **Persistência em `/opt/data`:** área persistente do container; preservar
  a pasta mantém o token válido.

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
- **Versão identificada:** não registrada nesta documentação.
- **Scripts relevantes (caminhos validados):**
  - `/opt/data/skills/productivity/google-workspace/scripts/setup.py`
  - `/opt/data/skills/productivity/google-workspace/scripts/google_api.py`
- **Fallback Python:** o ambiente **utiliza o fallback Python oficial**
  (client `google-api-python-client`) quando o CLI `gws` **não** está
  instalado — via funcional exercitada na validação.
- **Comandos funcionais utilizados:** os comandos exatos validados da seção 6.

---

## 6. Google Calendar — comandos funcionais

Comandos **exatos** validados no laboratório. O script `google_api.py` da
skill expõe subcomando `calendar`.

### 6.1 Listar eventos futuros (próximos 7 dias) — [validado]

```bash
docker exec -u hermes hermes-agent_web_1 sh -c 'HERMES_HOME=/opt/data /opt/data/.venv/bin/python /opt/data/skills/productivity/google-workspace/scripts/google_api.py calendar list --days 7'
```

- `--days 7` limita a janela de busca a 7 dias a partir de hoje (placeholder:
  ajuste conforme necessidade).
- Retorna lista de eventos com título, início, fim e metadados.

> Se houver mais subcomandos (ex.: `get`, `search`), verifique com:
> ```bash
> docker exec -u hermes hermes-agent_web_1 sh -c 'HERMES_HOME=/opt/data /opt/data/.venv/bin/python /opt/data/skills/productivity/google-workspace/scripts/google_api.py calendar --help'
> ```

---

## 7. Teste funcional validado

### 7.1 Habilitação da API — [validado]

A **Google Calendar API estava desabilitada** no projeto Google Cloud.
Após habilitá-la no console (APIs & Services → Library → Google Calendar API
→ Enable), o teste funcional passou.

### 7.2 Teste real executado — [validado]

Comando executado:

```bash
docker exec -u hermes hermes-agent_web_1 sh -c 'HERMES_HOME=/opt/data /opt/data/.venv/bin/python /opt/data/skills/productivity/google-workspace/scripts/google_api.py calendar list --days 7'
```

**Resultado:** `LIVE_CHECK_OK`

**Eventos retornados (3 eventos de teste nos próximos 7 dias):**

| Evento | Data | Horário |
|---|---|---|
| `teste calendar 4` | 06/09 | 13:00 |
| `teste calendar 1` | 07/09 | 08:30 |
| `teste calendar 2` | 09/09 | 14:00 |

O retorno confirmou que a integração Calendar → google-workspace → Hermes
está funcional para leitura de eventos.

---

## 8. Segurança / somente leitura

A integração atua **exclusivamente em leitura**. Proibido à automação:

- ❌ criar eventos;
- ❌ alterar eventos;
- ❌ excluir eventos;
- ❌ mover eventos entre calendários;
- ❌ alterar configurações do calendário;
- ❌ alterar permissões/acesso.

Regra de ouro: **consulta → retorna dados**. Nenhuma operação de escrita.

---

## 9. Hermes / provider / modelo

Configuração funcional utilizada **[validado]** (mesma do Gmail):

| Item | Valor funcional |
|---|---|
| provider | `omniroutePaiva` |
| model | `auto/best-free` |

- Provider: `omniroutePaiva`.
- Modelo: `auto/best-free` (seleção automática definida na configuração).
- Nenhuma credencial registrada aqui.

---

## 10. Operação do container

Comandos de operação do container Hermes. O nome de referência atual é
`hermes-agent_web_1`, mas **pode mudar após uma reinstalação** — confirme
sempre com `docker ps`.

### 10.1 Verificar containers — [validado]

```sh
docker ps
docker ps -a             # inclui parados
```

### 10.2 Entrar no container — [validado]

```sh
docker exec -it hermes-agent_web_1 sh
```

### 10.3 Executar um comando dentro do container — [validado]

```sh
docker exec hermes-agent_web_1 sh -c 'COMANDO'
```

Exemplo: `docker exec hermes-agent_web_1 sh -c 'hermes config get model.default'`.

### 10.4 Consultar logs — [validado]

```sh
docker logs -f hermes-agent_web_1          # segue o log
docker logs --tail 100 hermes-agent_web_1  # últimas 100 linhas
```

### 10.5 Reiniciar o container — [validado]

```sh
docker restart hermes-agent_web_1
```

### 10.6 Verificar se o Gateway está funcionando — [a confirmar]

Indícios funcionais (sem endpoint presumido):

```sh
docker ps --filter name=hermes             # serviço web deve estar "Up"
docker logs --tail 50 hermes-agent_web_1   # deve mostrar a inicialização do Gateway sem erros
```

> Um endpoint de health/healthcheck, se existir, deve ser confirmado na
> instalação — não presume-se aqui.

---

## 11. Configuração Hermes

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

## 12. Descobertas sobre o funcionamento

Somente descobertas confirmadas por teste/código/documentação disponível:

- **O Gateway é responsável pela execução dos cron jobs do Hermes**; essa
  característica já foi confirmada no contexto da integração Gmail.
- **Execução como usuário `hermes` (UID 1000)** **[validado]** — confirmado
  pela necessidade de dono/permissões no token (seção 4).
- **Persistência em `/opt/data`** **[validado]** — token e client secret
  compartilhados com Gmail ficam em `/opt/data/`.
- **Skill Google Workspace** **[validado]** — funciona com fallback Python
  oficial quando `gws` não está instalado; mesmo script (`google_api.py`)
  atende Gmail e Calendar.
- **Associação provider/modelo** **[validado]** — usa o provider/modelo
  configurado (`omniroutePaiva` / `auto/best-free`).
- **Calendar API precisa estar habilitada** **[validado]** — descoberto no
  laboratório: sem habilitar no Google Cloud Console, a chamada falha.

---

## 13. Recuperação após perda do container

Estado honesto: **um procedimento completo de restauração ainda não foi
testado**. Abaixo está o que já sabemos, separado por "o que preservar fora do
Git" × "o que documentar".

### Dados que NÃO devem ir para o Git

- `google_token.json` e `google_token*.json`;
- `client_secret.json` e `client_secret*.json`;
- API keys e demais credenciais de providers;
- arquivos `.env`;
- e-mails pessoais.

(Proteção de versão já presente no `.gitignore` do repositório.)

### Dados que devem ser preservados/documentados

- Configurações necessárias (provider/modelo — seção 9);
- Caminhos persistentes (`/opt/data` — seções 3 e 4);
- Comandos de operação (seção 10) e de consulta (seção 11);
- Nome das skills (`google-workspace` — seção 5);
- Procedimento de OAuth (seção 3) e permissões do token (seção 4);
- Habilitação da Calendar API no Google Cloud Console (seção 7.1);
- Testes de validação (seções 6 e 7).

### O que saber para restaurar

Conhecido:
- A área persistente é `/opt/data`; preservá-la conserva token e client secret
  compartilhados com Gmail.
- Se a pasta for preservada, o OAuth pode continuar funcionando sem nova
  autenticação, desde que o token/refresh token permaneça válido; se for
  perdida, será necessário reautenticar (seção 3) e reaplicar dono/permissões
  (seção 4).
- A **Calendar API deve ser re-habilitada** no Google Cloud Console se o
  projeto for recriado.
- O nome do container pode mudar após reinstalação — confirmar com `docker ps`.

A validar futuramente:
- Passos exatos de rebuild/restauração do stack (não executados nesta sessão);
- comportamento da skill e do cron após reinstalação;
- quais volumes/arquivos de configuração além de `/opt/data` precisam ser
  copiados.

---

## 14. Checklist de validação

Usado para confirmar uma instalação ou restauração da integração Calendar:

- [ ] Container funcionando
- [ ] Gateway funcionando
- [ ] google-workspace disponível
- [ ] OAuth autenticado (token válido)
- [ ] Permissões do token corretas (UID/GID 1000)
- [ ] Google Calendar API habilitada no Google Cloud Console
- [ ] Calendar acessível (teste `LIVE_CHECK_OK`)
- [ ] Leitura de eventos funcionando
- [ ] Somente leitura respeitado

---

## 15. Estado da validação

| Componente | Estado |
|---|---|
| Google OAuth | Validado |
| Google Workspace (skill) | Validado |
| Google Calendar API habilitada | Validado |
| Calendar leitura | Validado |
| Somente leitura | Validado |
| Hermes / provider / modelo | Validado |

> Referências de status: as seções marcadas **[validado]** correspondem a esta
> tabela. O que aparece como **[a confirmar]** não entra nesta tabela até ser
> exercitado em uma nova validação.
>
> Última atualização: 2026-09-06 · Documentação funcional e de recuperação da
> integração Google Calendar + Hermes Agent.