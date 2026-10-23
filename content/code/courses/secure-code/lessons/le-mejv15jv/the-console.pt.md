---
title: O console da equipe, e o que um recepcionista alcança
version: 1
---

O console da equipe é onde o pessoal da Vereda trabalha. **bruno** é recepcionista: cuida da agenda.
**carla** é fisioterapeuta: lê e escreve notas clínicas. **ana** é a administradora. A pasta desta
aula é `~/sc/console`:

```
(.venv) ana@vm:~/sc$ mkdir console
(.venv) ana@vm:~/sc$ cd console
(.venv) ana@vm:~/sc/console$ git init -b main
Initialized empty Git repository in /home/ana/sc/console/.git/
```

Este é o console como foi escrito primeiro. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport secrets\n\nfrom flask import Flask, abort, jsonify, render_template_string, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\nSTAFF = {\"bruno\": \"reception\", \"carla\": \"physio\", \"ana\": \"admin\"}\nNOTES = {\"lucia\": [\"Left knee: range of motion improving.\"]}\nAGENDA = [{\"patient\": \"lucia\", \"starts\": \"2026-11-11 09:00\", \"with\": \"carla\"}]\n", "note": "`STAFF` é a tabela do servidor com o papel de cada pessoa. Notas e agenda ficam em memória para o programa caber na página."}, {"code": "PAGE = \"\"\"<h1>Vereda console</h1>\n<p>Signed in as {{ name }}</p>\n<ul>\n  <li><a href=\"/agenda\">Agenda</a></li>\n  {% if role == \"physio\" %}\n  <li><a href=\"/patients/lucia/notes\">Clinical notes</a></li>\n  {% endif %}\n</ul>\n{% if role == \"physio\" %}\n<form method=\"post\" action=\"/patients/lucia/notes\">\n  <input type=\"hidden\" name=\"role\" value=\"physio\">\n  <textarea name=\"text\"></textarea>\n  <button>Add note</button>\n</form>\n{% endif %}\n\"\"\"\n\n", "note": "A página do console. Uma fisioterapeuta vê o link das notas e um formulário para acrescentar uma; os demais não veem nenhum dos dois. Repare no campo oculto: o formulário diz ao servidor quem o está enviando."}, {"code": "def signed_in():\n    name = session.get(\"staff\")\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "A única verificação do programa: alguém está logado? Não diz nada sobre quem."}, {"code": "@app.get(\"/console\")\ndef console():\n    name = signed_in()\n    return render_template_string(PAGE, name=name, role=STAFF.get(name))\n\n\n@app.get(\"/agenda\")\ndef agenda():\n    signed_in()\n    return jsonify(AGENDA)\n\n", "note": "O console e a agenda, para qualquer pessoa da equipe."}, {"code": "@app.get(\"/patients/<name>/notes\")\ndef read_notes(name):\n    signed_in()\n    return jsonify(NOTES.get(name, []))\n\n\n@app.post(\"/patients/<name>/notes\")\ndef add_note(name):\n    signed_in()\n    if request.form.get(\"role\") != \"physio\":\n        abort(403)\n    NOTES.setdefault(name, []).append(request.form[\"text\"])\n    return jsonify(NOTES[name]), 201\n\n", "note": "Ler notas pergunta só `signed_in()`, confiando que a página escondeu o link. Acrescentar uma nota confere um papel, e o tira do formulário."}, {"code": "@app.get(\"/export\")\ndef export():\n    rows = [f\"{patient},{len(notes)}\" for patient, notes in NOTES.items()]\n    return \"\\n\".join([\"patient,notes\", *rows]) + \"\\n\", {\"Content-Type\": \"text/csv\"}", "note": "Um CSV para um relatório mensal, escrito numa tarde. Procure a verificação dele."}]}
```

### O que uma requisição mostra

Inicie com `flask --app app run`, como na aula 1, e de um segundo terminal peça a exportação sem
sessão nenhuma, como qualquer programa poderia:

```
(.venv) ana@vm:~/sc/console$ curl -si http://127.0.0.1:5000/export
HTTP/1.1 200 OK
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:23:11 GMT
Content-Type: text/csv
Content-Length: 22
Connection: close

patient,notes
lucia,1
```

`200 OK`, e a lista de pacientes com notas clínicas. Ninguém logado, nada escondido desta
requisição, porque nada nunca foi perguntado a ela. Pare o servidor com `Ctrl+C`.

### Os testes

O login é assunto das aulas 10 e 11, então estes testes escrevem a sessão diretamente, como os da
aula 1. Salve como `test_app.py`:

```python
# test_app.py
import pytest

import app as portal


@pytest.fixture
def client():
    portal.NOTES.clear()
    portal.NOTES["lucia"] = ["Left knee: range of motion improving."]
    return portal.app.test_client()


def sign_in(client, name):
    with client.session_transaction() as session:
        session["staff"] = name


def test_a_physiotherapist_reads_clinical_notes(client):
    sign_in(client, "carla")
    assert client.get("/patients/lucia/notes").status_code == 200


def test_the_console_hides_notes_from_a_receptionist(client):
    sign_in(client, "bruno")
    assert "Clinical notes" not in client.get("/console").get_data(as_text=True)


def test_a_receptionist_cannot_read_clinical_notes(client):
    sign_in(client, "bruno")
    assert client.get("/patients/lucia/notes").status_code == 403


def test_the_role_comes_from_the_server_not_the_form(client):
    sign_in(client, "bruno")
    answer = client.post("/patients/lucia/notes", data={"role": "physio", "text": "added by bruno"})
    assert answer.status_code == 403
    assert portal.NOTES["lucia"] == ["Left knee: range of motion improving."]


def test_nobody_signed_in_gets_the_export(client):
    assert client.get("/export").status_code == 401


def test_every_route_says_who_may_use_it():
    open_routes = [
        rule.rule
        for rule in portal.app.url_map.iter_rules()
        if rule.endpoint != "static"
        and not hasattr(portal.app.view_functions[rule.endpoint], "allowed_roles")
    ]
    assert not open_routes, f"no rule says who may use {open_routes}"
```

O segundo teste está ali de propósito, e **passa**: o console esconde mesmo o link do bruno. O
terceiro teste pede as mesmas notas pelo endereço, e o quarto manda o formulário com o campo oculto
preenchido, exatamente o que a página mandaria para a carla. O último é o assunto da quarta seção.

### Vermelho

```
(.venv) ana@vm:~/sc/console$ pytest -q --tb=no
..FFFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_receptionist_cannot_read_clinical_notes - Assertio...
FAILED test_app.py::test_the_role_comes_from_the_server_not_the_form - assert...
FAILED test_app.py::test_nobody_signed_in_gets_the_export - AssertionError: a...
FAILED test_app.py::test_every_route_says_who_may_use_it - AssertionError: no...
4 failed, 2 passed in 0.13s
```

**Dois passam, quatro falham**, e os dois que passam são a fisioterapeuta lendo suas notas e o link
que não é desenhado. Toda conferência que uma pessoa faria clicando pelo console passa. Toda falha é
uma requisição que as telas do próprio console nunca mandam. Faça o commit da versão com falhas:

```
(.venv) ana@vm:~/sc/console$ git add app.py test_app.py
(.venv) ana@vm:~/sc/console$ git commit -q -m "Staff console: agenda, clinical notes and the export"
```
