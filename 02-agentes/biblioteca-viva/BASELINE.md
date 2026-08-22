# REGISTRO DE BASELINE — Biblioteca Viva

**Status: CONGELADA como baseline experimental.** Esta aplicação é a primeira
implementação experimental do Laboratório de IA e serve como referência
arquitetural para as próximas etapas. Não é uma especificação definitiva de
infraestrutura de IA. Alterações somente por autorização explícita.

## Princípio registrado

```
IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA
```

Implementado no ciclo `PERCEBER → DECIDIR → AGIR → VERIFICAR → REGISTRAR`
(`nucleo.py`), com catálogo como fonte de verdade (`catalogo.py`) e pré-voo
bloqueante (`pre_voo.py`).

## Camadas obrigatórias (desacoplamento de modelo)

```
AGENTE
   ↓
INTERFACE DE IA  (contrato: propor(percepcao, categorias) -> {categoria, confianca, motivo})
   ↓
MODELO ATIVO     (decisão de execução/configuração, NÃO arquitetural)
```

O agente depende apenas do **contrato da interface**. É proibido acoplar o
projeto a fornecedor ou família de modelo específico (Gemma, Qwen, Llama,
Ollama, OpenRouter ou qualquer outro). O modelo ativo pode mudar dinamicamente
sem alterar o desenho do agente. Testes de latência/disponibilidade não fazem
parte do objetivo da aplicação.

## Requisitos demonstrados nesta baseline

Pasta de entrada; localização de arquivos; percepção (nome, extensão, tamanho,
metadados, conteúdo quando tecnicamente possível); proposta por IA; comparação
contra catálogo; decisão determinística; apresentação da decisão; movimento;
nunca sobrescrever silenciosamente; verificação; registro; processamento em
sequência; preservação de arquivos em erro de IA; Outros para baixa confiança;
dry-run padrão; IA separada da execução determinística.

## Verificações executadas (reais)

Dry-run completo; execução real controlada com SHA-256 pós-movimento; colisões
com sufixos; erro de IA sem movimentação; catálogo inválido bloqueando;
entrada/biblioteca aninhadas bloqueando; modelo indisponível bloqueando.

## Limitações e defeitos conhecidos (registrados, não corrigidos)

1. Resumo da execução conta duas vezes um arquivo que falhou e foi reprocessado
   com sucesso na segunda tentativa (relatório; a auditoria JSONL distingue via
   campo `tentativa`).
2. Em erro de IA durante a decisão, a percepção já coletada não entra no evento
   auditado (fica apenas a nota "nao registrado devido ao erro").
3. Status `falha_movimento` é inalcançável (falha de movimento vira
   `erro_processamento`); retry continua funcionando.
4. O dry-run não antecipa sufixo de colisão (`-1`) no destino previsto.
5. Risco latente não observado em teste: movimento entre volumes diferentes usa
   cópia+exclusão; uma falha no meio registraria `erro_processamento` com o
   arquivo já no destino.
6. Mojibake cosmético em alguns consoles Windows capturados; eventos em disco
   são UTF-8 corretos.

Nenhum desses itens contraria os requisitos do prompt original; ficam
registrados para eventual autorização futura de correção.

## Regras vigentes

- Biblioteca Viva congelada; sem novas funcionalidades, módulos, tecnologias ou
  otimizações sem autorização.
- Próxima aplicação do laboratório seguirá seu próprio prompt como especificação
  principal, podendo tomar esta baseline como referência do princípio acima.
