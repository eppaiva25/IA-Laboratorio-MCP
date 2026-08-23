import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import comparador_corridas as comparador
from modulos import calcular_hash
from pre_voo import listar_arquivos

MOVIDO_CONFIRMADO = "movido_confirmado"
AINDA_NA_ORIGEM = "ainda_na_origem"
RETIDO_NA_ORIGEM = "retido_na_origem"
SEM_EVENTO = "sem_evento"
INCONSISTENTE = "inconsistente"
INSUFICIENTE = "informacao_insuficiente"

ORDEM_CLASSES = (
    MOVIDO_CONFIRMADO,
    AINDA_NA_ORIGEM,
    RETIDO_NA_ORIGEM,
    SEM_EVENTO,
    INCONSISTENTE,
    INSUFICIENTE,
)
CLASSES_PENDENTES = (AINDA_NA_ORIGEM, RETIDO_NA_ORIGEM, SEM_EVENTO)


def coletar_logs(caminhos_logs):
    decisoes_por_hash = {}
    sem_hash = []
    colapsados = 0
    total_eventos = 0
    primeira_origem = None
    for caminho in caminhos_logs:
        por_hash, sem_hash_parcial, colapsados_parcial = comparador.carregar_decisoes(Path(caminho))
        total_eventos += len(por_hash) + len(sem_hash_parcial) + len(colapsados_parcial)
        colapsados += len(colapsados_parcial)
        sem_hash.extend(sem_hash_parcial)
        for hash_arquivo, decisao in por_hash.items():
            decisoes_por_hash[hash_arquivo] = decisao
            if primeira_origem is None and decisao["origem"]:
                primeira_origem = decisao["origem"]
    return decisoes_por_hash, sem_hash, colapsados, total_eventos, primeira_origem


def estado_da_origem(pasta_origem):
    mapa = {}
    for caminho in listar_arquivos(Path(pasta_origem).resolve()):
        mapa[calcular_hash(caminho)] = caminho
    return mapa


def verificar_tripla(hash_esperado, origem_path, destino_real):
    if not destino_real:
        return False, "evento sem destino_real registrado"
    destino = Path(destino_real)
    if not destino.is_file():
        return False, "destino nao existe no filesystem atual"
    if origem_path is not None and origem_path.exists():
        return False, "origem ainda presente no filesystem atual"
    if calcular_hash(destino) != hash_esperado:
        return False, "hash do destino difere do registrado"
    return True, "destino existe, origem vazia, hash identico"


def classificar_por_status(hash_arquivo, decisao, disco_map):
    status = decisao["status"]
    origem_texto = decisao["origem"]
    origem_path = Path(origem_texto) if origem_texto else None
    disco_path = disco_map.get(hash_arquivo)
    nota_extra = None
    if disco_path and origem_path and disco_path != origem_path.resolve():
        nota_extra = f"copia com mesmo hash presente em {disco_path}"

    if status == "movido" or status == "falha_verificacao":
        ok, motivo = verificar_tripla(hash_arquivo, origem_path, decisao.get("destino_real"))
        if status == "movido" and decisao.get("destino_real") is None:
            classe, detalhe = INSUFICIENTE, motivo
        elif ok:
            classe = MOVIDO_CONFIRMADO
            detalhe = motivo if status == "movido" else f"log marcava falha_verificacao; reavaliado agora: {motivo}"
        else:
            classe, detalhe = INCONSISTENTE, f"log diz '{status}' mas {motivo}"
    elif status == "simulado":
        if origem_path is not None and origem_path.exists():
            classe, detalhe = AINDA_NA_ORIGEM, "dry-run nao move; arquivo aguarda execucao real"
        elif disco_path:
            classe, detalhe = INCONSISTENTE, "dry-run nao move, porem mesmo hash aparece na origem em outro caminho"
        else:
            classe, detalhe = INSUFICIENTE, "origem vazia e nenhum movimento registrado nas corridas informadas"
    elif status in ("nao_decidido_erro_ia", "erro_processamento"):
        if origem_path is not None and origem_path.exists():
            classe, detalhe = RETIDO_NA_ORIGEM, "retido conforme log; aguarda revisao ou nova corrida"
        else:
            classe, detalhe = INCONSISTENTE, "log indica retencao na origem, porem arquivo ausente agora"
    else:
        classe, detalhe = INSUFICIENTE, f"status desconhecido '{status}'"

    return {
        "hash": hash_arquivo,
        "classe": classe,
        "detalhe": detalhe,
        "nota_extra": nota_extra,
        "referencia": str(disco_path or origem_path or "?"),
    }


def classificar_sem_hash(decisao):
    origem_texto = decisao["origem"]
    origem_path = Path(origem_texto) if origem_texto else None
    status = decisao["status"]
    if origem_path is not None and origem_path.exists():
        if status in ("nao_decidido_erro_ia", "erro_processamento"):
            return {"hash": None, "classe": RETIDO_NA_ORIGEM, "detalhe": "evento sem hash; retido na origem",
                    "nota_extra": None, "referencia": str(origem_path)}
        return {"hash": None, "classe": INCONSISTENTE, "detalhe": f"evento sem hash com status '{status}' e origem ainda presente",
                "nota_extra": None, "referencia": str(origem_path)}
    return {"hash": None, "classe": INSUFICIENTE, "detalhe": "evento sem hash e sem como correlacionar ao filesystem",
            "nota_extra": None, "referencia": origem_texto or "?"}


