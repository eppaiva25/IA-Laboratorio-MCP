import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import modelos_ia
from modulos import perceber

categorias = [
    "Documentos/Pessoal", "Documentos/Financeiro", "Fotos/Família", "Fotos/Viagens",
    "Vídeos/Família", "Vídeos/Cursos", "Tecnologia/Linux", "Tecnologia/Programação", "Outros",
]
modelo = modelos_ia.selecionar_modelo()
print(f"modelo ativo: {modelo}")
alvo = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("exemplos/entrada_teste/IMG_20260801_0042.cr2")
inicio = time.time()
percepcao = perceber(alvo)
proposta = modelos_ia.propor(modelo, percepcao, categorias)
print(f"latencia: {time.time() - inicio:.1f}s")
print(f"proposta: {proposta}")
