# Diário do Laboratório de IA: Nossa Jornada de Aprendizado

*Um registro didático para iniciantes, da configuração inicial até a decisão de uma abordagem mais simples.*

---

## 📅 Capítulo 1: Iniciando com Claude Code e OpenRouter

### A Contação da História

Tudo começou quando você, o pesquisador, entrou em contato com o Claude Code. O ambiente estava configurado com o provedor **OpenRouter** na camada `free`, o que significa:

- **Modelo em uso**: Um modelo de código aberto gratuito (provavelmente baseado no modelo Haiku ou similar)
- **Limites**: 1.600 tokens máximos em alguns casos, limites variáveis dependendo da carga
- **Plano gratuito**: 500k tokens de contexto total disponível, com limite por sessão

### O Primeiro Desafio: Entender o Diretório

Ao chegar, fizemos a descoberta inicial:
```
V:\Claude Code\Laboratorio-IA\
└── README.md (66 bytes)
```

Apenas um arquivo muito pequeno. Sentiu falta de estrutura? Foi exatamente isso que motivou nossa jornada de construção!

### O Aprendizado Inicial

**💡 Lição para iniciantes**: Começar praticamente vazio é normal. O importante não é quantos arquivos você tem, mas o **propósito** que você dá aos poucos recursos que inicia com. Um `README.md` bem escrito pode valer mais que 50 arquivos mal organizados.

---

## 🔍 Capítulo 2: O Encontro com o Repositório Remoto

### Descobrindo o GitHub

Você tinha um repositório já existente em:
`https://github.com/eppaiva25/IA-Laboratorio-MCP`

Usando a ferramenta `WebFetch`, conseguimos mapear sua estrutura:
```
IA-Laboratorio-MCP/
├── 01-agentes/
│   ├── 00-arquitetura.md
│   └── agente-explorador/
│       └── AGENTE.md
├── README.md
└── agente-teste.md
```

### A Surpresa: Encontramos o "Agente Explorador v1"

O arquivo `AGENTE.md` era uma especificação técnica de um agente de análise não-destrutiva. Vamos ver uma amostra:

> *"Agente de análise não destrutiva para o laboratório IA-Laboratorio-MCP. Revisão R2 — proporcionalidade explícita, diferenciação por ângulo, releitura obrigatória de estado."*

### O Que Fizemos (Leitura, Nunca Modificação)

1. **Leímos o arquivo local**: `C:\Users\lenovo\IA-Laboratorio\01-agentes\agente-explorador\AGENTE.md`
2. **Leímos o archivo remoto**: Versão correspondente no GitHub
3. **Comparamos os dois arquivos**: Descobrimos que são **100% idênticos** - uma cópia direta

### Resultado da Comparação

| Arquivo | Local | GitHub | Situação |
|---------|--------|---------|----------|
| AGENTE.md | 11.763 bytes | 11.763 bytes | **Idêntico** |

---

## 🤔 Capítulo 3: O Momento da Verdadeira Complexidade

### A Tentativa de Exploração Automática

Para avançar, migramos para a **fase 2: Experiência com agentes autônomos reais**.

Lançamos um agente `Explore` para buscar código relacionado a PDF:
```yaml
Subagente: Explore
Prompt: "Encontre códigos para ler/arquivar PDFs"
```

### O Desafio Surpreendente

A busca foi **cancelada com erro 402**:
```
API Error: 402 This request requires more credits, or fewer max_tokens. 
Você pediu até 64000 tokens, mas pode apenas afford 1600.
```

Isso nos fez parar para refletir: **quanto seria "demais" para um iniciante?**

### O Aprendizado Importante

**🔑 Chave para Iniciantes**: 
> Não tente fazer o agente ler "tudo de uma vez". Comece com perguntas específicas e delimitadas. Cada busca deve ter o "Tamanho Certo para o Cérebro" do seu colaborador.

---

## 🎯 Capítulo 4: A Decisão que Mudou Tudo

### Eis o Problema

O Agente Explorador v1, embora muito bem escrito, tinha características que assustavam iniciantes:

- **3 níveis de profundidade** com tabelas de orçamento
- **Checklist de 7-12 itens** internos
- **Fluxo de 10 passos** formalizado
- **15 regras explícitas** de limites

Para alguém que nunca programou um agente antes, parecia mais um manual técnico do que uma ferramenta prática.

### A Nossa Solução: Agente Explorador v2

Pensamos: **"e se fôssemos mais simples?"**

Criamos o v2 com regras de ouro muito mais simples:

| Conceito | v1 (Complexo) | v2 (Simples) |
|----------|---------------|--------------|
| Modos | 3 níveis: resumido/padrão/aprofundado | 2 modos: RÁPIDO / COMPLETO |
| Orçamento | Tabela matemática de leituras | "Leia o necessário, pare quando responder" |
| Verificação | Checklist de 7-12 itens | 3 perguntas visíveis |
| Fluxo | 10 passos formais | 3: Entender → Inspecionar → Relatar |

