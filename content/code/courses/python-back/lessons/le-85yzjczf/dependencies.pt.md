---
title: Dependências: as peças que uma rota pede
version: 1
---

As rotas da aula 7 chamavam cada uma `find_event(slug)` e declaravam o `limit` por conta própria. As
duas coisas são algo de que **muitas rotas precisam**, e o FastAPI tem um mecanismo exatamente para
isso: uma rota declara o que precisa na assinatura, e o FastAPI monta antes de chamá-la. Isso é
**injeção de dependência**, e é como o FastAPI compartilha tudo, de uma busca a uma sessão de banco.
Salve isto como `app/dependencies.py`:

```schooling-example
{"language": "python", "file": "app/dependencies.py", "parts": [{"code": "# app/dependencies.py\nimport threading\nfrom typing import Annotated\n\nfrom fastapi import Depends, HTTPException, Query, status\n\nfrom .store import EVENTS\n\n\n", "note": "Tudo o que uma rota pode pedir ao FastAPI para montar mora em `app/dependencies.py`."}, {"code": "def get_event(slug: str) -> dict:\n    if slug not in EVENTS:\n        raise HTTPException(status.HTTP_404_NOT_FOUND, f\"No event called {slug}\")\n    return EVENTS[slug]\n\n\n", "note": "**Uma dependência é uma função.** Os parâmetros dela são lidos da requisição como os de uma rota, então o `slug` vem do caminho."}, {"code": "EventDep = Annotated[dict, Depends(get_event)]\n\n\n", "note": "O `Annotated` junta o tipo e o `Depends` num nome só, para uma rota escrever `event: EventDep` e nada mais."}, {"code": "class Page:\n    def __init__(\n        self,\n        limit: int = Query(default=20, ge=1, le=100),\n        offset: int = Query(default=0, ge=0),\n    ):\n        self.limit = limit\n        self.offset = offset\n\n\n", "note": "Uma classe também serve: o FastAPI a chama com os parâmetros de query, e a rota recebe a instância. `limit` e `offset` agora têm uma definição só para toda lista."}, {"code": "PageDep = Annotated[Page, Depends()]\n\n", "note": "`Depends()` sem argumento quer dizer \"chame a própria classe anotada\"."}, {"code": "_registrations = threading.Lock()\n\n\n", "note": "**Uma trava para o processo inteiro**, compartilhada por toda requisição que este processo atende."}, {"code": "def registration_lock():\n    with _registrations:\n        print(\"lock held\", flush=True)\n        try:\n            yield\n        finally:\n            print(\"lock released\", flush=True)\n", "note": "**Uma dependência com `yield`**: o código antes dele roda antes da rota, o código depois dele roda quando a rota termina. O `finally` garante que a segunda metade rode mesmo quando a rota levantou erro."}]}
```

E troque o `app/main.py` por esta versão, que as usa:

