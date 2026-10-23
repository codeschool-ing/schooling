---
title: O TestClient do FastAPI, num banco próprio
version: 1
---

Os testes do FastAPI usam o `TestClient` do Starlette, que chama a aplicação no mesmo processo, como o
cliente do Django faz. A diferença é o banco: não há pytest-django para criar um, então os testes criam
o seu. Crie-o, acrescente o pytest, e deixe o pytest importar o `app` da raiz do projeto:

```
ana@vm:~/agenda-api$ createdb agenda_api_test
ana@vm:~/agenda-api$ uv add --dev pytest
Resolved 40 packages in 192ms
Installed 5 packages in 8ms
 + iniconfig==2.3.1
 + packaging==26.3
 + pluggy==1.7.0
 + pygments==2.21.0
 + pytest==9.1.1
ana@vm:~/agenda-api$ sed -n '/^\[tool.pytest/,$p' pyproject.toml
[tool.pytest.ini_options]
pythonpath = ["."]
```

As fixtures, em `tests/conftest.py`:

```schooling-example
{"language": "python", "file": "tests/conftest.py", "parts": [{"code": "# tests/conftest.py\nfrom datetime import datetime\nfrom zoneinfo import ZoneInfo\n\nimport pytest\nfrom fastapi.testclient import TestClient\nfrom sqlalchemy import create_engine\nfrom sqlalchemy.orm import Session\n\nfrom app.db import get_session\nfrom app.main import app\nfrom app.models import Base, Event, User\nfrom app.security import make_token, passwords\n\n"}, {"code": "engine = create_engine(\"postgresql+psycopg:///agenda_api_test\")\nSAO_PAULO = ZoneInfo(\"America/Sao_Paulo\")\n\n\n", "note": "Um banco só para os testes, que o `createdb` criou acima."}, {"code": "@pytest.fixture(scope=\"session\", autouse=True)\ndef tables():\n    Base.metadata.create_all(engine)\n    yield\n    Base.metadata.drop_all(engine)\n\n\n", "note": "Tabelas uma vez para a rodada inteira, a partir dos models, e apagadas no fim."}, {"code": "@pytest.fixture\ndef session():\n    with engine.connect() as connection:\n        outer = connection.begin()\n        with Session(bind=connection, join_transaction_mode=\"create_savepoint\") as session:\n            yield session\n        outer.rollback()\n\n\n", "note": "**O isolamento.** Uma transação numa conexão, e uma session ligada a ela que transforma cada `commit()` num savepoint. O rollback no fim remove tudo o que o teste escreveu."}, {"code": "@pytest.fixture\ndef client(session):\n    app.dependency_overrides[get_session] = lambda: session\n    yield TestClient(app)\n    app.dependency_overrides.clear()\n\n\n", "note": "A técnica da aula 8: toda rota que pede `get_session` recebe a session do teste. As substituições são limpas depois de cada teste."}, {"code": "@pytest.fixture\ndef tokens(session):\n    users = {\n        name: User(username=name, password_hash=passwords.hash(\"x\"), is_admin=name == \"ana\")\n        for name in (\"ana\", \"bruno\", \"carla\")\n    }\n    session.add_all(users.values())\n    session.flush()\n    session.add_all([\n        Event(slug=\"testing-dojo\", title=\"Testing dojo\",\n              starts_at=datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),\n              venue=\"Community Centre, room 3\", capacity=20, organiser_id=users[\"bruno\"].id),\n        Event(slug=\"async-workshop\", title=\"Async Python workshop\",\n              starts_at=datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),\n              venue=\"Public Library, lab 2\", capacity=1, organiser_id=users[\"ana\"].id),\n    ])\n    session.flush()\n    return {name: {\"Authorization\": \"Bearer \" + make_token(user)} for name, user in users.items()}\n", "note": "Usuários, eventos e um token para cada pessoa, feito com o próprio `make_token` da aplicação, então os testes nunca passam pelo formulário de login."}]}
```

E os testes, em `tests/test_api.py`: as mesmas portas do Django, com o 422 do FastAPI na última linha,
e dois sobre inscrição:

