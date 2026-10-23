---
title: As senhas do portal, e nove testes
version: 1
---

A pasta desta aula é `~/sc/passwords`, um repositório git próprio, como na aula 1:

```
(.venv) ana@vm:~/sc$ mkdir passwords
(.venv) ana@vm:~/sc$ cd passwords
(.venv) ana@vm:~/sc/passwords$ git init -b main
Initialized empty Git repository in /home/ana/sc/passwords/.git/
```

Este é o código de contas do portal como a ana o escreveu primeiro. Guarda um SHA-256 de cada senha,
confere uma senha nova com as regras de composição que muitos sites ainda usam, e mantém as sessões
como a aula 10 as deixou, sem a expiração, para a página ficar curta. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport hashlib\nimport secrets\n\nfrom flask import Flask, abort, jsonify, request\n\napp = Flask(__name__)\nUSERS = {}\nSESSIONS = {}\n\n", "note": "Duas tabelas: o que fica guardado da senha de cada paciente, e as sessões, de um id aleatório para um nome, como na aula 10."}, {"code": "def set_password(name, password):\n    USERS[name] = hashlib.sha256(password.encode()).hexdigest()\n\n\ndef password_is_right(name, password):\n    return USERS[name] == hashlib.sha256(password.encode()).hexdigest()\n\n", "note": "Guardada como SHA-256, e conferida aplicando o mesmo hash à tentativa. É de mão única, e não parece nada. Guarde as duas impressões para o primeiro teste."}, {"code": "def policy_problem(password):\n    if len(password) < 8:\n        return \"use at least 8 characters\"\n    if not any(c.isupper() for c in password):\n        return \"add an uppercase letter\"\n    if not any(c.isdigit() for c in password):\n        return \"add a digit\"\n    if password.isalnum():\n        return \"add a symbol\"\n    return None\n\n", "note": "A política responde `None` para uma senha aceitável e uma frase para o paciente nos outros casos. São as regras de composição que muitos sites ainda usam."}, {"code": "def current_patient():\n    name = SESSIONS.get(request.cookies.get(\"sid\"))\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "A conferência de sessão da aula 10, sem os dois relógios."}, {"code": "@app.post(\"/sign-in\")\ndef sign_in():\n    name = request.form.get(\"name\", \"\")\n    if name not in USERS:\n        return jsonify(error=\"no such patient\"), 404\n    if not password_is_right(name, request.form.get(\"password\", \"\")):\n        return jsonify(error=\"wrong password\"), 401\n    sid = secrets.token_urlsafe(32)\n    SESSIONS[sid] = name\n    response = jsonify(patient=name)\n    response.set_cookie(\"sid\", sid, httponly=True, secure=True, samesite=\"Lax\")\n    return response\n\n", "note": "Duas mensagens de erro prestativas. Leia como um estranho leria: uma delas diz se um nome é de um paciente."}, {"code": "@app.get(\"/me\")\ndef me():\n    return jsonify(patient=current_patient())\n\n", "note": "A menor página que exige sessão, para um teste perguntar se uma ainda vale."}, {"code": "@app.post(\"/password\")\ndef change_password():\n    name = current_patient()\n    if not password_is_right(name, request.form.get(\"current\", \"\")):\n        return jsonify(error=\"wrong password\"), 401\n    new = request.form.get(\"new\", \"\")\n    problem = policy_problem(new)\n    if problem:\n        return jsonify(error=problem), 400\n    set_password(name, new)\n    return jsonify(changed=True)", "note": "Trocar a senha pede a atual, confere a nova com a política e a guarda. Pergunte o que acontece com as outras sessões da paciente."}]}
```

### Os testes

Os testes abaixo dizem cinco coisas. Uma senha é guardada como hash Argon2id. Dois pacientes com a
mesma senha ficam guardados de forma diferente. O nome de um estranho recebe exatamente a mesma
resposta que uma senha errada. A política aceita uma frase longa e recusa senhas curtas ou fáceis de
adivinhar. E uma senha trocada encerra toda outra sessão daquela conta, o teste que a aula 10
prometeu. Salve como `test_app.py`:

```python
# test_app.py
import pytest

import app as portal

PASSWORD = "lilac river morning tea"


@pytest.fixture
def client():
    portal.USERS.clear()
    portal.SESSIONS.clear()
    portal.set_password("lucia", PASSWORD)
    portal.set_password("rafael", PASSWORD)
    return portal.app.test_client()


def sign_in(client, name="lucia", password=PASSWORD):
    return client.post("/sign-in", data={"name": name, "password": password})


def test_a_patient_signs_in_with_the_right_password(client):
    assert sign_in(client).status_code == 200


def test_the_password_is_stored_as_an_argon2id_hash(client):
    stored = portal.USERS["lucia"]
    assert stored.startswith("$argon2id$")
    assert "lilac" not in stored


def test_the_same_password_is_stored_differently(client):
    assert portal.USERS["lucia"] != portal.USERS["rafael"]


def test_an_unknown_name_looks_like_a_wrong_password(client):
    unknown = sign_in(client, name="nobody")
    wrong = sign_in(client, password="not the password at all")
    assert unknown.status_code == wrong.status_code == 401
    assert unknown.json == wrong.json


@pytest.mark.parametrize("password, accepted", [
    ("lilac river morning tea", True),
    ("Vereda2026!", False),
    ("Vereda@2026Vereda!", False),
    ("passwordpassword", False),
])
def test_the_password_policy(password, accepted):
    assert (portal.policy_problem(password) is None) == accepted


def test_changing_the_password_ends_the_other_sessions(client):
    laptop, phone = client, portal.app.test_client()
    sign_in(laptop)
    sign_in(phone)
    answer = laptop.post("/password", data={"current": PASSWORD, "new": "seven quiet harbour lamps"})
    assert answer.status_code == 200
    assert phone.get("/me").status_code == 401
    assert laptop.get("/me").status_code == 200
```

O `@pytest.mark.parametrize` roda `test_the_password_policy` uma vez por par, e o pytest relata cada
execução numa linha própria com a senha no nome, então uma falha diz qual senha a política errou.
São nove testes a partir de seis funções.

### Vermelho

```
(.venv) ana@vm:~/sc/passwords$ pytest -q --tb=no
.FFFFFF.F                                                                [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_password_is_stored_as_an_argon2id_hash - Asserti...
FAILED test_app.py::test_the_same_password_is_stored_differently - AssertionE...
FAILED test_app.py::test_an_unknown_name_looks_like_a_wrong_password - assert...
FAILED test_app.py::test_the_password_policy[lilac river morning tea-True] - ...
FAILED test_app.py::test_the_password_policy[Vereda2026!-False] - AssertionEr...
FAILED test_app.py::test_the_password_policy[Vereda@2026Vereda!-False] - Asse...
FAILED test_app.py::test_changing_the_password_ends_the_other_sessions - asse...
7 failed, 2 passed in 0.15s
```

**Sete de nove falham.** Os dois que passam são os que uma conferência manual faria: a lucia entra
com a senha dela, e a política recusa `passwordpassword`, mas só porque falta uma letra maiúscula.
Faça o commit da versão com falhas:

```
(.venv) ana@vm:~/sc/passwords$ git add app.py test_app.py
(.venv) ana@vm:~/sc/passwords$ git commit -q -m "Store passwords and check the policy"
```
