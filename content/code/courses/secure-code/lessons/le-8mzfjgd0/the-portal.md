---
title: The exam results, and a test that asks for everything
version: 1
---

Patients upload the exams their doctor asked for, an MRI or an X-ray, so the physiotherapist sees them
before the session. The portal lists a patient's exams, shows one, and lets her delete one she
uploaded by mistake. This lesson's folder is `~/sc/exams`:

```
(.venv) ana@vm:~/sc$ mkdir exams
(.venv) ana@vm:~/sc$ cd exams
(.venv) ana@vm:~/sc/exams$ git init -b main
Initialized empty Git repository in /home/ana/sc/exams/.git/
```

The exams live in **SQLite**, as lesson 5's patients did, and values reach each query through `?`
placeholders, never by building the SQL string; lesson 5 is about why. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, jsonify, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\napp.config[\"DATABASE\"] = \"exams.db\"\n", "note": "The database is a file, `exams.db`, named in the app's configuration so a test can point it somewhere else."}, {"code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS exams (\n    id INTEGER PRIMARY KEY,\n    patient TEXT NOT NULL,\n    title TEXT NOT NULL,\n    taken TEXT NOT NULL\n)\n\"\"\"\nSAMPLE = [\n    (\"lucia\", \"Knee MRI\", \"2026-10-28\"),\n    (\"marta\", \"Lumbar spine X-ray\", \"2026-10-30\"),\n    (\"rafael\", \"Shoulder ultrasound\", \"2026-11-02\"),\n]\n\n", "note": "One table. `id` is an `INTEGER PRIMARY KEY`, so SQLite numbers the exams 1, 2, 3 in the order they arrive. Each row knows its patient."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(app.config[\"DATABASE\"])\n        g.db.row_factory = sqlite3.Row\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(error):\n    connection = g.pop(\"db\", None)\n    if connection is not None:\n        connection.close()\n\n\ndef init_db():\n    with app.app_context():\n        db().execute(SCHEMA)\n        if db().execute(\"SELECT count(*) FROM exams\").fetchone()[0] == 0:\n            db().executemany(\"INSERT INTO exams (patient, title, taken) VALUES (?, ?, ?)\", SAMPLE)\n        db().commit()\n\n", "note": "Flask's usual pattern: one connection per request, kept in `g` and closed when the request ends. `init_db` creates the table and the three sample exams if the table is empty."}, {"code": "def signed_in():\n    name = session.get(\"patient\")\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "The session check of lesson 1: somebody is signed in, and this is their name."}, {"code": "@app.get(\"/exams\")\ndef list_exams():\n    name = request.args.get(\"patient\", signed_in())\n    rows = db().execute(\"SELECT id, title, taken FROM exams WHERE patient = ?\", (name,))\n    return jsonify([dict(row) for row in rows])\n\n", "note": "The list: the signed-in patient's exams, unless the request names another patient. The staff console wanted to reuse this route."}, {"code": "@app.get(\"/exams/<int:exam_id>\")\ndef read_exam(exam_id):\n    signed_in()\n    row = db().execute(\"SELECT id, title, taken FROM exams WHERE id = ?\", (exam_id,)).fetchone()\n    if row is None:\n        abort(404)\n    return jsonify(dict(row))\n\n\n@app.delete(\"/exams/<int:exam_id>\")\ndef delete_exam(exam_id):\n    signed_in()\n    db().execute(\"DELETE FROM exams WHERE id = ?\", (exam_id,))\n    db().commit()\n    return \"\", 204", "note": "One exam, read or deleted by its id. Both ask that somebody be signed in. Read the queries and look for the patient."}]}
```

### The tests

The fixture gives every test a fresh database in pytest's `tmp_path`, a temporary folder of its own,
so no test sees what another deleted. `OWNERS` writes down who owns each sample exam. Save them as
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

The last test is the one to keep in every project. **It does not test one forbidden request; it tests
the whole grid**: each patient asks for each exam, and the only `200`s allowed are on the diagonal,
where the patient is the owner. Three patients and three exams make nine requests, and adding a
fourth exam to `OWNERS` adds four more.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l13-grid\" aria-label=\"The grid test drawn as a table. Rows are the patient who is signed in, lucia, marta and rafael; columns are exams 1, 2 and 3, owned by lucia, marta and rafael in that order. The cells on the diagonal, where the patient owns the exam, must answer 200. Every other cell must answer 404. Against the flawed portal all nine answered 200, so the six off the diagonal failed.\"><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">signed in as</text><text x=\"300\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /exams/1</text><text x=\"440\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /exams/2</text><text x=\"580\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /exams/3</text><rect x=\"60\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lucia</text><rect x=\"240\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200</text><rect x=\"380\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><rect x=\"520\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><rect x=\"60\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">marta</text><rect x=\"240\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><rect x=\"380\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200</text><rect x=\"520\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><rect x=\"60\" y=\"140\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rafael</text><rect x=\"240\" y=\"140\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><rect x=\"380\" y=\"140\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><rect x=\"520\" y=\"140\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200</text><text x=\"450\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">before the fix, all nine answered 200</text></svg>", "caption": "Nine requests, and only the diagonal may answer 200. A fourth exam adds a column, and the test checks it without a new line."}
```

### Red

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

**Six of seven fail.** Only the first passes, and it is the only test that asks for one's own data.
Run the grid for one patient alone and read what the portal answered:

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

rafael asked for three exams and received three, two of them other people's. Commit the flawed
version:

```
(.venv) ana@vm:~/sc/exams$ git add app.py test_app.py
(.venv) ana@vm:~/sc/exams$ git commit -q -m "List, show and delete a patient's exams"
```