```python
# tests/test_api.py
import pytest

DOORS = [
    (None, "GET", "/events/testing-dojo", 200),
    (None, "PATCH", "/events/testing-dojo", 401),
    ("carla", "PATCH", "/events/testing-dojo", 403),
    ("bruno", "PATCH", "/events/testing-dojo", 200),
    ("bruno", "PATCH", "/events/async-workshop", 403),
    ("ana", "PATCH", "/events/async-workshop", 200),
    ("bruno", "POST", "/events", 403),
    ("ana", "POST", "/events", 422),
]


@pytest.mark.parametrize("who, method, path, expected", DOORS)
def test_doors(client, tokens, who, method, path, expected):
    headers = tokens[who] if who else {}
    answer = client.request(method, path, json={}, headers=headers)
    assert answer.status_code == expected


def test_registering_sends_a_confirmation(client, tokens, monkeypatch):
    sent = []
    monkeypatch.setattr("app.mail.confirmation", lambda *args: sent.append(args))
    answer = client.post("/events/testing-dojo/registrations", json={"name": "Davi", "email": "davi@example.org"})
    assert answer.status_code == 201
    assert sent == [("Davi", "davi@example.org", "Testing dojo")]


def test_a_full_event_answers_409(client, tokens, monkeypatch):
    monkeypatch.setattr("app.mail.confirmation", lambda *args: None)
    path = "/events/async-workshop/registrations"
    assert client.post(path, json={"name": "Davi", "email": "davi@example.org"}).status_code == 201
    answer = client.post(path, json={"name": "Elisa", "email": "elisa@example.org"})
    assert answer.status_code == 409
    assert answer.json() == {"detail": "This event is full."}
```

**O `monkeypatch.setattr("app.mail.confirmation", ...)`** troca a função que a tarefa em segundo plano
chamaria, então o teste registra os argumentos em vez de falar com um servidor de e-mail. Funciona
porque o `register` procura `mail.confirmation` quando roda, não quando o módulo é importado.

```
ana@vm:~/agenda-api$ uv run pytest -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda-api/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/ana/agenda-api
configfile: pyproject.toml
plugins: anyio-4.15.1
collecting ... collected 10 items

tests/test_api.py::test_doors[None-GET-/events/testing-dojo-200] PASSED                      [ 10%]
tests/test_api.py::test_doors[None-PATCH-/events/testing-dojo-401] PASSED                    [ 20%]
tests/test_api.py::test_doors[carla-PATCH-/events/testing-dojo-403] PASSED                   [ 30%]
tests/test_api.py::test_doors[bruno-PATCH-/events/testing-dojo-200] PASSED                   [ 40%]
tests/test_api.py::test_doors[bruno-PATCH-/events/async-workshop-403] PASSED                 [ 50%]
tests/test_api.py::test_doors[ana-PATCH-/events/async-workshop-200] PASSED                   [ 60%]
tests/test_api.py::test_doors[bruno-POST-/events-403] PASSED                                 [ 70%]
tests/test_api.py::test_doors[ana-POST-/events-422] PASSED                                   [ 80%]
tests/test_api.py::test_registering_sends_a_confirmation PASSED                              [ 90%]
tests/test_api.py::test_a_full_event_answers_409 PASSED                                      [100%]

======================================== 10 passed in 1.49s ========================================
ana@vm:~/agenda-api$ psql agenda_api_test -c "\dt"
Did not find any relations.
```

As tabelas foram apagadas no fim da rodada, como a fixture de session dizia.

## Uma guarda esquecida

A aula 12 avisou que uma rota que esquece a guarda fica aberta, e nada reclama. Cometa o erro: no
`app/main.py`, dê ao `update_event` o `EventDep` simples em vez do `EditableEvent`.

```
ana@vm:~/agenda-api$ grep -n 'def update_event' app/main.py
57:def update_event(changes: EventPatch, event: EventDep, session: SessionDep):
ana@vm:~/agenda-api$ uv run pytest -q --tb=line
.FF.F.....                                                                                   [100%]
============================================= FAILURES =============================================
E   assert 200 == 401
     +  where 200 = <Response [200 OK]>.status_code
/home/ana/agenda-api/tests/test_api.py:20: assert 200 == 401
E   assert 200 == 403
     +  where 200 = <Response [200 OK]>.status_code
/home/ana/agenda-api/tests/test_api.py:20: assert 200 == 403
E   assert 200 == 403
     +  where 200 = <Response [200 OK]>.status_code
/home/ana/agenda-api/tests/test_api.py:20: assert 200 == 403
===================================== short test summary info ======================================
FAILED tests/test_api.py::test_doors[None-PATCH-/events/testing-dojo-401] - assert 200 == 401
FAILED tests/test_api.py::test_doors[carla-PATCH-/events/testing-dojo-403] - assert 200 == 403
FAILED tests/test_api.py::test_doors[bruno-PATCH-/events/async-workshop-403] - assert 200 == 403
3 failed, 7 passed in 1.60s
```

**Três portas falharam**, cada uma com sua linha no nome: anônimo, a Carla e o Bruno no evento de outra
pessoa, todos respondidos com 200. Ponha o `EditableEvent` de volta:

```
ana@vm:~/agenda-api$ grep -n 'def update_event' app/main.py
57:def update_event(changes: EventPatch, event: EditableEvent, session: SessionDep):
ana@vm:~/agenda-api$ uv run pytest -q
..........                                                                                   [100%]
10 passed in 1.55s
```

É para isso que a tabela serve. Ela não prova que a aplicação é segura; prova que as decisões escritas
nela continuam valendo depois de toda mudança, e quebra o build, num log que alguém lê, antes de a
mudança chegar a qualquer pessoa.
