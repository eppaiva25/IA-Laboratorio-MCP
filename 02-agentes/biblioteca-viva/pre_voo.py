import hashlib
from pathlib import Path

import catalogo


class ErroPreVoo(Exception):
    pass


def executar(entrada, biblioteca, caminho_catalogo, modo):
    avisos = []
    if modo not in ("simular", "organizar"):
        raise ErroPreVoo(f"modo desconhecido: {modo!r}")
    pasta_entrada = Path(entrada)
    if not pasta_entrada.is_dir():
        raise ErroPreVoo(f"pasta de entrada nao existe ou nao e pasta: {entrada}")
    dados_catalogo = catalogo.carregar(caminho_catalogo)
    caminhos_categorias = catalogo.validar(dados_catalogo)

    resolved_entrada = pasta_entrada.resolve()
    resolved_biblioteca = Path(biblioteca).resolve()
    if _uma_dentro_da_outra(resolved_entrada, resolved_biblioteca):
        raise ErroPreVoo(
            f"entrada e biblioteca nao podem ocupar a mesma pasta ou estar aninhadas:\n"
            f"  entrada:    {resolved_entrada}\n  biblioteca: {resolved_biblioteca}"
        )

    arquivos = listar_arquivos(resolved_entrada)
    if not arquivos:
        avisos.append("nenhum arquivo encontrado na pasta de entrada")

    if modo == "organizar":
        _provar_escrita(resolved_biblioteca, dados_catalogo["categorias"])
    else:
        avisos.append("modo SIMULAR: nenhum arquivo sera movido e nenhuma pasta sera criada")

    return {
        "catalogo_dados": dados_catalogo,
        "catalogo_sha256": _hash_arquivo(caminho_catalogo),
        "categorias": caminhos_categorias,
        "arquivos": arquivos,
        "avisos": avisos,
    }


def listar_arquivos(pasta_raiz):
    encontrados = []
    for caminho in sorted(pasta_raiz.rglob("*")):
        if not caminho.is_file():
            continue
        if any(parte.startswith(".") for parte in caminho.parts):
            continue
        encontrados.append(caminho)
    return encontrados


def _uma_dentro_da_outra(a, b):
    return a == b or _esta_dentro(a, b) or _esta_dentro(b, a)


def _esta_dentro(possivel_filho, possivel_pai):
    try:
        possivel_filho.relative_to(possivel_pai)
        return True
    except ValueError:
        return False


def _provar_escrita(biblioteca, arvore_categorias):
    try:
        biblioteca.mkdir(parents=True, exist_ok=True)
        if not biblioteca.is_dir():
            raise OSError("caminho existe mas nao e pasta")
        catalogo.materializar_pastas(biblioteca, arvore_categorias)
        prova = biblioteca / ".prova_de_escrita.tmp"
        prova.write_text("ok", encoding="utf-8")
        prova.unlink()
    except OSError as erro:
        raise ErroPreVoo(f"biblioteca nao gravavel em {biblioteca}: {erro}")


def _hash_arquivo(caminho):
    digestor = hashlib.sha256()
    digestor.update(Path(caminho).read_bytes())
    return digestor.hexdigest()
