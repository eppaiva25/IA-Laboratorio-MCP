import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent))

import catalogo
import nucleo
from modulos import calcular_hash

RAIZ_APLICACAO = Path(__file__).resolve().parent
CATALOGO_PADRAO = RAIZ_APLICACAO / "dados" / "catalogo_exemplo.json"
PASTA_EVENTOS = RAIZ_APLICACAO / "eventos"

BLOQUEIO_ESTRUTURA = "estrutura_invalida"
BLOQUEIO_ORIGEM = "origem_ausente"
BLOQUEIO_HASH = "hash_divergente"
BLOQUEIO_DESTINO = "fora_da_biblioteca"
BLOQUEIO_CATEGORIA = "categoria_invalida"


class ErroExecutor(Exception):
    pass


def _agora():
    return datetime.now().isoformat(timespec="seconds")


def carregar_decisoes_simuladas(caminho_log):
    caminho = Path(caminho_log)
    decisoes = []
    for linha in caminho.read_text(encoding="utf-8").splitlines():
        if not linha.strip():
            continue
        evento = json.loads(linha)
        if evento.get("evento") != "arquivo_processado" or evento.get("status") != "simulado":
            continue
        decisoes.append(_extrair_decisao(evento))
    if not decisoes:
        raise ErroExecutor(f"nenhuma decisao simulada no log: {caminho}")
    return decisoes, calcular_hash(caminho)


def _extrair_decisao(evento):
    ciclo = evento.get("ciclo") or {}
    decidir = ciclo.get("decidir") or {}
    agir = ciclo.get("agir") or {}
    return {
        "hash_sha256": str(evento.get("hash_sha256") or "").lower(),
        "origem": evento.get("origem"),
        "destino_previsto": agir.get("destino_previsto"),
        "categoria_executada": decidir.get("categoria_executada"),
        "confianca": decidir.get("confianca"),
        "motivo": decidir.get("motivo") or "",
        "proposta_da_ia": decidir.get("proposta_da_ia"),
        "quando_simulado": evento.get("quando"),
    }


def _estrutura_valida(decisao):
    hash_registrado = decisao["hash_sha256"]
    if len(hash_registrado) != 64 or any(c not in "0123456789abcdef" for c in hash_registrado):
        return False
    return bool(decisao["origem"]) and bool(decisao["destino_previsto"]) and bool(decisao["categoria_executada"])


def _dentro_da_biblioteca(destino, biblioteca):
    try:
        Path(destino).resolve().relative_to(biblioteca.resolve())
        return True
    except (OSError, ValueError):
        return False


def avaliar_viabilidade(decisao, biblioteca, categorias_validas):
    if not _estrutura_valida(decisao):
        return BLOQUEIO_ESTRUTURA
    origem = Path(decisao["origem"])
    if not origem.exists():
        return BLOQUEIO_ORIGEM
    if calcular_hash(origem) != decisao["hash_sha256"]:
        return BLOQUEIO_HASH
    if not _dentro_da_biblioteca(decisao["destino_previsto"], biblioteca):
        return BLOQUEIO_DESTINO
    if decisao["categoria_executada"] not in categorias_validas:
        return BLOQUEIO_CATEGORIA
    return None


def _perguntar(perguntar, rotulo):
    try:
        return perguntar(rotulo).strip().lower()
    except EOFError:
        return ""


def conduzir_revisao(itens_viaveis, perguntar):
    aprovados, recusados = [], []
    total = len(itens_viaveis)
    for indice, item in enumerate(itens_viaveis, 1):
        decisao = item["decisao"]
        print(f"\n[{indice}/{total}] {Path(decisao['origem']).name}")
        print(f"  origem : {decisao['origem']}")
        print(f"  destino: {decisao['destino_previsto']}")
        print(f"  decisao: {decisao['categoria_executada']} ({decisao['confianca']}%)")
        if decisao["motivo"]:
            print(f"  motivo : {str(decisao['motivo'])[:160]}")
        print(f"  hash   : {decisao['hash_sha256'][:12]}...")
        if _perguntar(perguntar, "  APROVAR movimentacao deste arquivo? [s/N]: ") in ("s", "sim"):
            item["revisao_usuario"] = "aprovado"
            aprovados.append(item)
            print("  REVISAO   aprovado pelo usuario")
        else:
            item["revisao_usuario"] = "recusado"
            recusados.append(item)
            print("  REVISAO   recusado pelo usuario")
    return aprovados, recusados


def conduzir_confirmacao(quantidade, perguntar):
    print("\n" + "=" * 62)
    print(f"PRONTO PARA MOVIMENTACAO FISICA de {quantidade} arquivo(s)")
    print("Os arquivos aprovados serao MOVIDOS para a biblioteca.")
    print("Sem confirmacao positiva, NENHUM arquivo e tocado.")
    return _perguntar(perguntar, "CONFIRMA a execucao fisica agora? Digite 's': ") in ("s", "sim")


