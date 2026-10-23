---
title: A página da conta, e sete testes
version: 1
---

A página da conta deixa a paciente trocar o e-mail e o telefone, os dois lugares para onde vai uma
recuperação de senha. A pasta desta aula é `~/sc/csrf`:

```
(.venv) ana@vm:~/sc$ mkdir csrf
(.venv) ana@vm:~/sc$ cd csrf
(.venv) ana@vm:~/sc/csrf$ git init -b main
Initialized empty Git repository in /home/ana/sc/csrf/.git/
```

Aqui está ela como foi escrita primeiro. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport secrets\n\nfrom flask import Flask, abort, redirect, render_template_string, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\nACCOUNTS = {\"lucia\": {\"email\": \"lucia@mail.example\", \"phone\": \"+55 11 5555-0101\"}}\n", "note": "Uma conta, guardada em memória. O e-mail e o telefone são para onde vai uma recuperação de senha, e é isso que faz valer forjar uma mudança neles."}, {"code": "PAGE = \"\"\"<h1>Your account</h1>\n<form method=\"post\" action=\"/account/email\">\n  <input name=\"email\" value=\"{{ account.email }}\">\n  <button>Change e-mail</button>\n</form>\n<form method=\"post\" action=\"/account/phone\">\n  <input name=\"phone\" value=\"{{ account.phone }}\">\n  <button>Change phone</button>\n</form>\n\"\"\"\n\n", "note": "Dois formulários. Todo campo neles é algo que quem envia escolhe; nada em nenhum dos dois é um valor que só o portal conhece."}, {"code": "def signed_in():\n    name = session.get(\"patient\")\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "A verificação de sessão. Está certa, e não basta: uma requisição forjada leva uma sessão válida."}, {"code": "@app.get(\"/account\")\ndef account():\n    return render_template_string(PAGE, account=ACCOUNTS[signed_in()])\n\n\n@app.post(\"/account/email\")\ndef change_email():\n    ACCOUNTS[signed_in()][\"email\"] = request.form[\"email\"]\n    return redirect(\"/account\", 303)\n\n\n@app.post(\"/account/phone\")\ndef change_phone():\n    ACCOUNTS[signed_in()][\"phone\"] = request.form[\"phone\"]\n    return redirect(\"/account\", 303)", "note": "A página, e duas mudanças. Cada mudança responde `303 See Other`, que manda o navegador de volta à página com um `GET`, para que recarregar não envie o formulário de novo."}]}
```

### Os testes

Os testes escrevem a sessão da lucia diretamente, como na aula 1, e depois fazem o que um navegador
faz: carregam a página da conta, leem o que a página traz e enviam o formulário. `token_from_page` lê
o campo oculto do token no HTML da página, do jeito que um navegador o envia. Salve como
`test_app.py`:

```python
# test_app.py
import re

import pytest

import app as portal

EMAIL = "lucia@mail.example"


@pytest.fixture
def client():
    portal.ACCOUNTS["lucia"] = {"email": EMAIL, "phone": "+55 11 5555-0101"}
    client = portal.app.test_client()
    with client.session_transaction() as session:
        session["patient"] = "lucia"
    return client


def token_from_page(client):
    page = client.get("/account").get_data(as_text=True)
    found = re.search(r'name="csrf" value="([^"]+)"', page)
    return found.group(1) if found else None


def change_email(client, **extra):
    return client.post("/account/email", data={"email": "new@mail.example", **extra.pop("data", {})}, **extra)


def test_the_forms_carry_a_token(client):
    assert token_from_page(client)


def test_a_change_with_the_token_is_accepted(client):
    token = token_from_page(client)
    assert change_email(client, data={"csrf": token}).status_code == 303
    assert portal.ACCOUNTS["lucia"]["email"] == "new@mail.example"


def test_a_change_without_the_token_is_refused(client):
    assert change_email(client).status_code == 403
    assert portal.ACCOUNTS["lucia"]["email"] == EMAIL


def test_a_token_from_another_session_is_refused(client):
    other = portal.app.test_client()
    with other.session_transaction() as session:
        session["patient"] = "lucia"
    assert change_email(client, data={"csrf": token_from_page(other)}).status_code == 403


def test_every_change_needs_the_token(client):
    assert client.post("/account/phone", data={"phone": "+55 11 5555-0199"}).status_code == 403


def test_a_change_from_another_origin_is_refused(client):
    token = token_from_page(client)
    answer = change_email(client, data={"csrf": token}, headers={"Origin": "https://elsewhere.example"})
    assert answer.status_code == 403


def test_the_session_cookie_is_samesite_lax(client):
    cookie = client.get_cookie("session")
    assert cookie.same_site == "Lax"
    assert cookie.secure and cookie.http_only
```

**O terceiro teste é a requisição forjada, como o portal a recebe**: a sessão válida da lucia, uma
mudança bem formada, e nada que prove que a página dela a enviou. Não é preciso outro site para
mostrar a falha. Um cliente de teste mandando a mesma requisição é exatamente o que o portal veria.

### Vermelho

```
(.venv) ana@vm:~/sc/csrf$ pytest -q --tb=no
F.FFFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_forms_carry_a_token - AssertionError: assert None
FAILED test_app.py::test_a_change_without_the_token_is_refused - AssertionErr...
FAILED test_app.py::test_a_token_from_another_session_is_refused - AssertionE...
FAILED test_app.py::test_every_change_needs_the_token - AssertionError: asser...
FAILED test_app.py::test_a_change_from_another_origin_is_refused - assert 303...
FAILED test_app.py::test_the_session_cookie_is_samesite_lax - AssertionError:...
6 failed, 1 passed in 0.17s
```

**Seis de sete falham.** O que passa é uma mudança enviada com o token que a página tivesse, e a
primeira versão não tem nenhum e não confere nenhum, então aceita qualquer coisa. Faça o commit da
versão com falhas:

```
(.venv) ana@vm:~/sc/csrf$ git add app.py test_app.py
(.venv) ana@vm:~/sc/csrf$ git commit -q -m "Change the e-mail address and the phone number"
```
