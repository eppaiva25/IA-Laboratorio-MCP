# Hermes Agent — Correção do limite de contexto do OmniRoute

> Registro fiel da investigação de 05/09/2026 sobre a falha **HTTP 503** causada por excesso
> de contexto combinado com o limite do provider, e da correção aplicada.

## 1. Contexto da falha

Em uma sessão do Telegram com aproximadamente **289 mensagens**, o contexto acumulado chegou
a cerca de **90.345 tokens**. No momento do envio, a requisição total alcançou
aproximadamente **106.879 tokens**.

O provider final (Groq) opera com limite de **8.000 tokens por minuto (TPM)**.

### Sintoma

A requisição foi rejeitada com **HTTP 503** e a mensagem:

```
all targets were skipped by pre-dispatch filters
```

## 2. Diagnóstico

Concluiu-se que o problema era **excesso de contexto combinado com o limite do provider**, e
**não** uma falha de OAuth/Google Calendar.

### Descoberta: cache de contexto

O Hermes mantém em `/opt/data/context_length_cache.yaml` o tamanho de contexto que considera
para cada modelo. Naquele estado, o cache registrava, entre outros:

| Modelo | context_length considerado |
|---|---|
| `nemotron-3-ultra` | `262144` |
| `auto/best-free@http://omniroute:20128` | `1000000` |

Ou seja: o Hermes estava considerando até **1.000.000 de tokens** para o `auto/best-free`,
muito acima do contexto real do fluxo, o que permitia montar requisições gigantes — e então
esbarrar no TPM de 8.000 do Groq.

## 3. Solução adotada

Antes de qualquer alteração, foi criado um backup em:

```
/opt/data/config.yaml.bak.before-context-limit
```

A alteração consistiu em declarar explicitamente o limite de contexto do modelo custom
`auto/best-free` em `/opt/data/config.yaml`. O resultado em configuração passou a ser:

```text
modelo: auto/best-free
base_url: http://omniroute:20128
context_length: 128000
```

> Observação: o comando de edição em si (editor/sed usado para alterar o YAML) **não foi
> transcrito literalmente** nesta documentação; o que foi validado é o **resultado** — o
> backup criado, a entrada acima em `config.yaml` e as validações retornando `128000`.

### Validações que retornaram `128000`

1. Leitura da configuração dentro do container:

```bash
docker exec hermes-agent_web_1 cat /opt/data/config.yaml
```

Confirmando para o modelo `auto/best-free`:

```
name: auto/best-free
base_url: http://omniroute:20128
context_length: 128000
```

2. Após o restart do container (procedimento em `02-diagnostico-restart.md`), a validação
novamente retornou `128000` para `auto/best-free@http://omniroute:20128`.

## 4. Resolução final

```
Hermes → auto/best-free → http://omniroute:20128 → 128000
```

O Hermes agora limita o contexto enviado ao `auto/best-free` a **128.000 tokens**, mantendo a
sessão dentro das condições do provider.

## 5. Recomendações

- **Não apagar** `/opt/data/context_length_cache.yaml`: ele é parte do funcionamento do
  Hermes; a correção foi feita pela declaração explícita em `config.yaml`, **não** pela
  remoção do cache.
- Manter o backup `config.yaml.bak.before-context-limit` disponível por segurança.
- Se a falha 503 reaparecer em outra conversa extensa, revisar o `context_length` do modelo e
  o tamanho da sessão antes de considerar problemas de fornecedor.