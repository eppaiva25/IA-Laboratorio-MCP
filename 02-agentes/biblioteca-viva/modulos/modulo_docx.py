import re
import zipfile
from pathlib import Path

DESCRICAO = "modulo DOCX (Word/OpenXML)"


def extrair_texto(caminho, limite):
    try:
        with zipfile.ZipFile(caminho) as pacote:
            xml = pacote.read("word/document.xml").decode("utf-8", errors="replace")
    except (zipfile.BadZipFile, KeyError):
        return None
    xml = xml.replace("</w:p>", "\n")
    texto = re.sub(r"<[^>]+>", "", xml)
    return texto.strip()[: limite * 2] or None
