import json
import shutil
from collections import Counter
from datetime import datetime
from pathlib import Path

import modelos_ia
from modulos import calcular_hash, perceber


class DecisaoInvalida(Exception):
    pass


class Agente:
    def __init__(self, entrada, biblioteca, resultado_pre_voo, modelo, modo, limiar, arquivo_eventos, mostrar=print):
        self.entrada = Path(entrada).resolve()
        self.biblioteca = Path(biblioteca).resolve()
        self.categorias = resultado_pre_voo["categorias"]
        self.modelo = modelo
        self.modo = modo
        self.limiar = limiar
        self.arquivo_eventos = Path(arquivo_eventos)
        self.mostrar = mostrar

    def rodar(self, arquivos):
        total = len(arquivos)
        self._evento({"evento": "execucao_iniciada", "total_arquivos": total})
        self.mostrar(f"\nAnalisando {total} arquivo(s) | modo={self.modo} | modelo(IA)={self.modelo} | limiar={self.limiar}%")
        resultados = []
        for indice, caminho in enumerate(arquivos, 1):
            resultado = self._processar_com_rede_de_seguranca(indice, total, caminho, tentativa=1)
            resultados.append(resultado)
        reprocessar = [r["_caminho"] for r in resultados if r["status"] in ("erro_processamento",)]
        if reprocessar:
            self.mostrar(f"\nSegunda tentativa para {len(reprocessar)} arquivo(s) com falha transitoria...")
            for indice, caminho in enumerate(reprocessar, 1):
                resultado = self._processar_com_rede_de_seguranca(indice, len(reprocessar), caminho, tentativa=2)
                resultados.append(resultado)
        finais = {}
        for resultado in resultados:
            finais[resultado["origem"]] = resultado
        self._resumo(list(finais.values()))
        return list(finais.values())

    def _processar_com_rede_de_seguranca(self, indice, total, caminho, tentativa):
        try:
            return self.processar(indice, total, caminho, tentativa)
        except (modelos_ia.ErroIA, DecisaoInvalida) as erro:
            return self._registrar_nao_decidido_por_erro_da_ia(indice, total, caminho, tentativa, erro)
        except Exception as erro:
            return self._registrar_erro_inesperado(indice, total, caminho, tentativa, erro)

    def processar(self, indice, total, caminho, tentativa=1):
        nome_rel = caminho.relative_to(self.entrada)
        self.mostrar(f"\n[{indice}/{total}] {nome_rel}")

        percepcao = perceber(caminho)
        detalhe_conteudo = f", {len(percepcao['conteudo'])} caracteres de texto" if percepcao["conteudo"] else ""
        self.mostrar(
            f"  PERCEBER   sha256={percepcao['hash_sha256'][:12]}…  "
            f"{percepcao['tamanho_bytes']} bytes  [{percepcao['leitura_por']}{detalhe_conteudo}]"
        )

        try:
            proposta_da_ia = modelos_ia.propor(self.modelo, percepcao, self.categorias)
            categoria_executada, confianca, motivo, ajuste = _validar_proposta(proposta_da_ia, self.categorias, self.limiar)
        except (modelos_ia.ErroIA, DecisaoInvalida) as erro:
            return self._registrar_nao_decidido_por_erro_da_ia(indice, total, caminho, tentativa, erro, percepcao)
        self.mostrar(
            f"  DECIDIR    IA propoe: {proposta_da_ia.get('categoria')} ({proposta_da_ia.get('confianca')}%)"
        )
        if ajuste:
            self.mostrar(f"             sistema ajustou: {ajuste}")
        self.mostrar(f"             decisao executavel: {categoria_executada} — {motivo}")

        destino_previsto = self.biblioteca / categoria_executada / caminho.name
        if self.modo == "organizar":
            alvo = _mover_sem_sobrescrever(caminho, self.biblioteca / categoria_executada)
            self.mostrar(f"  AGIR       movido -> {alvo}")
        else:
            alvo = None
            self.mostrar(f"  AGIR       (simulado) -> {destino_previsto}")

        if self.modo == "organizar":
            ok_destino = alvo is not None and alvo.exists()
            ok_origem = not caminho.exists()
            ok_identidade = ok_destino and calcular_hash(alvo) == percepcao["hash_sha256"]
            verificado = ok_destino and ok_origem and ok_identidade
            detalhe_verificacao = (
                "destino existe, origem vazia, hash identico"
                if verificado
                else f"destino={ok_destino} origem_vazia={ok_origem} hash={ok_identidade}"
            )
            self.mostrar(f"  VERIFICAR  {'ok' if verificado else 'FALHOU'} ({detalhe_verificacao})")
            resultado_verificacao = "ok" if verificado else "falhou"
        else:
            self.mostrar("  VERIFICAR  nao aplicavel em simulacao")
            resultado_verificacao = "nao_aplicavel"

        if self.modo == "organizar":
            status = "movido" if resultado_verificacao == "ok" else "falha_verificacao"
        else:
            status = "simulado"
        self.mostrar(f"  REGISTRAR  {self.arquivo_eventos.name}  [status: {status}]")

        evento = {
            "versao_esquema": 1,
            "evento": "arquivo_processado",
            "tentativa": tentativa,
            "quando": _agora(),
            "modo": self.modo,
            "modelo": self.modelo,
            "origem": str(caminho),
            "hash_sha256": percepcao["hash_sha256"],
            "ciclo": {
                "perceber": percepcao,
                "decidir": {
                    "proposta_da_ia": proposta_da_ia,
                    "categoria_executada": categoria_executada,
                    "confianca": confianca,
                    "motivo": motivo,
                    "ajuste_do_sistema": ajuste,
                },
                "agir": {
                    "acao": "mover" if self.modo == "organizar" else "simulada",
                    "destino_previsto": str(destino_previsto),
                    "destino_real": str(alvo) if alvo else None,
                },
                "verificar": {"resultado": resultado_verificacao, "detalhe": detalhe_verificacao if self.modo == "organizar" else "simulacao"},
            },
            "status": status,
        }
        self._evento(evento)
        evento["_caminho"] = caminho
        return evento

    def _registrar_nao_decidido_por_erro_da_ia(self, indice, total, caminho, tentativa, erro, percepcao=None):
        self.mostrar(f"\n[{indice}/{total}] {caminho.relative_to(self.entrada)}")
        if percepcao:
            self.mostrar(f"  PERCEBER   sha256={percepcao['hash_sha256'][:12]}…  (coletado antes da falha)")
        else:
            self.mostrar(f"  PERCEBER   (interrompido antes da coleta)")
        self.mostrar(f"  DECIDIR    ERRO DA IA: {erro}")
        self.mostrar(f"  AGIR       NENHUMA — arquivo NAO movido (erro da IA jamais gera movimentacao silenciosa)")
        self.mostrar(f"  VERIFICAR  nao aplicavel")
        self.mostrar(f"  REGISTRAR  {self.arquivo_eventos.name}  [status: nao_decidido_erro_ia]")
        evento = {
            "versao_esquema": 1,
            "evento": "arquivo_processado",
            "tentativa": tentativa,
            "quando": _agora(),
            "modo": self.modo,
            "modelo": self.modelo,
            "origem": str(caminho),
            "hash_sha256": percepcao["hash_sha256"] if percepcao else None,
            "ciclo": {
                "perceber": percepcao if percepcao else {"nota": "nao registrado devido ao erro"},
                "decidir": {"erro_da_ia": str(erro)},
                "agir": {"acao": "nenhuma"},
                "verificar": {"resultado": "nao_aplicavel", "detalhe": "sem decisao, sem acao"},
            },
            "status": "nao_decidido_erro_ia",
        }
        self._evento(evento)
        evento["_caminho"] = caminho
        return evento

    def _registrar_erro_inesperado(self, indice, total, caminho, tentativa, erro):
        self.mostrar(f"\n[{indice}/{total}] {caminho.relative_to(self.entrada)}")
        self.mostrar(f"  ERRO INESPERADO: {erro.__class__.__name__}: {erro}")
        self.mostrar("  arquivo NAO movido")
        evento = {
            "versao_esquema": 1,
            "evento": "arquivo_processado",
            "tentativa": tentativa,
            "quando": _agora(),
            "modo": self.modo,
            "modelo": self.modelo,
            "origem": str(caminho),
            "ciclo": {
                "perceber": {"nota": "falhou com erro inesperado"},
                "decidir": {},
                "agir": {"acao": "nenhuma"},
                "verificar": {"resultado": "nao_aplicavel"},
            },
            "erro": f"{erro.__class__.__name__}: {erro}",
            "status": "erro_processamento",
        }
        self._evento(evento)
        evento["_caminho"] = caminho
        return evento

    def _resumo(self, resultados):
        contagens = Counter(r["status"] for r in resultados)
        self.mostrar("\n" + "=" * 62)
        self.mostrar("RESUMO DA EXECUCAO")
        self.mostrar("=" * 62)
        for status, quantidade in sorted(contagens.items()):
            self.mostrar(f"  {quantidade:>3}  {status}")
        nao_decididos = [r for r in resultados if r["status"] == "nao_decidido_erro_ia"]
        if nao_decididos:
            self.mostrar("\nArquivos retidos por erro da IA (revisar manualmente):")
            for r in nao_decididos:
                self.mostrar(f"  - {Path(r['origem']).name}: {r['ciclo']['decidir'].get('erro_da_ia', '')[:120]}")
        self.mostrar(f"\nAuditoria completa: {self.arquivo_eventos}")
        if self.modo == "organizar":
            self.mostrar("\nEstado final da biblioteca:")
            _imprimir_arvore(self.biblioteca, prefixo="  ")
        self._evento({
            "evento": "execucao_concluida",
            "contagens_por_status": dict(contagens),
        })

    def _evento(self, dados):
        self.arquivo_eventos.parent.mkdir(parents=True, exist_ok=True)
        linha = json.dumps(dados, ensure_ascii=False) + "\n"
        with open(self.arquivo_eventos, "a", encoding="utf-8") as arquivo:
            arquivo.write(linha)


