import json
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))

from modulos import calcular_hash
import executar

VERIFICADOR = RAIZ / "testes" / "verificar_resultado.py"

CATALOGO_FIXTURE = {
    "versao_esquema": 1,
    "categorias": {
        "Documentos": {"Financeiro": {}, "Pessoal": {}},
        "Fotos": {"Viagens": {}},
        "Outros": {},
    },
}

falhas = []
verificacoes = 0
contador = iter(range(1, 10000))


def checar(condicao, descricao):
    global verificacoes
    verificacoes += 1
    if not condicao:
        falhas.append(descricao)
    print(f"{'OK ' if condicao else 'FALHA'} {descricao}")


def novo_ambiente(nome):
    base = Path(tempfile.mkdtemp(prefix=f"exec_{nome}_"))
    (base / "entrada").mkdir()
    (base / "biblioteca").mkdir()
    caminho_catalogo = base / "catalogo.json"
    caminho_catalogo.write_text(json.dumps(CATALOGO_FIXTURE), encoding="utf-8")
    return base, base / "entrada", base / "biblioteca", caminho_catalogo


def criar_arquivo(entrada, nome, conteudo):
    caminho = entrada / nome
    caminho.write_bytes(conteudo)
    return caminho


def evento_simulado(origem, categoria, destino_previsto, confianca=90, hash_forcado=None):
    hash_arquivo = hash_forcado or calcular_hash(origem)
    return {
        "versao_esquema": 2,
        "evento": "arquivo_processado",
        "tentativa": 1,
        "quando": "2026-08-23T00:00:00",
        "modo": "simular",
        "modelo": "fixture",
        "origem": str(origem),
        "hash_sha256": hash_arquivo,
        "ciclo": {
            "perceber": {"arquivo": origem.name, "hash_sha256": hash_arquivo},
            "decidir": {
                "proposta_da_ia": {"categoria": categoria, "confianca": confianca, "motivo": "teste"},
                "categoria_executada": categoria,
                "confianca": confianca,
                "motivo": "teste",
                "ajuste_do_sistema": "",
            },
            "agir": {"acao": "simulada", "destino_previsto": str(destino_previsto), "destino_real": None},
            "verificar": {"resultado": "nao_aplicavel", "detalhe": "simulacao"},
        },
        "status": "simulado",
    }


def criar_log(base, eventos):
    caminho = base / "log_simulacao.jsonl"
    caminho.write_text("".join(json.dumps(e, ensure_ascii=False) + "\n" for e in eventos), encoding="utf-8")
    return caminho


def respostas(*valores):
    sequencia = iter(valores)

    def perguntar(_rotulo):
        try:
            return next(sequencia)
        except StopIteration:
            return ""

    return perguntar


def rodar(base, biblioteca, log, catalogo, valores):
    caminho_eventos = base / f"eventos_execucao_{next(contador)}.jsonl"
    resumo = executar.executar_decisoes(
        log, biblioteca, catalogo, caminho_eventos, perguntar=respostas(*valores)
    )
    return resumo, caminho_eventos


def ler_eventos(caminho):
    return [json.loads(linha) for linha in Path(caminho).read_text(encoding="utf-8").splitlines() if linha.strip()]


def bytes_totais(*pastas):
    total = 0
    for pasta in pastas:
        for caminho in Path(pasta).rglob("*"):
            if caminho.is_file():
                total += caminho.stat().st_size
    return total


