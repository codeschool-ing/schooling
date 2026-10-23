---
title: Rotas, parâmetros de caminho e parâmetros de query
version: 1
---

Com os formatos declarados, a API ganha as rotas. Este é o `app/main.py` inteiro para o resto da aula:

```schooling-example
{"language": "python", "file": "app/main.py", "parts": [{"code": "# app/main.py\nfrom datetime import datetime, timezone\n\nfrom fastapi import FastAPI, HTTPException, Query, status\n\nfrom .schemas import EventIn, EventOut, RegistrationIn, RegistrationOut, RegistrationPublic\nfrom .store import EVENTS, REGISTRATIONS\n\n", "note": "A API inteira num módulo por enquanto. O `HTTPException` é como uma função para com um status de erro; o `Query` acrescenta regras a um parâmetro de query."}, {"code": "app = FastAPI(title=\"agenda API\", version=\"0.1.0\")\n\n\n", "note": "O `title` e o `version` descrevem a API, e a aula 8 mostra onde eles aparecem."}, {"code": "def find_event(slug: str) -> dict:\n    if slug not in EVENTS:\n        raise HTTPException(status.HTTP_404_NOT_FOUND, f\"No event called {slug}\")\n    return EVENTS[slug]\n\n\n", "note": "**Uma função comum, não uma rota.** Levantar `HTTPException` dentro dela para qualquer rota que a chamou, com um 404."}, {"code": "def with_taken(event: dict) -> dict:\n    taken = sum(1 for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"])\n    return {**event, \"taken\": taken}\n\n\n", "note": "A contagem que a aula 4 pôs no banco, feita aqui sobre uma lista até a aula 10 dar um banco a esta API."}, {"code": "@app.get(\"/events\", response_model=list[EventOut])\ndef list_events(venue: str | None = None, limit: int = Query(default=20, ge=1, le=100)):\n    events = [e for e in EVENTS.values() if venue is None or e[\"venue\"] == venue]\n    return [with_taken(e) for e in events[:limit]]\n\n\n", "note": "**Todo parâmetro que não está no caminho é um parâmetro de query.** O `venue` é opcional porque o padrão é `None`; o `limit` tem de ser um inteiro de 1 a 100."}, {"code": "@app.get(\"/events/{slug}\", response_model=EventOut)\ndef get_event(slug: str):\n    return with_taken(find_event(slug))\n\n\n", "note": "O `{slug}` no caminho vira o argumento `slug`, tipado como `str`."}, {"code": "@app.post(\"/events\", response_model=EventOut, status_code=status.HTTP_201_CREATED)\ndef create_event(event: EventIn):\n    if event.slug in EVENTS:\n        raise HTTPException(status.HTTP_409_CONFLICT, f\"{event.slug} already exists\")\n    EVENTS[event.slug] = event.model_dump()\n    return with_taken(EVENTS[event.slug])\n\n\n", "note": "**Um parâmetro cujo tipo é um modelo Pydantic é lido do corpo JSON**, validado antes de a função rodar. O `status_code` define o código de sucesso."}, {"code": "@app.post(\n    \"/events/{slug}/registrations\",\n    response_model=RegistrationOut,\n    status_code=status.HTTP_201_CREATED,\n)\ndef register(slug: str, registration: RegistrationIn):\n    event = find_event(slug)\n    mine = [r for r in REGISTRATIONS if r[\"slug\"] == slug]\n    if len(mine) >= event[\"capacity\"]:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This event is full.\")\n    if any(r[\"email\"] == registration.email for r in mine):\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This address is already registered.\")\n    row = {\"slug\": slug, **registration.model_dump(), \"created_at\": datetime.now(timezone.utc)}\n    REGISTRATIONS.append(row)\n    return row\n\n\n", "note": "A inscrição: as mesmas três regras que o formulário do Django tinha na aula 3, no mesmo formato sujeito a corrida, até a aula 10 pô-las num banco."}, {"code": "@app.get(\"/events/{slug}/registrations\", response_model=list[RegistrationPublic])\ndef list_registrations(slug: str):\n    find_event(slug)\n    return [r for r in REGISTRATIONS if r[\"slug\"] == slug]\n", "note": "Devolve as linhas com os endereços; o modelo de resposta tira os endereços."}]}
```

De onde vem um valor é decidido pela assinatura da função, e por nada mais:

| o parâmetro | é lido de |
|---|---|
| citado no caminho, `{slug}` | o caminho |
| um tipo simples, `str`, `int`, `bool`, fora do caminho | a query string |
| um modelo Pydantic | o corpo JSON |

## Parâmetros de query, tipados

O `limit` tem padrão 20 e tem de ser um inteiro de 1 a 100. Peça um:

```
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?limit=1" | python3 -m json.tool
[
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": "2026-11-12T19:00:00-03:00",
        "venue": "Community Centre, room 3",
        "capacity": 40,
        "description": "",
        "taken": 0
    }
]
```

O `taken` está lá porque o modelo de resposta `EventOut` pediu. O `venue` filtra, e simplesmente não
aparece quando não é dado:

```
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?venue=Public%20Library,%20lab%202" | python3 -m json.tool | grep slug
        "slug": "async-workshop",
```

Um `limit` fora da faixa, e um que não é número:

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?limit=500"
{"detail":[{"type":"less_than_equal","loc":["query","limit"],"msg":"Input should be less than or equal to 100","input":"500","ctx":{"le":100}}]}
422
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?limit=ten"
{"detail":[{"type":"int_parsing","loc":["query","limit"],"msg":"Input should be a valid integer, unable to parse string as an integer","input":"ten"}]}
422
```

**422, e a função nem rodou.** Cada erro diz onde estava o valor ruim, `["query", "limit"]`, que regra
ele quebrou e o que foi mandado. Essa lista `loc` é como um cliente sabe qual input marcar de vermelho.

## Um evento que não existe

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/no-such-event
{"detail":"No event called no-such-event"}
404
```

O `find_event` levantou `HTTPException` com 404, e o FastAPI respondeu com a mensagem dela em
`detail`. A exceção não é capturada pela rota: o FastAPI a captura para toda rota, e é por isso que uma
função auxiliar três chamadas abaixo consegue parar uma requisição com o status certo.
