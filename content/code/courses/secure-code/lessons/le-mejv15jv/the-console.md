---
title: The staff console, and what a receptionist can reach
version: 1
---

The staff console is where Vereda's people work. **bruno** is a receptionist: he manages the agenda.
**carla** is a physiotherapist: she reads and writes clinical notes. **ana** is the administrator.
This lesson's folder is `~/sc/console`:

```
(.venv) ana@vm:~/sc$ mkdir console
(.venv) ana@vm:~/sc$ cd console
(.venv) ana@vm:~/sc/console$ git init -b main
Initialized empty Git repository in /home/ana/sc/console/.git/
```

Here is the console as it was first written. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport secrets\n\nfrom flask import Flask, abort, jsonify, render_template_string, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\nSTAFF = {\"bruno\": \"reception\", \"carla\": \"physio\", \"ana\": \"admin\"}\nNOTES = {\"lucia\": [\"Left knee: range of motion improving.\"]}\nAGENDA = [{\"patient\": \"lucia\", \"starts\": \"2026-11-11 09:00\", \"with\": \"carla\"}]\n", "note": "`STAFF` is the server's table of who holds which role. Notes and agenda are held in memory so the program fits on the page."}, {"code": "PAGE = \"\"\"<h1>Vereda console</h1>\n<p>Signed in as {{ name }}</p>\n<ul>\n  <li><a href=\"/agenda\">Agenda</a></li>\n  {% if role == \"physio\" %}\n  <li><a href=\"/patients/lucia/notes\">Clinical notes</a></li>\n  {% endif %}\n</ul>\n{% if role == \"physio\" %}\n<form method=\"post\" action=\"/patients/lucia/notes\">\n  <input type=\"hidden\" name=\"role\" value=\"physio\">\n  <textarea name=\"text\"></textarea>\n  <button>Add note</button>\n</form>\n{% endif %}\n\"\"\"\n\n", "note": "The console's page. A physiotherapist sees the notes link and a form to add one; everybody else sees neither. Note the hidden field: the form tells the server who is sending it."}, {"code": "def signed_in():\n    name = session.get(\"staff\")\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "The only check in the program: is somebody signed in? It says nothing about who."}, {"code": "@app.get(\"/console\")\ndef console():\n    name = signed_in()\n    return render_template_string(PAGE, name=name, role=STAFF.get(name))\n\n\n@app.get(\"/agenda\")\ndef agenda():\n    signed_in()\n    return jsonify(AGENDA)\n\n", "note": "The console and the agenda, for any member of staff."}, {"code": "@app.get(\"/patients/<name>/notes\")\ndef read_notes(name):\n    signed_in()\n    return jsonify(NOTES.get(name, []))\n\n\n@app.post(\"/patients/<name>/notes\")\ndef add_note(name):\n    signed_in()\n    if request.form.get(\"role\") != \"physio\":\n        abort(403)\n    NOTES.setdefault(name, []).append(request.form[\"text\"])\n    return jsonify(NOTES[name]), 201\n\n", "note": "Reading notes asks only `signed_in()`, trusting that the page hid the link. Adding a note does check a role, and takes it from the form."}, {"code": "@app.get(\"/export\")\ndef export():\n    rows = [f\"{patient},{len(notes)}\" for patient, notes in NOTES.items()]\n    return \"\\n\".join([\"patient,notes\", *rows]) + \"\\n\", {\"Content-Type\": \"text/csv\"}", "note": "A CSV for a monthly report, written in an afternoon. Look for its check."}]}
```

### What one request shows

Start it with `flask --app app run`, as in lesson 1, and from a second terminal ask for the export
with no session at all, as any program could:

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

`200 OK`, and the list of patients with clinical notes. Nobody signed in, nothing was hidden from
this request, because nothing was ever asked of it. Stop the server with `Ctrl+C`.

### The tests

Signing in is lessons 10 and 11, so these tests write the session directly, as lesson 1's did. Save
them as `test_app.py`:

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

The second test is there on purpose, and it **passes**: the console does hide the link from bruno.
The third test asks for the same notes by their address, and the fourth sends the form with the
hidden field filled in, which is exactly what the page would send for carla. The last one is the
subject of the fourth section.

### Red

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

**Two pass, four fail**, and the two that pass are the physiotherapist reading her notes and the
link that is not drawn. Every check a person would make by clicking through the console passes. Every
failure is a request the console's own screens never send. Commit the flawed version:

```
(.venv) ana@vm:~/sc/console$ git add app.py test_app.py
(.venv) ana@vm:~/sc/console$ git commit -q -m "Staff console: agenda, clinical notes and the export"
```
