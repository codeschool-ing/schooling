---
title: async def e def no FastAPI, medidos
version: 1
---

O FastAPI aceita os dois tipos de função de rota, e os roda de jeitos diferentes:

- uma rota **`async def`** roda **no event loop**, então só pode esperar com `await`;
- uma rota **`def`** comum roda **numa pool de threads**, 40 por padrão, então pode esperar do jeito que
  quiser, e ocupa uma thread enquanto espera.

Este módulo põe três versões da mesma rota lado a lado, mais uma que calcula em vez de esperar. Salve
como `app/forecast.py`:

```schooling-example
{"language": "python", "file": "app/forecast.py", "parts": [{"code": "# app/forecast.py\nimport time\n\nimport httpx2\nfrom fastapi import APIRouter\n\nfrom .dependencies import EventDep\n\nrouter = APIRouter(prefix=\"/forecast\", tags=[\"forecast\"])\nPARTNER = \"http://127.0.0.1:8002/forecast/\"\n\n\n", "note": "Um `APIRouter` é um grupo de rotas que um módulo pode definir e uma aplicação pode incluir, para o `main.py` continuar curto."}, {"code": "@router.get(\"/async/{slug}\")\nasync def forecast_async(event: EventDep):\n    async with httpx2.AsyncClient() as client:\n        answer = await client.get(PARTNER + event[\"slug\"])\n    return answer.json()\n\n\n", "note": "**O jeito certo de esperar**: uma rota `async def` que faz `await` num cliente assíncrono. Enquanto ela espera, o servidor roda outras requisições."}, {"code": "@router.get(\"/sync/{slug}\")\ndef forecast_sync(event: EventDep):\n    with httpx2.Client() as client:\n        answer = client.get(PARTNER + event[\"slug\"])\n    return answer.json()\n\n\n", "note": "**Também correto**: uma rota `def` comum com um cliente síncrono. O FastAPI a roda numa pool de threads, então ela bloqueia uma thread e não o servidor."}, {"code": "@router.get(\"/blocking/{slug}\")\nasync def forecast_blocking(event: EventDep):\n    with httpx2.Client() as client:\n        answer = client.get(PARTNER + event[\"slug\"])\n    return answer.json()\n\n\n", "note": "**O erro**: `async def` com uma chamada síncrona dentro. Ela roda no próprio event loop, e enquanto espera nada mais consegue rodar."}, {"code": "def crunch():\n    started = time.perf_counter()\n    total = sum(i * i for i in range(20_000_000))\n    return {\"total\": total, \"seconds\": round(time.perf_counter() - started, 2)}\n\n\n", "note": "Trabalho para o processador, não para a rede: cerca de um segundo de conta."}, {"code": "@router.get(\"/busy/async\")\nasync def busy_async():\n    return crunch()\n\n\n@router.get(\"/busy/sync\")\ndef busy_sync():\n    return crunch()\n"}]}
```

Inclua o roteador no `app/main.py`: o import ao lado dos outros, e o `include_router` depois da chamada
`FastAPI(...)`.

```
ana@vm:~/agenda-api$ grep -n 'forecast' app/main.py
7:from .forecast import router as forecast_router
16:app.include_router(forecast_router)
```

E um gerador de carga pequeno, salvo como `load.py`, que manda `n` requisições a um endereço **ao mesmo
tempo** e diz quanto tempo todas levaram:

```python
# load.py
import asyncio
import sys
import time

import httpx2


async def main(url, n):
    async with httpx2.AsyncClient(timeout=120) as client:
        started = time.perf_counter()
        answers = await asyncio.gather(*(client.get(url) for _ in range(n)))
        elapsed = time.perf_counter() - started
    codes = sorted({a.status_code for a in answers})
    print(f"{n} requests, status {codes}, {elapsed:.1f} s")


asyncio.run(main(sys.argv[1], int(sys.argv[2])))
```

Suba o agenda-api desta vez sem `--reload`, `uv run uvicorn app.main:app --port 8001`, com o parceiro
ainda rodando na 8002. Uma requisição, para conferir:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/forecast/async/django-night; echo
{"venue":"django-night","rain":"unlikely"}
```

## Vinte de uma vez, depois cem

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 20
20 requests, status [200], 1.5 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/sync/django-night 20
20 requests, status [200], 1.8 s
```

Vinte requisições, cada uma esperando um segundo pelo parceiro, terminaram em **1,5 segundo com
`async def` e 1,8 com `def`**. As duas sobrepuseram as esperas: a primeira no loop, a segunda em vinte
das quarenta threads. Agora mais requisições do que threads:

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 100
100 requests, status [200], 3.3 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/sync/django-night 100
100 requests, status [200], 5.2 s
```

**3,3 segundos contra 5,2.** A rota `def` tinha quarenta threads, então cem requisições passaram em três
ondas de um segundo cada, mais o custo de trocar de thread. A rota `async def` não tem esse teto: toda
requisição esperando é uma corrotina, que custa um pouco de memória e nenhuma thread. A maior parte do
tempo que sobra vai para montar um cliente novo por requisição; uma aplicação de verdade mantém um
`AsyncClient` aberto para o processo inteiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Barras do tempo total medido com o load.py. 20 requisições levaram 1,5 segundo com async def e 1,8 com def. 100 requisições levaram 3,3 segundos com async def e 5,2 com def. 10 requisições a uma rota async def que faz uma chamada bloqueante levaram 10,2 segundos.\"> <text x=\"260\" y=\"36\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">20 requisições, async def</text> <rect x=\"270\" y=\"20\" width=\"60.0\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\"></rect> <text x=\"338.0\" y=\"36\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.5 s</text> <text x=\"260\" y=\"70\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">20 requisições, def</text> <rect x=\"270\" y=\"54\" width=\"72.0\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"350.0\" y=\"70\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.8 s</text> <text x=\"260\" y=\"104\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">100 requisições, async def</text> <rect x=\"270\" y=\"88\" width=\"132.0\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\"></rect> <text x=\"410.0\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3.3 s</text> <text x=\"260\" y=\"138\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">100 requisições, def</text> <rect x=\"270\" y=\"122\" width=\"208.0\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"486.0\" y=\"138\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5.2 s</text> <text x=\"260\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10 requisições, chamada bloqueante em async def</text> <rect x=\"270\" y=\"156\" width=\"408.0\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"686.0\" y=\"172\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10.2 s</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Toda requisição espera um segundo pelo parceiro; a barra é o tempo de todas elas.</text> </svg>", "caption": "Medido nos quatro processadores do laboratório. O caso bloqueante tem dez requisições, não vinte, porque cada uma para o servidor inteiro durante o seu segundo.", "same": ["1.5 s", "1.8 s", "3.3 s", "5.2 s", "10.2 s"]}
```