def cenario_aprovacao_total():
    base, entrada, biblioteca, catalogo = novo_ambiente("total")
    a = criar_arquivo(entrada, "a.txt", b"conteudo A")
    b = criar_arquivo(entrada, "b.pdf", b"conteudo B")
    h_a, h_b = calcular_hash(a), calcular_hash(b)
    log = criar_log(base, [
        evento_simulado(a, "Documentos/Financeiro", biblioteca / "Documentos" / "Financeiro" / "a.txt"),
        evento_simulado(b, "Fotos/Viagens", biblioteca / "Fotos" / "Viagens" / "b.pdf"),
    ])
    sha_log_antes = calcular_hash(log)
    bytes_antes = bytes_totais(entrada, biblioteca)
    resumo, eventos = rodar(base, biblioteca, log, catalogo, ["s", "s", "s"])
    bytes_depois = bytes_totais(entrada, biblioteca)

    checar(resumo["aprovados"] == 2 and resumo["confirmacao"], "total: 2 aprovados com confirmacao positiva")
    checar(resumo["contagens_movimento"].get("movido") == 2, "total: 2 arquivos movidos")
    checar(not a.exists() and not b.exists(), "total: origens ficaram vazias")
    alvo_a = biblioteca / "Documentos" / "Financeiro" / "a.txt"
    alvo_b = biblioteca / "Fotos" / "Viagens" / "b.pdf"
    checar(alvo_a.exists() and calcular_hash(alvo_a) == h_a, "total: destino A existe com hash identico")
    checar(alvo_b.exists() and calcular_hash(alvo_b) == h_b, "total: destino B existe com hash identico")
    checar(bytes_antes == bytes_depois, "total: conservacao de bytes (nada apagado)")

    evs = ler_eventos(eventos)
    tipos = [e["evento"] for e in evs]
    esperado = ["execucao_decisoes_iniciada", "decisao_avaliada", "decisao_avaliada",
                "execucao_fisica_confirmada", "arquivo_processado", "arquivo_processado",
                "execucao_decisoes_concluida"]
    checar(tipos == esperado, "total: sequencia exata dos eventos")
    processados = [e for e in evs if e["evento"] == "arquivo_processado"]
    checar(len(processados) == 2 and all(p["status"] == "movido" for p in processados),
           "total: eventos fisicos com status movido")
    checar(all(e["ciclo"]["verificar"]["resultado"] == "ok" for e in processados),
           "total: triade ok nos eventos fisicos")
    checar(all(p.get("origem_decisao") and p["origem_decisao"].get("sha256_log_fonte") for p in processados),
           "total: origem_decisao registrada")
    checar(calcular_hash(log) == sha_log_antes, "total: log da simulacao intocado")

    proc = subprocess.run([sys.executable, str(VERIFICADOR), str(eventos)], capture_output=True, text=True)
    checar(proc.returncode == 0, "total: verificar_resultado aceita o log de execucao (rc=0)")


def cenario_aprovacao_parcial():
    base, entrada, biblioteca, catalogo = novo_ambiente("parcial")
    c = criar_arquivo(entrada, "c.txt", b"C")
    d = criar_arquivo(entrada, "d.txt", b"D")
    log = criar_log(base, [
        evento_simulado(c, "Documentos/Pessoal", biblioteca / "Documentos" / "Pessoal" / "c.txt"),
        evento_simulado(d, "Outros", biblioteca / "Outros" / "d.txt"),
    ])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, ["s", "n", "s"])

    checar(resumo["aprovados"] == 1 and resumo["recusados"] == 1, "parcial: 1 aprovado, 1 recusado")
    checar(resumo["contagens_movimento"].get("movido") == 1, "parcial: apenas 1 movido")
    checar(not c.exists(), "parcial: aprovado foi movido")
    checar(d.exists(), "parcial: recusado permanece na origem")
    avaliadas = [e for e in ler_eventos(eventos) if e["evento"] == "decisao_avaliada"]
    desfechos = {Path(e["origem"]).name: e["desfecho_revisao"] for e in avaliadas}
    checar(desfechos.get("c.txt") == "aprovado" and desfechos.get("d.txt") == "recusado",
           "parcial: decisao_avaliada distingue aprovado/recusado")


def cenario_nenhuma_aprovacao():
    base, entrada, biblioteca, catalogo = novo_ambiente("nenhuma")
    e1 = criar_arquivo(entrada, "e1.txt", b"E1")
    e2 = criar_arquivo(entrada, "e2.txt", b"E2")
    log = criar_log(base, [
        evento_simulado(e1, "Outros", biblioteca / "Outros" / "e1.txt"),
        evento_simulado(e2, "Outros", biblioteca / "Outros" / "e2.txt"),
    ])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, ["n", "n"])

    checar(resumo["aprovados"] == 0 and resumo["confirmacao"] is False, "nenhuma: nada aprovado, sem confirmacao")
    checar(resumo["contagens_movimento"] == {}, "nenhuma: nenhum movimento tentado")
    checar(e1.exists() and e2.exists(), "nenhuma: arquivos intactos na origem")
    tipos = [e["evento"] for e in ler_eventos(eventos)]
    checar("arquivo_processado" not in tipos and tipos[-1] == "execucao_decisoes_concluida",
           "nenhuma: sem evento fisico e sequencia fechada")


