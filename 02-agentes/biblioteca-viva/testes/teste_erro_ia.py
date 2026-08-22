import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import modelos_ia
import nucleo
import pre_voo


class IASeletiva:
    def __init__(self, nomes_com_falha):
        self.nomes_com_falha = set(nomes_com_falha)

    def propor(self, modelo, percepcao, categorias):
        if percepcao["arquivo"] in self.nomes_com_falha:
            raise modelos_ia.ErroIA("simulacao: falha proposital da IA nesta proposta")
        return {"categoria": "Outros", "confianca": 70, "motivo": "proposta valida de teste"}


def main():
    temporario = Path(tempfile.mkdtemp(prefix="bv_teste_erro_ia_"))
    entrada = temporario / "entrada"
    biblioteca = temporario / "Biblioteca"
    entrada.mkdir()

    conteudos = {}
    for nome in ("mantem-a.txt", "quebra-b.txt", "mantem-c.txt"):
        (entrada / nome).write_text(f"conteudo de {nome}", encoding="utf-8")
        conteudos[nome] = hashlib.sha256((entrada / nome).read_bytes()).hexdigest()

    resultado_pre_voo = pre_voo.executar(
        entrada, biblioteca,
        Path(__file__).resolve().parents[1] / "dados" / "catalogo_exemplo.json",
        "organizar",
    )
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

    stub_original = nucleo.modelos_ia.propor
    nucleo.modelos_ia.propor = IASeletiva({"quebra-b.txt"}).propor
    try:
        resultados = agente.rodar(resultado_pre_voo["arquivos"])
    finally:
        nucleo.modelos_ia.propor = stub_original

    por_status = {}
    for r in resultados:
        por_status.setdefault(r["status"], []).append(Path(r["origem"]).name)

    quebra_intacta = (entrada / "quebra-b.txt").exists() and hashlib.sha256(
        (entrada / "quebra-b.txt").read_bytes()
    ).hexdigest() == conteudos["quebra-b.txt"]

    linhas = [json.loads(l) for l in (temporario / "eventos.jsonl").read_text(encoding="utf-8").splitlines()]
    evento_quebra = next(l for l in linhas if l.get("origem", "").endswith("quebra-b.txt") and l.get("evento") == "arquivo_processado")
    percepcao_registrada = isinstance(evento_quebla_percepcao := evento_quebra["ciclo"]["perceber"], dict) and "hash_sha256" in evento_quebla_percepcao
    processou_todos = len(resultados) == 3

    print(f"statuses finais:              {por_status}")
    print(f"total processado sem parar:   {processou_todos} (esperado 3)")
    print(f"quebra-b.txt intacto na origem: {quebra_intacta}")
    print(f"percepcao no evento de erro:  {percepcao_registrada}")

    movidos_ok = sorted(por_status.get("movido", [])) == ["mantem-a.txt", "mantem-c.txt"]
    erro_ok = por_status.get("nao_decidido_erro_ia", []) == ["quebra-b.txt"]
    ok = movidos_ok and erro_ok and quebra_intacta and percepcao_registrada and processou_todos
    print("RESULTADO:", "OK - erro isolado, demais arquivos movidos, ciclo registrado" if ok else "FALHA")
    shutil.rmtree(temporario)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
