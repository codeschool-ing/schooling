---
title: As sessões do portal, e seis testes que falham
version: 1
---

A pasta desta aula é `~/sc/sessions`, um repositório git próprio, como na aula 1:

```
(.venv) ana@vm:~/sc$ mkdir sessions
(.venv) ana@vm:~/sc$ cd sessions
(.venv) ana@vm:~/sc/sessions$ git init -b main
Initialized empty Git repository in /home/ana/sc/sessions/.git/
```

Esta é a parte do portal que faz o login de um paciente, como a ana a escreveu primeiro. Funciona:
um paciente que entra vê seus agendamentos, e um que não entrou recebe `401`. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport hashlib\nfrom datetime import datetime\n\nfrom flask import Flask, abort, jsonify, make_response, request\n\napp = Flask(__name__)\nSESSIONS = {}\n\n", "note": "A tabela de sessões: cada id que o servidor emitiu, ligado ao que ele sabe daquela sessão. Aqui um dicionário; em produção, uma tabela de banco ou o Redis."}, {"code": "def now():\n    return datetime.now()\n\n\ndef check_password(name, password):\n    # Lesson 11 replaces this with a real password store.\n    return (name, password) in {(\"lucia\", \"lucia-pw\"), (\"rafael\", \"rafael-pw\")}\n\n", "note": "O relógio é uma função própria para que um teste possa movê-lo, como na aula 1. A verificação de senha é provisória: guardar senhas é a aula 11, e aqui só atrapalharia."}, {"code": "def new_session_id(name):\n    return hashlib.md5(f\"{name}{now():%Y%m%d%H%M}\".encode()).hexdigest()\n\n", "note": "O id: um hash do nome e do minuto. Parece aleatório. Guarde essa impressão para a próxima seção."}, {"code": "def current_patient():\n    record = SESSIONS.get(request.cookies.get(\"sid\"))\n    if record is None or record[\"patient\"] is None:\n        abort(401)\n    return record[\"patient\"]\n\n", "note": "Toda rota que precisa de um paciente pergunta a esta função. Um id que a tabela não conhece, ou uma sessão em que ninguém entrou, é `401`."}, {"code": "@app.get(\"/\")\ndef home():\n    response = make_response(\"Vereda patient portal\\n\")\n    if request.cookies.get(\"sid\") not in SESSIONS:\n        sid = new_session_id(\"visitor\")\n        SESSIONS[sid] = {\"patient\": None}\n        response.set_cookie(\"sid\", sid)\n    return response\n\n", "note": "Um visitante recebe uma sessão antes de entrar, para lembrar a escolha de idioma ou, na aula 9, um token de formulário. Ela é anônima: `patient` é `None`."}, {"code": "@app.post(\"/sign-in\")\ndef sign_in():\n    name = request.form.get(\"name\", \"\")\n    if not check_password(name, request.form.get(\"password\", \"\")):\n        abort(401)\n    sid = request.cookies.get(\"sid\")\n    if sid not in SESSIONS:\n        sid = new_session_id(name)\n    SESSIONS[sid] = {\"patient\": name}\n    response = jsonify(patient=name)\n    response.set_cookie(\"sid\", sid)\n    return response\n\n", "note": "Login: se o navegador já tem uma sessão, grava o paciente nela; senão emite uma. Pergunte-se com qual id a lucia fica."}, {"code": "@app.get(\"/bookings\")\ndef bookings():\n    return jsonify(patient=current_patient(), bookings=[])\n\n", "note": "Uma página que exige paciente autenticado. Os agendamentos não são o assunto desta aula, então a lista vem vazia."}, {"code": "@app.post(\"/sign-out\")\ndef sign_out():\n    response = jsonify(signed_out=True)\n    response.delete_cookie(\"sid\")\n    return response", "note": "O logout manda o navegador esquecer o cookie. Repare no que ele não toca."}]}
```

Nada nele parece descuidado, e é por isso que vale ler devagar. Cada função faz o que o nome diz. As
falhas estão no que as funções deixam de fora, e nenhuma aparece quando você clica pelo portal à mão.

### Os testes

Os testes abaixo escrevem os quatro momentos da seção anterior como frases. Duas fixtures os
sustentam. `clock` troca `now` por uma hora que o teste pode adiantar, e é assim que um teste espera
dezesseis minutos sem esperar nada. `client` esvazia a tabela de sessões e devolve o cliente de
teste do Flask. Salve como `test_app.py`:

```python
# test_app.py
from datetime import datetime, timedelta

