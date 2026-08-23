import hashlib
import unicodedata
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
MINIMO_CARACTERES_UTEIS = 50
LIMITE_TOKENS_CURTOS = 90.0
LIMITE_VOGAIS_ESPARSO = 42.0
LIMITE_VOGAIS_ATIPICO = 34.0
LIMITE_TOKENS_SEM_VOGAL = 20.0
LIMITE_LETRAS_ATIPICO = 50.0
VOGAIS = set("aeiouáéíóúâêôãõàüAEIOUÁÉÍÓÚÂÊÔÃÕÀÜ")


def modulo_para(extensao):
    return MODULOS_LEITURA.get(extensao.lower(), modulo_metadados)


def avaliar_qualidade(texto):
    if not texto or not texto.strip():
        return False, "sem_texto"
    n = len(texto)
    if n < MINIMO_CARACTERES_UTEIS:
        return False, "texto_insuficiente"
    tokens = [t for t in texto.split() if t]
    if not tokens:
        return False, "sem_texto"
    caracteres = [c for c in texto if not c.isspace()]
    letras = sum(1 for c in caracteres if unicodedata.category(c).startswith("L"))
    vogais = sum(1 for c in caracteres if c in VOGAIS)
    sem_vogal = sum(1 for t in tokens if not any(c in VOGAIS for c in t))
    curtos = sum(1 for t in tokens if len(t) <= 2)
    percentual_vogais = 100 * vogais / letras if letras else 0
    percentual_sem_vogal = 100 * sem_vogal / len(tokens)
    percentual_curtos = 100 * curtos / len(tokens)
    percentual_letras = 100 * letras / len(caracteres)
    esparso = (percentual_curtos >= LIMITE_TOKENS_CURTOS
               and percentual_vogais < LIMITE_VOGAIS_ESPARSO)
    atipico = (percentual_vogais < LIMITE_VOGAIS_ATIPICO
               and percentual_sem_vogal >= LIMITE_TOKENS_SEM_VOGAL
               and percentual_letras <= LIMITE_LETRAS_ATIPICO)
    if esparso:
        return False, "mojibake_esparso"
    if atipico:
        return False, "estatistica_atipica"
    return True, None


def percepcao_para_pedido(percepcao):
    if percepcao.get("conteudo_confivel", True):
        return dict(percepcao)
    pedido = dict(percepcao)
    pedido["conteudo"] = None
    pedido["aviso_extracao"] = (
        f"texto extraido nao confiavel ({percepcao.get('conteudo_sinalizacao')});"
        " avalie pelo nome do arquivo e metadados"
    )
    return pedido


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
    confivel, sinalizacao = avaliar_qualidade(conteudo)
    return {
        "arquivo": alvo.name,
        "extensao": extensao,
        "tamanho_bytes": estatisticas.st_size,
        "hash_sha256": calcular_hash(alvo),
        "modificado_em": datetime.fromtimestamp(estatisticas.st_mtime).isoformat(timespec="seconds"),
        "conteudo": conteudo,
        "leitura_por": leitura,
        "conteudo_caracteres": len(conteudo) if conteudo else 0,
        "conteudo_confivel": confivel,
        "conteudo_sinalizacao": sinalizacao,
    }
