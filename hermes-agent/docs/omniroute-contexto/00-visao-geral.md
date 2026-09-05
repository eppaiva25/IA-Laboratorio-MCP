# Hermes Agent + OmniRoute — Visão Geral

> Documentação da investigação **“Hermes Agent — Correção do limite de contexto do OmniRoute”**
> (05/09/2026), registrada no Laboratório de IA como referência técnica do ambiente
> Hermes Agent + OmniRoute.

## 1. Finalidade

Registrar a arquitetura e o ambiente em que o Hermes Agent opera, o papel do OmniRoute no
fluxo de modelos e a correção aplicada no limite de contexto (ver `01-limite-contexto.md`).
Serve de ponto de partida para diagnóstico futuro e para a validação do Google OAuth/Calendar
(`03-validacao-google-oauth-calendar.md`).

## 2. Arquitetura relevante

O fluxo de inferência do Hermes nesta configuração é:

```
Hermes Agent  →  custom provider  →  auto/best-free  →  OmniRoute
```

- **Hermes Agent** — agente pessoal que conversa via Telegram (executando em Docker).
- **custom provider** — provedor customizado configurado no Hermes para alcançar modelos
  fora dos provedores nativos.
- **`auto/best-free`** — identificador do modelo customizado registrado nesse provedor.
- **OmniRoute** — serviço que roteia/agrega modelos; o Hermes o acessa pelo endpoint interno
  `http://omniroute:20128`.

## 3. Ambiente Docker

- **Container:** `hermes-agent_web_1`
- **Imagem:** `ghcr.io/getumbrel/hermes-agent-umbrel:v2026.8.19`
- **Interface de uso:** Telegram
- **Dados/configuração do Hermes:** `/opt/data/` dentro do container
  (ex.: `config.yaml`, `context_length_cache.yaml`)

## 4. Relação entre Hermes, OmniRoute e o limite de contexto

O Hermes consulta o OmniRoute pelo modelo `auto/best-free` em `http://omniroute:20128`. O
tamanho de contexto efetivamente considerado pelo Hermes para esse modelo é controlado por
duas coisas:

1. o `context_length` declarado para o modelo custom em `config.yaml`;
2. o cache local `/opt/data/context_length_cache.yaml`, usado pelo Hermes ao decidir quantos
   tokens pode enviar.

A investigação mostrou que, enquanto o Hermes considerou até **1.000.000 de tokens** para
`auto/best-free@http://omniroute:20128`, uma conversa extensa estourou o limite do provider
(Groq) e produziu **HTTP 503**. A correção foi declarar `context_length: 128000` no modelo
custom. Detalhes em `01-limite-contexto.md`.

## 5. Documentos desta pasta

| Arquivo | Conteúdo |
|---|---|
| `01-limite-contexto.md` | Problema do limite de contexto e a correção para 128000 |
| `02-diagnostico-restart.md` | Procedimento de diagnóstico e restart validado |
| `03-validacao-google-oauth-calendar.md` | Validação do Google OAuth/Calendar |

## 6. Regras de segurança

Ao atuar neste ambiente:

- não expor tokens, credenciais ou secrets;
- não alterar código, containers, configurações do Hermes/OmniRoute ou Google;
- suportar qualquer alteração futura nos procedimentos documentados e na revisão humana.