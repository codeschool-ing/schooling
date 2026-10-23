---
title: The patient search, and five tests
version: 1
---

The staff console lets a receptionist find a patient by surname and sort the list. This lesson's
folder is `~/sc/search`:

```
(.venv) ana@vm:~/sc$ mkdir search
(.venv) ana@vm:~/sc$ cd search
(.venv) ana@vm:~/sc/search$ git init -b main
Initialized empty Git repository in /home/ana/sc/search/.git/
```

This is the first application of the course to keep its data in **SQLite**, through Python's built-in
`sqlite3` module, because the flaw lives in a query. Save this as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport sqlite3\n\nfrom flask import Flask, abort, g, jsonify, request\n\napp = Flask(__name__)\napp.config[\"DATABASE\"] = \"patients.db\"\n", "note": "The database is a file named in the configuration, so a test can point it at a temporary folder, as in lesson 13."}, {"code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS patients (\n    id INTEGER PRIMARY KEY,\n    first_name TEXT NOT NULL,\n    surname TEXT NOT NULL,\n    clinic TEXT NOT NULL\n)\n\"\"\"\nSAMPLE = [\n    (\"Lucia\", \"D'Ávila\", \"Pinheiros\"),\n    (\"Rafael\", \"Souza\", \"Moema\"),\n    (\"Marta\", \"Avelar\", \"Pinheiros\"),\n    (\"Bruno\", \"O'Neill\", \"Santana\"),\n]\n\n", "note": "Four patients. Two of the surnames have an apostrophe, as real surnames do."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(app.config[\"DATABASE\"])\n        g.db.row_factory = sqlite3.Row\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(error):\n    connection = g.pop(\"db\", None)\n    if connection is not None:\n        connection.close()\n\n\ndef init_db():\n    with app.app_context():\n        db().execute(SCHEMA)\n        if db().execute(\"SELECT count(*) FROM patients\").fetchone()[0] == 0:\n            db().executemany(\n                \"INSERT INTO patients (first_name, surname, clinic) VALUES (?, ?, ?)\", SAMPLE\n            )\n        db().commit()\n\n", "note": "One connection per request, as in lesson 13. Notice that the sample rows go in with `?` placeholders: the author knew the safe call, and used it where the values were hers."}, {"code": "@app.get(\"/patients\")\ndef search():\n    term = request.args.get(\"surname\", \"\")\n    order = request.args.get(\"sort\", \"surname\")\n    rows = db().execute(\n        f\"SELECT first_name, surname, clinic FROM patients \"\n        f\"WHERE surname LIKE '%{term}%' ORDER BY {order}\"\n    )\n    return jsonify([dict(row) for row in rows])\n\n", "note": "The search. The surname and the sort come from the address and are written into the SQL text with an f-string. Read the quotes around `{term}` as the database will."}, {"code": "@app.cli.command(\"init-db\")\ndef init_db_command():\n    init_db()", "note": "`flask --app app init-db` creates the table and the four patients in `patients.db`."}]}
```

Create the database with the command the file defines, start the portal, and from a second terminal
ask for the patient whose surname is `D'Ávila`. `curl -G --data-urlencode` writes the apostrophe and
the accent into the address the way a browser would:

```
(.venv) ana@vm:~/sc/search$ flask --app app init-db
```

```
(.venv) ana@vm:~/sc/search$ curl -si -G --data-urlencode "surname=D'Ávila" http://127.0.0.1:5000/patients
HTTP/1.1 500 INTERNAL SERVER ERROR
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 17:58:17 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 265
Connection: close

<!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

`500 INTERNAL SERVER ERROR`, for a patient who exists. Stop the portal with `Ctrl+C`.

### The tests

Five tests, each a sentence about the search. Two of them pass already; the other three are a real
surname, a sort nobody offered, and two characters a receptionist could type. Save them as
`test_app.py`:

```python
# test_app.py
import pytest

import app as portal


@pytest.fixture
def client(tmp_path):
    portal.app.config["DATABASE"] = tmp_path / "patients.db"
    portal.init_db()
    return portal.app.test_client()


def surnames(answer):
    return [patient["surname"] for patient in answer.json]


def test_a_plain_surname_is_found(client):
    assert surnames(client.get("/patients?surname=Souza")) == ["Souza"]


def test_an_apostrophe_is_part_of_the_name(client):
    answer = client.get("/patients", query_string={"surname": "D'Ávila"})
    assert answer.status_code == 200
    assert surnames(answer) == ["D'Ávila"]


def test_the_list_can_be_sorted_by_clinic(client):
    answer = client.get("/patients?sort=clinic")
    assert [p["clinic"] for p in answer.json] == ["Moema", "Pinheiros", "Pinheiros", "Santana"]


def test_an_unknown_sort_is_refused(client):
    assert client.get("/patients?sort=age").status_code == 400


def test_percent_and_underscore_are_searched_for_literally(client):
    assert surnames(client.get("/patients", query_string={"surname": "%"})) == []
    assert surnames(client.get("/patients", query_string={"surname": "S_uza"})) == []
```

### Red

```
(.venv) ana@vm:~/sc/search$ pytest -q --tb=no
.F.FF                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_an_apostrophe_is_part_of_the_name - assert 500 == 200
FAILED test_app.py::test_an_unknown_sort_is_refused - AssertionError: assert ...
FAILED test_app.py::test_percent_and_underscore_are_searched_for_literally - ...
3 failed, 2 passed in 0.17s
```

**Three of five fail.** Run the apostrophe test alone and read what the database said:

```
(.venv) ana@vm:~/sc/search$ pytest -q --tb=short -k apostrophe
F                                                                        [100%]
=================================== FAILURES ===================================
____________________ test_an_apostrophe_is_part_of_the_name ____________________
test_app.py:24: in test_an_apostrophe_is_part_of_the_name
    assert answer.status_code == 200
E   assert 500 == 200
E    +  where 500 = <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]>.status_code
------------------------------ Captured log call -------------------------------
ERROR    app:app.py:875 Exception on /patients [GET]
Traceback (most recent call last):
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 1511, in wsgi_app
    response = self.full_dispatch_request()
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 919, in full_dispatch_request
    rv = self.handle_user_exception(e)
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 917, in full_dispatch_request
    rv = self.dispatch_request()
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 902, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "/home/ana/sc/search/app.py", line 53, in search
    rows = db().execute(
        f"SELECT first_name, surname, clinic FROM patients "
        f"WHERE surname LIKE '%{term}%' ORDER BY {order}"
    )
sqlite3.OperationalError: near "Ávila": syntax error
=========================== short test summary info ============================
FAILED test_app.py::test_an_apostrophe_is_part_of_the_name - assert 500 == 200
1 failed, 4 deselected in 0.18s
```

The last line is the lesson in one sentence: `near "Ávila": syntax error`. The database read the
apostrophe as the end of the string, and then tried to read `Ávila` as SQL. **Part of a patient's
name was parsed as program.** Here it made the query fail; with other text, the same line would have
made the query do something else.

Commit the flawed version:

```
(.venv) ana@vm:~/sc/search$ git add .gitignore app.py test_app.py
(.venv) ana@vm:~/sc/search$ git commit -q -m "Search patients by surname, sorted"
```