```schooling-example
{"language": "python", "file": "app/main.py", "parts": [{"code": "# app/main.py\nfrom datetime import datetime, timezone\n\nfrom fastapi import Depends, FastAPI, HTTPException, status\n\nfrom .dependencies import EventDep, PageDep, registration_lock\nfrom .schemas import EventIn, EventOut, RegistrationIn, RegistrationOut, RegistrationPublic\nfrom .store import EVENTS, REGISTRATIONS\n\n", "note": "`Depends` para a dependência sem valor, e nada mais de novo nos imports."}, {"code": "app = FastAPI(\n    title=\"agenda API\",\n    version=\"0.2.0\",\n    description=\"Community events with a limited number of seats.\",\n)\n\n\n", "note": "O `title`, a `version` e a `description` vão para o topo do esquema e das páginas de documentação."}, {"code": "def with_taken(event: dict) -> dict:\n    taken = sum(1 for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"])\n    return {**event, \"taken\": taken}\n\n\n"}, {"code": "@app.get(\"/events\", response_model=list[EventOut], tags=[\"events\"])\ndef list_events(page: PageDep, venue: str | None = None):\n    \"\"\"Events in date order, optionally only those at one venue.\"\"\"\n    events = sorted(EVENTS.values(), key=lambda e: e[\"starts_at\"])\n    events = [e for e in events if venue is None or e[\"venue\"] == venue]\n    return [with_taken(e) for e in events[page.offset : page.offset + page.limit]]\n\n\n", "note": "As `tags` agrupam rotas na página de documentação; **a docstring vira a descrição da operação**. O `page: PageDep` troca os dois parâmetros de query que a aula 7 declarava aqui."}, {"code": "@app.get(\n    \"/events/{slug}\",\n    response_model=EventOut,\n    tags=[\"events\"],\n    responses={404: {\"description\": \"No event has this slug\"}},\n)\ndef get_event(event: EventDep):\n    \"\"\"One event, with the number of seats already taken.\"\"\"\n    return with_taken(event)\n\n\n", "note": "O `responses` documenta uma resposta que o FastAPI não vê no código, o 404 que o `get_event` levanta. O `event: EventDep` troca o `find_event(slug)`."}, {"code": "@app.post(\"/events\", response_model=EventOut, status_code=status.HTTP_201_CREATED, tags=[\"events\"])\ndef create_event(event: EventIn):\n    if event.slug in EVENTS:\n        raise HTTPException(status.HTTP_409_CONFLICT, f\"{event.slug} already exists\")\n    EVENTS[event.slug] = event.model_dump()\n    return with_taken(EVENTS[event.slug])\n\n\n"}, {"code": "@app.post(\n    \"/events/{slug}/registrations\",\n    response_model=RegistrationOut,\n    status_code=status.HTTP_201_CREATED,\n    tags=[\"registrations\"],\n    summary=\"Register for an event\",\n    responses={409: {\"description\": \"The event is full, or the address is already registered\"}},\n    dependencies=[Depends(registration_lock)],\n)\ndef register(event: EventDep, registration: RegistrationIn):\n    mine = [r for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"]]\n    if len(mine) >= event[\"capacity\"]:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This event is full.\")\n    if any(r[\"email\"] == registration.email for r in mine):\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This address is already registered.\")\n    row = {\n        \"slug\": event[\"slug\"],\n        **registration.model_dump(),\n        \"created_at\": datetime.now(timezone.utc),\n    }\n    REGISTRATIONS.append(row)\n    print(\"registered\", registration.email, flush=True)\n    return row\n\n\n", "note": "O `summary` troca o título que o FastAPI deriva do nome da função. **O `dependencies=[...]`** roda uma dependência cujo valor a rota não usa: a trava."}, {"code": "@app.get(\n    \"/events/{slug}/registrations\",\n    response_model=list[RegistrationPublic],\n    tags=[\"registrations\"],\n)\ndef list_registrations(event: EventDep):\n    return [r for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"]]\n", "note": "O mesmo `EventDep`, então o 404 de um evento desconhecido é escrito uma vez."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"Antes de chamar o register, o FastAPI resolve as dependências a partir da requisição: o get_event pega o slug do caminho e devolve o evento ou responde 404; o RegistrationIn valida o corpo ou responde 422; o registration_lock pega a trava e a segura. Só quando as três deram certo o register é chamado, com os resultados delas como argumentos.\"> <defs><marker id=\"di-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a requisição</text> <rect x=\"20\" y=\"32\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">path: slug=django-night</text> <text x=\"32\" y=\"92\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">body: {name, email}</text> <text x=\"32\" y=\"126\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">query: limit, offset</text> <text x=\"32\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(para a rota da lista)</text> <rect x=\"270\" y=\"32\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">get_event(slug)</text> <text x=\"370\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um dict, ou 404</text> <rect x=\"270\" y=\"92\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RegistrationIn</text> <text x=\"370\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um modelo, ou 422</text> <rect x=\"270\" y=\"152\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registration_lock()</text> <text x=\"370\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segura até o fim</text> <path d=\"M220 54 L264 46\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <path d=\"M220 88 L264 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <rect x=\"520\" y=\"70\" width=\"180\" height=\"80\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"610\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">register(event,</text> <text x=\"610\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registration)</text> <text x=\"610\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda por último</text> <path d=\"M470 54 L514 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <path d=\"M470 114 L514 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <path d=\"M470 174 L514 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Qualquer dependência pode parar a requisição; a rota só roda se todas deram certo.</text> </svg>", "caption": "A assinatura da rota é uma lista do que ela precisa. O FastAPI monta cada coisa, em ordem, e as entrega."}
```

## Usando

A lista paginada, página dois de tamanho um:

```
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?limit=1&offset=1" | python3 -m json.tool | grep slug
        "slug": "async-workshop",
```

As regras da classe `Page` valem onde ela for usada, com o mesmo 422 de qualquer outro parâmetro:

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?offset=-1"
{"detail":[{"type":"greater_than_equal","loc":["query","offset"],"msg":"Input should be greater than or equal to 0","input":"-1","ctx":{"ge":0}}]}
422
```

E o `get_event` responde por toda rota que declara `EventDep`, o endereço do próprio evento e as
inscrições dele:

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/nope
{"detail":"No event called nope"}
404
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/nope/registrations
{"detail":"No event called nope"}
404
```

**Uma função, uma mensagem, duas rotas**, e uma terceira rota que precisar de um evento ganha o mesmo
comportamento escrevendo `event: EventDep`.

## Por que isso é melhor que chamar uma função

As rotas poderiam chamar `get_event(slug)` elas mesmas, como a aula 7 fazia. Declarar em vez disso
compra três coisas. **Os parâmetros que uma dependência lê aparecem no esquema**, como o `limit` e o
`offset` apareceram na seção anterior. **Dependências podem depender de outras**, e o FastAPI resolve a
árvore inteira uma vez por requisição, guardando um valor que duas delas compartilham. E uma
dependência pode ser **trocada de fora** sem mexer na rota, que é a última seção desta aula e o motivo
de os testes da aula 14 serem curtos.
