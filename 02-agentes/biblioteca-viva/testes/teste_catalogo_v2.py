import shutil
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))

import catalogo
import nucleo

verificacoes = []
dados_v1 = catalogo.carregar(RAIZ / "dados" / "catalogo_exemplo.json")
dados_v2 = catalogo.carregar(RAIZ / "dados" / "catalogo_v2.json")

folhas_v1 = catalogo.validar(dados_v1)
folhas_v2 = catalogo.validar(dados_v2)

verificacoes.append(("1 catalogo v2 valido para o leitor V1 (versao_esquema 1)", True))
verificacoes.append(("2 folhas: v2 expande de 9 para 13", len(folhas_v1) == 9 and len(folhas_v2) == 13))
verificacoes.append(("3 v2 mantem todas as 9 folhas originais", set(folhas_v1).issubset(set(folhas_v2))))
verificacoes.append(("4 v2 mantem Outros obrigatoria", "Outros" in folhas_v2))
novas = {"Documentos/Viagens", "Documentos/Acadêmico", "Documentos/Digitalizados", "Tecnologia/Manuais"}
verificacoes.append(("5 as 4 folhas novas estao presentes", novas.issubset(set(folhas_v2))))

categorias_v2 = sorted(folhas_v2)
for esperada in sorted(novas):
    casada = nucleo._casar_com_catalogo(esperada, categorias_v2)
    verificacoes.append((f"6 proposta exata '{esperada}' casa com o catalogo", casada == esperada))

verificacoes.append(("7 proposta curta 'Viagens' resolve para Documentos/Viagens",
                     nucleo._casar_com_catalogo("Viagens", categorias_v2) == "Documentos/Viagens"))
verificacoes.append(("8 variacao de caixa/acento estrutural casa ('documentos/academico' sem acento nao casa)",
                     nucleo._casar_com_catalogo("Documentos/Acadêmico", categorias_v2) == "Documentos/Acadêmico"))

temporario = Path(tempfile.mkdtemp(prefix="bv_teste_catalogo_v2_"))
try:
    try:
        nucleo._validar_proposta({"categoria": "Documentos/../../evita", "confianca": 90, "motivo": "t"},
                                 categorias_v2, 60)
        traversal_bloqueado = False
    except nucleo.DecisaoInvalida:
        traversal_bloqueado = True
    verificacoes.append(("9 proposta com traversal continua rejeitada", traversal_bloqueado))

    pasta_bib = temporario / "bib"
    catalogo.materializar_pastas(pasta_bib, dados_v2["categorias"])
    criadas = all((pasta_bib / parte).is_dir() for parte in
                  ["Documentos/Viagens", "Documentos/Acadêmico",
                   "Documentos/Digitalizados", "Tecnologia/Manuais", "Outros"])
    verificacoes.append(("10 materializacao cria as pastas novas", criadas))

    categoria, confianca, motivo, ajuste = nucleo._validar_proposta(
        {"categoria": "Tecnologia/Manuais", "confianca": 95, "motivo": "manual"},
        categorias_v2, 60)
    verificacoes.append(("11 proposta valida em folha nova aceita sem ajuste",
                         categoria == "Tecnologia/Manuais" and confianca == 95 and ajuste == ""))

    categoria, _, _, ajuste = nucleo._validar_proposta(
        {"categoria": "Documentos/Viagens", "confianca": 40, "motivo": "x"},
        categorias_v2, 60)
    verificacoes.append(("12 baixa confianca em folha nova cai para Outros (limiar intacto)",
                         categoria == "Outros" and ajuste != ""))
finally:
    shutil.rmtree(temporario, ignore_errors=True)

falhas = [nome for nome, ok in verificacoes if not ok]
for nome, ok in verificacoes:
    print(("OK  " if ok else "FALHA") + " " + nome)
print()
if falhas:
    print(f"RESULTADO: FALHA - {len(falhas)} verificacao(oes) reprovaram")
    sys.exit(1)
print("RESULTADO: OK - catalogo v2 validado (O1)")
