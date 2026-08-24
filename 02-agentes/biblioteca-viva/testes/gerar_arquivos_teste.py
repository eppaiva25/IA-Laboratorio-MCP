import sys
import zipfile
from pathlib import Path

RAIZ_APLICACAO = Path(__file__).resolve().parents[1]
PASTA_PADRAO = RAIZ_APLICACAO / "exemplos" / "entrada_teste"


def gerar_tudo(pasta):
    pasta.mkdir(parents=True, exist_ok=True)
    for antigo in pasta.iterdir():
        if antigo.is_file():
            antigo.unlink()

    gerar_pdf(
        pasta / "linux-curso.pdf",
        "Curso intensivo de Linux. Comandos basicos do terminal, shell bash, permissoes de arquivos e gerenciamento de pacotes apt.",
    )
    gerar_pdf(
        pasta / "contrato-aluguel.pdf",
        "CONTRATO DE LOCACAO RESIDENCIAL. As partes contratam a locacao do imovel pelo valor mensal de aluguel de dois mil reais, com fiador e prazo de trinta meses.",
    )
    gerar_pdf(
        pasta / "doc.pdf",
        "Receita de pao caseiro: misture farinha de trigo, fermento biologico, agua morna e sal. Deixe a massa descansar por duas horas antes de assar.",
    )
    gerar_docx(
        pasta / "receita-bolo.docx",
        [
            "Receita de bolo de chocolate",
            "Ingredientes: 2 xicaras de farinha de trigo, 1 xicara de acucar, cacau em po, ovos, leite e fermento.",
            "Modo de preparo: misture os ingredientes liquidos, acrescente os secos peneirados e asse em forno medio por 40 minutos.",
        ],
    )
    gerar_xlsx(
        pasta / "orcamento-casa.xlsx",
        ["Planilha de orcamento mensal da casa", "Itens previstos: mercado, transporte e lazer."],
    )
    gerar_pptx(
        pasta / "apresentacao-projeto.pptx",
        [
            ["Apresentacao do projeto", "Introducao e objetivos principais"],
            ["Resultados parciais", "Proximos passos e cronograma"],
        ],
    )
    gerar_binario(pasta / "fotos-ferias.jpg", b"\xff\xd8\xff\xe0" + b"JFIF\x00" + b"\x00" * 2048)
    gerar_binario(pasta / "filme-familia.mp4", b"\x00\x00\x00\x18ftypmp42" + b"\x00" * 4096)
    gerar_binario(pasta / "aula-python.mp4", b"\x00\x00\x00\x18ftypmp42" + b"\x00" * 4096)
    gerar_texto(
        pasta / "anotacoes-jardim.txt",
        "Anotacoes de jardinagem\n\nPlantar tomates em setembro.\nAdubar as hortelas a cada 15 dias.\nPodar a roseira no fim do inverno.\n",
    )
    gerar_binario(pasta / "IMG_20260801_0042.cr2", b"\x49\x49\x2a\x00" + b"\x00" * 1536)

    print(f"Arquivos de teste criados em {pasta}:")
    for arquivo in sorted(pasta.iterdir()):
        print(f"  {arquivo.name} ({arquivo.stat().st_size} bytes)")


def gerar_texto(caminho, conteudo):
    caminho.write_text(conteudo, encoding="utf-8")


def gerar_binario(caminho, bytes_iniciais):
    caminho.write_bytes(bytes_iniciais)


def gerar_docx(caminho, paragrafos):
    xml_paragrafos = "".join(
        f"<w:p><w:r><w:t>{p}</w:t></w:r></w:p>" for p in paragrafos
    )
    documento = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        f"<w:body>{xml_paragrafos}</w:body></w:document>"
    )
    tipos = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        "</Types>"
    )
    relacoes = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        "</Relationships>"
    )
    with zipfile.ZipFile(caminho, "w") as pacote:
        pacote.writestr("[Content_Types].xml", tipos)
        pacote.writestr("_rels/.rels", relacoes)
        pacote.writestr("word/document.xml", documento)


def gerar_xlsx(caminho, textos):
    itens = "".join(f"<si><t>{t}</t></si>" for t in textos)
    compartilhadas = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        f' count="{len(textos)}" uniqueCount="{len(textos)}">{itens}</sst>'
    )
    pasta_trabalho = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        "<sheets><sheet name=\"Plan1\" sheetId=\"1\" r:id=\"rId1\""
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/></sheets></workbook>'
    )
    with zipfile.ZipFile(caminho, "w") as pacote:
        pacote.writestr("xl/sharedStrings.xml", compartilhadas)
        pacote.writestr("xl/workbook.xml", pasta_trabalho)


def gerar_pptx(caminho, slides):
    tipos = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>'
        "</Types>"
    )
    with zipfile.ZipFile(caminho, "w") as pacote:
        pacote.writestr("[Content_Types].xml", tipos)
        for numero, linhas in enumerate(slides, 1):
            paragrafos = "".join(
                f"<a:p><a:r><a:t>{linha}</a:t></a:r></a:p>" for linha in linhas
            )
            slide = (
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
                ' xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
                f"<p:cSld><p:spTree>{paragrafos}</p:spTree></p:cSld></p:sld>"
            )
            pacote.writestr(f"ppt/slides/slide{numero}.xml", slide)


def gerar_pdf(caminho, texto):
    stream = ("BT /F1 14 Tf 72 700 Td (" + texto.replace("\\", r"\\").replace("(", r"\(").replace(")", r"\)") + ") Tj ET").encode("latin-1", "replace")
    objetos = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    saida = bytearray(b"%PDF-1.4\n")
    offsets = []
    for numero, corpo in enumerate(objetos, 1):
        offsets.append(len(saida))
        saida += f"{numero} 0 obj\n".encode() + corpo + b"\nendobj\n"
    inicio_xref = len(saida)
    saida += f"xref\n0 {len(objetos) + 1}\n".encode()
    saida += b"0000000000 65535 f \n"
    for deslocamento in offsets:
        saida += f"{deslocamento:010d} 00000 n \n".encode()
    saida += (
        f"trailer\n<< /Size {len(objetos) + 1} /Root 1 0 R >>\nstartxref\n{inicio_xref}\n%%EOF\n".encode()
    )
    caminho.write_bytes(bytes(saida))


if __name__ == "__main__":
    destino = Path(sys.argv[1]) if len(sys.argv) > 1 else PASTA_PADRAO
    gerar_tudo(destino)
