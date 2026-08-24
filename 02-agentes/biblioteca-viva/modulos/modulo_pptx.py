import re
import zipfile

DESCRICAO = "modulo PPTX (apresentacao/OpenXML)"

LIMITE_SLIDES = 30


def extrair_texto(caminho, limite):
    try:
        with zipfile.ZipFile(caminho) as pacote:
            slides = sorted(
                (nome for nome in pacote.namelist() if re.fullmatch(r"ppt/slides/slide\d+\.xml", nome)),
                key=lambda nome: int(re.search(r"slide(\d+)\.xml", nome).group(1)),
            )[:LIMITE_SLIDES]
            partes = []
            for nome in slides:
                xml = pacote.read(nome).decode("utf-8", errors="replace").replace("</a:p>", "\n")
                partes.append(re.sub(r"<[^>]+>", "", xml))
    except (zipfile.BadZipFile, KeyError):
        return None
    texto = "\n".join(partes).strip()[: limite * 2]
    return texto or None
