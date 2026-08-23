import json
import sys
from pathlib import Path

MESMA_DECISAO = "mesma_decisao"
DECISAO_DIFERENTE = "decisao_diferente"
SOMENTE_EM_A = "somente_na_corrida_A"
SOMENTE_EM_B = "somente_na_corrida_B"
INSUFICIENTE = "informacao_insuficiente"
SEM_HASH = "sem_hash_sha256"

DIMENSOES_VALIDAS = ("categoria", "destino", "confianca", "status")


def carregar_decisoes(caminho_log):
    por_hash = {}
    sem_hash = []
    colapsados = []
    linhas = Path(caminho_log).read_text(encoding="utf-8").splitlines()
    for numero, linha in enumerate(linhas, 1):
        if not linha.strip():
            continue
        evento = json.loads(linha)
        if evento.get("evento") != "arquivo_processado":
            continue
        decisao = extrair_decisao(evento, numero)
        hash_arquivo = decisao["hash"]
        if not hash_arquivo:
            sem_hash.append(decisao)
            continue
        if hash_arquivo in por_hash:
            colapsados.append(hash_arquivo)
        por_hash[hash_arquivo] = decisao
    return por_hash, sem_hash, colapsados


def extrair_decisao(evento, numero_linha):
    ciclo = evento.get("ciclo") or {}
    decidir = ciclo.get("decidir") or {}
    agir = ciclo.get("agir") or {}
    categoria = decidir.get("categoria_executada")
    destino_previsto = agir.get("destino_previsto")
    nome_destino = Path(destino_previsto).name if destino_previsto else None
    return {
        "hash": evento.get("hash_sha256"),
        "origem": evento.get("origem"),
        "linha": numero_linha,
        "status": evento.get("status"),
        "categoria": categoria,
        "confianca": decidir.get("confianca"),
        "destino_nome": nome_destino,
        "destino_real": agir.get("destino_real"),
    }


def avaliar_par(hash_arquivo, da, db):
    if da is None:
        return {"hash": hash_arquivo, "classificacao": SOMENTE_EM_B, "b": db}
    if db is None:
        return {"hash": hash_arquivo, "classificacao": SOMENTE_EM_A, "a": da}
    if da["categoria"] is None or db["categoria"] is None:
        motivo = "lado A sem decisao registrada" if da["categoria"] is None else "lado B sem decisao registrada"
        return {"hash": hash_arquivo, "classificacao": INSUFICIENTE, "motivo": motivo, "a": da, "b": db}
    dimensoes = []
    if da["categoria"] != db["categoria"]:
        dimensoes.append("categoria")
    if da["status"] is None or db["status"] is None:
        return {"hash": hash_arquivo, "classificacao": INSUFICIENTE, "motivo": "sem status", "a": da, "b": db}
    if da["status"] != db["status"]:
        dimensoes.append("status")
    if (da["destino_nome"] is None) != (db["destino_nome"] is None):
        dimensoes.append("destino")
    elif da["destino_nome"] is not None and da["destino_nome"] != db["destino_nome"]:
        dimensoes.append("destino")
    confianca_divergente = (
        da["confianca"] is not None
        and db["confianca"] is not None
        and da["confianca"] != db["confianca"]
    )
    if confianca_divergente:
        dimensoes.append("confianca")
    dimensoes_de_decisao = [d for d in dimensoes if d != "confianca"]
    if not dimensoes_de_decisao:
        classificacao = MESMA_DECISAO
    else:
        classificacao = DECISAO_DIFERENTE
    return {
        "hash": hash_arquivo,
        "classificacao": classificacao,
        "dimensoes": dimensoes,
        "a": da,
        "b": db,
    }


def comparar(por_hash_a, por_hash_b):
    resultados = []
    for hash_arquivo in sorted(set(por_hash_a) | set(por_hash_b)):
        resultados.append(avaliar_par(hash_arquivo, por_hash_a.get(hash_arquivo), por_hash_b.get(hash_arquivo)))
    return resultados


def resumir(resultados):
    contagens = {chave: 0 for chave in (MESMA_DECISAO, DECISAO_DIFERENTE, SOMENTE_EM_A, SOMENTE_EM_B, INSUFICIENTE)}
    dimensoes = {nome: 0 for nome in DIMENSOES_VALIDAS}
    mesma_com_confianca_divergente = 0
    for r in resultados:
        contagens[r["classificacao"]] += 1
        for dimensao in r.get("dimensoes", []):
            dimensoes[dimensao] += 1
        if r["classificacao"] == MESMA_DECISAO and "confianca" in r.get("dimensoes", []):
            mesma_com_confianca_divergente += 1
    return contagens, dimensoes, mesma_com_confianca_divergente