def cenario_confirmacao_negativa():
    base, entrada, biblioteca, catalogo = novo_ambiente("negativa")
    f1 = criar_arquivo(entrada, "f1.txt", b"F1")
    log = criar_log(base, [evento_simulado(f1, "Outros", biblioteca / "Outros" / "f1.txt")])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, ["s", "n"])

    checar(resumo["aprovados"] == 1 and resumo["confirmacao"] is False, "negativa: aprovado mas confirmacao recusada")
    checar(resumo["contagens_movimento"] == {} and f1.exists(), "negativa: nenhum movimento fisico ocorreu")
    confirmada = [e for e in ler_eventos(eventos) if e["evento"] == "execucao_fisica_confirmada"][0]
    checar(confirmada["confirmacao"] is False, "negativa: confirmacao registrada como falsa")


def _cenario_bloqueio(nome, preparar, motivo_esperado):
    base, entrada, biblioteca, catalogo = novo_ambiente(nome)
    g = criar_arquivo(entrada, "g.txt", b"G")
    hash_original = calcular_hash(g)
    destino = preparar(base, entrada, biblioteca, g)
    log = criar_log(base, [evento_simulado(g, "Documentos/Financeiro", destino, hash_forcado=hash_original)])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, [])

    checar(resumo["bloqueados"] == 1 and resumo["aprovados"] == 0, f"{nome}: item bloqueado sem revisao")
    checar(resumo["contagens_movimento"] == {}, f"{nome}: nada movido")
    avaliada = [e for e in ler_eventos(eventos) if e["evento"] == "decisao_avaliada"][0]
    checar(avaliada["desfecho_revisao"] == "bloqueado" and avaliada["motivo_bloqueio"] == motivo_esperado,
           f"{nome}: motivo registrado = {motivo_esperado}")


def cenario_bloqueio_origem_ausente():
    def preparar(base, entrada, biblioteca, g):
        (entrada / "g.txt").unlink()
        return biblioteca / "Documentos" / "Financeiro" / "g.txt"
    _cenario_bloqueio("origem_ausente", preparar, "origem_ausente")


def cenario_bloqueio_hash_divergente():
    def preparar(base, entrada, biblioteca, g):
        (entrada / "g.txt").write_bytes(b"G modificado apos a simulacao")
        return biblioteca / "Documentos" / "Financeiro" / "g.txt"
    _cenario_bloqueio("hash_divergente", preparar, "hash_divergente")


def cenario_bloqueio_categoria_invalida():
    base, entrada, biblioteca, catalogo = novo_ambiente("categoria")
    g = criar_arquivo(entrada, "g.txt", b"G")
    log = criar_log(base, [evento_simulado(g, "Receitas/Doces", biblioteca / "Receitas" / "Doces" / "g.txt")])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, [])
    avaliada = [e for e in ler_eventos(eventos) if e["evento"] == "decisao_avaliada"][0]
    checar(resumo["bloqueados"] == 1 and g.exists(), "categoria: bloqueado e intocado")
    checar(avaliada["motivo_bloqueio"] == "categoria_invalida", "categoria: motivo = categoria_invalida")


def cenario_bloqueio_fora_da_biblioteca():
    base, entrada, biblioteca, catalogo = novo_ambiente("fora")
    g = criar_arquivo(entrada, "g.txt", b"G")
    log = criar_log(base, [evento_simulado(g, "Outros", entrada.parent / "outra_raiz" / "g.txt")])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, [])
    avaliada = [e for e in ler_eventos(eventos) if e["evento"] == "decisao_avaliada"][0]
    checar(resumo["bloqueados"] == 1 and g.exists(), "fora: bloqueado e intocado")
    checar(avaliada["motivo_bloqueio"] == "fora_da_biblioteca", "fora: motivo = fora_da_biblioteca")


def cenario_bloqueio_estrutura_invalida():
    base, entrada, biblioteca, catalogo = novo_ambiente("estrutura")
    g = criar_arquivo(entrada, "g.txt", b"G")
    log = criar_log(base, [evento_simulado(g, "Outros", biblioteca / "Outros" / "g.txt", hash_forcado="curto")])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, [])
    avaliada = [e for e in ler_eventos(eventos) if e["evento"] == "decisao_avaliada"][0]
    checar(resumo["bloqueados"] == 1 and g.exists(), "estrutura: bloqueado e intocado")
    checar(avaliada["motivo_bloqueio"] == "estrutura_invalida", "estrutura: motivo = estrutura_invalida")


