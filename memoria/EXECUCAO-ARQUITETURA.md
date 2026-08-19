---
name: EXECUCAO-ARQUITETURA
description: Documenta as três formas de executar modelos no Laboratório de IA (OpenRouter, Ollama Cloud, Ollama Local) e a arquitetura de integração com Claude Code — contendo apenas comandos e fatos confirmados até hoje.
type: reference
---

# Arquitetura de Execução de Modelos

> **Objetivo:** descrever, de forma centralizada, como o Laboratório de IA seleciona e chama modelos através de três back‑ends distintos. Apenas fatos e comandos já testados/confirmados são registrados.

## 1. Visão geral do fluxo

```mermaid
graph LR
    A[Usuário / Claude Code] -->|Requisição| B[(Alternância Manual)]
    B -->|OpenRouter| C[Loader PowerShell (key.sec DPAPI)]
    B -->|Ollama Cloud| D[Ollama Cloud Server]
    B -->|Ollama Local| E[Ollama Local (localhost:11434)]
    C -->|HTTP Request| F[Model API]
    D -->|HTTP Request| F
    E -->|HTTP Request| F
    F -->|Resposta| B
    B -->|Resultado| A
```

> **Nota:** a "Alternância Manual" **não é um componente implementado** — hoje a troca entre backends é feita manualmente pelo usuário (executando o loader correspondente, apontando para o endpoint desejado, etc.). Não existe `MODEL_BACKEND`, `fallback`, `fallbackOrder` nem qualquer mecanismo automático de seleção.

## 2. Back‑ends suportados

| Backend | Tipo | Endpoint base | Chave de acesso | Observações |
|---------|------|--------------|----------------|-------------|
| **OpenRouter** | API pública (gratuita) | `https://openrouter.ai/api` | API‑Key armazenada em `$env:USERPROFILE\.openrouter\key.sec` (DPAPI/SecureString), **nunca escrita em texto puro** | Loader PowerShell injeta temporariamente as variáveis e limpa após a execução do Claude Code. Testado: `openrouter/free` → `OPENROUTER FREE OK`. |
| **Ollama Cloud** | Serviço SaaS pago | Endpoint: não documentado neste momento | **Não documentado** — não há configuração de token/secret store nos arquivos atuais (regra do usuário). | Conta com créditos/limite semanal. Em teste anterior recebeu HTTP 429 indicando limite atingido. Já usou `minimax/m3:cloud` via essa via. |
| **Ollama Local** | Execução local | `http://127.0.0.1:11434/api/` | Nenhuma (modelo já instalado) | Ideal para testes offline. Três modelos confirmados localmente (ver seção de comandos). |

> **Importante:** não documente como funcional nenhuma integração `Claude Code → Ollama Local` ou `Claude Code → Ollama Cloud` que ainda não tenha sido testada. O que está confirmado hoje é apenas o uso direto do `ollama run` local e o uso do loader OpenRouter com `openrouter/free`.

## 3. Comandos de diagnóstico e operação

### Ollama Local

```powershell
ollama --version
ollama list
ollama ps
curl http://localhost:11434/api/tags
```

### Teste de modelo local

```powershell
ollama run 4skl/gemma4-e4b-mtp:latest
```

Teste:

```text
Responda apenas: GEMMA LOCAL OK
```

Resultado confirmado:

```text
GEMMA LOCAL OK
```

Modelos atualmente instalados localmente:

* `gemma4:26b`
* `gemma4:12b`
* `4skl/gemma4-e4b-mtp:latest`

### Claude Code

```powershell
claude --version
claude --help
where.exe claude
```

Executável confirmado:

```text
C:\Users\lenovo\.local\bin\claude.exe
```

### Verificação do cofre OpenRouter

```powershell
Test-Path "$env:USERPROFILE\.openrouter\key.sec"
```

Resultado confirmado:

```text
True
```

Também regista-se que foi criado o backup:

```powershell
Test-Path "$env:USERPROFILE\.openrouter\key.sec.bak-antes-nova-chave"
```

Resultado confirmado:

```text
True
```

**Não documente a chave** ou seu conteúdo.

### Verificação do loader OpenRouter

```powershell
claude --version
```

Quando o loader está funcionando, aparece uma mensagem equivalente a:

```text
[openrouter] chave OK (length=73), base_url=https://openrouter.ai/api, bin=C:\Users\lenovo\.local\bin\claude.exe
```

**Não registrar a chave** ou seu conteúdo.

### Teste OpenRouter Free

```powershell
claude --model openrouter/free
```

Teste:

```text
Responda apenas: OPENROUTER FREE OK
```

Resultado confirmado:

```text
OPENROUTER FREE OK
```

**Histórico de diagnóstico:** tentou-se também:

```text
minimax/minimax-m2.5:free
```

Esse identificador **não foi aceito** pelo Claude Code/OpenRouter no nosso teste, enquanto `openrouter/free` funcionou.

### Diagnóstico das variáveis de ambiente

Registrar que usamos:

```powershell
$env:ANTHROPIC_BASE_URL
$env:ANTHROPIC_API_KEY
$env:OPENROUTER_API_KEY

Get-ChildItem Env: |
    Where-Object { $_.Name -match 'ANTHROPIC|OPENROUTER|OLLAMA' } |
    Select-Object Name
```

**Explicação:** o resultado vazio antes de executar `claude` é compatível com o nosso desenho atual, porque o loader descriptografa a chave somente durante a execução do Claude Code e depois remove as variáveis do processo.

## 4. Importante sobre alternância

Atualmente **não existe** um comando único nosso como:

```text
/model-backend ollama-local
```

ou

```text
MODEL_BACKEND=...
```

A alternância entre backends ainda é feita por configuração/manual — não há mecanismo automático implementado. Esse ponto será objeto de estudo/futuro implementação.

## 5. Memória — diferenciação conceitual

O repositório `V:\Claude Code\Laboratorio-IA` é a **fonte persistente de documentação e memória do projeto**.

Separar concepualmente três camadas:

1. **Memória/documentação persistente do laboratório**  
   — Arquivos versionados no Git (`ESTADO-ATUAL.md`, `DECISOES.md`, arquivos em `docs/`, o próprio `EXECUCAO-ARQUITETURA.md`, etc.). São a fonte oficial de referência para o projeto.

2. **Histórico/contexto da sessão do Claude Code**  
   — Registro da conversa atual com o agente. **Não se assume** que trocar de backend preserva automaticamente esse contexto; cada nova sessão ou mudança de provedor deve ser comunicada explicitamente para evitar perda de contexto.

3. **Backend e modelo utilizados naquela sessão**  
   — Registro do backend ativo (OpenRouter/free, Ollama Cloud, Ollama Local) e do modelo específico (`4skl/gemma4-e4b-mtp:latest`, `gemma4:26b`, etc.). Essa escolha deve ser **documentada ao iniciar** uma nova sessão ou ao mudar de provedor, para que o usuário saiba em qual contexto está trabalhando.

**A troca de modelo/backend NÃO deve ser considerada automaticamente como preservação de todo o contexto da sessão.** Isso será objeto de teste futuro.

---

*Este documento será mantido em sincronia com o repositório de memória (`MEMORY.md`) e com `DECISOES.md` para garantir rastreabilidade de decisões arquiteturais e de execução.*