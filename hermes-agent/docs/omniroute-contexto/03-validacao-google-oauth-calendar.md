# Hermes Agent — Validação do Google OAuth/Calendar

> Registro do que foi **efetivamente validado** em 05/09/2026. Nada além do descrito abaixo
> foi testado ou alterado.

## 1. Validação da autenticação OAuth

Dentro do container do Hermes:

```bash
setup.py --check
```

Resultado:

```
AUTHENTICATED
```

### Verificação ao vivo

```bash
setup.py --check-live
```

Resultado:

```
LIVE_CHECK_OK
```

## 2. Teste funcional do Google Calendar

- Teste realizado em modo **somente leitura** do Google Calendar.
- Validados os **próximos 3 eventos** do calendário principal, dentro dos **próximos 7 dias**.
- **Não** foram criados, editados ou excluídos eventos.
- Foi utilizada a skill existente **`google-workspace`**.

## 3. Pendência conhecida (NÃO alterada)

- O token do Google parece estar **`root`-owned**, e a skill `google-workspace` pode tentar
  renová-lo ao usá-lo.
- Essa situação **não foi alterada** nesta investigação.
- O Hermes conseguiu **contornar** a situação via **API direta**, sem depender dessa renovação
  pela skill.

## 4. Conclusão e próximos passos

- OAuth autenticado (`AUTHENTICATED`) e check ao vivo OK (`LIVE_CHECK_OK`).
- Leitura do Calendar validada (próximos 3 eventos / 7 dias), sem nenhuma alteração.
- **Regra para o futuro:** se o Calendar voltar a apresentar erro, **primeiro** verificar os
  **logs do Hermes** antes de alterar qualquer coisa em OAuth/Google Cloud.