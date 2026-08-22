import json
from pathlib import Path


class CatalogoInvalido(Exception):
    pass


def carregar(caminho_json):
    try:
        return json.loads(Path(caminho_json).read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise CatalogoInvalido(f"catalogo nao encontrado: {caminho_json}")
    except json.JSONDecodeError as erro:
        raise CatalogoInvalido(f"catalogo com JSON invalido: {erro}")


def validar(dados):
    if not isinstance(dados, dict):
        raise CatalogoInvalido("catalogo deve ser um objeto JSON")
    if int(dados.get("versao_esquema") or 0) != 1:
        raise CatalogoInvalido('catalogo precisa de "versao_esquema": 1')
    categorias = dados.get("categorias")
    if not isinstance(categorias, dict) or not categorias:
        raise CatalogoInvalido('catalogo precisa do objeto "categorias"')
    caminhos = caminhos_de_folha(categorias)
    if len(caminhos) == 0:
        raise CatalogoInvalido("catalogo sem nenhuma categoria folha")
    if "Outros" not in caminhos:
        raise CatalogoInvalido('catalogo precisa conter a categoria "Outros"')
    return caminhos


def caminhos_de_folha(arvore, prefixo=""):
    caminhos = []
    for nome, filhos in arvore.items():
        caminho = f"{prefixo}/{nome}" if prefixo else nome
        if isinstance(filhos, dict) and filhos:
            caminhos.extend(caminhos_de_folha(filhos, caminho))
        else:
            caminhos.append(caminho)
    return caminhos


def materializar_pastas(raiz, arvore):
    for nome, filhos in arvore.items():
        atual = Path(raiz) / nome
        atual.mkdir(parents=True, exist_ok=True)
        if isinstance(filhos, dict) and filhos:
            materializar_pastas(atual, filhos)
