import json
import os
import re
import urllib.error
import urllib.request

from modulos import percepcao_para_pedido

URL_OLLAMA = os.getenv("OLLAMA_URL", "http://localhost:11434").rstrip("/")
MODELO_ENV = os.getenv("BIBLIOTECA_MODELO") or os.getenv("OLLAMA_MODEL")
LIMITE_TOKENS_RESPOSTA = 400
TIMEOUT_SEGUNDOS = 600

PROMPT_SISTEMA = (
    "Voce e o modulo de decisao de um agente organizador de arquivos."
    " Para cada arquivo voce recebe as percepcoes coletadas e a lista de categorias validas do catalogo oficial."
    " Sua unica funcao e PROPOR: escolha a UNICA categoria mais adequada dentre as da lista."
    " Responda SOMENTE com um objeto JSON valido neste formato exato:"
    ' {"categoria": "<caminho exato copiado da lista>", "confianca": <inteiro de 0 a 100>, "motivo": "<frase curta>"}'
    " Nunca invente uma categoria fora da lista."
    ' Se nenhuma categoria servir bem, proponha "Outros" com confianca baixa.'
)


class ErroIA(Exception):
    pass


def selecionar_modelo(nome_pedido=None):
    disponiveis = modelos_disponiveis()
    escolhido = nome_pedido or MODELO_ENV
    if escolhido:
        if escolhido not in disponiveis:
            raise ErroIA(
                f"modelo '{escolhido}' nao esta disponivel no Ollama. Disponiveis: {disponiveis}"
            )
        return escolhido
    if disponiveis:
        return disponiveis[0]
    raise ErroIA("Ollama esta acessivel mas nenhum modelo esta instalado")


def modelos_disponiveis():
    try:
        with urllib.request.urlopen(URL_OLLAMA + "/api/tags", timeout=5) as resposta:
            dados = json.loads(resposta.read().decode("utf-8"))
    except Exception as erro:
        raise ErroIA(f"Ollama inacessivel em {URL_OLLAMA}: {erro}")
    return [m["name"] for m in dados.get("models", [])]


def propor(modelo, percepcao, categorias_validas):
    pedido = json.dumps(
        {"percepcao": percepcao_para_pedido(percepcao), "categorias_validas": categorias_validas},
        ensure_ascii=False,
    )
    mensagens = [
        {"role": "system", "content": PROMPT_SISTEMA},
        {"role": "user", "content": pedido},
    ]
    try:
        dados = _conversar(modelo, mensagens)
    except urllib.error.HTTPError as erro:
        if erro.code == 400:
            dados = _conversar(modelo, mensagens, sem_parametros_extras=True)
        else:
            raise ErroIA(f"falha na chamada ao modelo: {erro}")
    except ErroIA:
        raise
    except Exception as erro:
        raise ErroIA(f"falha na chamada ao modelo: {erro}")
    texto = (dados.get("message") or {}).get("content", "")
    proposta = extrair_objeto_json(texto)
    if proposta is None:
        raise ErroIA(f"resposta do modelo sem JSON valido contendo 'categoria': {texto[:200]!r}")
    return proposta


def _conversar(modelo, mensagens, sem_parametros_extras=False):
    corpo = {
        "model": modelo,
        "messages": mensagens,
        "stream": False,
        "options": {"temperature": 0, "num_predict": LIMITE_TOKENS_RESPOSTA},
    }
    if not sem_parametros_extras:
        corpo["think"] = False
        corpo["format"] = "json"
    requisicao = urllib.request.Request(
        URL_OLLAMA + "/api/chat",
        data=json.dumps(corpo).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(requisicao, timeout=TIMEOUT_SEGUNDOS) as resposta:
            return json.loads(resposta.read().decode("utf-8"))
    except urllib.error.HTTPError:
        raise
    except Exception as erro:
        raise ErroIA(f"falha na chamada ao modelo: {erro}")


def extrair_objeto_json(texto):
    for achado in re.finditer(r"\{[^{}]*\}", texto, re.DOTALL):
        try:
            objeto = json.loads(achado.group(0))
        except json.JSONDecodeError:
            continue
        if isinstance(objeto, dict) and "categoria" in objeto:
            return objeto
    return None
