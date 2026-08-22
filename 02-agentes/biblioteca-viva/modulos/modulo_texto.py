from pathlib import Path

DESCRICAO = "modulo texto simples"


def extrair_texto(caminho, limite):
    return Path(caminho).read_text(encoding="utf-8", errors="replace")[: limite * 2]