def cenario_colisao_e_nao_sobrescrita():
    base, entrada, biblioteca, catalogo = novo_ambiente("colisao")
    x = criar_arquivo(entrada, "x.txt", b"X da origem")
    existente = biblioteca / "Outros" / "x.txt"
    existente.parent.mkdir(parents=True)
    existente.write_bytes(b"X pre-existente")
    log = criar_log(base, [evento_simulado(x, "Outros", existente)])
    resumo, eventos = rodar(base, biblioteca, log, catalogo, ["s", "s"])

    checar(resumo["contagens_movimento"].get("movido") == 1, "colisao: movimento concluido com colisao")
    alvo_real = biblioteca / "Outros" / "x-1.txt"
    checar(alvo_real.exists() and not x.exists(), "colisao: sufixo -1 aplicado e origem vazia")
    checar(existente.read_bytes() == b"X pre-existente", "colisao: arquivo pre-existente NAO sobrescrito")
    checar(calcular_hash(alvo_real) == calcular_hash_from(b"X da origem"), "colisao: triade hash no sufixado")

    processado = [e for e in ler_eventos(eventos) if e["evento"] == "arquivo_processado"][0]
    checar(processado["ciclo"]["agir"]["destino_real"].endswith("x-1.txt"),
           "colisao: destino_real real registrado (diferente do previsto)")


def calcular_hash_from(conteudo):
    import hashlib
    return hashlib.sha256(conteudo).hexdigest()


def cenario_execucao_duplicada_segura():
    base, entrada, biblioteca, catalogo = novo_ambiente("duplicada")
    y = criar_arquivo(entrada, "y.txt", b"Y")
    z = criar_arquivo(entrada, "z.txt", b"Z")
    log = criar_log(base, [
        evento_simulado(y, "Outros", biblioteca / "Outros" / "y.txt"),
        evento_simulado(z, "Outros", biblioteca / "Outros" / "z.txt"),
    ])
    primeiro, eventos1 = rodar(base, biblioteca, log, catalogo, ["s", "s", "s"])
    bytes_entre = bytes_totais(entrada, biblioteca)
    segundo, eventos2 = rodar(base, biblioteca, log, catalogo, ["s", "s"])

    checar(primeiro["contagens_movimento"].get("movido") == 2, "duplicada: primeira execucao move 2")
    checar(segundo["bloqueados"] == 2 and segundo["contagens_movimento"] == {},
           "duplicada: segunda execucao bloqueia tudo (origem ausente), zero movimentos")
    checar(bytes_totais(entrada, biblioteca) == bytes_entre, "duplicada: nada mudou na segunda execucao")


def cenario_checagem_estatica():
    fonte = (RAIZ / "executar.py").read_text(encoding="utf-8")
    checar("modelos_ia" not in fonte, "estatica: executar.py nao referencia modelos_ia")
    checar("propor" not in fonte.replace("_proposta", ""), "estatica: executar.py nao consulta IA")
    checar("_mover_sem_sobrescrever" in fonte, "estatica: reaproveita movimentacao deterministica do nucleo")


def main():
    print("=" * 62)
    print("TESTE DO EXECUTOR DE DECISOES SIMULADAS (offline, sem IA, sem rede)")
    print("=" * 62)
    cenarios = [
        cenario_aprovacao_total,
        cenario_aprovacao_parcial,
        cenario_nenhuma_aprovacao,
        cenario_confirmacao_negativa,
        cenario_bloqueio_origem_ausente,
        cenario_bloqueio_hash_divergente,
        cenario_bloqueio_categoria_invalida,
        cenario_bloqueio_fora_da_biblioteca,
        cenario_bloqueio_estrutura_invalida,
        cenario_colisao_e_nao_sobrescrita,
        cenario_execucao_duplicada_segura,
        cenario_checagem_estatica,
    ]
    for cenario in cenarios:
        print(f"\n--- {cenario.__name__} ---")
        try:
            cenario()
        except Exception as erro:
            checar(False, f"{cenario.__name__} levantou {erro.__class__.__name__}: {erro}")
    print("\n" + "=" * 62)
    print(f"verificacoes: {verificacoes} | falhas: {len(falhas)}")
    for falha in falhas:
        print(f"  FALHOU: {falha}")
    sys.exit(1 if falhas else 0)


if __name__ == "__main__":
    main()