def _rotulo(d):
    partes = [f"{d['categoria']}({d['confianca']}%)" if d["categoria"] else "(sem decisao)", d["status"] or "?"]
    return " ".join(partes)


def gerar_relatorio(resultados, sem_hash_a, sem_hash_b, colapsados_a, colapsados_b, rotulo_a, rotulo_b):
    contagens, dimensoes, mesma_conf = resumir(resultados)
    marcadores = {
        MESMA_DECISAO: "IGUAL      ",
        DECISAO_DIFERENTE: "DIFERENTE  ",
        SOMENTE_EM_A: "SOMENTE_A  ",
        SOMENTE_EM_B: "SOMENTE_B  ",
        INSUFICIENTE: "INSUFICIENTE",
    }
    linhas = [
        "=" * 74,
        "COMPARADOR DE CORRIDAS - Biblioteca Viva (offline, somente leitura)",
        f"corrida A: {rotulo_a}  ({len(sem_hash_a)} evento(s) sem hash; {len(colapsados_a)} evento(s) colapsado(s) por hash repetido)",
        f"corrida B: {rotulo_b}  ({len(sem_hash_b)} evento(s) sem hash; {len(colapsados_b)} evento(s) colapsado(s) por hash repetido)",
        "=" * 74,
    ]
    for r in resultados:
        classe = r["classificacao"]
        prefixo = marcadores[classe]
        if classe == SOMENTE_EM_A:
            detalhe = f"A:{_rotulo(r['a'])}  origem={Path(r['a']['origem']).name if r['a']['origem'] else '?'}"
        elif classe == SOMENTE_EM_B:
            detalhe = f"B:{_rotulo(r['b'])}  origem={Path(r['b']['origem']).name if r['b']['origem'] else '?'}"
        elif classe == INSUFICIENTE:
            detalhe = f"motivo={r['motivo']}"
        else:
            dims = ",".join(r.get("dimensoes", [])) or "-"
            detalhe = (
                f"dims=[{dims}]  "
                f"A:{_rotulo(r['a'])} | B:{_rotulo(r['b'])}"
            )
        linhas.append(f"{prefixo} {r['hash']}  {detalhe}")
    linhas.append("-" * 74)
    linhas.append("RESUMO")
    linhas.append(f"  mesma_decisao:                    {contagens[MESMA_DECISAO]}  (com confianca divergente: {mesma_conf})")
    linhas.append(f"  decisao_diferente:                {contagens[DECISAO_DIFERENTE]}")
    for nome in DIMENSOES_VALIDAS:
        linhas.append(f"    diverge em {nome}: {dimensoes[nome]}")
    linhas.append(f"  somente_na_corrida_A:             {contagens[SOMENTE_EM_A]}")
    linhas.append(f"  somente_na_corrida_B:             {contagens[SOMENTE_EM_B]}")
    linhas.append(f"  informacao_insuficiente:          {contagens[INSUFICIENTE]}")
    linhas.append(f"  eventos_sem_hash_sha256:          A={len(sem_hash_a)} B={len(sem_hash_b)}")
    linhas.append("=" * 74)
    return "\n".join(linhas)


def main():
    if len(sys.argv) != 3:
        print("uso: python testes/comparador_corridas.py <log_A.jsonl> <log_B.jsonl>", file=sys.stderr)
        sys.exit(2)
    caminho_a, caminho_b = Path(sys.argv[1]), Path(sys.argv[2])
    for caminho in (caminho_a, caminho_b):
        if not caminho.is_file():
            print(f"log nao encontrado: {caminho}", file=sys.stderr)
            sys.exit(2)
    try:
        por_hash_a, sem_hash_a, colapsados_a = carregar_decisoes(caminho_a)
        por_hash_b, sem_hash_b, colapsados_b = carregar_decisoes(caminho_b)
    except (json.JSONDecodeError, OSError) as erro:
        print(f"falha ao ler logs: {erro}", file=sys.stderr)
        sys.exit(2)
    resultados = comparar(por_hash_a, por_hash_b)
    relatorio = gerar_relatorio(
        resultados, sem_hash_a, sem_hash_b, colapsados_a, colapsados_b,
        caminho_a.name, caminho_b.name,
    )
    print(relatorio)
    sys.exit(0)


if __name__ == "__main__":
    main()
