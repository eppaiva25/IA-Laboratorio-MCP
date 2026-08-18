# Git Local no Laboratório de IA — Primeiro Repositório e Primeiro Commit

*Registro do aprendizado prático realizado em 18/08/2026.*

---

## 1. O objetivo desta etapa

Nesta etapa do Laboratório de IA, aprendemos a configurar o **Git localmente** e utilizá-lo para criar o primeiro histórico de versões do projeto `Laboratorio-IA`.

O objetivo não foi apenas executar comandos, mas entender o que o Git está fazendo e por que cada etapa é importante.

O repositório foi criado em:

`V:\Claude Code\Laboratorio-IA`

---

## 2. Verificação da instalação do Git

O Git já estava instalado no Windows e foi confirmado com:

```powershell
git --version
```

Resultado:

```text
git version 2.55.0.windows.3
```

Também verificamos se o PowerShell estava sendo executado como administrador. O resultado foi:

```text
False
```

Isso não impediu a utilização do Git, pois a instalação já havia sido concluída com sucesso.

---

## 3. Configuração da identidade do Git

O Git precisa saber quem está criando os commits.

Verificamos:

```powershell
git config --global user.name
git config --global user.email
```

O nome e o e-mail já estavam configurados corretamente.

Essas informações ficam associadas aos commits para identificar o autor das alterações.

---

## 4. Criação do repositório

Entramos na pasta do laboratório:

```powershell
Set-Location "V:\Claude Code\Laboratorio-IA"
```

Confirmamos o caminho com:

```powershell
Get-Location
```

Depois inicializamos o Git:

```powershell
git init
```

O resultado foi:

```text
Initialized empty Git repository in V:/Claude Code/Laboratorio-IA/.git/
```

Isso criou a pasta:

```text
V:\Claude Code\Laboratorio-IA\.git
```

---

## 5. O que é a pasta `.git`

Uma das principais coisas aprendidas foi entender que `.git` é o **repositório Git local**.

Ela contém as informações internas necessárias para que o Git mantenha:

- histórico dos commits;
- branches;
- referências;
- objetos;
- estado do repositório;
- configurações internas.

Podemos pensar na estrutura assim:

```text
Laboratorio-IA
│
├── README.md
├── docs\
├── .gitignore
│
└── .git\
    ├── objects\
    ├── refs\
    ├── HEAD
    └── ...
```

Os arquivos que trabalhamos ficam fora de `.git`.

A pasta `.git` mantém o histórico e as informações necessárias para controlar suas versões.

### Uma correção importante

`.git` não é um cofre criptografado.

Ela é uma pasta interna/oculta do Git, mas **não oferece proteção por senha ou criptografia**.

Portanto:

> Git é uma ferramenta de controle de versões, não um mecanismo de proteção de segredos.

---

## 6. Primeiro `git status`

Depois de inicializar o repositório executamos:

```powershell
git status
```

O Git informou:

```text
On branch master

No commits yet

Untracked files:
    README.md
    docs/
```

Aprendemos aqui o conceito de **untracked files**.

Os arquivos existiam no computador, mas o Git ainda não estava acompanhando suas alterações.

---

## 7. Verificação da estrutura do projeto

Antes de adicionar os arquivos ao Git, verificamos toda a estrutura:

```powershell
Get-ChildItem -Force
```

e:

```powershell
Get-ChildItem -Recurse -Force | Select-Object FullName
```

Encontramos:

```text
.git\
README.md
docs\
```

Dentro de `docs` havia documentos relacionados ao aprendizado sobre agentes de IA e ao diário do laboratório.

Também verificamos que não havia naquele momento diretórios como:

```text
.claude\
node_modules\
.venv\
```

Isso permitiu criar um `.gitignore` inicial simples, sem ignorar estruturas que ainda não existiam.

---

## 8. Criação do `.gitignore`

Criamos:

```text
.gitignore
```

O objetivo foi impedir que determinados arquivos potencialmente sensíveis ou temporários sejam adicionados ao Git.

Incluímos regras para:

### Segredos

```text
.env
.env.*
!.env.example
```

### Chaves e certificados

```text
*.key
*.pem
*.p12
*.pfx
```

### Diretórios de credenciais

```text
secrets/
credentials/
```

### Arquivos temporários do Python

```text
__pycache__/
*.py[cod]
.venv/
venv/
```

Uma lição importante foi:

> O `.gitignore` deve ser configurado antes de colocar arquivos no primeiro commit, principalmente quando o projeto poderá trabalhar futuramente com credenciais e chaves de API.

---

## 9. A diferença entre o arquivo existir e o Git acompanhá-lo

Antes do `git add`, os arquivos estavam assim:

```text
Arquivos no computador
        ↓
Git ainda não os acompanha
```

O comando:

```powershell
git status
```

mostrava:

```text
Untracked files
```

Isso significa que os arquivos existiam, mas ainda não faziam parte do controle de versões.

---

## 10. O `git add`

Executamos:

```powershell
git add .
```

O ponto `.` significa adicionar ao staging as alterações encontradas a partir da pasta atual, respeitando as regras do `.gitignore`.

Depois executamos novamente:

```powershell
git status
```

O Git passou a mostrar:

```text
Changes to be committed:
```

e listou os oito arquivos que seriam incluídos no primeiro commit.

### O conceito de Staging Area

Aprendemos que o `git add` **não cria um commit**.

