---
title: The account page, and seven tests
version: 1
---

The account page lets a patient change her e-mail address and her phone number, the two places a
password reset is sent. This lesson's folder is `~/sc/csrf`:

```
(.venv) ana@vm:~/sc$ mkdir csrf
(.venv) ana@vm:~/sc$ cd csrf
(.venv) ana@vm:~/sc/csrf$ git init -b main
Initialized empty Git repository in /home/ana/sc/csrf/.git/
```

Here it is as first written. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport secrets\n\nfrom flask import Flask, abort, redirect, render_template_string, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\nACCOUNTS = {\"lucia\": {\"email\": \"lucia@mail.example\", \"phone\": \"+55 11 5555-0101\"}}\n", "note": "One account, held in memory. The e-mail address and the phone number are where a password reset is sent, which is what makes them worth forging a change to."}, {"code": "PAGE = \"\"\"<h1>Your account</h1>\n<form method=\"post\" action=\"/account/email\">\n  <input name=\"email\" value=\"{{ account.email }}\">\n  <button>Change e-mail</button>\n</form>\n<form method=\"post\" action=\"/account/phone\">\n  <input name=\"phone\" value=\"{{ account.phone }}\">\n  <button>Change phone</button>\n</form>\n\"\"\"\n\n", "note": "Two forms. Every field in them is something the sender chooses; nothing in either form is a value only the portal knows."}, {"code": "def signed_in():\n    name = session.get(\"patient\")\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "The session check. It is right, and it is not enough: a forged request carries a valid session."}, {"code": "@app.get(\"/account\")\ndef account():\n    return render_template_string(PAGE, account=ACCOUNTS[signed_in()])\n\n\n@app.post(\"/account/email\")\ndef change_email():\n    ACCOUNTS[signed_in()][\"email\"] = request.form[\"email\"]\n    return redirect(\"/account\", 303)\n\n\n@app.post(\"/account/phone\")\ndef change_phone():\n    ACCOUNTS[signed_in()][\"phone\"] = request.form[\"phone\"]\n    return redirect(\"/account\", 303)", "note": "The page, and two changes. Each change answers `303 See Other`, which sends the browser back to the page with a `GET`, so reloading it does not post the form again."}]}
```

### The tests

The tests write lucia's session directly, as in lesson 1, and then do what a browser does: load the
account page, read what the page holds, and post the form. `token_from_page` reads the hidden token
field out of the page's HTML, the way a browser submits it. Save them as `test_app.py`:

```python
# test_app.py
import re

import pytest

import app as portal

EMAIL = "lucia@mail.example"


@pytest.fixture
def client():
    portal.ACCOUNTS["lucia"] = {"email": EMAIL, "phone": "+55 11 5555-0101"}
    client = portal.app.test_client()
    with client.session_transaction() as session:
        session["patient"] = "lucia"
    return client


def token_from_page(client):
    page = client.get("/account").get_data(as_text=True)
    found = re.search(r'name="csrf" value="([^"]+)"', page)
    return found.group(1) if found else None


def change_email(client, **extra):
    return client.post("/account/email", data={"email": "new@mail.example", **extra.pop("data", {})}, **extra)


def test_the_forms_carry_a_token(client):
    assert token_from_page(client)


def test_a_change_with_the_token_is_accepted(client):
    token = token_from_page(client)
    assert change_email(client, data={"csrf": token}).status_code == 303
    assert portal.ACCOUNTS["lucia"]["email"] == "new@mail.example"


def test_a_change_without_the_token_is_refused(client):
    assert change_email(client).status_code == 403
    assert portal.ACCOUNTS["lucia"]["email"] == EMAIL


def test_a_token_from_another_session_is_refused(client):
    other = portal.app.test_client()
    with other.session_transaction() as session:
        session["patient"] = "lucia"
    assert change_email(client, data={"csrf": token_from_page(other)}).status_code == 403


def test_every_change_needs_the_token(client):
    assert client.post("/account/phone", data={"phone": "+55 11 5555-0199"}).status_code == 403


def test_a_change_from_another_origin_is_refused(client):
    token = token_from_page(client)
    answer = change_email(client, data={"csrf": token}, headers={"Origin": "https://elsewhere.example"})
    assert answer.status_code == 403


def test_the_session_cookie_is_samesite_lax(client):
    cookie = client.get_cookie("session")
    assert cookie.same_site == "Lax"
    assert cookie.secure and cookie.http_only
```

**The third test is the forged request, as the portal receives it**: lucia's valid session, a
well-formed change, and nothing that proves her own page sent it. No other site is needed to show the
flaw. A test client sending the same request is exactly what the portal would see.

### Red

```
(.venv) ana@vm:~/sc/csrf$ pytest -q --tb=no
F.FFFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_forms_carry_a_token - AssertionError: assert None
FAILED test_app.py::test_a_change_without_the_token_is_refused - AssertionErr...
FAILED test_app.py::test_a_token_from_another_session_is_refused - AssertionE...
FAILED test_app.py::test_every_change_needs_the_token - AssertionError: asser...
FAILED test_app.py::test_a_change_from_another_origin_is_refused - assert 303...
FAILED test_app.py::test_the_session_cookie_is_samesite_lax - AssertionError:...
6 failed, 1 passed in 0.17s
```

**Six of seven fail.** The one that passes is a change sent with whatever token the page held, and
the first version holds none and checks none, so it accepts anything. Commit the flawed version:

```
(.venv) ana@vm:~/sc/csrf$ git add app.py test_app.py
(.venv) ana@vm:~/sc/csrf$ git commit -q -m "Change the e-mail address and the phone number"
```
