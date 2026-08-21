import json
import sys

from pypdf import PdfReader


def main():
    caminho = sys.argv[1]
    destino_txt = sys.argv[2]

    resultado = {
        "ok": False,
        "paginas": 0,
        "caracteres": 0,
        "observacoes": [],
    }

    try:
        leitor = PdfReader(caminho)

        if leitor.is_encrypted:
            try:
                if leitor.decrypt(""):
                    resultado["observacoes"].append("aberto_com_senha_vazia")
                else:
                    resultado["observacoes"].append("precisa_senha")
                    print(json.dumps(resultado))
                    return
            except Exception:
                resultado["observacoes"].append("precisa_senha")
                print(json.dumps(resultado))
                return

        partes = []
        for pagina in leitor.pages:
            try:
                partes.append(pagina.extract_text() or "")
            except Exception:
                partes.append("")

        texto = "\n".join(partes).replace("\x00", "")
        with open(destino_txt, "w", encoding="utf-8") as saida:
            saida.write(texto)

        resultado["ok"] = True
        resultado["paginas"] = len(leitor.pages)
        resultado["caracteres"] = len(texto.strip())
        if resultado["caracteres"] < 200:
            resultado["observacoes"].append("texto_insuficiente")

    except Exception as erro:
        resultado["observacoes"].append(f"erro:{type(erro).__name__}")

    print(json.dumps(resultado))


main()
