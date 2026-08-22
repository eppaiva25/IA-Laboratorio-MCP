import json
import time
import urllib.request

def sondar(modelo):
    corpo = {"model": modelo, "messages": [{"role": "user", "content": "Responda apenas: ok"}], "stream": False}
    requisicao = urllib.request.Request(
        "http://localhost:11434/api/chat",
        data=json.dumps(corpo).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    inicio = time.time()
    try:
        with urllib.request.urlopen(requisicao, timeout=900) as resposta:
            dados = json.loads(resposta.read().decode("utf-8"))
        conteudo = dados["message"]["content"]
        print(f"{modelo}: {time.time()-inicio:.1f}s -> {conteudo[:40]!r}")
    except Exception as erro:
        print(f"{modelo}: ERRO {erro} ({time.time()-inicio:.1f}s)")

for modelo in ["gemma4:12b", "4skl/gemma4-e4b-mtp:latest", "gemma4:26b"]:
    sondar(modelo)
