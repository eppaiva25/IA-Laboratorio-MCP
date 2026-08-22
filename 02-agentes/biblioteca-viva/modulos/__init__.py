import hashlib
from datetime import datetime
from pathlib import Path

from . import modulo_docx, modulo_metadados, modulo_pdf, modulo_texto

MODULOS_LEITURA = {
    ".pdf": modulo_pdf,
    ".docx": modulo_docx,
    ".txt": modulo_texto,
    ".md": modulo_texto,
    ".csv": modulo_texto,
    ".log": modulo_texto,
}

LIMITE_CONTEUDO = 2000


def modulo_para(extensao):
    return MODULOS_LEITURA.get(extensao.lower(), modulo_metadados)


def calcular_hash(caminho):
    digestor = hashlib.sha256()
    with open(caminho, "rb") as arquivo:
        for bloco in iter(lambda: arquivo.read(1 << 20), b""):
            digestor.update(bloco)
    return digestor.hexdigest()


def perceber(caminho):
    alvo = Path(caminho)
    estatisticas = alvo.stat()
    extensao = alvo.suffix.lower()
    modulo = modulo_para(extensao)
    conteudo = None
    try:
        bruto = modulo.extrair_texto(alvo, LIMITE_CONTEUDO)
        if bruto and bruto.strip():
            conteudo = " ".join(bruto.split())[:LIMITE_CONTEUDO]
            leitura = modulo.DESCRICAO
        else:
            leitura = f"{modulo.DESCRICAO} (nenhum texto recuperavel)"
    except Exception as erro:
        leitura = f"falha na leitura ({erro.__class__.__name__})"
    return {
        "arquivo": alvo.name,
        "extensao": extensao,
        "tamanho_bytes": estatisticas.st_size,
        "hash_sha256": calcular_hash(alvo),
        "modificado_em": datetime.fromtimestamp(estatisticas.st_mtime).isoformat(timespec="seconds"),
        "conteudo": conteudo,
        "leitura_por": leitura,
    }
