---
title: Os resultados de exame, e um teste que pede tudo
version: 1
---

Pacientes enviam os exames que o médico pediu, uma ressonância ou um raio X, para a fisioterapeuta os
ver antes da sessão. O portal lista os exames de uma paciente, mostra um, e deixa que ela apague um
que enviou por engano. A pasta desta aula é `~/sc/exams`:

```
(.venv) ana@vm:~/sc$ mkdir exams
(.venv) ana@vm:~/sc$ cd exams
(.venv) ana@vm:~/sc/exams$ git init -b main
Initialized empty Git repository in /home/ana/sc/exams/.git/
```

Esta é a primeira aplicação do curso a guardar os dados em **SQLite**, pelo módulo `sqlite3` que já
vem com o Python, porque a falha mora numa consulta. Os valores chegam a cada consulta por marcadores
`?`, nunca montando a string do SQL; a aula 5 explica por quê. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, jsonify, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\napp.config[\"DATABASE\"] = \"exams.db\"\n", "note": "O banco é um arquivo, `exams.db`, nomeado na configuração da aplicação para um teste poder apontá-lo para outro lugar."}, {"code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS exams (\n    id INTEGER PRIMARY KEY,\n    patient TEXT NOT NULL,\n    title TEXT NOT NULL,\n    taken TEXT NOT NULL\n)\n\"\"\"\nSAMPLE = [\n    (\"lucia\", \"Knee MRI\", \"2026-10-28\"),\n    (\"marta\", \"Lumbar spine X-ray\", \"2026-10-30\"),\n    (\"rafael\", \"Shoulder ultrasound\", \"2026-11-02\"),\n]\n\n", "note": "Uma tabela. `id` é `INTEGER PRIMARY KEY`, então o SQLite numera os exames 1, 2, 3 na ordem em que chegam. Cada linha sabe de que paciente é."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(app.config[\"DATABASE\"])\n        g.db.row_factory = sqlite3.Row\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(error):\n    connection = g.pop(\"db\", None)\n    if connection is not None:\n        connection.close()\n\n\ndef init_db():\n    with app.app_context():\n        db().execute(SCHEMA)\n        if db().execute(\"SELECT count(*) FROM exams\").fetchone()[0] == 0:\n            db().executemany(\"INSERT INTO exams (patient, title, taken) VALUES (?, ?, ?)\", SAMPLE)\n        db().commit()\n\n", "note": "O padrão de sempre do Flask: uma conexão por requisição, guardada em `g` e fechada quando a requisição termina. `init_db` cria a tabela e os três exames de exemplo se a tabela estiver vazia."}, {"code": "def signed_in():\n    name = session.get(\"patient\")\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "A verificação de sessão da aula 1: alguém está logado, e este é o nome."}, {"code": "@app.get(\"/exams\")\ndef list_exams():\n    name = request.args.get(\"patient\", signed_in())\n    rows = db().execute(\"SELECT id, title, taken FROM exams WHERE patient = ?\", (name,))\n    return jsonify([dict(row) for row in rows])\n\n", "note": "A lista: os exames do paciente logado, a não ser que a requisição nomeie outro. O console da equipe queria reaproveitar esta rota."}, {"code": "@app.get(\"/exams/<int:exam_id>\")\ndef read_exam(exam_id):\n    signed_in()\n    row = db().execute(\"SELECT id, title, taken FROM exams WHERE id = ?\", (exam_id,)).fetchone()\n    if row is None:\n        abort(404)\n    return jsonify(dict(row))\n\n\n@app.delete(\"/exams/<int:exam_id>\")\ndef delete_exam(exam_id):\n    signed_in()\n    db().execute(\"DELETE FROM exams WHERE id = ?\", (exam_id,))\n    db().commit()\n    return \"\", 204", "note": "Um exame, lido ou apagado pelo id. As duas rotas exigem que alguém esteja logado. Leia as consultas e procure o paciente."}]}
```

### Os testes

A fixture dá a cada teste um banco novo no `tmp_path` do pytest, uma pasta temporária só dele, para
nenhum teste ver o que outro apagou. `OWNERS` anota quem é dono de cada exame de exemplo. Salve como
`test_app.py`:

```python
# test_app.py
import pytest

import app as portal

OWNERS = {1: "lucia", 2: "marta", 3: "rafael"}


@pytest.fixture
def client(tmp_path):
    portal.app.config["DATABASE"] = tmp_path / "exams.db"
    portal.init_db()
    return portal.app.test_client()


def sign_in(client, name):
    with client.session_transaction() as session:
        session["patient"] = name


def test_a_patient_reads_her_own_exam(client):
    sign_in(client, "lucia")
    assert client.get("/exams/1").json["title"] == "Knee MRI"


def test_somebody_elses_exam_looks_like_no_exam(client):
    sign_in(client, "lucia")
    other, missing = client.get("/exams/2"), client.get("/exams/999")
    assert other.status_code == missing.status_code == 404
    assert other.get_data() == missing.get_data()


def test_a_patient_cannot_delete_somebody_elses_exam(client):
    sign_in(client, "lucia")
    assert client.delete("/exams/2").status_code == 404
    sign_in(client, "marta")
    assert client.get("/exams/2").status_code == 200


def test_the_list_shows_only_her_own_exams(client):
    sign_in(client, "lucia")
    titles = [exam["title"] for exam in client.get("/exams?patient=marta").json]
    assert titles == ["Knee MRI"]


@pytest.mark.parametrize("name", ["lucia", "marta", "rafael"])
def test_each_exam_answers_only_its_owner(client, name):
    sign_in(client, name)
    answers = {exam_id: client.get(f"/exams/{exam_id}").status_code for exam_id in OWNERS}
    assert answers == {exam_id: 200 if owner == name else 404 for exam_id, owner in OWNERS.items()}
```

O último teste é o que vale guardar em todo projeto. **Ele não testa uma requisição proibida; testa a
grade inteira**: cada paciente pede cada exame, e os únicos `200` permitidos estão na diagonal, onde o
paciente é o dono. Três pacientes e três exames dão nove requisições, e acrescentar um quarto exame em
`OWNERS` acrescenta mais quatro.

### Vermelho

```
(.venv) ana@vm:~/sc/exams$ pytest -q --tb=no
.FFFFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_somebody_elses_exam_looks_like_no_exam - assert 200 ...
FAILED test_app.py::test_a_patient_cannot_delete_somebody_elses_exam - Assert...
FAILED test_app.py::test_the_list_shows_only_her_own_exams - AssertionError: ...
FAILED test_app.py::test_each_exam_answers_only_its_owner[lucia] - assert {1:...
FAILED test_app.py::test_each_exam_answers_only_its_owner[marta] - assert {1:...
FAILED test_app.py::test_each_exam_answers_only_its_owner[rafael] - assert {1...
6 failed, 1 passed in 0.19s
```

**Seis de sete falham.** Só o primeiro passa, e é o único teste que pede os próprios dados. Rode a
grade para um paciente só e leia o que o portal respondeu:

```
(.venv) ana@vm:~/sc/exams$ pytest -q --tb=short -k 'owner and rafael'
F                                                                        [100%]
=================================== FAILURES ===================================
________________ test_each_exam_answers_only_its_owner[rafael] _________________
test_app.py:50: in test_each_exam_answers_only_its_owner
    assert answers == {exam_id: 200 if owner == name else 404 for exam_id, owner in OWNERS.items()}
E   assert {1: 200, 2: 200, 3: 200} == {1: 404, 2: 404, 3: 200}
E     
E     Omitting 1 identical items, use -vv to show
E     Differing items:
E     {1: 200} != {1: 404}
E     {2: 200} != {2: 404}
E     Use -v to get more diff
=========================== short test summary info ============================
FAILED test_app.py::test_each_exam_answers_only_its_owner[rafael] - assert {1...
1 failed, 6 deselected in 0.17s
```

O rafael pediu três exames e recebeu três, dois deles de outras pessoas. Faça o commit da versão com
falhas:

```
(.venv) ana@vm:~/sc/exams$ git add app.py test_app.py
(.venv) ana@vm:~/sc/exams$ git commit -q -m "List, show and delete a patient's exams"
```