Ele coloca uma fotografia das alterações na chamada:

**Staging Area**

Podemos visualizar:

```text
Working Directory
       │
       │ git add
       ▼
Staging Area
       │
       │ git commit
       ▼
Repository
```

Isso permite revisar o que será registrado antes de criar o histórico.

---

## 11. Os avisos LF e CRLF

Durante o `git add` apareceram avisos como:

```text
LF will be replaced by CRLF
```

Aprendemos que isso está relacionado aos caracteres utilizados para representar o final das linhas dos arquivos.

- `LF` é comum em Linux e macOS.
- `CRLF` é tradicional no Windows.

O aviso não significava que havia erro ou corrupção dos arquivos.

O `git add` foi concluído normalmente.

---

## 12. O primeiro commit

Depois de verificar a staging area, criamos o primeiro commit:

```powershell
git commit -m "chore: inicializa Laboratório de IA"
```

O Git retornou:

```text
[master (root-commit) 4c63ef8] chore: inicializa Laboratório de IA
8 files changed, 1132 insertions(+)
```

Esse foi o primeiro registro oficial do estado do projeto.

O identificador curto do commit é:

```text
4c63ef8
```

---

## 13. Verificação do estado final

Depois do commit executamos:

```powershell
git status
```

Resultado:

```text
On branch master
nothing to commit, working tree clean
```

Isso significa que não existem alterações pendentes.

O estado atual dos arquivos corresponde ao estado registrado no último commit.

Também executamos:

```powershell
git log --oneline
```

Resultado:

```text
4c63ef8 (HEAD -> master) chore: inicializa Laboratório de IA
```

Assim confirmamos que o primeiro commit existe no histórico local.

---

## 14. O ciclo básico aprendido

A principal sequência aprendida foi:

```text
1. Trabalhar/modificar arquivos
          ↓
2. git status
          ↓
3. git add
          ↓
4. git status
          ↓
5. git commit
          ↓
6. git status
          ↓
7. git log
```

Essa sequência permite acompanhar conscientemente o que está acontecendo.

---

## 15. Git como ponto de segurança para experimentos

Uma das conclusões mais importantes para o nosso Laboratório de IA é que o Git pode funcionar como uma espécie de **ponto de restauração do projeto**.

Por exemplo:

```text
Estado inicial
     │
     ├── Commit 1
     │
     ├── Experimentação com agente
     │
     ├── Commit 2
     │
     ├── Alterações
     │
     └── Commit 3
```

Isso será particularmente útil quando começarmos a experimentar:

- Claude Code;
- agentes de IA;
- MCP;
- Python;
- n8n;
- scripts;
- automações;
- configurações de ferramentas.

Podemos experimentar, registrar estados importantes e, quando necessário, comparar as mudanças com versões anteriores.

---

## 16. Uma limitação importante

O Git não deve ser confundido com um sistema de backup ou criptografia.

O repositório local está dentro da própria pasta do projeto:

```text
V:\Claude Code\Laboratorio-IA\.git
```

Se o dispositivo ou o disco for perdido ou danificado, o repositório local também poderá ser perdido.

Da mesma forma, se uma informação secreta for colocada em um commit, simplesmente apagar o arquivo posteriormente não significa necessariamente que o segredo desapareceu do histórico.

Por isso:

> `.gitignore` ajuda a evitar que segredos sejam adicionados, mas não substitui boas práticas de segurança.

---

## 17. O que aprendemos até agora

Nesta primeira etapa aprendemos:

- o que é um repositório Git;
- o que é a pasta `.git`;
- o que significa `untracked`;
- o que é a staging area;
- para que serve `git add`;
- para que serve `git commit`;
- como verificar o estado com `git status`;
- como consultar o histórico com `git log`;
- para que serve `.gitignore`;
- a diferença entre controle de versões e backup;
- a diferença entre controle de versões e criptografia;
- como criar um primeiro ponto de restauração do laboratório.

---

## 18. Estado atual do Laboratório

Neste momento o repositório local está limpo e possui um primeiro commit:

```text
Branch: master

Commit:
4c63ef8 chore: inicializa Laboratório de IA

Working tree:
clean
```

O laboratório agora possui uma base versionada sobre a qual podemos começar a experimentar.

---

## 19. Próxima etapa

A próxima fase será entender como utilizar o Git durante o desenvolvimento com **Claude Code e agentes de IA**.

A ideia não será apenas usar Git para "guardar arquivos", mas aprender a utilizá-lo como parte da metodologia de trabalho:

```text
Git
  ↓
Estado conhecido
  ↓
Experimento com IA
  ↓
Verificação das alterações
  ↓
Commit
  ↓
Novo estado conhecido
```

Isso cria uma forma mais segura de experimentar automações e agentes, pois conseguimos saber **o que mudou, quando mudou e qual era o estado anterior**.

---

## Reflexão

O principal aprendizado desta etapa foi:

> **Git não é apenas um lugar para guardar código. É uma forma de registrar a evolução de um projeto.**

Para um laboratório de IA, isso é especialmente valioso porque podemos experimentar sem perder completamente a referência de onde começamos.

O primeiro commit do `Laboratório-IA` representa justamente isso: **um ponto de partida conhecido, identificado e recuperável dentro do histórico local.**

---

*Documento criado em 18/08/2026 como parte do aprendizado prático sobre Git e sua utilização no Laboratório de IA.*