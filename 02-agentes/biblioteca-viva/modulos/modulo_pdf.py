import re
import zlib
from pathlib import Path

DESCRICAO = "modulo PDF (primeiro modulo de leitura)"

TAMANHO_MAXIMO_VARREDURA = 20_000_000


def extrair_texto(caminho, limite):
    texto = _com_pypdf(caminho, limite)
    if texto and texto.strip():
        return texto
    return _extracao_nativa(caminho, limite)


def _com_pypdf(caminho, limite):
    try:
        from pypdf import PdfReader
    except ImportError:
        return None
    try:
        leitor = PdfReader(str(caminho))
        partes = []
        total = 0
        for pagina in leitor.pages[:10]:
            trecho = pagina.extract_text() or ""
            partes.append(trecho)
            total += len(trecho)
            if total > limite * 2:
                break
        return "\n".join(partes)
    except Exception:
        return None


def _extracao_nativa(caminho, limite):
    try:
        dados = Path(caminho).read_bytes()
        if len(dados) > TAMANHO_MAXIMO_VARREDURA:
            dados = dados[:TAMANHO_MAXIMO_VARREDURA]
        trechos = []
        for bruto in re.findall(rb"stream\r?\n(.*?)endstream", dados, re.DOTALL)[:60]:
            try:
                bruto = zlib.decompress(bruto)
            except Exception:
                pass
            trechos.append(bruto)
            if sum(len(t) for t in trechos) > 500_000:
                break
        texto_operadores = b"\n".join(trechos).decode("latin-1", "replace")
        partes = []
        for bloco in re.findall(r"BT(.*?)ET", texto_operadores, re.DOTALL):
            for achado in re.findall(r"\(((?:\\.|[^\\()])*)\)", bloco):
                partes.append(achado)
        texto = " ".join(partes)
        texto = texto.replace("\\(", "(").replace("\\)", ")").replace("\\\\", "\\")
        return texto.strip()[: limite * 2] or None
    except Exception:
        return None
