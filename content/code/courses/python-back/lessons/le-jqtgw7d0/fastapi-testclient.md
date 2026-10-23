---
title: FastAPI's TestClient, on a database of its own
version: 1
---

FastAPI's tests use Starlette's `TestClient`, which calls the application in the same process, as
Django's client does. The difference is the database: there is no pytest-django to make one, so the
tests make their own. Create it, add pytest, and let pytest import `app` from the project's root:

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

The fixtures, in `tests/conftest.py`:

```schooling-example
{"language": "python", "file": "tests/conftest.py", "parts": [{"code": "# tests/conftest.py\nfrom datetime import datetime\nfrom zoneinfo import ZoneInfo\n\nimport pytest\nfrom fastapi.testclient import TestClient\nfrom sqlalchemy import create_engine\nfrom sqlalchemy.orm import Session\n\nfrom app.db import get_session\nfrom app.main import app\nfrom app.models import Base, Event, User\nfrom app.security import make_token, passwords\n\n"}, {"code": "engine = create_engine(\"postgresql+psycopg:///agenda_api_test\")\nSAO_PAULO = ZoneInfo(\"America/Sao_Paulo\")\n\n\n", "note": "A database of its own for the tests, which `createdb` made above."}, {"code": "@pytest.fixture(scope=\"session\", autouse=True)\ndef tables():\n    Base.metadata.create_all(engine)\n    yield\n    Base.metadata.drop_all(engine)\n\n\n", "note": "Tables once for the whole run, from the models, and dropped at the end."}, {"code": "@pytest.fixture\ndef session():\n    with engine.connect() as connection:\n        outer = connection.begin()\n        with Session(bind=connection, join_transaction_mode=\"create_savepoint\") as session:\n            yield session\n        outer.rollback()\n\n\n", "note": "**The isolation.** A transaction on one connection, and a session bound to it that turns each `commit()` into a savepoint. The rollback at the end removes everything the test wrote."}, {"code": "@pytest.fixture\ndef client(session):\n    app.dependency_overrides[get_session] = lambda: session\n    yield TestClient(app)\n    app.dependency_overrides.clear()\n\n\n", "note": "Lesson 8's technique: every route that asks for `get_session` gets the test's session. The overrides are cleared after each test."}, {"code": "@pytest.fixture\ndef tokens(session):\n    users = {\n        name: User(username=name, password_hash=passwords.hash(\"x\"), is_admin=name == \"ana\")\n        for name in (\"ana\", \"bruno\", \"carla\")\n    }\n    session.add_all(users.values())\n    session.flush()\n    session.add_all([\n        Event(slug=\"testing-dojo\", title=\"Testing dojo\",\n              starts_at=datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),\n              venue=\"Community Centre, room 3\", capacity=20, organiser_id=users[\"bruno\"].id),\n        Event(slug=\"async-workshop\", title=\"Async Python workshop\",\n              starts_at=datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),\n              venue=\"Public Library, lab 2\", capacity=1, organiser_id=users[\"ana\"].id),\n    ])\n    session.flush()\n    return {name: {\"Authorization\": \"Bearer \" + make_token(user)} for name, user in users.items()}\n", "note": "Users, events and a token for each person, made with the application's own `make_token`, so the tests never go through the login form."}]}
```

And the tests, in `tests/test_api.py`: the same doors as Django's, with FastAPI's 422 in the last
row, and two about registering:

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

**`monkeypatch.setattr("app.mail.confirmation", ...)`** replaces the function the background task
would call, so the test records the arguments instead of talking to a mail server. It works because
`register` looks up `mail.confirmation` when it runs, not when the module is imported.

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

The tables were dropped at the end of the run, as the session fixture said.

## A forgotten guard

Lesson 12 warned that a route which forgets its guard is open, and nothing complains. Make the
mistake: in `app/main.py`, give `update_event` the plain `EventDep` instead of `EditableEvent`.

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

**Three doors failed**, each with its row in the name: anonymous, Carla and Bruno on somebody else's
event, all answered 200. Put `EditableEvent` back:

```
ana@vm:~/agenda-api$ grep -n 'def update_event' app/main.py
57:def update_event(changes: EventPatch, event: EditableEvent, session: SessionDep):
ana@vm:~/agenda-api$ uv run pytest -q
..........                                                                                   [100%]
10 passed in 1.55s
```

That is what the table is for. It does not prove the application is secure; it proves that the
decisions written in it still hold after every change, and it fails the build, in a log somebody
reads, before the change reaches anybody.