def _validar_proposta(proposta, categorias_validas, limiar):
    categoria_bruta = str(proposta.get("categoria", "")).strip().strip("/\\").replace("\\", "/").strip("/")
    try:
        confianca = int(float(proposta.get("confianca", 0)))
    except (TypeError, ValueError):
        confianca = 0
    confianca = max(0, min(100, confianca))
    motivo = str(proposta.get("motivo", ""))[:300]

    categoria = _casar_com_catalogo(categoria_bruta, categorias_validas)
    if categoria is None:
        raise DecisaoInvalida(
            f"a IA propos a categoria '{categoria_bruta}' que NAO existe no catalogo. "
            f"Categorias validas: {categorias_validas}"
        )
    ajuste = ""
    if confianca < limiar and categoria != "Outros":
        motivo = f"[baixa confianca] proposta original era '{categoria}' ({confianca}%). {motivo}"
        categoria = "Outros"
        ajuste = f"'{proposta.get('categoria')}' -> Outros (confianca {confianca}% < limiar {limiar}%)"
    return categoria, confianca, motivo, ajuste


def _casar_com_catalogo(proposta, categorias_validas):
    normalizada = proposta.lower()
    for categoria in categorias_validas:
        if categoria.lower() == normalizada:
            return categoria
    for categoria in categorias_validas:
        if normalizada.endswith("/" + categoria.lower()) or categoria.lower().endswith("/" + normalizada):
            return categoria
    partes_proposta = [p.strip().lower() for p in normalizada.split("/") if p.strip()]
    if partes_proposta:
        for categoria in categorias_validas:
            partes_categoria = [p.strip().lower() for p in categoria.lower().split("/")]
            if partes_proposta[-len(partes_categoria):] == partes_categoria:
                return categoria
    return None


def _mover_sem_sobrescrever(origem, pasta_destino):
    pasta_destino.mkdir(parents=True, exist_ok=True)
    alvo = pasta_destino / origem.name
    if alvo.exists():
        numero = 1
        while (pasta_destino / f"{origem.stem}-{numero}{origem.suffix}").exists():
            numero += 1
        alvo = pasta_destino / f"{origem.stem}-{numero}{origem.suffix}"
    shutil.move(str(origem), str(alvo))
    return alvo


def _imprimir_arvore(pasta, prefixo=""):
    entradas = sorted(pasta.iterdir(), key=lambda e: (e.is_file(), e.name.lower()))
    for indice, entrada in enumerate(entradas):
        ultimo = indice == len(entradas) - 1
        ramo = "`-- " if ultimo else "|-- "
        sufixo = "/" if entrada.is_dir() else ""
        print(prefixo + ramo + entrada.name + sufixo)
        if entrada.is_dir():
            _imprimir_arvore(entrada, prefixo + ("   " if ultimo else "|  "))


def _agora():
    return datetime.now().isoformat(timespec="seconds")
