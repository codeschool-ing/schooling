---
title: Three console features, and six tests
version: 1
---

The staff console has three small features that each hand text to an interpreter. One reports the
file type of an exam a patient uploaded, by running the `file` command. One looks up a member of
staff in Vereda's directory, which speaks **LDAP**. One previews the reminder a patient will receive,
with a note the receptionist adds. This lesson's folder is `~/sc/exams-convert`:

```
(.venv) ana@vm:~/sc$ mkdir exams-convert
(.venv) ana@vm:~/sc$ cd exams-convert
(.venv) ana@vm:~/sc/exams-convert$ git init -b main
Initialized empty Git repository in /home/ana/sc/exams-convert/.git/
```

The directory is a real LDAP client, `ldap3`, talking to the **mock server** that `ldap3` includes for
testing: it answers searches from entries the program adds at start, so nothing outside your
machine is involved. Install it:

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

Here is the console. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport subprocess\nfrom pathlib import Path\n\nfrom flask import Flask, jsonify, render_template_string, request\nfrom ldap3 import MOCK_SYNC, Connection, Server\n\napp = Flask(__name__)\nEXAMS = Path(\"exams\")\nSTAFF = [(\"bruno\", \"reception\"), (\"carla\", \"physio\"), (\"ana\", \"admin\")]\n\n", "note": "Exams live in a folder called `exams`; the directory holds the three members of staff of lesson 12."}, {"code": "def directory():\n    connection = Connection(\n        Server(\"ldap.vereda.example\"),\n        user=\"cn=portal,ou=apps,dc=vereda,dc=example\",\n        password=\"test-only\",\n        client_strategy=MOCK_SYNC,\n    )\n    for name, role in STAFF:\n        connection.strategy.add_entry(\n            f\"cn={name},ou=staff,dc=vereda,dc=example\",\n            {\"objectClass\": \"person\", \"cn\": name, \"sn\": name, \"title\": role},\n        )\n    connection.bind()\n    return connection\n\n", "note": "`MOCK_SYNC` makes `ldap3` answer from entries added here, in memory. The code that searches is the code that would search a real directory; only this function would change."}, {"code": "@app.get(\"/exams/<path:name>/type\")\ndef exam_type(name):\n    result = subprocess.run(\n        f\"file --brief --mime-type exams/{name}\", shell=True, capture_output=True, text=True\n    )\n    return jsonify(name=name, type=result.stdout.strip())\n\n", "note": "The file type of an exam, from the `file` command. The command line is built with an f-string and given to the shell."}, {"code": "@app.get(\"/staff\")\ndef find_staff():\n    connection = directory()\n    connection.search(\n        \"ou=staff,dc=vereda,dc=example\", f\"(cn={request.args['name']})\", attributes=[\"cn\", \"title\"]\n    )\n    return jsonify([{\"name\": str(e.cn), \"role\": str(e.title)} for e in connection.entries])\n\n", "note": "A staff lookup by name. The LDAP filter `(cn=…)` is built with an f-string."}, {"code": "@app.post(\"/reminders/preview\")\ndef preview():\n    note = request.form.get(\"note\", \"\")\n    page = render_template_string(\n        \"<p>Hello {{ patient }}, see you on {{ day }}.</p><p>\" + note + \"</p>\",\n        patient=\"lucia\",\n        day=\"Monday 16 November\",\n    )\n    return page", "note": "The reminder preview. `patient` and `day` are template variables; the note is joined into the template's text."}]}
```

### The tests

Three tests that pass already, one per feature, and three that ask each feature to treat an ordinary
value as data. Save them as `test_app.py`:

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

The fixture runs each test in pytest's `tmp_path` with two exam files in an `exams` folder, written
with the first bytes of a PDF so `file` recognises them. `monkeypatch.chdir` makes that folder the
current one, so the relative path `exams/` in `app.py` finds them.

`ldap3` 2.9.1 uses two names that the current `pyasn1` has deprecated, and pytest would print a
warning about each in every run. The warning is about the library, not about this code, so a small
`pytest.ini` silences exactly those two, **by their text**, and any other warning still shows:

```ini
# pytest.ini
[pytest]
filterwarnings =
    ignore:tagMap is deprecated:DeprecationWarning
    ignore:typeMap is deprecated:DeprecationWarning
```

### Red

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

**Four of six fail**, one in the shell, two in the directory, one in the template. Commit the flawed
version, and take them one interpreter at a time:

```
(.venv) ana@vm:~/sc/exams-convert$ git add app.py test_app.py pytest.ini
(.venv) ana@vm:~/sc/exams-convert$ git commit -q -m "Exam types, staff lookup and reminder preview"
```
