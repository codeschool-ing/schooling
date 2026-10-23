---
title: Três recursos do console, e seis testes
version: 1
---

O console da equipe tem três recursos pequenos que entregam texto a um interpretador. Um informa o
tipo de arquivo de um exame que um paciente enviou, rodando o comando `file`. Um procura uma pessoa da
equipe no diretório da Vereda, que fala **LDAP**. Um mostra a prévia do lembrete que um paciente vai
receber, com um recado que a recepcionista acrescenta. A pasta desta aula é `~/sc/exams-convert`:

```
(.venv) ana@vm:~/sc$ mkdir exams-convert
(.venv) ana@vm:~/sc$ cd exams-convert
(.venv) ana@vm:~/sc/exams-convert$ git init -b main
Initialized empty Git repository in /home/ana/sc/exams-convert/.git/
```

O diretório é um cliente LDAP de verdade, o `ldap3`, falando com o **servidor simulado** que o próprio
`ldap3` traz para testes: ele responde a buscas a partir de entradas que o programa acrescenta ao
iniciar, então nada fora da sua máquina participa. Instale:

```
(.venv) ana@vm:~/sc/exams-convert$ pip install --progress-bar off ldap3==2.9.1
Collecting ldap3==2.9.1
  Using cached ldap3-2.9.1-py2.py3-none-any.whl.metadata (5.4 kB)
Collecting pyasn1>=0.4.6 (from ldap3==2.9.1)
  Using cached pyasn1-0.6.4-py3-none-any.whl.metadata (8.4 kB)
Using cached ldap3-2.9.1-py2.py3-none-any.whl (432 kB)
Using cached pyasn1-0.6.4-py3-none-any.whl (84 kB)
Installing collected packages: pyasn1, ldap3
Successfully installed ldap3-2.9.1 pyasn1-0.6.4
```

Este é o console. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport subprocess\nfrom pathlib import Path\n\nfrom flask import Flask, jsonify, render_template_string, request\nfrom ldap3 import MOCK_SYNC, Connection, Server\n\napp = Flask(__name__)\nEXAMS = Path(\"exams\")\nSTAFF = [(\"bruno\", \"reception\"), (\"carla\", \"physio\"), (\"ana\", \"admin\")]\n\n", "note": "Os exames ficam numa pasta chamada `exams`; o diretório guarda as três pessoas da equipe da aula 12."}, {"code": "def directory():\n    connection = Connection(\n        Server(\"ldap.vereda.example\"),\n        user=\"cn=portal,ou=apps,dc=vereda,dc=example\",\n        password=\"test-only\",\n        client_strategy=MOCK_SYNC,\n    )\n    for name, role in STAFF:\n        connection.strategy.add_entry(\n            f\"cn={name},ou=staff,dc=vereda,dc=example\",\n            {\"objectClass\": \"person\", \"cn\": name, \"sn\": name, \"title\": role},\n        )\n    connection.bind()\n    return connection\n\n", "note": "O `MOCK_SYNC` faz o `ldap3` responder a partir de entradas acrescentadas aqui, em memória. O código que busca é o que buscaria num diretório de verdade; só esta função mudaria."}, {"code": "@app.get(\"/exams/<path:name>/type\")\ndef exam_type(name):\n    result = subprocess.run(\n        f\"file --brief --mime-type exams/{name}\", shell=True, capture_output=True, text=True\n    )\n    return jsonify(name=name, type=result.stdout.strip())\n\n", "note": "O tipo de arquivo de um exame, pelo comando `file`. A linha de comando é montada com f-string e entregue ao shell."}, {"code": "@app.get(\"/staff\")\ndef find_staff():\n    connection = directory()\n    connection.search(\n        \"ou=staff,dc=vereda,dc=example\", f\"(cn={request.args['name']})\", attributes=[\"cn\", \"title\"]\n    )\n    return jsonify([{\"name\": str(e.cn), \"role\": str(e.title)} for e in connection.entries])\n\n", "note": "Uma busca de pessoa da equipe pelo nome. O filtro LDAP `(cn=…)` é montado com f-string."}, {"code": "@app.post(\"/reminders/preview\")\ndef preview():\n    note = request.form.get(\"note\", \"\")\n    page = render_template_string(\n        \"<p>Hello {{ patient }}, see you on {{ day }}.</p><p>\" + note + \"</p>\",\n        patient=\"lucia\",\n        day=\"Monday 16 November\",\n    )\n    return page", "note": "A prévia do lembrete. `patient` e `day` são variáveis do template; o recado é emendado no texto do template."}]}
```

### Os testes

Três testes que já passam, um por recurso, e três que pedem a cada recurso que trate um valor comum
como dado. Salve como `test_app.py`:

```python
# test_app.py
import pytest

import app as portal


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "exams").mkdir()
    (tmp_path / "exams" / "knee.pdf").write_bytes(b"%PDF-1.7\n")
    (tmp_path / "exams" / "knee scan.pdf").write_bytes(b"%PDF-1.7\n")
    return portal.app.test_client()


def test_an_exam_type_is_found(client):
    assert client.get("/exams/knee.pdf/type").json["type"] == "application/pdf"


def test_a_name_with_spaces_is_one_file(client):
    assert client.get("/exams/knee scan.pdf/type").json["type"] == "application/pdf"


def test_a_name_finds_that_person(client):
    assert client.get("/staff?name=carla").json == [{"name": "carla", "role": "physio"}]


def test_a_star_is_a_character_not_everyone(client):
    assert client.get("/staff?name=*").json == []


def test_parentheses_in_a_name_are_searched_for(client):
    assert client.get("/staff", query_string={"name": "Silva (Pinheiros)"}).json == []


def test_a_note_is_shown_as_written(client):
    note = "Please bring {{ the referral }} from your doctor."
    page = client.post("/reminders/preview", data={"note": note}).get_data(as_text=True)
    assert "Hello lucia" in page
    assert "Please bring {{ the referral }} from your doctor." in page
```

A fixture roda cada teste no `tmp_path` do pytest com dois arquivos de exame numa pasta `exams`,
escritos com os primeiros bytes de um PDF para o `file` reconhecê-los. O `monkeypatch.chdir` faz dessa
pasta a pasta atual, para o caminho relativo `exams/` do `app.py` achá-los.

O `ldap3` 2.9.1 usa dois nomes que o `pyasn1` atual marcou como obsoletos, e o pytest imprimiria um
aviso sobre cada um em toda execução. O aviso é sobre a biblioteca, não sobre este código, então um
`pytest.ini` pequeno silencia exatamente esses dois, **pelo texto**, e qualquer outro aviso continua
aparecendo:

```ini
# pytest.ini
[pytest]
filterwarnings =
    ignore:tagMap is deprecated:DeprecationWarning
    ignore:typeMap is deprecated:DeprecationWarning
```

### Vermelho

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=no
.F.FFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_name_with_spaces_is_one_file - AssertionError: ass...
FAILED test_app.py::test_a_star_is_a_character_not_everyone - AssertionError:...
FAILED test_app.py::test_parentheses_in_a_name_are_searched_for - AssertionEr...
FAILED test_app.py::test_a_note_is_shown_as_written - AssertionError: assert ...
4 failed, 2 passed in 0.18s
```

**Quatro de seis falham**, uma no shell, duas no diretório, uma no template. Faça o commit da versão
com falhas, e trate-as um interpretador de cada vez:

```
(.venv) ana@vm:~/sc/exams-convert$ git add app.py test_app.py pytest.ini
(.venv) ana@vm:~/sc/exams-convert$ git commit -q -m "Exam types, staff lookup and reminder preview"
```
