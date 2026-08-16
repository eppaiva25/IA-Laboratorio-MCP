# Arquitetura: LLM, Tool, Agente, Skill e MCP

  Este documento explica cinco conceitos fundamentais de sistemas de IA com exemplos baseados no próprio
  laboratório (a pasta `IA-Laboratorio` onde este documento vive).

  ---

  ## 1. Modelo de linguagem (LLM)

  **O que é:** o "cérebro" estatístico que gera texto. Recebe um prompt e produz uma resposta com base em padrões 
  aprendidos durante o treinamento.

  **Características:**
  - Não tem acesso ao mundo real (arquivos, internet, relógio).
  - Só sabe o que viu no treinamento + o que está no contexto atual.
  - Pura predição de tokens.

  **Exemplo no laboratório:** quando você pergunta *"retorne ok"*, o modelo usado nesta sessão gera a palavra `ok`
  porque, dado o padrão da pergunta, essa é a continuação mais provável. Não há leitura de arquivo nenhuma — é só 
  texto.

  > A escolha exata do modelo (versão, provedor) não importa para este documento: o conceito vale para qualquer   
  LLM atual.

  ---

  ## 2. Tool (ferramenta)

  **O que é:** uma função externa que o LLM pode *pedir* para ser executada. Exemplos: leitura de arquivo, edição 
  de arquivo, execução de comandos, busca na web. O LLM não executa — ele emite uma chamada estruturada e o       
  ambiente de execução (o "harness") executa.

  **Características:**
  - Tem efeito colateral observável (lê arquivo, roda comando, busca na web).
  - O LLM recebe o *resultado* como texto e continua o raciocínio.

  **Exemplo no laboratório:** quando foi pedido *"leia o arquivo teste-agente.txt"*, o modelo emitiu uma chamada  
  para a tool de leitura de arquivo. O harness abriu o arquivo no disco e devolveu o conteúdo como texto, que o   
  modelo então mostrou na resposta.

  ---

  ## 3. Agente

  **O que é:** um loop que combina **LLM + tools + memória + objetivo**. O LLM decide qual tool usar, o harness   
  executa, o resultado volta para o LLM, e isso se repete até o objetivo ser atingido (ou esgotar passos).        

  **Características:**
  - Tem autonomia de decisão: escolhe a próxima ação com base no resultado anterior.
  - Pode encadear muitas tools em uma única tarefa.

  **Exemplo no laboratório:** uma sessão típica deste laboratório é um **agente**. Ela usa a tool de leitura de   
  arquivo para inspecionar conteúdo, a tool de edição para acrescentar uma frase, a tool de leitura novamente para
  confirmar, depois a tool de listagem para inventariar a pasta, e as tools de escrita para criar os documentos   
  `relatorio.md` e `arquitetura.md`. Nenhuma dessas ações foi pré-programada — o modelo decidiu cada passo.       

  ---

  ## 4. Skill

  **O que é:** um pacote nomeado de instruções que *estende* o comportamento do agente. É invocado por um comando 
  específico (por exemplo, `/nome-da-skill`) e carrega um conjunto de regras/fluxo para um tipo de tarefa.        

  **Características:**
  - Não é uma tool no sentido de "executar código externo" — é mais um **manual de procedimento** carregado no    
  contexto.
  - Pode acionar tools por conta própria (ex.: uma skill de visualização carrega regras e depois chama a tool de  
  escrita para gerar HTML).
  - Disponível apenas quando listada na configuração da sessão.

  **Exemplo no laboratório:** uma skill de inicialização de projeto carrega instruções para gerar um arquivo de   
  documentação; o agente então usa tools de leitura, listagem e escrita seguindo aquele roteiro. As skills        
  disponíveis mudam de versão para versão do ambiente — esta seção descreve o *conceito*, não a lista atual.      

  ---

  ## 5. MCP (Model Context Protocol)

  **O que é:** um protocolo padronizado para conectar o LLM a **fontes externas de dados e ferramentas** (bancos, 
  APIs, sistemas internos). Um *MCP server* expõe tools que aparecem para o agente como se fossem tools nativas.  

  **Características:**
  - Padroniza a interface — um mesmo servidor MCP pode ser usado por diferentes clientes de IA.
  - Amplia o "universo de tools" sem alterar o LLM em si.
  - É a forma moderna de dar ao agente acesso a sistemas empresariais (GitHub, Jira, banco de dados interno,      
  etc.).

  **Exemplo no laboratório:** o **GitHub MCP Server** adiciona ao agente ferramentas como leitura de arquivos,    
  consulta de commits e outras operações sobre repositórios. O LLM continua o mesmo; o cliente MCP passa a        
  disponibilizar novas ferramentas ao agente.

  ---

  ## Resumo visual da composição

  ```
  ┌─────────────────────────────────────────────────────────┐
  │                      AGENTE (loop)                      │
  │                                                         │
  │   ┌───────────┐    pensa    ┌──────────────┐            │
  │   │   LLM     │ ─────────►  │  decide qual │            │
  │   │ (cérebro) │ ◄─────────  │   tool usar  │            │
  │   └───────────┘   resultado └──────────────┘            │
  │                         │                               │
  │                         ▼                               │
  │              ┌──────────────────────┐                   │
  │              │  TOOLS (leitura,     │                   │
  │              │  escrita, shell,     │                   │
  │              │  MCP...)             │                   │
  │              └──────────────────────┘                   │
  │                                                         │
  │   Skills carregam instruções extras no contexto do LLM  │
  └─────────────────────────────────────────────────────────┘
  ```

  **Em uma frase cada:**
  - **LLM** gera texto.
  - **Tool** executa ações no mundo.
  - **Agente** é o loop LLM + tools com objetivo.
  - **Skill** é um procedimento nomeado que guia o agente.
  - **MCP** é um protocolo que permite conectar clientes de IA a servidores que expõem ferramentas e outros       
  recursos.
