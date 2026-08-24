import re
import zipfile

DESCRICAO = "modulo XLSX (planilha/OpenXML)"


def extrair_texto(caminho, limite):
    try:
        with zipfile.ZipFile(caminho) as pacote:
            xml = pacote.read("xl/sharedStrings.xml").decode("utf-8", errors="replace")
    except (zipfile.BadZipFile, KeyError):
        return None
    partes = re.findall(r"<t[^>]*>(.*?)</t>", xml, re.DOTALL)
    texto = " ".join(partes).strip()[: limite * 2]
    return texto or None
