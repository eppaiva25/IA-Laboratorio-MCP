# Hermes Agent — Alertas e Lembretes — Fase 1

## 1. Objetivo

Documentar a primeira fase de validação do sistema de alertas e lembretes do Hermes Agent, verificando criação, execução, notificação, cancelamento, uso do fuso horário America/Sao_Paulo e prevenção de lembretes duplicados.

## 2. Ambiente

- Hermes Agent executando em Docker.
- Interface de teste: Telegram.
- Fuso horário utilizado nos testes: America/Sao_Paulo.
- Container do Hermes: hermes-agent_web_1.
- O container utiliza UTC como horário do sistema, mas o Hermes consegue trabalhar explicitamente com America/Sao_Paulo.
- Os testes foram realizados de forma controlada, com lembretes de teste.

## 3. Testes realizados

### 3.1 Teste básico de resposta

Prompt solicitou exatamente:

TESTE-1-OK

Resultado:
- Hermes respondeu exatamente `TESTE-1-OK`.
- Não houve uso de ferramentas.
- Teste aprovado.

### 3.2 Teste de terminal — pwd

Foi solicitado que o Hermes executasse somente `pwd`.

Resultado:

`/opt/data`

Teste aprovado.

### 3.3 Teste de usuário e HOME

Foram executados:

`whoami`

e

`echo $HOME`

Resultado:

`hermes`

`/opt/data/home`

Teste aprovado.

### 3.4 Teste de fuso horário

Foram executados comandos para verificar o horário do container:

`date`

`date +%Z`

`date +%z`

`echo "TZ=$TZ"`

`date -u`

Resultado:
- O sistema do container utiliza UTC.
- O TZ não estava definido.
- O offset retornado foi `+0000`.

### 3.5 Conversão para horário de São Paulo

Foi executado:

`date -u; TZ=America/Sao_Paulo date`

Resultado:
- O horário UTC foi convertido corretamente para o horário de São Paulo.
- O Hermes consegue utilizar explicitamente `America/Sao_Paulo`.
- Não foi necessário alterar o fuso horário do container.

Teste aprovado.

### 3.6 Agendamento relativo

Foi realizado teste criando lembrete para aproximadamente dois minutos depois.

Resultado:
- O lembrete foi executado e a notificação foi recebida.
- Foi observada uma pequena diferença entre o horário solicitado e o recebimento da notificação.
- Em um dos testes simples houve duplicação interna do agendamento.

Conclusão:
- O mecanismo básico de agendamento relativo funciona.
- A duplicação observada levou à criação de uma regra mais rígida no prompt de controle.

### 3.7 Agendamento relativo com regra de lembrete único

Foi utilizado um prompt solicitando explicitamente:

"Crie exatamente UM lembrete para daqui a 2 minutos."

Resultado:
- Foi criado um único agendamento.
- Uma única notificação foi recebida.

Teste aprovado.

### 3.8 Cancelamento

Foi criado um lembrete de teste chamado:

`TESTE-CANCELADO`

Em seguida foi solicitado o cancelamento, explicitando:

"Cancele o lembrete TESTE-CANCELADO. Não crie um novo lembrete."

Resultado:
- O Hermes confirmou o cancelamento/remoção.
- O teste demonstrou que o mecanismo de cancelamento funciona.
- Durante o teste foram observadas várias chamadas internas de remoção, mas o lembrete foi efetivamente cancelado.

Teste aprovado, com observação sobre o comportamento interno.

### 3.9 Horário absoluto já ultrapassado

Foi solicitado um lembrete para um horário que já havia passado.

Resultado:
- O Hermes verificou o horário em `America/Sao_Paulo`.
- Identificou corretamente que o horário solicitado já havia passado.
- Não foi considerado um agendamento válido para aquele horário.

Teste aprovado.

### 3.10 Horário absoluto válido

Foi solicitado exatamente um lembrete para um horário futuro específico, usando `America/Sao_Paulo`.

Mensagem:

`TESTE-ABSOLUTO-OK`

Resultado:
- Um único agendamento foi criado.
- O Hermes confirmou o horário correto em São Paulo.
- O cronjob foi executado.
- A notificação foi recebida.
- O job_id observado foi `7a0d7a106706`.