import pytest

import app as portal


@pytest.fixture
def clock(monkeypatch):
    times = [datetime(2026, 11, 9, 9, 0)]
    monkeypatch.setattr(portal, "now", lambda: times[0])
    return times


@pytest.fixture
def client(clock):
    portal.SESSIONS.clear()
    return portal.app.test_client()


def sign_in(client, name="lucia"):
    return client.post("/sign-in", data={"name": name, "password": f"{name}-pw"})


def sid(client):
    return client.get_cookie("sid").value


def test_a_signed_in_patient_sees_their_bookings(client):
    sign_in(client)
    assert client.get("/bookings").json["patient"] == "lucia"


def test_session_ids_cannot_be_worked_out(client):
    first, second = portal.app.test_client(), portal.app.test_client()
    sign_in(first)
    sign_in(second)
    assert sid(first) != sid(second)
    assert len(sid(first)) >= 43


def test_the_cookie_is_kept_from_scripts_and_plain_http(client):
    cookie = sign_in(client).headers["Set-Cookie"]
    assert "HttpOnly" in cookie
    assert "Secure" in cookie
    assert "SameSite=Lax" in cookie


def test_signing_in_issues_a_new_id(client):
    client.get("/")
    before = sid(client)
    sign_in(client)
    assert sid(client) != before
    assert before not in portal.SESSIONS


def test_an_idle_session_expires(client, clock):
    sign_in(client)
    clock[0] += timedelta(minutes=16)
    assert client.get("/bookings").status_code == 401


def test_a_session_has_an_absolute_limit(client, clock):
    sign_in(client)
    for _ in range(8 * 6 + 1):
        clock[0] += timedelta(minutes=10)
        client.get("/bookings")
    assert client.get("/bookings").status_code == 401


def test_signing_out_ends_the_session_on_the_server(client):
    sign_in(client)
    old = sid(client)
    client.post("/sign-out")
    client.set_cookie("sid", old)
    assert client.get("/bookings").status_code == 401
```

Leia o último teste com atenção, porque é o que um teste manual nunca faz. Ele sai da sessão, o que
faz o navegador esquecer o cookie, e depois **devolve o id antigo**, como faria uma cópia guardada
em qualquer outro lugar. A resposta do servidor é a única que conta.

### Vermelho

```
(.venv) ana@vm:~/sc/sessions$ pytest -q --tb=no
.FFFFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_session_ids_cannot_be_worked_out - AssertionError: a...
FAILED test_app.py::test_the_cookie_is_kept_from_scripts_and_plain_http - Ass...
FAILED test_app.py::test_signing_in_issues_a_new_id - AssertionError: assert ...
FAILED test_app.py::test_an_idle_session_expires - AssertionError: assert 200...
FAILED test_app.py::test_a_session_has_an_absolute_limit - AssertionError: as...
FAILED test_app.py::test_signing_out_ends_the_session_on_the_server - Asserti...
6 failed, 1 passed in 0.20s
```

**Seis de sete falham.** O primeiro teste passa, e era isso que "funciona" queria dizer: a sessão
faz seu trabalho para a pessoa a quem pertence. Toda falha trata de outra pessoa com o id na mão, ou
de um id que sobrevive ao motivo pelo qual foi emitido. Faça o commit da versão com falhas, para
cada correção ser um diff próprio:

```
(.venv) ana@vm:~/sc/sessions$ git add app.py test_app.py
(.venv) ana@vm:~/sc/sessions$ git commit -q -m "Sign patients in with a server-side session"
```

As três próximas seções pegam as falhas na ordem dos quatro momentos, e cada uma termina com os
testes que ela deixa verdes.
