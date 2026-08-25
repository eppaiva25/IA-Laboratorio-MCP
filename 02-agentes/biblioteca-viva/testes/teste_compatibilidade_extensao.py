import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))

import nucleo

verificacoes = []

categorias_v2 = [
    "Documentos/Pessoal", "Documentos/Financeiro", "Documentos/Viagens",
    "Documentos/Acadêmico", "Documentos/Digitalizados",
    "Fotos/Família", "Fotos/Viagens",
    "Vídeos/Família", "Vídeos/Cursos",
    "Áudio",
    "Tecnologia/Linux", "Tecnologia/Programação", "Tecnologia/Manuais",
    "Outros"
]

# 1. foto.jpg -> Fotos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Fotos/Família", "confianca": 90, "motivo": "foto"}, categorias_v2, 60, ".jpg"
)
verificacoes.append(("1 foto.jpg -> Fotos/Família", cat == "Fotos/Família" and ajuste == ""))

# 2. foto.jpeg -> Fotos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Fotos/Viagens", "confianca": 85, "motivo": "foto"}, categorias_v2, 60, ".jpeg"
)
verificacoes.append(("2 foto.jpeg -> Fotos/Viagens", cat == "Fotos/Viagens" and ajuste == ""))

# 3. video.mp4 -> Vídeos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Vídeos/Família", "confianca": 92, "motivo": "video"}, categorias_v2, 60, ".mp4"
)
verificacoes.append(("3 video.mp4 -> Vídeos/Família", cat == "Vídeos/Família" and ajuste == ""))

# 4. video.wmv -> Vídeos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Vídeos/Cursos", "confianca": 88, "motivo": "video"}, categorias_v2, 60, ".wmv"
)
verificacoes.append(("4 video.wmv -> Vídeos/Cursos", cat == "Vídeos/Cursos" and ajuste == ""))

# 5. audio.mp3 -> Áudio/
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Áudio", "confianca": 80, "motivo": "audio"}, categorias_v2, 60, ".mp3"
)
verificacoes.append(("5 audio.mp3 -> Áudio", cat == "Áudio" and ajuste == ""))

# 6. documento.pdf -> Documentos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Documentos/Pessoal", "confianca": 95, "motivo": "doc"}, categorias_v2, 60, ".pdf"
)
verificacoes.append(("6 documento.pdf -> Documentos/Pessoal", cat == "Documentos/Pessoal" and ajuste == ""))

# 7. planilha.xlsx -> Documentos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Documentos/Financeiro", "confianca": 91, "motivo": "planilha"}, categorias_v2, 60, ".xlsx"
)
verificacoes.append(("7 planilha.xlsx -> Documentos/Financeiro", cat == "Documentos/Financeiro" and ajuste == ""))

# 8. apresentacao.pptx -> Documentos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Documentos/Acadêmico", "confianca": 87, "motivo": "apres"}, categorias_v2, 60, ".pptx"
)
verificacoes.append(("8 apresentacao.pptx -> Documentos/Acadêmico", cat == "Documentos/Acadêmico" and ajuste == ""))

# 9. foto.jpg IA propõe Tecnologia/Programação -> DEVE ser corrigido para Fotos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Tecnologia/Programação", "confianca": 70, "motivo": "errado"}, categorias_v2, 60, ".jpg"
)
verificacoes.append(("9 foto.jpg + IA propos Tecnologia/Programação -> corrigido para Fotos/",
                     cat == "Fotos/Família" and ajuste != "" and "extensao" in ajuste.lower()))

# 10. video.mp4 IA propõe Outros -> DEVE ser corrigido para Vídeos/...
# (confiança >= limiar para não ser sobreposto pela regra de baixa confiança)
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Outros", "confianca": 80, "motivo": "errado"}, categorias_v2, 60, ".mp4"
)
verificacoes.append(("10 video.mp4 + IA propos Outros -> corrigido para Vídeos/",
                     cat == "Vídeos/Família" and ajuste != "" and "extensao" in ajuste.lower()))

# 11. arquivo desconhecido -> mantém proposta da IA
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Tecnologia/Linux", "confianca": 80, "motivo": "arquivo"}, categorias_v2, 60, ".xyz"
)
verificacoes.append(("11 arquivo .xyz -> mantém proposta (sem regra)",
                     cat == "Tecnologia/Linux" and ajuste == ""))

# 12. video.mkv -> Vídeos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Vídeos/Família", "confianca": 89, "motivo": "video"}, categorias_v2, 60, ".mkv"
)
verificacoes.append(("12 video.mkv -> Vídeos/Família", cat == "Vídeos/Família" and ajuste == ""))

# 13. audio.wav -> Áudio/
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Áudio", "confianca": 75, "motivo": "audio"}, categorias_v2, 60, ".wav"
)
verificacoes.append(("13 audio.wav -> Áudio", cat == "Áudio" and ajuste == ""))

# 14. foto.png + IA propõe Vídeos/Família -> corrigido para Fotos/...
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Vídeos/Família", "confianca": 60, "motivo": "errado"}, categorias_v2, 60, ".png"
)
verificacoes.append(("14 foto.png + IA propos Vídeos/Família -> corrigido para Fotos/",
                     cat == "Fotos/Família" and ajuste != "" and "extensao" in ajuste.lower()))

# 15. audio.m4a -> Áudio/
cat, _, _, ajuste = nucleo._validar_proposta(
    {"categoria": "Áudio", "confianca": 82, "motivo": "audio"}, categorias_v2, 60, ".m4a"
)
verificacoes.append(("15 audio.m4a -> Áudio", cat == "Áudio" and ajuste == ""))

falhas = [nome for nome, ok in verificacoes if not ok]
for nome, ok in verificacoes:
    print(("OK  " if ok else "FALHA") + " " + nome)
print()
if falhas:
    print(f"RESULTADO: FALHA - {len(falhas)} verificacao(oes) reprovaram")
    sys.exit(1)
print("RESULTADO: OK - validacao de compatibilidade por extensao funcionando")
