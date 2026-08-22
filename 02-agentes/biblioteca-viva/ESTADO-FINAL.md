# ESTADO FINAL — Biblioteca Viva

**Data do fechamento:** 2026-08-22
**Status:** FECHADA E APROVADA PARA USO como organizador de arquivos.
Nenhuma implementação nova foi feita neste fechamento; apenas verificação,
demonstração final e esta documentação. Ver `BASELINE.md` para decisões
arquiteturais congeladas e limitações conhecidas registradas.

## O que ela faz

Organiza os arquivos de uma **pasta de entrada** dentro de uma **biblioteca
categorizada**, seguindo o princípio:

```
IA PROPÕE → CÓDIGO VALIDA → CÓDIGO EXECUTA → CÓDIGO VERIFICA → CÓDIGO REGISTRA
```

Ciclo por arquivo: `PERCEBER > DECIDIR > AGIR > VERIFICAR > REGISTRAR`.

Garantias: dry-run por padrão; pré-voo bloqueante; nunca sobrescreve (sufixo
`-1`, `-2`…); erro da IA não move nada; confiança abaixo de 60% vai para
`Outros`; nada é apagado jamais; auditoria append-only de tudo.

## Como iniciar

```powershell
cd "V:\Claude Code\IA-Laboratorio-MCP\02-agentes\biblioteca-viva"
python entrar.py
```

Sem flags o app pergunta interativamente; responder vazio = modo seguro.

## Comandos reais

```powershell
# DRY-RUN (padrão seguro — não move nem cria nada)
python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo simular

# ORGANIZAR DE VERDADE
python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo organizar

# Outros parâmetros opcionais
#   --catalogo caminho.json   (padrão: dados/catalogo_exemplo.json)
#   --modelo NOME             (padrão: detecção automática)
#   --limiar N                (padrão: 60)
```

## Simular x Organizar

| | `--modo simular` | `--modo organizar` |
|---|---|---|
| Move arquivos | Não | Sim |
| Cria pastas | Não | Materializa categorias no pré-voo |
| AGIR | `(simulado) -> destino previsto` | `movido -> destino real` |
| VERIFICAR | Não aplicável | Destino existe + origem vazia + hash idêntico |
| Status gerado | `simulado` | `movido` / `falha_verificacao` |

## Verificação do resultado

Logo após uma execução em modo `organizar`:

```powershell
python -u testes/verificar_resultado.py eventos/eventos_<timestamp>.jsonl
```

Confere por evento: esquema v1, ciclo completo, origem esvaziada, destino
existente, SHA-256 idêntico (`OK`/`FALHA`). Observação registrada: o verificador
foi desenhado para auditar corridas reais contra o filesystem do momento —
em log de dry-run ele marca `simulado` como "sem destino" (esperado), e logs
antigos divergem se as fixtures forem regeneradas depois da corrida. Isso não
impede o uso da aplicação.

## Registros / auditoria

`eventos/eventos_<data_hora>.jsonl` — uma linha JSON por evento
(append-only, `versao_esquema: 1`): percepção completa, proposta da IA,
decisão executada, destino previsto/real, verificação e status.

## Demonstração final executada no fechamento (2026-08-22)

Comando: `python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo simular`
Log gerado: `eventos/eventos_20260822_012838.jsonl`. Resultado: 9/9 `simulado`,
origem intacta (9 arquivos), biblioteca intocada.

## Estrutura final

```
biblioteca-viva\
├── entrar.py                   porta única de execução
├── nucleo.py                   ciclo PERCEBER>DECIDIR>AGIR>VERIFICAR>REGISTRAR
├── pre_voo.py                  checagens bloqueantes antes de qualquer ação
├── catalogo.py                 catálogo = fonte de verdade
├── modelos_ia.py               interface de IA (só propõe)
├── dados\catalogo_exemplo.json 9 categorias válidas
├── modulos\                    leitura: pdf, docx, texto, metadados
├── eventos\eventos_*.jsonl     auditoria
├── exemplos\
│   ├── entrada_teste\          fixtures de teste (9 arquivos)
│   └── Biblioteca\             biblioteca exemplo (contém colisões -1 reais)
└── testes\
    ├── gerar_arquivos_teste.py
    └── verificar_resultado.py
```

## Exemplo completo de uso

```powershell
cd "V:\Claude Code\IA-Laboratorio-MCP\02-agentes\biblioteca-viva"

# 1) Ver o que aconteceria (dry-run)
python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo simular

# 2) Conferir decisões no relatório; ajustar limiar se quiser (--limiar 70, p.ex.)

# 3) Executar de verdade
python entrar.py --entrada exemplos/entrada_teste --biblioteca exemplos/Biblioteca --modo organizar

# 4) Auditar
python -u testes/verificar_resultado.py eventos/eventos_<timestamp>.jsonl
```

Arquivos com erro de IA permanecem na origem para revisão manual e são listados
no resumo final. Repetir o comando depois processa apenas o que restou na pasta
de entrada.
