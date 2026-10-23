---
title: Envio de exames e preferências, e oito testes
version: 1
---

Pacientes enviam os exames que o médico pediu, em PDF, e baixam de novo depois. O portal também lembra
o tamanho de texto preferido de cada paciente num cookie, para a configuração durar entre visitas no
mesmo navegador. A pasta desta aula é `~/sc/upload`:

```
(.venv) ana@vm:~/sc$ mkdir upload
(.venv) ana@vm:~/sc$ cd upload
(.venv) ana@vm:~/sc/upload$ git init -b main
Initialized empty Git repository in /home/ana/sc/upload/.git/
```

Esta é a primeira versão. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport base64\nimport pickle\nfrom pathlib import Path\n\nfrom flask import Flask, jsonify, request, send_from_directory\n\napp = Flask(__name__)\napp.config[\"UPLOADS\"] = Path(\"static/uploads\")\n\n", "note": "Os envios vão para `static/uploads`, dentro da pasta que o Flask serve a qualquer um em `/static/…`."}, {"code": "@app.post(\"/exams\")\ndef upload():\n    exam = request.files[\"exam\"]\n    folder = app.config[\"UPLOADS\"]\n    folder.mkdir(parents=True, exist_ok=True)\n    exam.save(folder / exam.filename)\n    return jsonify(id=exam.filename), 201\n\n", "note": "O envio guarda o arquivo com o nome que o navegador mandou, como caminho dentro da pasta."}, {"code": "@app.get(\"/exams/<name>\")\ndef download(name):\n    return send_from_directory(app.config[\"UPLOADS\"], name)\n\n", "note": "O download serve o arquivo por esse mesmo nome, com o tipo que o Flask deduzir dele."}, {"code": "@app.post(\"/preferences\")\ndef save_preferences():\n    prefs = {\"text_size\": request.form.get(\"text_size\", \"normal\")}\n    response = jsonify(prefs)\n    response.set_cookie(\"prefs\", base64.b64encode(pickle.dumps(prefs)).decode())\n    return response\n\n\n@app.get(\"/preferences\")\ndef read_preferences():\n    raw = request.cookies.get(\"prefs\")\n    prefs = pickle.loads(base64.b64decode(raw)) if raw else {\"text_size\": \"normal\"}\n    return jsonify(prefs)", "note": "O tamanho do texto, guardado num cookie como dicionário em pickle, e reconstruído de qualquer cookie que o navegador mande de volta."}]}
```

### O que o envio faz com um nome

Inicie o portal e, de um segundo terminal, crie um PDF pequeno e envie-o duas vezes: uma com o nome
dele, e uma com um nome com `../` na frente, como poderia mandar um cliente com defeito no tratamento
de caminhos. O `printf` escreve o arquivo (`%%` é como o `printf` escreve um `%`), o `curl -F` o manda
como um formulário de navegador manda, e o `filename=` define o nome que ele informa:

```
(.venv) ana@vm:~/sc/upload$ printf '%%PDF-1.7\n' > knee.pdf
(.venv) ana@vm:~/sc/upload$ curl -s -F 'exam=@knee.pdf' http://127.0.0.1:5000/exams
{"id":"knee.pdf"}
(.venv) ana@vm:~/sc/upload$ curl -s -F 'exam=@knee.pdf;filename=../escape.pdf' http://127.0.0.1:5000/exams
{"id":"../escape.pdf"}
(.venv) ana@vm:~/sc/upload$ ls static static/uploads
static:
escape.pdf
uploads

static/uploads:
knee.pdf
```

O segundo envio foi aceito como o primeiro, e o `ls` mostra o arquivo **fora** de `static/uploads`, em
`static`. O nome decidiu onde o arquivo foi gravado. Pare o portal com `Ctrl+C`.

### Os testes

Cinco testes para o envio e três para as preferências. O `upload` manda um arquivo do mesmo jeito que o
`curl -F` mandou. Salve como `test_app.py`:

```python
# test_app.py
import base64
import io
import json
import pickle

import pytest

import app as portal

PDF = b"%PDF-1.7\n1 0 obj << >> endobj\n"


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    portal.app.config["UPLOADS"] = tmp_path / "uploads"
    return portal.app.test_client()


def upload(client, name, content):
    return client.post("/exams", data={"exam": (io.BytesIO(content), name)})


def test_a_pdf_is_accepted(client):
    answer = upload(client, "knee.pdf", PDF)
    assert answer.status_code == 201
    assert client.get(f"/exams/{answer.json['id']}").data == PDF


def test_a_name_cannot_leave_the_upload_folder(client, tmp_path):
    upload(client, "../escape.pdf", PDF)
    assert not (tmp_path / "escape.pdf").exists()


def test_a_file_that_is_not_a_pdf_is_refused(client):
    assert upload(client, "scan.pdf", b"plain text, not a PDF").status_code == 400


def test_a_large_file_is_refused(client):
    assert upload(client, "big.pdf", PDF + b"0" * (6 * 1024 * 1024)).status_code == 413


def test_a_download_is_an_attachment(client):
    exam_id = upload(client, "knee.pdf", PDF).json["id"]
    answer = client.get(f"/exams/{exam_id}")
    assert answer.headers["Content-Disposition"].startswith("attachment")
    assert answer.headers["X-Content-Type-Options"] == "nosniff"


def test_preferences_are_kept(client):
    client.post("/preferences", data={"text_size": "large"})
    assert client.get("/preferences").json == {"text_size": "large"}


def test_preferences_travel_as_json(client):
    client.post("/preferences", data={"text_size": "large"})
    raw = client.get_cookie("prefs").value
    assert json.loads(base64.urlsafe_b64decode(raw)) == {"text_size": "large"}


def test_a_pickled_cookie_is_refused(client):
    client.set_cookie("prefs", base64.b64encode(pickle.dumps({"text_size": "large"})).decode())
    assert client.get("/preferences").status_code == 400
```

O último teste monta ele mesmo um cookie em pickle, com nada além do tamanho do texto, para
representar qualquer pickle que um navegador possa mandar. **Ele não precisa de conteúdo nocivo para
provar o ponto**: se o portal responde `200`, rodou `pickle.loads` em bytes vindos da requisição, e essa
é a falha, digam os bytes o que disserem.

### Vermelho

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=no
.FFFF.FF                                                                 [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_name_cannot_leave_the_upload_folder - AssertionErr...
FAILED test_app.py::test_a_file_that_is_not_a_pdf_is_refused - AssertionError...
FAILED test_app.py::test_a_large_file_is_refused - AssertionError: assert 201...
FAILED test_app.py::test_a_download_is_an_attachment - AssertionError: assert...
FAILED test_app.py::test_preferences_travel_as_json - UnicodeDecodeError: 'ut...
FAILED test_app.py::test_a_pickled_cookie_is_refused - AssertionError: assert...
6 failed, 2 passed in 0.24s
```

**Seis de oito falham.** Faça o commit da versão com falhas:

```
(.venv) ana@vm:~/sc/upload$ git add app.py test_app.py
(.venv) ana@vm:~/sc/upload$ git commit -q -m "Exam uploads and text-size preferences"
```
