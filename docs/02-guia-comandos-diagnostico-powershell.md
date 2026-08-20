# Guia de comandos de diagnóstico — PowerShell e Git

> Referência didática do Laboratório de IA: comandos usados nas sessões de
> diagnóstico e validação (OpenRouter, cofre DPAPI, Claude Code, 9Router).
> Para cada comando: para que serve, quando usamos e o que conseguimos verificar.
>
> **Regra de segurança:** nenhum exemplo abaixo exibe chaves, tokens ou cabeçalhos
> `Authorization` reais. O segredo permanece sempre no cofre DPAPI e é referenciado
> apenas como variável em memória (`$key`).

## PowerShell

### Get-ChildItem

- **Para que serve:** listar arquivos e diretórios, com tamanho e datas.
- **Quando usamos:** para inspecionar o diretório do cofre (`%USERPROFILE%\.openrouter`)
  e conferir a estrutura do repositório.
- **O que verificamos:** a existência de `key.sec` e do backup
  `key.sec.bak-antes-nova-chave` (nomes, tamanhos e datas — nunca o conteúdo).

```powershell
Get-ChildItem "$env:USERPROFILE\.openrouter"
```

### Get-Content

- **Para que serve:** ler o conteúdo de um arquivo.
- **Quando usamos:** para ler o cofre `key.sec` e enviar o resultado direto ao
  `ConvertTo-SecureString`, sem exibir o segredo no console.
- **O que verificamos:** que o cofre é legível e decodificável como SecureString.

```powershell
$sec = Get-Content "$env:USERPROFILE\.openrouter\key.sec" | ConvertTo-SecureString
```

### Get-Command e Get-Command -All

- **Para que serve:** localizar comandos, funções, aliases e executáveis; com `-All`,
  lista todas as origens/versões do mesmo nome.
- **Quando usamos:** para descobrir qual `claude` seria executado de fato e confirmar
  que o alias aponta para o wrapper `Start-ClaudeCode` e o binário para o executável real.
- **O que verificamos:** alias `claude` → função `Start-ClaudeCode` (perfil PowerShell);
  binário resolvido: `C:\Users\lenovo\.local\bin\claude.exe`.

```powershell
Get-Command claude
Get-Command -All claude
```

### ConvertTo-SecureString

- **Para que serve:** converter texto (incluindo saída criptografada por DPAPI) em
  `SecureString`, protegida em memória.
- **Quando usamos:** ao descriptografar o cofre DPAPI da chave OpenRouter.
- **O que verificamos:** que a chave só pode ser recuperada pelo mesmo usuário/máquina
  que criptografou (vínculo DPAPI).

### PSCredential

- **Para que serve:** encapsular usuário + senha (`SecureString`) em um objeto padrão
  do PowerShell.
- **Quando usamos:** para manipular a chave recuperada do cofre sem ecoá-la no console
  nem no histórico de comandos.
- **O que verificamos:** manuseio seguro do segredo em memória (acesso somente via
  `Password`, que devolve SecureString).

```powershell
$cred = New-Object System.Management.Automation.PSCredential("openrouter", $sec)
```

### Marshal (SecureStringToBSTR / PtrToStringAuto / ZeroFreeBSTR)

- **Para que serve:** extrair o valor de uma SecureString para uso pontual em memória
  e liberar/zerar essa memória depois.
- **Quando usamos:** quando precisamos da chave como string apenas para montar a
  chamada de API ou alimentar o wrapper.
- **O que verificamos:** o padrão seguro de uso — extrair, usar, zerar
  (`ZeroFreeBSTR`); nunca imprimir o valor extraído.

```powershell
$b   = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password)
$key = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($b)
# usar $key aqui — nunca exibir
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)
```

### Invoke-RestMethod

- **Para que serve:** fazer chamadas HTTP com conversão automática de JSON em
  objetos PowerShell.
- **Quando usamos:** na validação completa da nova chave OpenRouter: catálogo de
  modelos, dados da chave e teste de chat completion.
- **O que verificamos:**
  - `GET /api/v1/models` → HTTP 200, catálogo retornado;
  - `GET /api/v1/key` → HTTP 200, chave ativa;
  - `POST /api/v1/chat/completions` com `anthropic/claude-haiku-4.5` e
    `max_tokens=1000` → resposta OK, com uso e custo retornados pela API
    (prompt_tokens = 20, completion_tokens = 11, total_tokens = 31,
    cost = 0.000075 USD).

```powershell
Invoke-RestMethod "https://openrouter.ai/api/v1/key" -Headers @{ Authorization = "Bearer $key" }
```

### curl.exe

- **Para que serve:** cliente HTTP de linha de comando para requisições brutas.
- **Quando usamos:** nas primeiras tentativas de diagnóstico da API.
- **O que verificamos:** a causa do erro `401 Missing Authentication header` —
  o cabeçalho `Authorization` não estava sendo enviado corretamente por causa do
  quoting do PowerShell. Depois disso migramos para `Invoke-RestMethod`, que evita
  esse problema.

## Claude Code (via wrapper)

### claude --version / where.exe claude

- **Para que serve:** conferir a versão do CLI e o caminho físico do executável.
- **Quando usamos:** antes de validar o wrapper, para garantir qual binário seria chamado.
- **O que verificamos:** binário confirmado em `C:\Users\lenovo\.local\bin\claude.exe`.

### claude --model openrouter/free

- **Para que serve:** executar o Claude Code usando o modelo de gateway do OpenRouter.
- **Quando usamos:** na validação final da frente Claude Code → OpenRouter.
- **O que verificamos:** resposta correta ao prompt de teste
  (`CLAUDE CODE + OPENROUTER FREE OK`), mesmo com o aviso esperado de que
  `openrouter/free` não é um modelo reconhecido internamente pelo CLI.

## Git

### git status

- **Para que serve:** mostrar o estado do Working Directory e da Staging Area.
- **Quando usamos:** no início e no fim das revisões, para saber o que mudou.
- **O que verificamos:** working tree sem alterações rastreadas; presença de arquivos
  untracked (`app.py`, `opencode.json`, `opencode.json.backup`) — decisão adiada.

### git log --oneline

- **Para que serve:** mostrar o histórico resumido de commits.
- **Quando usamos:** para confirmar o último estado registrado do repositório.
- **O que verificamos:** último commit `3965af5` — a memória documentada estava
  atrás dele e foi atualizada.

### git diff / git diff --staged

- **Para que serve:** revisar alterações fora da Staging Area (`git diff`) e já
  preparadas (`git diff --staged`).
- **Quando usamos:** antes de aceitar qualquer alteração neste laboratório —
  inclusive as feitas por agentes.
- **O que verificamos:** exatamente quais linhas seriam registradas no próximo commit.

### git add / git restore / git commit

- **Para que serve:** `git add` prepara alterações; `git restore` descarta alterações
  do Working Directory (com `--staged`, tira da Staging Area); `git commit` registra
  no histórico.
- **Quando usamos:** para aceitar (`add` → `diff --staged` → `commit`) ou rejeitar
  (`restore`) alterações — o agente propõe, a decisão é humana.
- **O que verificamos:** que o ciclo completo de revisão continua valendo para
  trabalho feito por agentes de IA.

---

*Guia mantido pelo Laboratório de IA — atualizado em 20/08/2026.*
