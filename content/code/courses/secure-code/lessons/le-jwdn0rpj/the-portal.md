---
title: The portal's sessions, and six tests that fail
version: 1
---

This lesson's folder is `~/sc/sessions`, a git repository of its own as in lesson 1:

```
(.venv) ana@vm:~/sc$ mkdir sessions
(.venv) ana@vm:~/sc$ cd sessions
(.venv) ana@vm:~/sc/sessions$ git init -b main
Initialized empty Git repository in /home/ana/sc/sessions/.git/
```

Here is the part of the portal that signs a patient in, as ana first wrote it. It works: a patient
who signs in sees her bookings, and one who has not gets `401`. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport hashlib\nfrom datetime import datetime\n\nfrom flask import Flask, abort, jsonify, make_response, request\n\napp = Flask(__name__)\nSESSIONS = {}\n\n", "note": "The session table: each id the server has issued, mapped to what it knows about that session. A dictionary here; a database table or Redis in production."}, {"code": "def now():\n    return datetime.now()\n\n\ndef check_password(name, password):\n    # Lesson 11 replaces this with a real password store.\n    return (name, password) in {(\"lucia\", \"lucia-pw\"), (\"rafael\", \"rafael-pw\")}\n\n", "note": "The clock is a function of its own so a test can move it, as in lesson 1. The password check is a stand-in: storing passwords is lesson 11, and here it would only be in the way."}, {"code": "def new_session_id(name):\n    return hashlib.md5(f\"{name}{now():%Y%m%d%H%M}\".encode()).hexdigest()\n\n", "note": "The id: a hash of the name and the minute. It looks random. Keep that impression in mind for the next section."}, {"code": "def current_patient():\n    record = SESSIONS.get(request.cookies.get(\"sid\"))\n    if record is None or record[\"patient\"] is None:\n        abort(401)\n    return record[\"patient\"]\n\n", "note": "Every route that needs a patient asks this function. An id the table does not know, or a session nobody has signed in to, is `401`."}, {"code": "@app.get(\"/\")\ndef home():\n    response = make_response(\"Vereda patient portal\\n\")\n    if request.cookies.get(\"sid\") not in SESSIONS:\n        sid = new_session_id(\"visitor\")\n        SESSIONS[sid] = {\"patient\": None}\n        response.set_cookie(\"sid\", sid)\n    return response\n\n", "note": "A visitor gets a session before signing in, to remember a language choice or, in lesson 9, a form token. It is anonymous: `patient` is `None`."}, {"code": "@app.post(\"/sign-in\")\ndef sign_in():\n    name = request.form.get(\"name\", \"\")\n    if not check_password(name, request.form.get(\"password\", \"\")):\n        abort(401)\n    sid = request.cookies.get(\"sid\")\n    if sid not in SESSIONS:\n        sid = new_session_id(name)\n    SESSIONS[sid] = {\"patient\": name}\n    response = jsonify(patient=name)\n    response.set_cookie(\"sid\", sid)\n    return response\n\n", "note": "Sign-in: if the browser already has a session, write the patient into it; otherwise issue one. Ask yourself which id lucia ends up with."}, {"code": "@app.get(\"/bookings\")\ndef bookings():\n    return jsonify(patient=current_patient(), bookings=[])\n\n", "note": "One page that needs a signed-in patient. The bookings themselves are not this lesson's subject, so the list is empty."}, {"code": "@app.post(\"/sign-out\")\ndef sign_out():\n    response = jsonify(signed_out=True)\n    response.delete_cookie(\"sid\")\n    return response", "note": "Sign-out tells the browser to forget the cookie. Notice what it does not touch."}]}
```

Nothing in it looks careless, and that is the point of reading it slowly. Each function does what
its name says. The flaws are in what the functions leave out, and none of them shows up when you
click through the portal by hand.

### The tests

The tests below state the four moments of the last section as sentences. Two fixtures carry them.
`clock` replaces `now` with a time the test can move forward, which is how a test waits sixteen
minutes in no time at all. `client` empties the session table and returns Flask's test client.
Save them as `test_app.py`:

```python
# test_app.py
from datetime import datetime, timedelta

import pytest

import app as portal


@pytest.fixture
def clock(monkeypatch):
    times = [datetime(2026, 11, 9, 9, 0)]
    monkeypatch.setattr(portal, "now", lambda: times[0])
    return times


@pytest.fixture
def client(clock):
    portal.SESSIONS.clear()
    return portal.app.test_client()


def sign_in(client, name="lucia"):
    return client.post("/sign-in", data={"name": name, "password": f"{name}-pw"})


def sid(client):
    return client.get_cookie("sid").value


def test_a_signed_in_patient_sees_their_bookings(client):
    sign_in(client)
    assert client.get("/bookings").json["patient"] == "lucia"


def test_session_ids_cannot_be_worked_out(client):
    first, second = portal.app.test_client(), portal.app.test_client()
    sign_in(first)
    sign_in(second)
    assert sid(first) != sid(second)
    assert len(sid(first)) >= 43


def test_the_cookie_is_kept_from_scripts_and_plain_http(client):
    cookie = sign_in(client).headers["Set-Cookie"]
    assert "HttpOnly" in cookie
    assert "Secure" in cookie
    assert "SameSite=Lax" in cookie


def test_signing_in_issues_a_new_id(client):
    client.get("/")
    before = sid(client)
    sign_in(client)
    assert sid(client) != before
    assert before not in portal.SESSIONS


def test_an_idle_session_expires(client, clock):
    sign_in(client)
    clock[0] += timedelta(minutes=16)
    assert client.get("/bookings").status_code == 401


def test_a_session_has_an_absolute_limit(client, clock):
    sign_in(client)
    for _ in range(8 * 6 + 1):
        clock[0] += timedelta(minutes=10)
        client.get("/bookings")
    assert client.get("/bookings").status_code == 401


def test_signing_out_ends_the_session_on_the_server(client):
    sign_in(client)
    old = sid(client)
    client.post("/sign-out")
    client.set_cookie("sid", old)
    assert client.get("/bookings").status_code == 401
```

Read the last test closely, because it is the one a manual check never runs. It signs out, which
makes the browser forget the cookie, and then **puts the old id back**, as a copy kept anywhere
else would. The server is the only party whose answer counts.

### Red

```
(.venv) ana@vm:~/sc/sessions$ pytest -q --tb=no
.FFFFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_session_ids_cannot_be_worked_out - AssertionError: a...
FAILED test_app.py::test_the_cookie_is_kept_from_scripts_and_plain_http - Ass...
FAILED test_app.py::test_signing_in_issues_a_new_id - AssertionError: assert ...
FAILED test_app.py::test_an_idle_session_expires - AssertionError: assert 200...
FAILED test_app.py::test_a_session_has_an_absolute_limit - AssertionError: as...
FAILED test_app.py::test_signing_out_ends_the_session_on_the_server - Asserti...
6 failed, 1 passed in 0.20s
```

**Six of seven fail.** The first test passes, which is what "it works" meant: the session does
its job for the person it belongs to. Every failure is about somebody else holding the id, or the
id outliving the reason it was issued. Commit the flawed version, so each fix is a diff of its own:

```
(.venv) ana@vm:~/sc/sessions$ git add app.py test_app.py
(.venv) ana@vm:~/sc/sessions$ git commit -q -m "Sign patients in with a server-side session"
```

The next three sections take the failures in the order of the four moments, and each ends with the
tests it turns green.
