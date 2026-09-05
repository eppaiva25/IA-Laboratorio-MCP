# Hermes Agent — Procedimento de diagnóstico e restart

> Procedimento real validado em 05/09/2026 para verificar o estado do container e confirmar a
> configuração de contexto do OmniRoute.

## 1. Verificar o estado do Docker

```bash
docker ps
```

Confirma-se que `hermes-agent_web_1` está listado e em `Up`.

Se o container não aparecer na lista padrão:

```bash
docker ps -a
```

## 2. Reiniciar o container do Hermes

```bash
docker restart hermes-agent_web_1
```

## 3. Confirmar que o container voltou a `Up`

```bash
docker ps
```

Esperado: `hermes-agent_web_1` aparece novamente com status `Up`.

## 4. Executar a validação da configuração

Com o container em `Up`:

```bash
docker exec hermes-agent_web_1 cat /opt/data/config.yaml
```

Confirmar os três itens:

| Item | Valor esperado |
|---|---|
| Modelo | `auto/best-free` |
| `base_url` | `http://omniroute:20128` |
| Contexto | `128000` |

## 5. Confirmação final

Resultado conhecido: a validação retornou os três valores conforme o esperado, confirmando o
`context_length: 128000` declarado para o `auto/best-free` (ver `01-limite-contexto.md`).

A cadeia permanece:

```
Hermes → auto/best-free → http://omniroute:20128 → 128000
```

> Importante: este procedimento **não** altera configurações; apenas reinicia o container e
> confere a configuração. Não edite arquivos no container (`docker exec` com escrita) sem
> revisão humana.