class EscritorEventos:
    def __init__(self, caminho_arquivo, catalogo_sha256):
        self.caminho = Path(caminho_arquivo)
        self.catalogo_sha256 = catalogo_sha256

    def registrar(self, dados):
        dados.setdefault("versao_esquema", 2)
        dados.setdefault("catalogo_sha256", self.catalogo_sha256)
        self.caminho.parent.mkdir(parents=True, exist_ok=True)
        with open(self.caminho, "a", encoding="utf-8") as arquivo:
            arquivo.write(json.dumps(dados, ensure_ascii=False) + "\n")


def executar_decisoes(caminho_log, biblioteca, caminho_catalogo, caminho_eventos, perguntar=input):
    biblioteca = Path(biblioteca).resolve()
    if not biblioteca.is_dir():
        raise ErroExecutor(f"biblioteca nao existe: {biblioteca}")
    decisoes, sha_log_fonte = carregar_decisoes_simuladas(caminho_log)
    categorias_validas = catalogo.validar(catalogo.carregar(caminho_catalogo))
    catalogo_sha256 = calcular_hash(caminho_catalogo)

    itens = []
    for decisao in decisoes:
        motivo_bloqueio = avaliar_viabilidade(decisao, biblioteca, categorias_validas)
        itens.append({
            "decisao": decisao,
            "viavel": motivo_bloqueio is None,
            "motivo_bloqueio": motivo_bloqueio,
            "revisao_usuario": None,
        })

    escritor = EscritorEventos(caminho_eventos, catalogo_sha256)
    escritor.registrar({
        "evento": "execucao_decisoes_iniciada",
        "quando": _agora(),
        "modo": "executar_decisoes",
        "log_fonte": str(Path(caminho_log)),
        "sha256_log_fonte": sha_log_fonte,
        "biblioteca": str(biblioteca),
        "total_decisoes": len(itens),
    })

    viaveis = [i for i in itens if i["viavel"]]
    bloqueados = [i for i in itens if not i["viavel"]]
    aprovados, recusados = conduzir_revisao(viaveis, perguntar)

    for item in itens:
        decisao = item["decisao"]
        if not item["viavel"]:
            desfecho = "bloqueado"
        elif item["revisao_usuario"] == "aprovado":
            desfecho = "aprovado"
        elif item["revisao_usuario"] == "recusado":
            desfecho = "recusado"
        else:
            desfecho = "indefinido"
        escritor.registrar({
            "evento": "decisao_avaliada",
            "quando": _agora(),
            "hash_sha256": decisao["hash_sha256"],
            "origem": decisao["origem"],
            "destino_previsto": decisao["destino_previsto"],
            "categoria_executada": decisao["categoria_executada"],
            "confianca": decisao["confianca"],
            "viabilidade": "ok" if item["viavel"] else "bloqueado",
            "motivo_bloqueio": item["motivo_bloqueio"],
            "aprovacao_humana": item["revisao_usuario"],
            "desfecho_revisao": desfecho,
        })

    print("\n" + "-" * 62)
    print(f"REVISAO CONCLUIDA - aprovados: {len(aprovados)} | recusados: {len(recusados)} | bloqueados: {len(bloqueados)}")
    for item in bloqueados:
        print(f"  BLOQUEADO [{item['motivo_bloqueio']}] {Path(item['decisao']['origem']).name}")

    confirmacao = conduzir_confirmacao(len(aprovados), perguntar) if aprovados else False
    escritor.registrar({
        "evento": "execucao_fisica_confirmada",
        "quando": _agora(),
        "quantidade_aprovada": len(aprovados),
        "confirmacao": confirmacao,
    })

    contagens = {}
    bloqueios_pre_move = 0
    if confirmacao:
        print(f"\nExecutando movimentacao fisica de {len(aprovados)} arquivo(s)...")
        contexto = {
            "log_fonte": str(Path(caminho_log)),
            "sha256_log_fonte": sha_log_fonte,
            "biblioteca": str(biblioteca),
        }
        for indice, item in enumerate(aprovados, 1):
            resultado = _mover_um(item, biblioteca, categorias_validas, escritor, contexto, indice, len(aprovados))
            status = resultado["status"]
            contagens[status] = contagens.get(status, 0) + 1
            if status == "bloqueado_pre_move":
                bloqueios_pre_move += 1
    else:
        print("\nExecucao fisica CANCELADA - nenhum arquivo foi movido.")

    escritor.registrar({
        "evento": "execucao_decisoes_concluida",
        "quando": _agora(),
        "contagens_por_status": contagens,
        "totais_revisao": {"aprovados": len(aprovados), "recusados": len(recusados), "bloqueados": len(bloqueados)},
        "bloqueios_pre_move": bloqueios_pre_move,
    })
    return {
        "caminho_eventos": str(escritor.caminho),
        "total_decisoes": len(itens),
        "aprovados": len(aprovados),
        "recusados": len(recusados),
        "bloqueados": len(bloqueados),
        "confirmacao": confirmacao,
        "contagens_movimento": contagens,
        "bloqueios_pre_move": bloqueios_pre_move,
    }


