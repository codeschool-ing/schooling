---
title: The first flaw, found by a test
version: 1
---

The loop of this course, once, on the requirement from the first section: *a patient can cancel a
booking online up to 24 hours before the session.* Here is the cancel button as ana wrote it,
holding just enough of the portal to run. Save it as `~/sc/cancel/app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import secrets\nfrom datetime import datetime, timedelta\n\nfrom flask import Flask, abort, jsonify, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\n", "note": "Flask signs the session cookie with `secret_key`. A random one at every start is enough for a program that only runs on your machine; lesson 16 is about keeping a real one."}, {"code": "BOOKINGS = {\n    101: {\"patient\": \"lucia\", \"starts\": datetime(2026, 11, 3, 9, 0), \"status\": \"booked\"},\n    102: {\"patient\": \"rafael\", \"starts\": datetime(2026, 11, 3, 10, 0), \"status\": \"booked\"},\n}\n\n", "note": "Two bookings held in memory instead of a database, so the whole program fits on the page. Lesson 5 brings in SQLite."}, {"code": "def now():\n    return datetime.now()\n\n\ndef can_cancel(booking, at):\n    return booking[\"starts\"] - at >= timedelta(hours=24)\n\n", "note": "The clock is a function of its own, so a test can replace it. The rule is the requirement word for word: at least 24 hours before the session."}, {"code": "@app.post(\"/bookings/<int:booking_id>/cancel\")\ndef cancel(booking_id):\n    if \"patient\" not in session:\n        abort(401)\n    booking = BOOKINGS.get(booking_id)\n    if booking is None:\n        abort(404)\n    if not can_cancel(booking, now()):\n        abort(409)\n    booking[\"status\"] = \"cancelled\"\n    return jsonify(id=booking_id, status=booking[\"status\"])", "note": "Signed in, the booking exists, still in time: cancel it. Each check answers one sentence of the requirement. Read them and ask which sentence was never written."}]}
```

The program has three checks and every one of them is correct. What it lacks is a check nobody
asked for. **The tests below state the requirement, and then the sentence the requirement forgot.**
Save them beside it as `test_app.py`:

```python
# test_app.py
from datetime import datetime

import pytest

import app as portal


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setattr(portal, "now", lambda: datetime(2026, 11, 1, 9, 0))
    for booking in portal.BOOKINGS.values():
        booking["status"] = "booked"
    return portal.app.test_client()


def sign_in(client, patient):
    with client.session_transaction() as session:
        session["patient"] = patient


def test_a_patient_cancels_their_own_booking(client):
    sign_in(client, "lucia")
    assert client.post("/bookings/101/cancel").status_code == 200


def test_too_late_to_cancel(client, monkeypatch):
    monkeypatch.setattr(portal, "now", lambda: datetime(2026, 11, 2, 10, 0))
    sign_in(client, "lucia")
    assert client.post("/bookings/101/cancel").status_code == 409


def test_a_patient_cannot_cancel_somebody_elses_booking(client):
    sign_in(client, "lucia")
    assert client.post("/bookings/102/cancel").status_code == 404
    assert portal.BOOKINGS[102]["status"] == "booked"
```

Four things in that file are worth knowing, because every lesson uses them:

- **`client` is a fixture**: pytest calls it and hands the result to every test that names it.
  It pins the clock to 1 November 2026 at 09:00, puts both bookings back to `booked`, and returns
  Flask's **test client**, which sends requests to the application without starting a server.
- **`monkeypatch` replaces a name for the length of one test** and puts it back afterwards. That
  is why `now` was a function of its own.
- **`sign_in` writes the session directly.** Signing in properly is lessons 10 and 11; here it
  would only be in the way.
- **The last test is the missing sentence**: lucia, signed in, tries to cancel rafael's booking,
  and it must answer as though the booking did not exist, and leave it booked. Lesson 13 says why
  404 rather than 403.

### Red

