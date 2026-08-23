import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from modulos import calcular_hash
from pre_voo import listar_arquivos
import consolidar_corrida as consolidador

CONSOLIDADOR = Path(__file__).resolve().parent / "consolidar_corrida.py"


def criar_arquivo(pasta, nome, conteudo):
    pasta.mkdir(parents=True, exist_ok=True)
    caminho = pasta / nome
    caminho.write_text(conteudo, encoding="utf-8")
    return caminho


def mover(caminho, biblioteca, categoria, novo_nome=None):
    destino_pasta = biblioteca / categoria
    destino_pasta.mkdir(parents=True, exist_ok=True)
    alvo = destino_pasta / (novo_nome or caminho.name)
    shutil.move(str(caminho), str(alvo))
    return alvo


def evento(hash_arquivo, origem, status, destino_previsto=None, destino_real=None, versao=1, com_decisao=True):
    decidir = (
        {"categoria_executada": "Outros", "confianca": 70, "motivo": "m", "proposta_da_ia": {}}
        if com_decisao else {"erro_da_ia": "falha"}
    )
    evento = {
        "versao_esquema": versao,
        "evento": "arquivo_processado",
        "tentativa": 1,
        "modo": "organizar",
        "modelo": "stub",
        "origem": str(origem),
        "hash_sha256": hash_arquivo,
        "ciclo": {
            "perceber": {"arquivo": Path(origem).name},
            "decidir": decidir,
            "agir": {"acao": "nenhuma",
                     "destino_previsto": str(destino_previsto) if destino_previsto else None,
                     "destino_real": str(destino_real) if destino_real else None},
            "verificar": {"resultado": "nao_aplicavel"},
        },
        "status": status,
    }
    return evento


def escrever_log(caminho, eventos):
    caminho.write_text(
        "\n".join(json.dumps(e, ensure_ascii=False) for e in eventos) + "\n",
        encoding="utf-8",
    )
    return caminho


def rodar_ferramenta(*argumentos):
    return subprocess.run(
        [sys.executable, "-u", str(CONSOLIDADOR), *argumentos],
        capture_output=True, text=True,
    )


def snapshot(raiz):
    estado = {}
    if raiz.exists():
        for caminho in listar_arquivos(raiz):
            estado[str(caminho.relative_to(raiz))] = calcular_hash(caminho)
    return estado


