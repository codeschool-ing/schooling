---
title: Quase toda requisição é espera
version: 1
---

A crença comum é que o `async` deixa o Python mais rápido. **Ele não faz nenhum pedaço de código rodar
mais rápido.** O que ele faz é deixar um processo fazer algo útil enquanto um pedaço de código espera,
e uma requisição web passa a maior parte da vida esperando: pelo banco, por outro serviço, por um
cliente numa conexão lenta terminar de mandar.

Para ver isso, o agenda precisa de algo lento para esperar. Aplicações de verdade chamam parceiros, um
gateway de pagamento, um mapa, um serviço de previsão do tempo, e cada um leva centenas de
milissegundos. Esta aula põe um no lugar deles com uma aplicação FastAPI pequenina que responde depois
de exatamente um segundo. Salve como `slow.py` em `~/agenda-api`:

```python
# slow.py
import asyncio

from fastapi import FastAPI

app = FastAPI(title="a slow partner")


@app.get("/forecast/{venue}")
async def forecast(venue: str):
    await asyncio.sleep(1)
    return {"venue": venue, "rain": "unlikely"}
```

Rode num terminal próprio, na porta 8002, com `uv run uvicorn slow:app --port 8002`, e pergunte uma
vez:

```
ana@vm:~/agenda-api$ curl -s -w "  %{time_total} s\n" http://127.0.0.1:8002/forecast/community-centre
{"venue":"community-centre","rain":"unlikely"}  1.003181 s
```

**Um segundo**, o tempo que ele passa no `asyncio.sleep`. Agora três perguntas, uma para cada um de três
lugares, feitas de dois jeitos. Salve isto como `three.py`:

```schooling-example
{"language": "python", "file": "three.py", "parts": [{"code": "# three.py\nimport asyncio\nimport time\n\nimport httpx2\n\nURL = \"http://127.0.0.1:8002/forecast/\"\nVENUES = [\"community-centre\", \"public-library\", \"town-hall\"]\n\n\n", "note": "Um parceiro, três lugares para perguntar, e o `httpx2` para os dois estilos de cliente."}, {"code": "def one_after_another():\n    with httpx2.Client() as client:\n        return [client.get(URL + v).json()[\"venue\"] for v in VENUES]\n\n\n", "note": "**O jeito comum**: cada `get` volta quando a resposta chegou, então os três segundos se somam."}, {"code": "async def all_at_once():\n    async with httpx2.AsyncClient() as client:\n        answers = await asyncio.gather(*(client.get(URL + v) for v in VENUES))\n    return [a.json()[\"venue\"] for a in answers]\n\n\n", "note": "**O jeito concorrente**: cada `client.get(...)` faz uma corrotina, e o `gather` as roda juntas e espera as três."}, {"code": "started = time.perf_counter()\nprint(one_after_another(), f\"{time.perf_counter() - started:.1f} s\")\n\nstarted = time.perf_counter()\nprint(asyncio.run(all_at_once()), f\"{time.perf_counter() - started:.1f} s\")\n", "note": "Medindo os dois, o segundo pelo `asyncio.run`, que abre um event loop, roda uma corrotina e fecha o loop."}]}
```

```
ana@vm:~/agenda-api$ uv run python three.py
['community-centre', 'public-library', 'town-hall'] 3.1 s
['community-centre', 'public-library', 'town-hall'] 1.0 s
```

**3,1 segundos um depois do outro, 1,0 todos de uma vez.** O parceiro levou o mesmo segundo para
responder cada pergunta nas duas vezes. O que mudou é que a segunda versão não esperou a primeira
resposta para fazer a segunda pergunta, então as três esperas se sobrepuseram.

## Dois tipos de lentidão

| o tempo vai para | exemplo | o `async` ajuda? |
|---|---|---|
| **esperar** algo fora do processo | uma consulta, uma chamada HTTP, um arquivo num disco de rede | **sim**: outro trabalho roda durante a espera |
| **calcular** dentro do processo | redimensionar uma imagem, um laço grande, ler um documento enorme | **não**: o processador está ocupado de qualquer jeito |

O resto da aula mede as duas colunas.