def consolidar(decisoes_por_hash, sem_hash, disco_map):
    entradas = []
    for hash_arquivo in sorted(set(decisoes_por_hash) | set(disco_map)):
        decisao = decisoes_por_hash.get(hash_arquivo)
        if decisao is None:
            entradas.append({
                "hash": hash_arquivo,
                "classe": SEM_EVENTO,
                "detalhe": "arquivo presente na origem sem nenhum evento nas corridas informadas",
                "nota_extra": None,
                "referencia": str(disco_map[hash_arquivo]),
            })
        else:
            entradas.append(classificar_por_status(hash_arquivo, decisao, disco_map))
    for decisao in sem_hash:
        entradas.append(classificar_sem_hash(decisao))
    entradas.sort(key=lambda e: (ORDEM_CLASSES.index(e["classe"]), e["hash"] or "", e["referencia"]))
    return entradas


def gerar_relatorio(entradas, pasta_origem, rotulos_logs, totais):
    colapsados_total = totais["colapsados"]
    if not isinstance(colapsados_total, int):
        colapsados_total = len(colapsados_total)
    contagens = {classe: 0 for classe in ORDEM_CLASSES}
    for entrada in entradas:
        contagens[entrada["classe"]] += 1
    linhas = [
        "=" * 74,
        "CONSOLIDACAO DE CORRIDAS - Biblioteca Viva (offline, somente leitura)",
        f"origem: {pasta_origem}",
        f"corridas ({len(rotulos_logs)}): " + "; ".join(rotulos_logs),
        f"eventos lidos: {totais['eventos']}  eventos colapsados por hash repetido: {colapsados_total}"
        f"  eventos sem hash: {len(totais['sem_hash'])}",
        "=" * 74,
    ]
    for entrada in entradas:
        indice_classe = f"[{entrada['classe']}]".ljust(24)
        nome = Path(entrada["referencia"]).name if entrada["referencia"] not in ("?", None) else "?"
        linha = f"{indice_classe} {entrada['hash'][:16] if entrada['hash'] else 'sem-hash':<16} {nome}  {entrada['detalhe']}"
        if entrada["nota_extra"]:
            linha += f"  [{entrada['nota_extra']}]"
        linhas.append(linha)
    pendentes = [e for e in entradas if e["classe"] in CLASSES_PENDENTES]
    inconsistencias = [e for e in entradas if e["classe"] == INCONSISTENTE]
    linhas.append("-" * 74)
    linhas.append("RESUMO")
    for classe in ORDEM_CLASSES:
        linhas.append(f"  {classe:<24} {contagens[classe]}")
    linhas.append(f"\nPENDENTES NA ORIGEM ({len(pendentes)}) - candidatos a nova corrida:")
    if pendentes:
        for e in pendentes:
            linhas.append(f"  - {Path(e['referencia']).name}  ({e['classe']})")
    else:
        linhas.append("  (nenhum)")
    linhas.append(f"\nINCONSISTENCIAS ({len(inconsistencias)}):")
    if inconsistencias:
        for e in inconsistencias:
            linhas.append(f"  - {Path(e['referencia']).name}: {e['detalhe']}")
    else:
        linhas.append("  (nenhuma)")
    linhas.append("fonte do estado fisico: filesystem atual; logs usados apenas como historico")
    linhas.append("=" * 74)
    return "\n".join(linhas)


def main():
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass
    argumentos = sys.argv[1:]
    pasta_origem = None
    caminhos_logs = []
    indice = 0
    while indice < len(argumentos):
        token = argumentos[indice]
        if token == "--entrada":
            indice += 1
            if indice >= len(argumentos):
                print("--entrada exige um caminho", file=sys.stderr)
                sys.exit(2)
            pasta_origem = argumentos[indice]
        else:
            caminhos_logs.append(token)
        indice += 1
    if not caminhos_logs:
        print("uso: python testes/consolidar_corrida.py [--entrada PASTA] <log1.jsonl> [log2.jsonl ...]", file=sys.stderr)
        sys.exit(2)

    try:
        decisoes_por_hash, sem_hash, colapsados, total_eventos, primeira_origem = coletar_logs([Path(c) for c in caminhos_logs])
    except json.JSONDecodeError as erro:
        print(f"log invalido: {erro}", file=sys.stderr)
        sys.exit(2)
    except OSError as erro:
        print(f"falha ao ler logs: {erro}", file=sys.stderr)
        sys.exit(2)

    if pasta_origem is None:
        if primeira_origem is None:
            print("nenhum evento com origem nos logs informados; use --entrada", file=sys.stderr)
            sys.exit(2)
        pasta_origem = str(Path(primeira_origem).parent)
    if not Path(pasta_origem).is_dir():
        print(f"pasta de origem nao existe: {pasta_origem}", file=sys.stderr)
        sys.exit(2)

    disco_map = estado_da_origem(pasta_origem)
    entradas = consolidar(decisoes_por_hash, sem_hash, disco_map)
    totais = {"eventos": total_eventos, "colapsados": colapsados, "sem_hash": sem_hash}
    print(gerar_relatorio(
        entradas,
        str(Path(pasta_origem).resolve()),
        [Path(c).name for c in caminhos_logs],
        totais,
    ))
    sys.exit(0)


if __name__ == "__main__":
    main()
