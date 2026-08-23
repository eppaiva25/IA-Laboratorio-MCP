import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import comparador_corridas as comparador


def evento_arquivo(hash_arquivo, categoria="Outros", confianca=70, status="simulado", destino=None, com_decisao=True):
    if destino is None:
        destino = f"{categoria}/arquivo.pdf" if categoria else None
    decidir = (
        {"proposta_da_ia": {"categoria": categoria, "confianca": confianca, "motivo": "m"},
         "categoria_executada": categoria, "confianca": confianca, "motivo": "m", "ajuste_do_sistema": ""}
        if com_decisao else {"erro_da_ia": "falha"}
    )
    return {
        "versao_esquema": 1,
        "evento": "arquivo_processado",
        "tentativa": 1,
        "modo": "simular",
        "origem": f"C\\entrada\\{hash_arquivo[:8]}.pdf",
        "hash_sha256": hash_arquivo,
        "ciclo": {
            "perceber": {"arquivo": "x.pdf"},
            "decidir": decidir,
            "agir": {"acao": "mover" if status == "movido" else "nenhuma", "destino_previsto": destino, "destino_real": None},
            "verificar": {"resultado": "nao_aplicavel"},
        },
        "status": status,
    }


def escrever_log(pasta, nome, eventos):
    caminho = pasta / nome
    caminho.write_text(
        "\n".join(json.dumps(e, ensure_ascii=False) for e in eventos) + "\n",
        encoding="utf-8",
    )
    return caminho


def classes(resultados):
    return {r["hash"]: r["classificacao"] for r in resultados}


def por_hash(resultados):
    return {r["hash"]: r for r in resultados}


H1 = "a" * 64
H2 = "b" * 64
H3 = "c" * 64
H4 = "d" * 64
H5 = "e" * 64
H6 = "f" * 64
H7 = "1" * 64
H8 = "2" * 64
H9 = "3" * 64


