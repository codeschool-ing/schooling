---
title: Trocar uma dependência
version: 1
---

Como uma rota só declara o que precisa, outra coisa pode decidir o que ela recebe. O
`app.dependency_overrides` é um dicionário de uma dependência para a substituta, e enquanto uma entrada
estiver nele, toda rota que pediu a original recebe a substituta. O uso principal é em testes: uma rota
que precisa de um banco recebe um banco de teste, uma rota que precisa do usuário atual recebe um fixo.

O `TestClient` do FastAPI manda requisições à aplicação no mesmo processo, sem servidor, e precisa de
uma biblioteca de cliente HTTP para isso. Instale-a como dependência de **desenvolvimento**, que a
produção nunca instala:

```
ana@vm:~/agenda-api$ uv add --dev httpx2
Resolved 21 packages in 257ms
Prepared 3 packages in 18ms
Installed 3 packages in 3ms
 + httpcore2==2.16.0
 + httpx2==2.16.0
 + truststore==0.10.5
```

A biblioteca é a `httpx2`: o Starlette atual, por baixo do FastAPI, pede por ela pelo nome e avisa
quando só acha a `httpx` antiga. Depois, este script, salvo como `override.py` em `~/agenda-api`, troca
o `get_event` por uma função que devolve um evento sem lugar nenhum:

```python
# override.py
from fastapi.testclient import TestClient

from app.dependencies import get_event
from app.main import app


def a_full_event(slug: str) -> dict:
    return {
        "slug": slug,
        "title": "Full already",
        "starts_at": "2026-12-01T10:00:00-03:00",
        "venue": "Nowhere",
        "capacity": 0,
        "description": "",
    }


client = TestClient(app)
app.dependency_overrides[get_event] = a_full_event

answer = client.post("/events/anything/registrations", json={"name": "Gil", "email": "gil@example.org"})
print(answer.status_code, answer.json())

app.dependency_overrides.clear()
print(client.get("/events/anything").status_code)
```

```
ana@vm:~/agenda-api$ uv run python override.py
lock held
lock released
409 {'detail': 'This event is full.'}
404
```

**A rota de inscrição respondeu 409, `This event is full.`, para um evento que não existe**, porque a
rota nem procurou: recebeu o que o `get_event` teria devolvido, e o override devolveu um evento cheio.
A dependência da trava rodou mesmo assim, porque só o `get_event` foi trocado. Depois o `clear()` tirou
o override, e o mesmo endereço voltou a ser um 404.

Essa é a técnica inteira em que a aula 14 apoia os testes do FastAPI. Dois hábitos vêm com ela:
**limpe os overrides depois de cada teste**, senão a substituta de um teste vaza para o próximo; e troque
a menor coisa que torna o teste possível, para o teste continuar exercitando tudo em volta.