def main():
    verificacoes = []
    base = Path(tempfile.mkdtemp(prefix="bv_teste_consolidacao_"))
    logs_antes = {}

    def consolidacoes_basicas(entrada, log):
        decisoes, sem_hash, _, _, _ = consolidador.coletar_logs([log])
        disco = consolidador.estado_da_origem(entrada)
        return consolidador.consolidar(decisoes, sem_hash, disco)

    def classes_por_referencia(entradas):
        return {Path(e["referencia"]).name: e["classe"] for e in entradas}

    cenario = base / "s1_completa"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    hashes = {}
    for nome in ("a.txt", "b.txt", "c.txt"):
        caminho = criar_arquivo(entrada, nome, f"conteudo {nome}")
        hashes[nome] = calcular_hash(caminho)
        mover(caminho, biblioteca, "Outros")
    eventos = [
        evento(hashes["a.txt"], entrada / "a.txt", "movido",
               destino_previsto=biblioteca / "Outros" / "a.txt", destino_real=biblioteca / "Outros" / "a.txt"),
        evento(hashes["b.txt"], entrada / "b.txt", "movido",
               destino_previsto=biblioteca / "Outros" / "b.txt", destino_real=biblioteca / "Outros" / "b.txt"),
        evento(hashes["c.txt"], entrada / "c.txt", "movido",
               destino_previsto=biblioteca / "Outros" / "c.txt", destino_real=biblioteca / "Outros" / "c.txt"),
    ]
    log_s1 = escrever_log(cenario / "log.jsonl", [
        {"versao_esquema": 1, "evento": "execucao_iniciada", "total_arquivos": 3}
    ] + eventos)
    resultado_s1 = consolidacoes_basicas(entrada.resolve(), log_s1)
    mapa_s1 = classes_por_referencia(resultado_s1)
    verificacoes.append(("1 corrida completa: todos movido_confirmado",
                         len(resultado_s1) == 3 and all(c == consolidador.MOVIDO_CONFIRMADO for c in mapa_s1.values())))
    relatorio_s1 = consolidador.gerar_relatorio(
        resultado_s1, str(entrada.resolve()), ["log.jsonl"],
        {"eventos": 3, "colapsados": [], "sem_hash": []})
    verificacoes.append(("1 corrida completa: sem pendentes e sem inconsistentes",
                         "PENDENTES NA ORIGEM (0)" in relatorio_s1 and "INCONSISTENCIAS (0)" in relatorio_s1))

    cenario = base / "s2_interrompida"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    h_x = calcular_hash(criar_arquivo(entrada, "x.txt", "x"))
    h_y = calcular_hash(criar_arquivo(entrada, "y.txt", "y"))
    criar_arquivo(entrada, "z.txt", "z")
    destino_y = mover(entrada / "y.txt", biblioteca, "Documentos/Pessoal")
    log_s2 = escrever_log(cenario / "log.jsonl", [
        evento(h_y, entrada / "y.txt", "movido",
               destino_previsto=destino_y, destino_real=destino_y),
    ])
    resultado_s2 = consolidacoes_basicas(entrada.resolve(), log_s2)
    mapa_s2 = classes_por_referencia(resultado_s2)
    verificacoes.append(("2 corrida interrompida: movido + 2 sem_evento pendentes",
                         mapa_s2.get("y.txt") == consolidador.MOVIDO_CONFIRMADO
                         and mapa_s2.get("x.txt") == consolidador.SEM_EVENTO
                         and mapa_s2.get("z.txt") == consolidador.SEM_EVENTO))
    relatorio_s2 = consolidador.gerar_relatorio(
        resultado_s2, str(entrada.resolve()), ["log.jsonl"],
        {"eventos": 1, "colapsados": [], "sem_hash": []})
    verificacoes.append(("2 interrompida: pendentes apontam x e z",
                         "- x.txt  (sem_evento)" in relatorio_s2 and "- z.txt  (sem_evento)" in relatorio_s2))

    verificacoes.append(("3 movimento confirmado pelo filesystem (tripla refeita agora)",
                         any(e["classe"] == consolidador.MOVIDO_CONFIRMADO
                             and "hash identico" in e["detalhe"] for e in resultado_s2)))

    cenario = base / "s4_mentira_log"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    h_w = calcular_hash(criar_arquivo(entrada, "w.txt", "w"))
    log_s4 = escrever_log(cenario / "log_a.jsonl", [
        evento(h_w, entrada / "w.txt", "movido",
               destino_previsto=biblioteca / "Outros" / "w.txt", destino_real=biblioteca / "Outros" / "w.txt"),
    ])
    resultado_s4a = consolidacoes_basicas(entrada.resolve(), log_s4)
    verificacoes.append(("4a log diz movido, destino inexistente -> inconsistente",
                         resultado_s4a[0]["classe"] == consolidador.INCONSISTENTE
                         and "destino nao existe" in resultado_s4a[0]["detalhe"]))
    copia = biblioteca / "Outros"
    copia.mkdir(parents=True, exist_ok=True)
    (copia / "w.txt").write_text("w", encoding="utf-8")
    resultado_s4b = consolidacoes_basicas(entrada.resolve(), log_s4)
    verificacoes.append(("4b destino criado mas origem ainda ocupada -> inconsistente",
                         resultado_s4b[0]["classe"] == consolidador.INCONSISTENTE
                         and "origem ainda presente" in resultado_s4b[0]["detalhe"]))

    verificacoes.append(("5 arquivo sem evento classificado como pendente",
                         mapa_s2.get("x.txt") == consolidador.SEM_EVENTO))

    cenario = base / "s6_multiplos"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    h_m = calcular_hash(criar_arquivo(entrada, "m.txt", "m"))
    destino_m = mover(entrada / "m.txt", biblioteca, "Outros")
    log_s6 = escrever_log(cenario / "log.jsonl", [
        {"versao_esquema": 2, "evento": "execucao_iniciada", "total_arquivos": 1, "catalogo_sha256": "f" * 64},
        evento(h_m, entrada / "m.txt", "simulado",
               destino_previsto=destino_m, versao=2),
        evento(h_m, entrada / "m.txt", "movido",
               destino_previsto=destino_m, destino_real=destino_m, versao=2),
        {"versao_esquema": 2, "evento": "execucao_concluida"},
    ])
    resultado_s6 = consolidacoes_basicas(entrada.resolve(), log_s6)
    verificacoes.append(("6 multiplos eventos: ultimo prevalece (movido_confirmado)",
                         len(resultado_s6) == 1 and resultado_s6[0]["classe"] == consolidador.MOVIDO_CONFIRMADO))
    _, _, colapsados_s6, _, _ = consolidador.coletar_logs([log_s6])
    verificacoes.append(("6 colapso de evento repetido contabilizado", colapsados_s6 == 1))
    verificacoes.append(("7 log V1 aceito", resultado_s1 and mapa_s1.get("a.txt") == consolidador.MOVIDO_CONFIRMADO))
    verificacoes.append(("8 log V2 aceito (com catalogo_sha256)",
                         resultado_s6[0]["classe"] == consolidador.MOVIDO_CONFIRMADO))

    cenario = base / "s9_renomeado"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    h_k = calcular_hash(criar_arquivo(entrada, "k.txt", "k"))
    destino_k = mover(entrada / "k.txt", biblioteca, "Tecnologia/Linux", novo_nome="k-renomeado.pdf")
    log_s9 = escrever_log(cenario / "log.jsonl", [
        evento(h_k, entrada / "k.txt", "movido",
               destino_previsto=biblioteca / "Tecnologia/Linux/k.txt", destino_real=destino_k),
    ])
    resultado_s9 = consolidacoes_basicas(entrada.resolve(), log_s9)
    verificacoes.append(("9 correlacao por hash independe do nome no destino",
                         resultado_s9[0]["classe"] == consolidador.MOVIDO_CONFIRMADO
                         and "hash identico" in resultado_s9[0]["detalhe"]
                         and destino_k.name == "k-renomeado.pdf"))

    cenario = base / "s10_insuficiente"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    h_s = calcular_hash(criar_arquivo(entrada, "s.txt", "s"))
    log_s10 = escrever_log(cenario / "log.jsonl", [
        evento(h_s, entrada / "s.txt", "simulado",
               destino_previsto=biblioteca / "Outros" / "s.txt"),
    ])
    (entrada / "s.txt").unlink()
    resultado_s10 = consolidacoes_basicas(entrada.resolve(), log_s10)
    verificacoes.append(("10 sumiu apos dry-run -> informacao_insuficiente",
                         resultado_s10[0]["classe"] == consolidador.INSUFICIENTE))

    cenario = base / "s11_intruso"
    entrada, biblioteca = cenario / "entrada", cenario / "Biblioteca"
    h_t = calcular_hash(criar_arquivo(entrada, "t1.txt", "t1"))
    destino_t = mover(entrada / "t1.txt", biblioteca, "Outros")
    criar_arquivo(entrada, "intruso.txt", "aparecido depois das corridas")
    log_s11 = escrever_log(cenario / "log.jsonl", [
        evento(h_t, entrada / "t1.txt", "movido",
               destino_previsto=destino_t, destino_real=destino_t),
    ])
    resultado_s11 = consolidacoes_basicas(entrada.resolve(), log_s11)
    mapa_s11 = classes_por_referencia(resultado_s11)
    verificacoes.append(("11 arquivo inesperado no filesystem aparece como sem_evento",
                         mapa_s11.get("t1.txt") == consolidador.MOVIDO_CONFIRMADO
                         and mapa_s11.get("intruso.txt") == consolidador.SEM_EVENTO))

    saida_1 = rodar_ferramenta("--entrada", str((base / "s1_completa" / "entrada").resolve()), str(log_s1))
    saida_2 = rodar_ferramenta("--entrada", str((base / "s1_completa" / "entrada").resolve()), str(log_s1))
    verificacoes.append(("12 execucao repetida produz relatorio identico",
                         saida_1.returncode == 0 and saida_1.stdout == saida_2.stdout and len(saida_1.stdout) > 100))
    logs_antes["s1"] = hashlib.sha256(log_s1.read_bytes()).hexdigest()

    raiz_seguranca = base / "seguranca"
    entrada_seg = raiz_seguranca / "entrada"
    biblioteca_seg = raiz_seguranca / "Biblioteca"
    h_seg = calcular_hash(criar_arquivo(entrada_seg, "seguro.txt", "seguro"))
    destino_seg = mover(entrada_seg / "seguro.txt", biblioteca_seg, "Outros")
    criar_arquivo(entrada_seg, "ficou.txt", "fica")
    log_seg = escrever_log(raiz_seguranca / "log.jsonl", [
        evento(h_seg, entrada_seg / "seguro.txt", "movido",
               destino_previsto=destino_seg, destino_real=destino_seg),
    ])
    antes = (snapshot(entrada_seg), snapshot(biblioteca_seg), hashlib.sha256(log_seg.read_bytes()).hexdigest())
    execucao_seg = rodar_ferramenta("--entrada", str(entrada_seg.resolve()), str(log_seg))
    depois = (snapshot(entrada_seg), snapshot(biblioteca_seg), hashlib.sha256(log_seg.read_bytes()).hexdigest())
    verificacoes.append(("seguranca: nada alterado/movido/apagado no disco e log intacto",
                         execucao_seg.returncode == 0 and antes == depois))
    codigo_fonte = CONSOLIDADOR.read_text(encoding="utf-8")
    proibidos = ["urllib", "requests", "socket", "http://", "https://", "modelos_ia",
                 "subprocess", "shutil", "os.remove", ".unlink(", "rmdir", "rename"]
    encontrados = [token for token in proibidos if token in codigo_fonte]
    verificacoes.append(("seguranca: ferramenta sem IA, rede, escrita ou exclusao",
                         not encontrados and f"encontrados={encontrados}" == "encontrados=[]"))

    falhas = [nome for nome, ok in verificacoes if not ok]
    for nome, ok in verificacoes:
        print(f"{'OK ' if ok else 'FALHA'} {nome}")
    print("\nRESULTADO: " + ("OK - consolidacao validada" if not falhas else "FALHA: " + ", ".join(falhas)))
    print("--- exemplo de relatorio (cenario s2, corrida interrompida) ---")
    print(relatorio_s2)

    shutil.rmtree(base, ignore_errors=True)
    sys.exit(0 if not falhas else 1)


if __name__ == "__main__":
    main()
