import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))

import nucleo
import pre_voo

CATALOGO = RAIZ / "dados" / "catalogo_exemplo.json"
VERIFICADOR = RAIZ / "testes" / "verificar_resultado.py"


def propor_stub(modelo, percepcao, categorias):
    return {"categoria": "Outros", "confianca": 70, "motivo": "proposta fixa de teste"}


def main():
    verificacoes = []
    temporario = Path(tempfile.mkdtemp(prefix="bv_teste_eventos_v2_"))
    entrada = temporario / "entrada"
    biblioteca = temporario / "Biblioteca"
    entrada.mkdir()

    nomes = ["alpha.txt", "beta.txt"]
    for nome in nomes:
        (entrada / nome).write_text(f"conteudo {nome}", encoding="utf-8")

    resultado_pre_voo = pre_voo.executar(entrada, biblioteca, CATALOGO, "organizar")
    hash_catalogo_real = hashlib.sha256(CATALOGO.read_bytes()).hexdigest()
    verificacoes.append(("pre_voo expoe catalogo_sha256 correto",
                         resultado_pre_voo.get("catalogo_sha256") == hash_catalogo_real))

    stub_original = nucleo.modelos_ia.propor
    nucleo.modelos_ia.propor = propor_stub
    try:
        agente = nucleo.Agente(
            entrada=entrada,
            biblioteca=biblioteca,
            resultado_pre_voo=resultado_pre_voo,
            modelo="modelo-de-teste",
            modo="organizar",
            limiar=60,
            arquivo_eventos=temporario / "eventos.jsonl",
            mostrar=lambda m: None,
        )
        agente.rodar(resultado_pre_voo["arquivos"])
    finally:
        nucleo.modelos_ia.propor = stub_original

    linhas = [json.loads(l) for l in (temporario / "eventos.jsonl").read_text(encoding="utf-8").splitlines() if l.strip()]
    iniciada = [l for l in linhas if l.get("evento") == "execucao_iniciada"]
    processados = [l for l in linhas if l.get("evento") == "arquivo_processado"]
    concluida = [l for l in linhas if l.get("evento") == "execucao_concluida"]

    verificacoes.append(("execucao_iniciada v2 com catalogo_sha256",
                         len(iniciada) == 1
                         and iniciada[0].get("versao_esquema") == 2
                         and iniciada[0].get("catalogo_sha256") == hash_catalogo_real))
    verificacoes.append(("todos os arquivo_processado sao v2 com catalogo_sha256",
                         len(processados) == 2
                         and all(l.get("versao_esquema") == 2 for l in processados)
                         and all(l.get("catalogo_sha256") == hash_catalogo_real for l in processados)))
    verificacoes.append(("execucao_concluida v2", concluida and concluida[0].get("versao_esquema") == 2))
    verificacoes.append(("estrutura do ciclo preservada da v1",
                         all(set(l["ciclo"].keys()) == {"perceber", "decidir", "agir", "verificar"} for l in processados)))
    verificacoes.append(("campos v1 preservados (origem/hash/status/proposta)",
                         all(
                             l.get("origem") and l.get("hash_sha256")
                             and l["status"] == "movido"
                             and l["ciclo"]["decidir"]["proposta_da_ia"]["categoria"] == "Outros"
                             for l in processados)))

    processo_verificador = subprocess.run(
        [sys.executable, "-u", str(VERIFICADOR), str(temporario / "eventos.jsonl")],
        capture_output=True, text=True,
    )
    verificacoes.append((f"verificador existente aprova log v2 (rc={processo_verificador.returncode})",
                         processo_verificador.returncode == 0))

    log_v1 = temporario / "log_v1_sintetico.jsonl"
    (entrada / "antigo.txt").write_text("arquivo retido por erro da ia", encoding="utf-8")
    evento_v1 = {
        "versao_esquema": 1,
        "evento": "arquivo_processado",
        "tentativa": 1,
        "modo": "organizar",
        "modelo": "x",
        "origem": str(entrada / "antigo.txt"),
        "hash_sha256": "a" * 64,
        "ciclo": {
            "perceber": {"arquivo": "antigo.txt"},
            "decidir": {"categoria_executada": "Outros", "confianca": 70},
            "agir": {"acao": "mover", "destino_previsto": str(biblioteca / "Outros" / "antigo.txt"), "destino_real": None},
            "verificar": {"resultado": "nao_aplicavel"},
        },
        "status": "nao_decidido_erro_ia",
    }
    log_v1.write_text(json.dumps(evento_v1) + "\n", encoding="utf-8")
    processo_v1 = subprocess.run(
        [sys.executable, "-u", str(VERIFICADOR), str(log_v1)],
        capture_output=True, text=True,
    )
    saida_v1 = processo_v1.stdout + processo_v1.stderr
    verificacoes.append(("verificador continua aceitando log v1 (sem reclamar de versao)",
                         processo_v1.returncode == 0 and "versao_esquema invalida" not in saida_v1))

    falhas = [nome for nome, ok in verificacoes if not ok]
    for nome, ok in verificacoes:
        print(f"{'OK ' if ok else 'FALHA'} {nome}")
    print("\n" + ("RESULTADO: OK - eventos v2 aditivos, leitura v1 preservada" if not falhas else "RESULTADO: FALHA: " + ", ".join(falhas)))
    if processo_verificador.stdout:
        print("--- saida verificador sobre log v2 ---")
        print(processo_verificador.stdout.strip())

    shutil.rmtree(temporario, ignore_errors=True)
    sys.exit(0 if not falhas else 1)


if __name__ == "__main__":
    main()