Teste aprovado.

## 4. Prompt v1 — prevenção de duplicação

Foi criado o seguinte prompt padrão para testes:

Crie exatamente UM lembrete.

Data: [DATA]
Horário: [HH:MM]
Mensagem: [MENSAGEM]

Use exclusivamente o fuso horário `America/Sao_Paulo`.

Regras obrigatórias:
- Crie somente UM lembrete.
- Não crie lembretes duplicados.
- Não crie nenhum outro agendamento.
- Não faça nenhuma outra ação.
- Se já existir um lembrete idêntico para a mesma data, horário e mensagem, não crie outro.
- Depois de criar, apenas confirme o agendamento.

## 5. Teste de criação com o Prompt v1

Foi utilizado o Prompt v1 para criar:

Data: 04/09/2026
Horário: 14:45
Mensagem: `esse e o teste do prompt ver1`

Resultado:
- Hermes verificou se já existia lembrete idêntico.
- Não encontrou duplicação.
- Criou exatamente um lembrete.
- Confirmou o agendamento para 14:45 em São Paulo.
- O cronjob executou o lembrete.
- A mensagem recebida foi:
  `esse e o teste do prompt ver1`

Teste aprovado.

## 6. Teste de duplicação com o Prompt v1

O mesmo pedido foi repetido posteriormente para:

Data: 04/09/2026
Horário: 14:55
Mensagem: `esse e o teste do prompt ver1`

Na primeira solicitação:
- Hermes criou o lembrete.

Na segunda solicitação, idêntica:
- Hermes verificou a existência do lembrete.
- Identificou que já existia um lembrete idêntico.
- Não executou uma nova criação.
- Informou que não criaria um duplicado.

Resultado:
- A prevenção de duplicação funcionou conforme esperado.

Teste aprovado.

## 7. Resultado geral da Fase 1

| Funcionalidade | Resultado |
|---|---|
| Resposta básica | APROVADO |
| Execução de comandos simples | APROVADO |
| Identificação do usuário/Home | APROVADO |
| Verificação de horário | APROVADO |
| Conversão para America/Sao_Paulo | APROVADO |
| Agendamento relativo | APROVADO, com observação |
| Lembrete único | APROVADO |
| Cancelamento | APROVADO |
| Horário absoluto inválido/passado | APROVADO |
| Horário absoluto válido | APROVADO |
| Criação com Prompt v1 | APROVADO |
| Prevenção de duplicação com Prompt v1 | APROVADO |

## 8. Observações

Os testes demonstraram que o sistema de alertas do Hermes funciona para os cenários básicos avaliados.

Foi observada duplicação em alguns testes simples de agendamento relativo. Por isso, o Prompt v1 passou a exigir explicitamente a criação de somente um lembrete e a verificação de um lembrete idêntico antes da criação.

O teste específico de duplicação com o Prompt v1 foi aprovado: quando o mesmo lembrete foi solicitado novamente, o Hermes identificou o agendamento existente e não criou outro.

O sistema do container permanece em UTC. Para os testes, foi utilizado explicitamente o fuso `America/Sao_Paulo`.

## 9. Autoaperfeiçoamento observado

Após o teste de horário absoluto bem-sucedido, o Hermes apresentou uma atualização de perfil e informou a criação da skill:

`scheduling-reminders`

Esse comportamento foi registrado como observação do teste e não como prova de que a skill seja necessária para o funcionamento básico do sistema.

## 10. Conclusão

A Fase 1 dos testes de Alertas e Lembretes foi concluída com sucesso.

As funcionalidades básicas de criação, execução, notificação, cancelamento, horários absolutos e relativos, utilização explícita do fuso `America/Sao_Paulo` e prevenção de duplicação com o Prompt v1 foram validadas.

Status da Fase 1: CONCLUÍDA.

## 11. Próximos passos

A próxima fase poderá testar cenários mais avançados, como:
- múltiplos lembretes independentes;
- lembretes recorrentes;
- cancelamento de lembrete específico entre vários agendamentos;
- comportamento após reinicialização do container;
- persistência dos agendamentos;
- recuperação após reinicialização;
- comportamento em caso de falha do serviço.
