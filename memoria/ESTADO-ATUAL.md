# Estado Atual — Biblioteca Viva

**Última atualização:** 2026-08-23

---

> **Guia de Aprendizado:** O documento mestre de aprendizado e continuidade do Laboratório de IA está em `GUIA-DE-APRENDIZADO.md` (V1.1, commit `d2df579`). Consulte-o como ponto de entrada para retomada de contexto. Este arquivo (`ESTADO-ATUAL.md`) complementa o Guia, detalhando o estado da Biblioteca Viva.

---

## V2 — Status das Oportunidades

| ID | Oportunidade | Status |
|---|---|---|
| O1 | Ampliar/refinar a taxonomia | Implementado |
| O3 | Detecção de extração inutilizável (DA4) | Implementado |
| O5 | Consolidação/retomada de corridas | Implementado |
| O2 | Política de Risco | Pendente |
| O4 | Revisão analítica pós-execução | Pendente |

### Detalhes da implementação

**O1 — Taxonomia:**
* Catálogo V2 (`dados/catalogo_v2.json`) com 14 folhas (era 9 na V1).
* Categorias novas: Documentos/Viagens, Documentos/Acadêmico,
  Documentos/Digitalizados, Tecnologia/Manuais, Áudio.
* Compatibilidade com leitor V1 preservada.
* Compatibilidade determinística por extensão implementada em `nucleo.py`:
  extensão → tipo → categoria-base, sem depender da IA.

**O3/DA4 — Qualidade de leitura:**
* Heurística determinística de legibilidade em `modulos/__init__.py`.
* Campos `conteudo_confivel` e `conteudo_sinalizacao` na percepção.
* Conteúdo não confiável sinalizado e substituído por metadados na
  proposta da IA.
* Leitura mínima de XLSX e PPTX implementada.

**O5 — Consolidação:**
* Ferramenta offline `testes/consolidar_corrida.py`.
* Leitura de N logs JSONL, cruzamento com filesystem.
* Relatório de estado: movidos, pendentes, inconsistentes, sem evento.

---

## Próximo passo

**O2 — Política de Risco** (`executar` | `marcar` | `reter`).

Implementação somente após autorização explícita.

---

## Referências

* `V2-ARQUITETURA.md` — proposta arquitetural completa
* `V2-OPORTUNIDADES.md` — registro de oportunidades e limitações
* `TESTES-USUARIO.md` — documentação de testes realizados pelo usuário
* `VALIDACAO-TESTE-USUARIO.md` — validação do primeiro teste físico
* `memoria/SESSOES/2026-08-23.md` — sessão de implementação da
  compatibilidade determinística por extensão
