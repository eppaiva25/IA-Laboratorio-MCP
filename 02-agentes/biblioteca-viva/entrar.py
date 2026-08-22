import argparse
import sys
import time
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent))

import catalogo
import modelos_ia
import nucleo
import pre_voo

RAIZ_APLICACAO = Path(__file__).resolve().parent
CATALOGO_PADRAO = RAIZ_APLICACAO / "dados" / "catalogo_exemplo.json"
PASTA_EVENTOS = RAIZ_APLICACAO / "eventos"


def main():
    parser = argparse.ArgumentParser(
        prog="entrar.py",
        description="Biblioteca Viva - agente organizador de arquivos (IA propoe, sistema deterministico executa)",
    )
    parser.add_argument("--entrada", help="pasta com os arquivos desorganizados")
    parser.add_argument("--biblioteca", help="pasta raiz da biblioteca organizada")
    parser.add_argument("--catalogo", help="caminho do catalogo JSON (padrao: dados/catalogo_exemplo.json)")
    parser.add_argument("--modo", choices=["simular", "organizar"], help="padrao seguro: simular")
    parser.add_argument("--modelo", help="modelo Ollama que PROPÕE (padrao: deteccao automatica)")
    parser.add_argument("--limiar", type=int, default=60, help="confianca minima (%%) para aceitar proposta fora de Outros")
    argumentos = parser.parse_args()

    print("=" * 62)
    print("BIBLIOTECA VIVA - ORGANIZADOR")
    print("ciclo por arquivo: PERCEBER > DECIDIR > AGIR > VERIFICAR > REGISTRAR")
    print("IA propoe categoria | codigo deterministico valida e executa")
    print("=" * 62)

    entrada = Path(argumentos.entrada or _perguntar("Pasta de entrada", "./exemplos/entrada_teste"))
    biblioteca = Path(argumentos.biblioteca or _perguntar("Pasta da biblioteca", "./Biblioteca"))
    modo = argumentos.modo or _perguntar_modo()
    caminho_catalogo = Path(argumentos.catalogo or CATALOGO_PADRAO)

    try:
        modelo = modelos_ia.selecionar_modelo(argumentos.modelo)
    except modelos_ia.ErroIA as erro:
        _falhar(f"PRE-VOO (modelo): {erro}", 3)
    print(f"\nModelo que PROPÕE (via Ollama): {modelo}")

    try:
        resultado_pre_voo = pre_voo.executar(entrada, biblioteca, caminho_catalogo, modo)
    except pre_voo.ErroPreVoo as erro:
        _falhar(f"PRE-VOO REPROVADO: {erro}", 2)
    except catalogo.CatalogoInvalido as erro:
        _falhar(f"PRE-VOO REPROVADO (catalogo): {erro}", 2)

    print(f"Catalogo (fonte de verdade): {caminho_catalogo}")
    print(f"Categorias validas ({len(resultado_pre_voo['categorias'])}): {'; '.join(resultado_pre_voo['categorias'])}")
    for aviso in resultado_pre_voo["avisos"]:
        print(f"AVISO PRE-VOO: {aviso}")

    arquivo_eventos = PASTA_EVENTOS / f"eventos_{time.strftime('%Y%m%d_%H%M%S')}.jsonl"
    agente = nucleo.Agente(
        entrada=entrada,
        biblioteca=biblioteca,
        resultado_pre_voo=resultado_pre_voo,
        modelo=modelo,
        modo=modo,
        limiar=argumentos.limiar,
        arquivo_eventos=arquivo_eventos,
    )
    agente.rodar(resultado_pre_voo["arquivos"])


def _perguntar(rotulo, padrao):
    try:
        resposta = input(f"{rotulo} [{padrao}]: ").strip()
    except EOFError:
        resposta = ""
    return resposta or padrao


def _perguntar_modo():
    try:
        resposta = input("Modo - [1] Simular/dry-run (padrao)  [2] Organizar de verdade : ").strip()
    except EOFError:
        resposta = ""
    return {"1": "simular", "2": "organizar", "": "simular"}.get(resposta, "simular")


def _falhar(mensagem, codigo):
    print(f"ERRO: {mensagem}", file=sys.stderr)
    sys.exit(codigo)


if __name__ == "__main__":
    main()
