---
title: Exam uploads and preferences, and eight tests
version: 1
---

Patients upload the exams their doctor asked for, as PDFs, and download them again later. The portal
also remembers each patient's preferred text size in a cookie, so the setting survives between visits
on the same browser. This lesson's folder is `~/sc/upload`:

```
(.venv) ana@vm:~/sc$ mkdir upload
(.venv) ana@vm:~/sc$ cd upload
(.venv) ana@vm:~/sc/upload$ git init -b main
Initialized empty Git repository in /home/ana/sc/upload/.git/
```

Here is the first version. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport base64\nimport pickle\nfrom pathlib import Path\n\nfrom flask import Flask, jsonify, request, send_from_directory\n\napp = Flask(__name__)\napp.config[\"UPLOADS\"] = Path(\"static/uploads\")\n\n", "note": "Uploads go to `static/uploads`, inside the folder Flask serves to anybody at `/static/…`."}, {"code": "@app.post(\"/exams\")\ndef upload():\n    exam = request.files[\"exam\"]\n    folder = app.config[\"UPLOADS\"]\n    folder.mkdir(parents=True, exist_ok=True)\n    exam.save(folder / exam.filename)\n    return jsonify(id=exam.filename), 201\n\n", "note": "The upload keeps the file under the name the browser sent, as a path inside the folder."}, {"code": "@app.get(\"/exams/<name>\")\ndef download(name):\n    return send_from_directory(app.config[\"UPLOADS\"], name)\n\n", "note": "The download serves the file by that same name, with whatever type Flask guesses from it."}, {"code": "@app.post(\"/preferences\")\ndef save_preferences():\n    prefs = {\"text_size\": request.form.get(\"text_size\", \"normal\")}\n    response = jsonify(prefs)\n    response.set_cookie(\"prefs\", base64.b64encode(pickle.dumps(prefs)).decode())\n    return response\n\n\n@app.get(\"/preferences\")\ndef read_preferences():\n    raw = request.cookies.get(\"prefs\")\n    prefs = pickle.loads(base64.b64decode(raw)) if raw else {\"text_size\": \"normal\"}\n    return jsonify(prefs)", "note": "The text size, kept in a cookie as a pickled dictionary, and unpickled from whatever cookie the browser sends back."}]}
```

### What the upload does with a name

Start the portal, and from a second terminal make a small PDF and upload it twice: once under its own
name, and once under a name with `../` in front, as a client with a bug in its path handling might
send. `printf` writes the file (`%%` is how `printf` writes one `%`), `curl -F` sends it the way a browser's form
does, and `filename=` sets the name it reports:

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

The second upload was accepted like the first, and `ls` shows the file **outside** `static/uploads`,
in `static`. The name decided where the file was written. Stop the portal with `Ctrl+C`.

### The tests

Five tests for the upload and three for the preferences. `upload` sends a file the same way `curl -F`
did. Save them as `test_app.py`:

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

The last test builds a pickled cookie itself, holding nothing but the text size, to stand for any
pickle a browser might send. **It needs no harmful content to make its point**: if the portal answers
`200`, it ran `pickle.loads` on bytes from the request, and that is the flaw whatever the bytes say.

### Red

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

**Six of eight fail.** Commit the flawed version:

```
(.venv) ana@vm:~/sc/upload$ git add app.py test_app.py
(.venv) ana@vm:~/sc/upload$ git commit -q -m "Exam uploads and text-size preferences"
```