def main():
    verificacoes = []

    temporario = Path(tempfile.mkdtemp(prefix="bv_teste_comparador_"))

    log_a = escrever_log(temporario, "a.jsonl", [
        evento_arquivo(H1),
        evento_arquivo(H2, categoria="Documentos/Pessoal", confianca=90),
        evento_arquivo(H3, categoria="Outros", confianca=80),
        evento_arquivo(H4),
        evento_arquivo(H6),
        evento_arquivo(H7, categoria="Outros", confianca=30, status="simulado"),
        evento_arquivo(H8, categoria="Documentos/Financeiro", status="movido", destino="Documentos/Financeiro/doc.pdf"),
        evento_arquivo(H9, categoria="Outros", confianca=20),
    ])
    log_b = escrever_log(temporario, "b.jsonl", [
        evento_arquivo(H1, confianca=70),
        evento_arquivo(H2, categoria="Outros", confianca=90),
        evento_arquivo(H3, categoria="Outros", confianca=95),
        evento_arquivo(H5, categoria="Documentos/Pessoal", confianca=85),
        evento_arquivo(H6, com_decisao=False, status="nao_decidido_erro_ia", destino=None),
        evento_arquivo(H7, categoria="Documentos/Financeiro", confianca=95, status="movido"),
        evento_arquivo(H8, categoria="Documentos/Financeiro", status="movido", destino="Documentos/Financeiro/doc-1.pdf"),
        evento_arquivo(H9),
    ])

    por_hash_a, sem_hash_a, colapsados_a = comparador.carregar_decisoes(log_a)
    por_hash_b, sem_hash_b, colapsados_b = comparador.carregar_decisoes(log_b)
    resultados = comparador.comparar(por_hash_a, por_hash_b)
    mapa = classes(resultados)
    indice = por_hash(resultados)

    verificacoes.append(("iguais -> mesma_decisao", mapa[H1] == comparador.MESMA_DECISAO))
    verificacoes.append(("categoria diferente -> decisao_diferente[categoria]",
                         mapa[H2] == comparador.DECISAO_DIFERENTE and "categoria" in indice[H2]["dimensoes"]))
    verificacoes.append(("so confianca diferente -> mesma_decisao marcada",
                         mapa[H3] == comparador.MESMA_DECISAO and "confianca" in indice[H3]["dimensoes"]))
    verificacoes.append(("presente so na A -> somente_na_corrida_A", mapa[H4] == comparador.SOMENTE_EM_A))
    verificacoes.append(("presente so na B -> somente_na_corrida_B", mapa[H5] == comparador.SOMENTE_EM_B))
    verificacoes.append(("incompleto nos dois lados -> informacao_insuficiente",
                         mapa[H6] == comparador.INSUFICIENTE))
    verificacoes.append(("status e categoria divergentes -> decisao_diferente",
                         mapa[H7] == comparador.DECISAO_DIFERENTE
                         and set(indice[H7]["dimensoes"]) == {"categoria", "status", "confianca"}))
    verificacoes.append(("destino com sufixo divergente detectado",
                         mapa[H8] == comparador.DECISAO_DIFERENTE and indice[H8]["dimensoes"] == ["destino"]))
    verificacoes.append(("multiplos eventos do mesmo hash: ultimo vence (B tinha 1 so)",
                         mapa[H9] == comparador.MESMA_DECISAO))

    log_multi_a = escrever_log(temporario, "multi_a.jsonl", [
        evento_arquivo(H9, categoria="Outros", confianca=20, status="simulado"),
        evento_arquivo(H9, categoria="Documentos/Pessoal", confianca=90, status="movido"),
    ])
    log_multi_b = escrever_log(temporario, "multi_b.jsonl", [
        evento_arquivo(H9, categoria="Documentos/Pessoal", confianca=90, status="movido"),
    ])
    multi_a, _, colapsados_multi = comparador.carregar_decisoes(log_multi_a)
    multi_resultado = comparador.avaliar_par(H9, multi_a[H9], comparador.carregar_decisoes(log_multi_b)[0][H9])
    verificacoes.append(("multiplos eventos: ultimo evento prevalece na decisao",
                         multi_resultado["classificacao"] == comparador.MESMA_DECISAO and len(colapsados_multi) == 1))

    evento_sem_hash = evento_arquivo(H1)
    evento_sem_hash.pop("hash_sha256")
    log_sem_hash_a = escrever_log(temporario, "sh_a.jsonl", [evento_sem_hash])
    log_sem_hash_b = escrever_log(temporario, "sh_b.jsonl", [evento_arquivo("9" * 64)])
    sh_a, sem_a, _ = comparador.carregar_decisoes(log_sem_hash_a)
    sh_b, sem_b, _ = comparador.carregar_decisoes(log_sem_hash_b)
    verificacoes.append(("evento sem hash vai para lista separada",
                         len(sem_a) == 1 and len(sem_b) == 0 and len(sh_a) == 0))

    resultado_v2 = comparador.avaliar_par(H1,
                                          dict(por_hash_a[H1], origem="/novo/v2.pdf"),
                                          dict(por_hash_b[H1], origem="/outro/v1.pdf"))
    verificacoes.append(("campos extras/versoes distintas nao afetam comparacao",
                         resultado_v2["classificacao"] == comparador.MESMA_DECISAO))

    contagens, dimensoes, mesma_conf = comparador.resumir(resultados)
    relatorio = comparador.gerar_relatorio(resultados, [], [], [H9], [], "a.jsonl", "b.jsonl")
    verificacoes.append(("resumo consistente",
                         contagens[comparador.MESMA_DECISAO] == 3
                         and contagens[comparador.DECISAO_DIFERENTE] == 3
                         and contagens[comparador.SOMENTE_EM_A] == 1
                         and contagens[comparador.SOMENTE_EM_B] == 1
                         and contagens[comparador.INSUFICIENTE] == 1
                         and mesma_conf == 2
                         and dimensoes["categoria"] == 2
                         and dimensoes["destino"] == 1))
    verificacoes.append(("relatorio deterministico (duas geracoes identicas)",
                         relatorio == comparador.gerar_relatorio(resultados, [], [], [H9], [], "a.jsonl", "b.jsonl")))
    verificacoes.append(("relatorio menciona todos os hashes em ordem",
                         all(h in relatorio for h in sorted([H1, H2, H3, H4, H5, H6, H7, H8, H9]))))

    falhas = [nome for nome, ok in verificacoes if not ok]
    for nome, ok in verificacoes:
        print(f"{'OK ' if ok else 'FALHA'} {nome}")
    print(f"\nRESULTADO: {'OK - comparador validado' if not falhas else 'FALHA: ' + ', '.join(falhas)}")

    import shutil
    shutil.rmtree(temporario, ignore_errors=True)
    sys.exit(0 if not falhas else 1)


if __name__ == "__main__":
    main()
