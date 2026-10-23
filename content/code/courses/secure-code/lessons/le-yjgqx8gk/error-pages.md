---
title: An error page that says too much
version: 1
---

This lesson's application is a small piece of the portal with both problems in it: a route that
fails for a patient who does not exist, and a sign-in that logs what it receives. Make its folder
as before:

```
(.venv) ana@vm:~/sc$ mkdir errors
(.venv) ana@vm:~/sc$ cd errors
(.venv) ana@vm:~/sc/errors$ git init -b main
Initialized empty Git repository in /home/ana/sc/errors/.git/
```

Save this as `app.py`:

```python
# app.py
import logging
import traceback

from flask import Flask, request
from werkzeug.exceptions import HTTPException
from werkzeug.security import check_password_hash, generate_password_hash

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")
log = logging.getLogger("portal")

app = Flask(__name__)
USERS = {"lucia": generate_password_hash("correct horse battery staple")}
PHONES = {"lucia": "11987654321"}


@app.errorhandler(Exception)
def unexpected(error):
    if isinstance(error, HTTPException):
        return error
    return {"error": traceback.format_exc()}, 500


@app.post("/login")
def login():
    name = request.form.get("name", "")
    password = request.form.get("password", "")
    log.info("sign-in attempt name=%s password=%s", name, password)
    if name in USERS and check_password_hash(USERS[name], password):
        return {"signed_in": name}
    return {"error": "wrong name or password"}, 401


@app.get("/patients/<name>/phone")
def phone(name):
    return {"phone": PHONES[name]}
```

The error handler was written with good intentions: when something breaks, the support team wants
to know what, so the page carries the whole traceback. Start the application with its output sent
to a file, so you can read the log afterwards, and ask for a phone that does not exist, then sign
in:

```
(.venv) ana@vm:~/sc/errors$ flask --app app run > server.log 2>&1 &
(.venv) ana@vm:~/sc/errors$ curl -s http://127.0.0.1:5000/patients/marta/phone
{"error":"Traceback (most recent call last):\n  File \"/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py\", line 917, in full_dispatch_request\n    rv = self.dispatch_request()\n  File \"/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py\", line 902, in dispatch_request\n    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]\n           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^\n  File \"/home/ana/sc/errors/app.py\", line 36, in phone\n    return {\"phone\": PHONES[name]}\n                     ~~~~~~^^^^^^\nKeyError: 'marta'\n"}
(.venv) ana@vm:~/sc/errors$ curl -s -d 'name=lucia&password=correct horse battery staple' http://127.0.0.1:5000/login
{"signed_in":"lucia"}
(.venv) ana@vm:~/sc/errors$ grep portal server.log
INFO portal sign-in attempt name=lucia password=correct horse battery staple
```

Read the first answer as a stranger would. It names the framework and the paths of its files,
the folder the portal runs from, the name of the dictionary that holds the phones and the line of
code that failed. **None of that helps the person who asked**, who needed to hear that something
went wrong and what to do next, and all of it helps somebody mapping the portal from outside. The
third command shows the other half: the server's log holds the password lucia typed, in plain
text, beside her name.

### The tests

Four tests, two for the page and two for the log. `caplog` is pytest's fixture for reading what was
logged during a test, and the `client` fixture asks it to keep messages from the portal's logger at
INFO and above. Save them as `test_app.py`:

```python
# test_app.py
import logging

import pytest

import app as portal


@pytest.fixture
def client(caplog):
    caplog.set_level(logging.INFO, logger="portal")
    return portal.app.test_client()


def test_an_error_page_shows_no_internals(client):
    response = client.get("/patients/marta/phone")
    assert response.status_code == 500
    body = response.get_data(as_text=True)
    assert "Traceback" not in body
    assert "app.py" not in body


def test_the_log_keeps_what_the_page_does_not(client, caplog):
    response = client.get("/patients/marta/phone")
    reference = response.get_json()["reference"]
    assert f"ref={reference}" in caplog.text
    assert "KeyError" in caplog.text


def test_a_password_is_never_logged(client, caplog):
    client.post("/login", data={"name": "lucia", "password": "correct horse battery staple"})
    assert "correct horse" not in caplog.text


def test_one_attempt_is_one_line_of_log(client, caplog):
    client.post("/login", data={"name": "lucia\nsecond line", "password": "x"})
    assert "\nsecond line" not in caplog.text
```

```
(.venv) ana@vm:~/sc/errors$ pytest -q --tb=no
FFFF                                                                     [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_an_error_page_shows_no_internals - assert 'Traceback...
FAILED test_app.py::test_the_log_keeps_what_the_page_does_not - KeyError: 're...
FAILED test_app.py::test_a_password_is_never_logged - AssertionError: assert ...
FAILED test_app.py::test_one_attempt_is_one_line_of_log - AssertionError: ass...
4 failed in 0.30s
```

All four fail. The second fails with a `KeyError` on `reference`: the old page carries no reference
for a patient to quote, so there is nothing to look up in the log. Commit it as it is:

```
(.venv) ana@vm:~/sc/errors$ git add app.py test_app.py
(.venv) ana@vm:~/sc/errors$ git commit -q -m "Show phones, and log sign-ins"
```