```
(.venv) ana@vm:~/sc/cancel$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/cancel
collected 3 items

test_app.py ..F                                                          [100%]

=================================== FAILURES ===================================
_____________ test_a_patient_cannot_cancel_somebody_elses_booking ______________

client = <FlaskClient <Flask 'app'>>

    def test_a_patient_cannot_cancel_somebody_elses_booking(client):
        sign_in(client, "lucia")
>       assert client.post("/bookings/102/cancel").status_code == 404
E       AssertionError: assert 200 == 404
E        +  where 200 = <WrapperTestResponse streamed [200 OK]>.status_code
E        +    where <WrapperTestResponse streamed [200 OK]> = post('/bookings/102/cancel')
E        +      where post = <FlaskClient <Flask 'app'>>.post

test_app.py:35: AssertionError
=========================== short test summary info ============================
FAILED test_app.py::test_a_patient_cannot_cancel_somebody_elses_booking - Ass...
========================= 1 failed, 2 passed in 0.12s ==========================
```

Two tests pass and the third fails, and pytest says exactly how: the application answered `200`
where the test expected `404`. **That line is the flaw, shown in your own application by one
request.** Any signed-in patient can cancel any booking whose number they can guess, and booking
numbers count up from 101.

Commit the flawed version before touching it, so the fix is a diff you can read afterwards:

```
(.venv) ana@vm:~/sc/cancel$ git add app.py test_app.py
(.venv) ana@vm:~/sc/cancel$ git commit -m "Cancel a booking up to 24 hours before"
[main (root-commit) 556a7f2] Cancel a booking up to 24 hours before
 2 files changed, 69 insertions(+)
 create mode 100644 app.py
 create mode 100644 test_app.py
```

### Fix

The fix is one condition: a booking that is not the signed-in patient's is treated as one that
does not exist. Change the `if booking is None:` line in `app.py`, and `git diff` shows the whole
change:

```
(.venv) ana@vm:~/sc/cancel$ git diff
diff --git a/app.py b/app.py
index 0b47e64..6a47a61 100644
--- a/app.py
+++ b/app.py
@@ -25,7 +25,7 @@ def cancel(booking_id):
     if "patient" not in session:
         abort(401)
     booking = BOOKINGS.get(booking_id)
-    if booking is None:
+    if booking is None or booking["patient"] != session["patient"]:
         abort(404)
     if not can_cancel(booking, now()):
         abort(409)
```

### Green

```
(.venv) ana@vm:~/sc/cancel$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/cancel
collected 3 items

test_app.py ...                                                          [100%]

============================== 3 passed in 0.10s ===============================
```

Commit the fix with the test that proves it. From now on the missing sentence is written down, in
a form that fails loudly if anybody removes the check:

```
(.venv) ana@vm:~/sc/cancel$ git commit -am "Refuse to cancel a booking that is not the patient's"
[main 6cb0f01] Refuse to cancel a booking that is not the patient's
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### And it runs

The tests never started a server, but the application is a real one. `flask --app app run` starts
it on port 5000 of `127.0.0.1` and stays in the foreground, writing a line for each request it
answers; `Ctrl+C` stops it.

```
(.venv) ana@vm:~/sc/cancel$ flask --app app run
 * Serving Flask app 'app'
 * Debug mode: off
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

Flask's warning is accurate and worth taking literally: its built-in server is for development, on
your own machine, which is the only place this course uses it. From a **second terminal**, a
request with no session gets the refusal the first check was written for:

```
(.venv) ana@vm:~/sc/cancel$ curl -si -X POST http://127.0.0.1:5000/bookings/101/cancel
HTTP/1.1 401 UNAUTHORIZED
Server: Werkzeug/3.1.9 Python/3.13.16
Date: Fri, 23 Oct 2026 03:24:54 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 317
Vary: Cookie
Connection: close

<!doctype html>
<html lang=en>
<title>401 Unauthorized</title>
<h1>Unauthorized</h1>
<p>The server could not verify that you are authorized to access the URL requested. You either supplied the wrong credentials (e.g. a bad password), or your browser doesn&#39;t understand how to supply the credentials required.</p>
```

`401 UNAUTHORIZED`, and an HTML page saying so. The `Vary: Cookie` header is Flask noting that the
answer depends on the session cookie, which this request did not send.
