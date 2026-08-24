import inspect
import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))

import catalogo
import modulos
import nucleo
from modulos import avaliar_qualidade, percepcao_para_pedido

verificacoes = []


def checar(nome, ok):
    verificacoes.append((nome, bool(ok)))


TEXTO_BOM_PT = (
    "Ação, coração e mãe são palavras do português. "
    "Este texto de teste contém acentuação legítima: vôo, saída, país, após e também "
    "números como 123 e pontuação normal, para provar que o heurístico não rejeita português válido."
)

MOJIBAKE_ESPARSO = ("瞻 尺 口 家 丁 ¬ ¢ # ï ì û " * 30).strip()
ILEGIVEL_PALAVRA = ("xqz wkv npt jlh frt zpv 12345678 ##!! ??// 2468 " * 8).strip()

temporario = Path(tempfile.mkdtemp(prefix="bv_teste_o3_"))
try:
    checar("1 texto normal e legivel -> confiavel", avaliar_qualidade(TEXTO_BOM_PT) == (True, None))
    checar("2 texto vazio -> sem_texto", avaliar_qualidade("") == (False, "sem_texto")
           and avaliar_qualidade(None) == (False, "sem_texto")
           and avaliar_qualidade("   \n\t ") == (False, "sem_texto"))
    checar("3 texto muito curto -> texto_insuficiente",
           avaliar_qualidade("Relatorio") == (False, "texto_insuficiente"))
    checar("4 mojibake claro (glifos fora do latim) -> sinalizado",
           avaliar_qualidade(MOJIBAKE_ESPARSO) == (False, "mojibake_esparso"))
    checar("5 texto predominantemente ilegivel -> estatistica_atipica",
           avaliar_qualidade(ILEGIVEL_PALAVRA) == (False, "estatistica_atipica"))
    checar("6 portugues legitimo com acentos NAO e sinalizado",
           avaliar_qualidade(TEXTO_BOM_PT)[0] is True and "ç" in TEXTO_BOM_PT and "ã" in TEXTO_BOM_PT)

    pdf_minimo = temporario / "vazio.pdf"
    objetos = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>",
    ]
    brutos = b"%PDF-1.4\n"
    offsets = []
    for numero, corpo in enumerate(objetos, 1):
        offsets.append(len(brutos))
        brutos += f"{numero} 0 obj ".encode() + corpo + b" endobj\n"
    inicio_xref = len(brutos)
    brutos += f"xref\n0 {len(objetos)+1}\n0000000000 65535 f \n".encode()
    for offset in offsets:
        brutos += f"{offset:010d} 00000 n \n".encode()
    brutos += (f"trailer << /Size {len(objetos)+1} /Root 1 0 R >>\n"
               f"startxref\n{inicio_xref}\n%%EOF\n").encode()
    pdf_minimo.write_bytes(brutos)
    percepcao_pdf = modulos.perceber(pdf_minimo)
    checar("7 PDF sem texto extraivel -> sem_texto via perceber",
           percepcao_pdf["conteudo"] is None
           and percepcao_pdf["conteudo_confivel"] is False
           and percepcao_pdf["conteudo_sinalizacao"] == "sem_texto")

    visita = list(Path(r"G:\Documentos_Todos\Biblioteca").rglob("Visita Natal Junho 2014_6.pdf"))
    if visita:
        percepcao_visita = modulos.perceber(visita[0])
        checar("8 caso Visita Natal (arquivo real) detectado como nao confiavel",
               percepcao_visita["conteudo_confivel"] is False
               and percepcao_visita["conteudo_sinalizacao"] == "mojibake_esparso")
        checar("8b Visita Natal: conteudo original preservado na auditoria",
               isinstance(percepcao_visita["conteudo"], str) and len(percepcao_visita["conteudo"]) > 500)
    else:
        checar("8 caso Visita Natal (fixture do log) detectado", False)

    arquivo_txt = temporario / "bom.txt"
    arquivo_txt.write_text(TEXTO_BOM_PT, encoding="utf-8")
    percepcao_txt = modulos.perceber(arquivo_txt)
    chaves_originais = {"arquivo", "extensao", "tamanho_bytes", "hash_sha256",
                        "modificado_em", "conteudo", "leitura_por"}
    chaves_novas = {"conteudo_caracteres", "conteudo_confivel", "conteudo_sinalizacao"}
    checar("9 percepcao mantem todos os campos anteriores", chaves_originais.issubset(percepcao_txt.keys()))
    checar("10 novos campos sao aditivos e tipados",
           chaves_novas.issubset(percepcao_txt.keys())
           and isinstance(percepcao_txt["conteudo_caracteres"], int)
           and isinstance(percepcao_txt["conteudo_confivel"], bool)
           and percepcao_txt["conteudo_caracteres"] == len(percepcao_txt["conteudo"])
           and percepcao_txt["conteudo_confivel"] is True
           and percepcao_txt["conteudo_sinalizacao"] is None)

    percepcao_ruim = dict(percepcao_txt)
    percepcao_ruim.update(conteudo_confivel=False, conteudo_sinalizacao="estatistica_atipica")
    pedido_ruim = percepcao_para_pedido(percepcao_ruim)
    pedido_bom = percepcao_para_pedido(percepcao_txt)
    json.dumps(pedido_ruim, ensure_ascii=False)
    checar("11a proposta da IA recebe aviso e SEM o texto nao confiavel",
           pedido_ruim["conteudo"] is None
           and "estatistica_atipica" in pedido_ruim["aviso_extracao"]
           and "aviso_extracao" not in percepcao_ruim)
    checar("11b percepcao confiavel segue identica ao pedido",
           pedido_bom == percepcao_txt and "aviso_extracao" not in pedido_bom)

    categorias_validas = catalogo.validar(catalogo.carregar(RAIZ / "dados" / "catalogo_exemplo.json"))
    try:
        nucleo._validar_proposta({"categoria": "Nao/Existe", "confianca": 99}, categorias_validas, 60)
        rejeitou = False
    except nucleo.DecisaoInvalida:
        rejeitou = True
    saida = nucleo._validar_proposta(
        {"categoria": "Documentos/Financeiro", "confianca": 95, "motivo": "m"}, categorias_validas, 60)
    ajustada = nucleo._validar_proposta(
        {"categoria": "Fotos/Viagens", "confianca": 40, "motivo": "m"}, categorias_validas, 60)
    checar("12 validacao deterministica intacta",
           rejeitou and saida[0] == "Documentos/Financeiro"
           and ajustada[0] == "Outros" and ajustada[3] != "")

    fonte_nucleo = inspect.getsource(nucleo)
    fonte_mover = inspect.getsource(nucleo._mover_sem_sobrescrever)
    pasta_destino = temporario / "mover"
    pasta_destino.mkdir(parents=True)
    origem_teste = temporario / "doc.txt"
    origem_teste.write_text("conteudo de prova", encoding="utf-8")
    hash_antes = modulos.calcular_hash(origem_teste)
    movido = nucleo._mover_sem_sobrescrever(origem_teste, pasta_destino)
    checar("13 execucao/movimentacao intactos e heuristicas ausentes do nucleo",
           "avaliar_qualidade" not in fonte_nucleo
           and "percepcao_para_pedido" not in fonte_nucleo
           and "shutil.move" in fonte_mover
           and movido.exists() and not origem_teste.exists()
           and modulos.calcular_hash(movido) == hash_antes)

    from modulos import modulo_pptx, modulo_xlsx
    checar("14 mapa DA4: xlsx/pptx registrados; exe continua em metadados",
           modulos.modulo_para(".xlsx") is modulo_xlsx
           and modulos.modulo_para(".pptx") is modulo_pptx
           and modulos.modulo_para(".exe") is modulos.modulo_metadados
           and modulos.modulo_para(".doc") is modulos.modulo_metadados)

    arquivo_xlsx = temporario / "orcamento.xlsx"
    with zipfile.ZipFile(arquivo_xlsx, "w") as pacote:
        pacote.writestr(
            "xl/sharedStrings.xml",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="2" uniqueCount="2">'
            "<si><t>Planilha de orcamento mensal da casa</t></si>"
            "<si><t>Itens previstos: mercado, transporte e lazer.</t></si></sst>",
        )
    percepcao_xlsx = modulos.perceber(arquivo_xlsx)
    checar("15 XLSX com texto recuperavel e lido como conteudo confiavel",
           percepcao_xlsx["leitura_por"] == modulo_xlsx.DESCRICAO
           and "orcamento mensal" in percepcao_xlsx["conteudo"]
           and percepcao_xlsx["conteudo_confivel"] is True
           and percepcao_xlsx["conteudo_sinalizacao"] is None)

    arquivo_pptx = temporario / "apresentacao.pptx"
    with zipfile.ZipFile(arquivo_pptx, "w") as pacote:
        for numero, linhas in enumerate(
            [["Apresentacao do projeto", "Introducao e objetivos principais"],
             ["Resultados parciais", "Proximos passos e cronograma"]], 1):
            paragrafos = "".join(
                f"<a:p><a:r><a:t>{linha}</a:t></a:r></a:p>" for linha in linhas)
            pacote.writestr(
                f"ppt/slides/slide{numero}.xml",
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
                ' xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
                f"<p:cSld><p:spTree>{paragrafos}</p:spTree></p:cSld></p:sld>")
    percepcao_pptx = modulos.perceber(arquivo_pptx)
    checar("16 PPTX le slides na ordem e extrai texto",
           percepcao_pptx["leitura_por"] == modulo_pptx.DESCRICAO
           and percepcao_pptx["conteudo_confivel"] is True
           and percepcao_pptx["conteudo"].index("Apresentacao do projeto")
           < percepcao_pptx["conteudo"].index("Resultados parciais"))

    xlsx_vazio = temporario / "vazio.xlsx"
    xlsx_vazio.write_bytes(b"isto nao e um zip valido")
    pptx_vazio = temporario / "vazio.pptx"
    with zipfile.ZipFile(pptx_vazio, "w") as pacote:
        pacote.writestr("[Content_Types].xml", "<Types/>")
    percepcao_xlsx_vazio = modulos.perceber(xlsx_vazio)
    percepcao_pptx_vazio = modulos.perceber(pptx_vazio)
    checar("17 XLSX/PPTX sem texto recuperavel -> sem_texto sinalizado",
           percepcao_xlsx_vazio["conteudo"] is None
           and percepcao_xlsx_vazio["conteudo_sinalizacao"] == "sem_texto"
           and percepcao_pptx_vazio["conteudo"] is None
           and percepcao_pptx_vazio["conteudo_sinalizacao"] == "sem_texto")

    executavel = temporario / "instalador.exe"
    executavel.write_bytes(b"MZ" + b"\x00" * 256)
    percepcao_exe = modulos.perceber(executavel)
    checar("18 formato nao suportado (.exe) segue somente metadados",
           percepcao_exe["conteudo"] is None
           and percepcao_exe["conteudo_sinalizacao"] == "sem_texto"
           and "metadados" in percepcao_exe["leitura_por"])

    checar("19 contrato de percepcao intacto nos novos formatos",
           set(percepcao_txt.keys()) == set(percepcao_xlsx.keys())
           and set(percepcao_txt.keys()) == set(percepcao_pptx.keys()))
finally:
    shutil.rmtree(temporario, ignore_errors=True)

falhas = [nome for nome, ok in verificacoes if not ok]
for nome, ok in verificacoes:
    print(("OK  " if ok else "FALHA") + " " + nome)
print()
if falhas:
    print(f"RESULTADO: FALHA - {len(falhas)} verificacao(oes) reprovaram")
    sys.exit(1)
print("RESULTADO: OK - qualidade de leitura validada (O3) + leitura multiformato minima (DA4)")
