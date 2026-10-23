---
title: O formulário de agendamento, como a ana o encontrou
version: 1
---

A aplicação desta aula é o endpoint por trás do formulário de agendamento: um `POST` em `/bookings`
com um corpo JSON de quatro campos. Faça da pasta dela um repositório, do jeito que a aula 1 fez com
`cancel`; se você salvou o `digits.py` na seção anterior, ela já existe:

```
(.venv) ana@vm:~/sc$ mkdir booking
(.venv) ana@vm:~/sc$ cd booking
(.venv) ana@vm:~/sc/booking$ git init -b main
Initialized empty Git repository in /home/ana/sc/booking/.git/
```

Esta é a versão que a ana herdou, com a lista de bloqueio da primeira seção. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "from flask import Flask, jsonify, request\n\napp = Flask(__name__)\nBOOKINGS = []\n\nFORBIDDEN = (\"<\", \">\", \";\", \"--\")\n\n\ndef looks_safe(value):\n    return not any(bad in value for bad in FORBIDDEN)\n\n", "note": "Uma lista de caracteres que alguém um dia decidiu que eram perigosos. Todo o resto é bem-vindo."}, {"code": "@app.post(\"/bookings\")\ndef create():\n    data = request.get_json()\n    for field in (\"clinic\", \"date\", \"time\", \"phone\"):\n        if not looks_safe(str(data.get(field, \"\"))):\n            return jsonify(error=f\"invalid {field}\"), 400\n    BOOKINGS.append(data)\n    return jsonify(data), 201", "note": "Cada campo é conferido contra a lista e guardado exatamente como chegou. Um campo ausente vira uma string vazia, que não contém nada proibido."}]}
```

### Os testes enunciam a lista de permissão

Os testes descrevem um agendamento bom uma vez, em `GOOD`, e depois trocam um campo de cada vez por
um valor que tem de ser recusado. O `parametrize` roda a mesma função de teste uma vez por par, então
uma função cobre sete casos e cada um é relatado na sua própria linha. Salve como `test_app.py`:

```python
# test_app.py
import pytest

import app as portal

FULL_WIDTH = "".join(chr(0xFF10 + int(d)) for d in "11987654321")
GOOD = {"clinic": "moema", "date": "2026-11-10", "time": "09:00", "phone": "11987654321"}


@pytest.fixture
def client():
    portal.BOOKINGS.clear()
    return portal.app.test_client()


def test_a_good_booking_is_stored(client):
    assert client.post("/bookings", json=GOOD).status_code == 201
    assert len(portal.BOOKINGS) == 1


@pytest.mark.parametrize("field, value", [
    ("clinic", "Moema"),
    ("clinic", "paulista"),
    ("date", "2026-11-31"),
    ("time", "23:00"),
    ("phone", "1198765"),
    ("phone", FULL_WIDTH),
    ("phone", None),
])
def test_a_value_outside_the_allowlist_is_refused(client, field, value):
    response = client.post("/bookings", json=dict(GOOD, **{field: value}))
    assert response.status_code == 400
    assert response.get_json() == {"error": f"invalid {field}"}
    assert portal.BOOKINGS == []


def test_a_missing_field_is_refused(client):
    body = {k: v for k, v in GOOD.items() if k != "phone"}
    assert client.post("/bookings", json=body).status_code == 400
```

Cada teste verifica três coisas onde dá: o status, **o campo que o erro nomeia**, e que nada foi
guardado. Uma recusa que nomeia o campo errado passa numa verificação de status e ainda manda o
paciente procurar o erro errado.

### Vermelho

Oito testes falham, e um relatório completo de cada um encheria várias telas. O `--tb=line` encurta
cada falha para a linha que diz o que era esperado:

```
(.venv) ana@vm:~/sc/booking$ pytest --tb=line
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/booking
collected 9 items

test_app.py .FFFFFFFF                                                    [100%]

=================================== FAILURES ===================================
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   AssertionError: assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
     +    where <WrapperTestResponse streamed [201 CREATED]> = post('/bookings', json={'clinic': 'moema', 'date': '2026-11-10', 'time': '09:00'})
     +      where post = <FlaskClient <Flask 'app'>>.post
/home/ana/sc/booking/test_app.py:39: AssertionError: assert 201 == 400
=========================== short test summary info ============================
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[clinic-Moema]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[clinic-paulista]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[date-2026-11-31]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[time-23:00]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[phone-1198765]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[phone-\uff11\uff11\uff19\uff18\uff17\uff16\uff15\uff14\uff13\uff12\uff11]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[phone-None]
FAILED test_app.py::test_a_missing_field_is_refused - AssertionError: assert ...
========================= 8 failed, 1 passed in 0.13s ==========================
```

**Todo valor da tabela da primeira seção foi aceito com `201` e guardado.** O agendamento bom passa,
e essa é a armadilha da lista de bloqueio numa linha: ela nunca atrapalha dado correto, então
ninguém que usa o formulário percebe que ela não verifica nada. Faça commit desta versão antes de
mudá-la:

```
(.venv) ana@vm:~/sc/booking$ git add app.py test_app.py digits.py
(.venv) ana@vm:~/sc/booking$ git commit -m "Book a session from the form"
[main (root-commit) f356038] Book a session from the form
 3 files changed, 69 insertions(+)
 create mode 100644 app.py
 create mode 100644 digits.py
 create mode 100644 test_app.py
```
