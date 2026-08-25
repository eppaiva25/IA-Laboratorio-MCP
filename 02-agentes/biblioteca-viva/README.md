# Biblioteca Viva — Organizador

Agente autônomo de aprendizado que organiza uma pasta de arquivos misturados
dentro de uma árvore de categorias definida por um catálogo.

**Princípio central:** a IA apenas PROPÕE. O código determinístico valida contra
o catálogo, decide se aceita/ajusta/rejeita a proposta e é o único a EXECUTAR.

```
IA (Ollama)  --propõe JSON-->  núcleo determinístico  --valida e executa-->  disco
                                    |
                        catálogo = fonte de verdade
```

## Ciclo do agente (por arquivo)

| Etapa | Onde no código | O que faz |
|---|---|---|
| PERCEBER | `modulos/__init__.py` (`perceber`) | hash SHA-256, nome, extensão, tamanho e conteúdo (quando houver módulo de leitura) |
| DECIDIR | `modelos_ia.py` + `nucleo._validar_proposta` | IA propõe `{categoria, confianca, motivo}`; código determina tipo-base pela extensão e valida contra o catálogo; limiar de confiança aplicado |
| AGIR | `nucleo._mover_sem_sobrescrever` | move sem nunca sobrescrever (sufixo `-1`, `-2`, …) ou apenas simula |
| VERIFICAR | `nucleo.Agente.processar` | destino existe + origem vazia + hash idêntico ao da percepção |
| REGISTRAR | `nucleo.Agente._evento` | linha JSONL append-only com todo o ciclo (`versao_esquema: 1`) |

## Como executar

Requisitos: Python 3.10+ (somente biblioteca padrão) e um servidor Ollama com
ao menos um modelo instalado (`ollama pull llama3.2`, ou use o modelo já ativo).

```powershell
# gerar arquivos de teste representativos
python testes/gerar_arquivos_teste.py

# DRY-RUN (padrão seguro; nada é criado nem movido)
python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo simular

# ORGANIZAR de verdade
python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo organizar

# sem flags, a porta única pergunta interativamente (default = simular)
python entrar.py
```

Seleção de modelo (desacoplada de marca específica):
`--modelo NOME` > variável `BIBLIOTECA_MODELO` (ou `OLLAMA_MODEL`) > primeiro modelo disponível no Ollama.

## Segurança

- **Dry-run obrigatório por padrão**: sem `--modo`, ou respondendo vazio no menu, executa `simular`.
- **Pré-voo bloqueante**: entrada inexistente, catálogo inválido, entrada/biblioteca aninhadas,
  biblioteca não gravável ou modelo indisponível abortam ANTES de qualquer ação.
- **Nunca sobrescrever**: colisão de nome gera sufixo numérico, registrado na auditoria.
- **Erro da IA não move nada**: falha de rede/resposta inválida/categoria fora do catálogo
  produz status `nao_decidido_erro_ia`; o arquivo permanece na origem para revisão.
- **Confiança abaixo do limiar** (`--limiar`, padrão 60): proposta válida da IA é ajustada
  deterministicamente para `Outros`.
- **Tipo-base por extensão**: extensões conhecidas (.jpg → Fotos, .mp4 → Vídeos, .mp3 → Áudio,
  .pdf/.docx → Documentos etc.) são mapeadas deterministicamente; a IA não decide o tipo-base.
- **Identidade por hash**: SHA-256 recalculado após o movimento deve bater com o da percepção.
- **Nada é apagado jamais.**

## Catálogo (fonte de verdade)

`dados/catalogo_exemplo.json` define as únicas categorias permitidas (`versao_esquema: 1`,
campo `categorias` em árvore, precisa conter `Outros`). Para outra biblioteca, copie o
arquivo, edite a árvore e passe `--catalogo caminho.json`. Pastas das categorias são
materializadas na biblioteca durante o pré-voo do modo `organizar`.

## Módulos de leitura (extensível)

Registrados em `modulos/__init__.py`: `.pdf` (primeiro módulo; pypdf se instalado, senão
extração nativa via zlib), `.docx`, texto simples (`.txt .md .csv .log`). Qualquer outra
extensão cai em `modulo_metadados` (nome/extensão/tamanho) — adicionar um tipo novo =
criar `modulo_x.py` com `DESCRICAO` + `extrair_texto()` e registrar uma linha.

## Testes incluídos

```powershell
python testes/gerar_arquivos_teste.py        # fixtures: PDFs reais, DOCX real, binários, caso ambíguo
python -u testes/verificar_resultado.py eventos/eventos_<ts>.jsonl   # audita eventos x filesystem x hashes
python -u testes/teste_erro_ia.py            # prova: erro da IA não move arquivo
python -u testes/sonda_ollama.py             # latência dos modelos disponíveis
```

## Decisões de implementação registradas

1. Python puro (stdlib), sem dependências obrigatórias; `pypdf` é opcional.
2. Porta única: tudo entra por `entrar.py`; nenhum outro script altera a biblioteca.
3. Contrato das 5 etapas implementado literalmente como fases do registro de auditoria.
4. Proposta da IA em JSON estrito (`think:false` + `format:"json"` + `num_predict:400`
   quando suportado; repetição sem parâmetros extras se o servidor recusar).
5. Limiar de confiança padrão 60%; valor ajustável sem tocar no contrato.
6. Eventos append-only em `eventos/eventos_*.jsonl`, `versao_esquema: 1`.
7. Arquivos dentro de pastas ocultas (ex.: `.git`) são ignorados na varredura.
8. Movimento com falha transitoria é tentado uma segunda vez antes de ser reportado.
9. Tipo-base determinístico por extensão: mapeamento extensão→tipo→categoria-base
   em `nucleo.py`; a IA só participa de subcategorias semânticas.

## Limitações conhecidas (próximas versões)

- Sem OCR/exif para imagens e vídeos (decidem-se por nome/extensão/metadados).
- Extração nativa de PDF é best-effort (PDFs complexos podem não renderizar texto).
- Respostas do modelo variam entre execuções mesmo com `temperature=0` (não-determinismo
  do servidor); o sistema continua seguro pois toda proposta passa pelo mesmo filtro.
- Um único agente sequencial; sem fila, memória persistente ou reprocessamento automático.
