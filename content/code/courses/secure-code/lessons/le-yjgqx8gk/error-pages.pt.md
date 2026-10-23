---
title: Uma página de erro que fala demais
version: 1
---

A aplicação desta aula é um pedaço do portal com os dois problemas: uma rota que falha para um
paciente que não existe, e um login que registra em log o que recebe. Crie a pasta como antes:

```
(.venv) ana@vm:~/sc$ mkdir errors
(.venv) ana@vm:~/sc$ cd errors
(.venv) ana@vm:~/sc/errors$ git init -b main
Initialized empty Git repository in /home/ana/sc/errors/.git/
```

Salve isto como `app.py`:

```python
# app.py
import logging
import traceback

from flask import Flask, request
from werkzeug.exceptions import HTTPException
from werkzeug.security import check_password_hash, generate_password_hash

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")
log = logging.getLogger("portal")

app = Flask(__name__)
USERS = {"lucia": generate_password_hash("correct horse battery staple")}
PHONES = {"lucia": "11987654321"}


@app.errorhandler(Exception)
def unexpected(error):
    if isinstance(error, HTTPException):
        return error
    return {"error": traceback.format_exc()}, 500


@app.post("/login")
def login():
    name = request.form.get("name", "")
    password = request.form.get("password", "")
    log.info("sign-in attempt name=%s password=%s", name, password)
    if name in USERS and check_password_hash(USERS[name], password):
        return {"signed_in": name}
    return {"error": "wrong name or password"}, 401


@app.get("/patients/<name>/phone")
def phone(name):
    return {"phone": PHONES[name]}
```

O tratador de erros foi escrito com boa intenção: quando algo quebra, a equipe de suporte quer saber
o quê, então a página traz o traceback inteiro. Inicie a aplicação com a saída indo para um arquivo,
para ler o log depois, e peça o telefone de quem não existe, e depois entre na conta:

```
(.venv) ana@vm:~/sc/errors$ flask --app app run > server.log 2>&1 &
(.venv) ana@vm:~/sc/errors$ curl -s http://127.0.0.1:5000/patients/marta/phone
{"error":"Traceback (most recent call last):\n  File \"/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^\n  File \"/home/ana/sc/errors/app.py\", line 36, in phone\n    return {\"phone\": PHONES[name]}\n                     ~~~~~~^^^^^^\nKeyError: 'marta'\n"}
(.venv) ana@vm:~/sc/errors$ curl -s -d 'name=lucia&password=correct horse battery staple' http://127.0.0.1:5000/login
{"signed_in":"lucia"}
(.venv) ana@vm:~/sc/errors$ grep portal server.log
INFO portal sign-in attempt name=lucia password=correct horse battery staple
```

Leia a primeira resposta como um estranho leria. Ela nomeia o framework e os caminhos dos arquivos
dele, a pasta de onde o portal roda, o nome do dicionário que guarda os telefones e a linha de código
que falhou. **Nada disso ajuda quem perguntou**, que precisava ouvir que algo deu errado e o que fazer
a seguir, e tudo isso ajuda alguém mapeando o portal de fora. O terceiro comando mostra a outra
metade: o log do servidor guarda a senha que a lucia digitou, em texto puro, ao lado do nome dela.

### Os testes

Quatro testes, dois para a página e dois para o log. `caplog` é a fixture do pytest para ler o que foi
registrado durante um teste, e a fixture `client` pede que ele guarde as mensagens do logger do portal
de nível INFO para cima. Salve como `test_app.py`:

```python
# test_app.py
import logging

import pytest

import app as portal


@pytest.fixture
def client(caplog):
    caplog.set_level(logging.INFO, logger="portal")
    return portal.app.test_client()


def test_an_error_page_shows_no_internals(client):
    response = client.get("/patients/marta/phone")
    assert response.status_code == 500
    body = response.get_data(as_text=True)
    assert "Traceback" not in body
    assert "app.py" not in body


def test_the_log_keeps_what_the_page_does_not(client, caplog):
    response = client.get("/patients/marta/phone")
    reference = response.get_json()["reference"]
    assert f"ref={reference}" in caplog.text
    assert "KeyError" in caplog.text


def test_a_password_is_never_logged(client, caplog):
    client.post("/login", data={"name": "lucia", "password": "correct horse battery staple"})
    assert "correct horse" not in caplog.text


def test_one_attempt_is_one_line_of_log(client, caplog):
    client.post("/login", data={"name": "lucia\nsecond line", "password": "x"})
    assert "\nsecond line" not in caplog.text
```

```
(.venv) ana@vm:~/sc/errors$ pytest -q --tb=no
FFFF                                                                     [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_an_error_page_shows_no_internals - assert 'Traceback...
FAILED test_app.py::test_the_log_keeps_what_the_page_does_not - KeyError: 're...
FAILED test_app.py::test_a_password_is_never_logged - AssertionError: assert ...
FAILED test_app.py::test_one_attempt_is_one_line_of_log - AssertionError: ass...
4 failed in 0.30s
```

Os quatro falham. O segundo falha com `KeyError` em `reference`: a página antiga não traz referência
que um paciente possa ditar, então não há o que procurar no log. Faça commit como está:

```
(.venv) ana@vm:~/sc/errors$ git add app.py test_app.py
(.venv) ana@vm:~/sc/errors$ git commit -q -m "Show phones, and log sign-ins"
```