### O Impacto Visual

Imaginemos a diferença:

**ANTES (v1)**:
```
┌─────────────────────────────────────────────┐
│ Política de leitura:                        │
│ - Regra central: ...                        │
│ - Regras de capacidade: ...                 │
│ - Regras de redução: ...                    │
│ - Regra de expansão: ...                      │
└─────────────────────────────────────────────┘
```

**DEPOIS (v2)**:
```
┌─────────────────────────────────────────────┐
│ Regra de Ouro 1: Só leitura                 │
│ Regra de Ouro 2: Fotografia descartável    │
│ Regra de Ouro 3: Se não tem certeza, pergunta│
│ Regra de Ouro 4: Transparência total      │
└─────────────────────────────────────────────┘
```

---

## ✅ O Que Funcionou (e Deve Ser Replicado)

### 1. Leitura Não-Destrutiva
Nunca modificamos nenhum arquivo até o momento. Isso é a base da confiança.

### 2. Documentação de Processo
Criar o `docs/01-aprendizado-agente-explorador.md` foi um passo excelente - ajuda a fixar o aprendizado.

### 3. Pergunta Explícita de Caminhos
Quando o agente não trouxe resposta satisfatória, a solução foi perguntar: "Onde procurar PDFs?".

### 4. Transparência sobre Limites
Ao reportar o erro de tokens, ajudamos a entender os limites reais de recursos.

---

## ⚠️ O Que Foi Complexo Demais

### Para o Agente Explorador v1:

1. **Tabelas de Proporcionalidade**
   - Exigiam cálculos e entendimento de ranges de arquivo
   - Um iniciante espera: "analise meu projeto", não "qual o tamanho do seu repo?"

2. **Múltiplos Níveis com Sobreposição**
   - Você escolhe `padrão` mas quer detalhes de `aprofundado`?
   - Criam ambiguidade e insegurança

3. **Checklist Interno**
   - O agente verificava 7-12 itens, mas o usuário não via
   - Criou frustração quando achava que "tudo está certo" mas o agente ainda tinha falhas

4. **Leituras Massivas**
   - A tentativa de ler "todo o código" paralisou por limites de tokens
   - Um iniciante precisa de prompts: "me mostre só os arquivos principais"

---

## 🚀 Próximos Passos (Recomendados)

### Para o Laboratório

1. **✅ Concluir a documentação** (como fizemos com `01-aprendizado-agente-explorador.md`)
2. **📍 Definir caminho para PDFs**: Aqui está vamos perguntar ao usuário onde procurar
3. **📊 Implementar o v2 como prompt de sistema**: Testamos a lógica, agora codificamos

### Para o Iniciante

1. **Comece com o v2 "Modo Iniciante"**, não o v1
2. **Faça um teste pequeno hoje**:
   - Crie uma pasta teste
   - Coloque 2-3 arquivos de exemplo
   - Peça: "Analisa esta pasta rapidamente"
   - Veja como o agente responde (leia o que ele NOTOU, não só o que escreveu)

3. **Observe os limites de tokens**:
   - Quando um agente trava ou diz "não tenho créditos", entenda que é um recurso real
   - Ajuste o escopo: dois arquivos em vez de "toda a pasta"

---

## 📝 Diário de Borda: Perguntas que Realmente Fizemos

1. **Pergunta**: "Qual modelo estou usando?"
   **Resposta**: openrouter/free - entendemos os limites

2. **Pergunta**: "Listar arquivos da pasta"
   **Resposta**: Glob encontrou apenas README.md - aprendemos sobre estrutura inicial

3. **Pergunta**: "Comparar local com GitHub"
   **Resposta**: Encontramos AGENTE.md idêntico - validamos sincronização

4. **Pergunta**: "Fazer agente explorador"
   **Resposta**: Agente Explore falhou por tokens - aprendemos sobre limites de API

5. **Pergunta**: "Simplificar para v2"
   **Resposta**: Reduzimos 4 regras de ouro, 2 modos, 3 perguntas de verificação

---

## 🎓 Conclusão para Iniciantes

> **O maior insight desta jornada**: *Simplicidade não é menos funcionalidade - é mais foco no essencial.*

O Agente Explorador v1 era poderoso, mas como apontar um telescópio para entender uma antiga braseira. O v2 é como uma lanterna direta de cabeça: você aponta, ilumina o que importa e continua seu caminho sem se perder em complexidade.

**Próximos passos, se você decidir seguir com PDF:**
1. Me diga: "procure em `C:\Users\lenovo\Documents\PDFs`" (ou outro caminho)
2. Eu listarei os PDFs encontrados (sem abrir o conteúdo)
3. Você autoriza: "analise o conteúdo básico de cada PDF"
4. Eu mostro o inventário + proponho organização
5. Você diz: "pode organizar" ou "prefiro outra opção"

---

*Documento criado em 2026-08-18 como parte do diário de aprendizado deste laboratório de IA.*

---
*Não correspondente a qualquer código executável. Este arquivo documenta, não altera o sistema.*