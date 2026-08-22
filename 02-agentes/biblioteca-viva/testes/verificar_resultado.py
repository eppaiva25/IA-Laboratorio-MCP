import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from modulos import calcular_hash

caminho_eventos = Path(sys.argv[1])
linhas = [json.loads(linha) for linha in caminho_eventos.read_text(encoding="utf-8").splitlines() if linha.strip()]
processados = [l for l in linhas if l.get("evento") == "arquivo_processado"]

falhas = 0
for evento in processados:
    nome = Path(evento["origem"]).name
    ciclo = evento["ciclo"]
    problemas = []
    if evento.get("versao_esquema") != 1:
        problemas.append("versao_esquema != 1")
    if set(ciclo.keys()) != {"perceber", "decidir", "agir", "verificar"}:
        problemas.append(f"ciclo incompleto: {sorted(ciclo.keys())}")
    destino = ciclo["agir"].get("destino_real")
    if destino:
        if Path(evento["origem"]).exists():
            problemas.append("origem ainda existe!")
        alvo = Path(destino)
        if not alvo.exists():
            problemas.append("destino nao existe!")
        elif "hash_sha256" in evento and calcular_hash(alvo) != evento["hash_sha256"]:
            problemas.append("HASH DIFERENTE no destino!")
    else:
        if evento["status"] == "nao_decidido_erro_ia" and Path(evento["origem"]).exists():
            pass
        else:
            problemas.append("sem destino mas status inesperado")
    marca = "OK " if not problemas else "FALHA"
    if problemas:
        falhas += 1
    print(f"{marca} {nome:28s} -> {evento['status']:22s} {'; '.join(problemas)}")

iniciadas = [l for l in linhas if l.get("evento") == "execucao_iniciada"]
concluidas = [l for l in linhas if l.get("evento") == "execucao_concluida"]
print(f"\nlinhas totais={len(linhas)} arquivos={len(processados)} iniciada={len(iniciadas)} concluida={len(concluidas)} falhas_auditoria={falhas}")
sys.exit(1 if falhas else 0)