def _mover_um(item, biblioteca, categorias_validas, escritor, contexto, indice, total):
    decisao = item["decisao"]
    origem = Path(decisao["origem"])
    print(f"\n[{indice}/{total}] {origem.name}")

    motivo_bloqueio = avaliar_viabilidade(decisao, biblioteca, categorias_validas)
    if motivo_bloqueio is not None:
        print(f"  AGIR       BLOQUEADO antes do movimento ({motivo_bloqueio}) - arquivo NAO movido")
        escritor.registrar({
            "evento": "movimento_bloqueado_pre_move",
            "quando": _agora(),
            "hash_sha256": decisao["hash_sha256"],
            "origem": decisao["origem"],
            "motivo": motivo_bloqueio,
        })
        return {"status": "bloqueado_pre_move"}

    alvo = nucleo._mover_sem_sobrescrever(origem, Path(decisao["destino_previsto"]).parent)
    print(f"  AGIR       movido -> {alvo}")

    ok_destino = alvo.exists()
    ok_origem = not origem.exists()
    ok_identidade = ok_destino and calcular_hash(alvo) == decisao["hash_sha256"]
    verificado = ok_destino and ok_origem and ok_identidade
    detalhe = ("destino existe, origem vazia, hash identico" if verificado
               else f"destino={ok_destino} origem_vazia={ok_origem} hash={ok_identidade}")
    print(f"  VERIFICAR  {'ok' if verificado else 'FALHOU'} ({detalhe})")
    status = "movido" if verificado else "falha_verificacao"

    escritor.registrar({
        "evento": "arquivo_processado",
        "tentativa": 1,
        "quando": _agora(),
        "modo": "executar_decisoes",
        "modelo": "(nao consultada - decisao reaproveitada)",
        "origem": str(origem),
        "hash_sha256": decisao["hash_sha256"],
        "origem_decisao": {**contexto, "quando_simulado": decisao["quando_simulado"]},
        "ciclo": {
            "perceber": {"arquivo": origem.name, "hash_sha256": decisao["hash_sha256"], "nota": "percepcao herdada da corrida simulada"},
            "decidir": {
                "proposta_da_ia": decisao["proposta_da_ia"],
                "categoria_executada": decisao["categoria_executada"],
                "confianca": decisao["confianca"],
                "motivo": decisao["motivo"],
                "ajuste_do_sistema": "",
            },
            "agir": {"acao": "mover", "destino_previsto": decisao["destino_previsto"], "destino_real": str(alvo)},
            "verificar": {"resultado": "ok" if verificado else "falhou", "detalhe": detalhe},
        },
        "status": status,
    })
    print(f"  REGISTRAR  {escritor.caminho.name}  [status: {status}]")
    return {"status": status}


def main():
    parser = argparse.ArgumentParser(
        prog="executar.py",
        description="Biblioteca Viva - executor das decisoes simuladas (a IA NAO e consultada)",
    )
    parser.add_argument("--log", required=True, help="log JSONL da corrida simulada")
    parser.add_argument("--biblioteca", required=True, help="raiz da biblioteca de destino")
    parser.add_argument("--catalogo", help="catalogo atual (padrao: dados/catalogo_exemplo.json)")
    argumentos = parser.parse_args()

    print("=" * 62)
    print("BIBLIOTECA VIVA - EXECUTOR DE DECISOES SIMULADAS")
    print("fluxo: SIMULAR > REVISAR > CONFIRMAR > EXECUTAR > VERIFICAR > REGISTRAR")
    print("decisoes vem exclusivamente do log; nenhuma nova analise e feita")
    print("=" * 62)

    caminho_log = Path(argumentos.log)
    if not caminho_log.is_file():
        _falhar(f"log de simulacao nao encontrado: {caminho_log}")
    caminho_catalogo = Path(argumentos.catalogo or CATALOGO_PADRAO)
    if not caminho_catalogo.is_file():
        _falhar(f"catalogo nao encontrado: {caminho_catalogo}")
    caminho_eventos = PASTA_EVENTOS / f"eventos_{time.strftime('%Y%m%d_%H%M%S')}_decisoes.jsonl"

    try:
        resumo = executar_decisoes(caminho_log, argumentos.biblioteca, caminho_catalogo, caminho_eventos)
    except (ErroExecutor, catalogo.CatalogoInvalido) as erro:
        _falhar(str(erro))
    except OSError as erro:
        _falhar(f"erro de E/S: {erro}")

    print("\n" + "=" * 62)
    print("RESUMO DA EXECUCAO DE DECISOES")
    print(f"  decisoes lidas       : {resumo['total_decisoes']}")
    print(f"  aprovadas (usuario)  : {resumo['aprovados']}")
    print(f"  recusadas (usuario)  : {resumo['recusados']}")
    print(f"  bloqueadas (tecnico) : {resumo['bloqueados']}")
    for status, quantidade in sorted(resumo["contagens_movimento"].items()):
        print(f"  {quantidade:>3}  {status}")
    print(f"Auditoria da execucao: {resumo['caminho_eventos']}")
    if resumo["contagens_movimento"].get("movido"):
        print("\nEstado final da biblioteca:")
        nucleo._imprimir_arvore(Path(argumentos.biblioteca).resolve(), prefixo="  ")


def _falhar(mensagem):
    print(f"ERRO: {mensagem}", file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
