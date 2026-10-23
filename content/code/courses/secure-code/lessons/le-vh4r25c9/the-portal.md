---
title: The portal's passwords, and nine tests
version: 1
---

This lesson's folder is `~/sc/passwords`, a git repository of its own as in lesson 1:

```
(.venv) ana@vm:~/sc$ mkdir passwords
(.venv) ana@vm:~/sc$ cd passwords
(.venv) ana@vm:~/sc/passwords$ git init -b main
Initialized empty Git repository in /home/ana/sc/passwords/.git/
```

Here is the portal's account code as ana first wrote it. It stores a SHA-256 of each password, checks
a new password against the composition rules many sites still use, and keeps sessions as lesson 10
left them, without the expiry, so the page stays short. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport hashlib\nimport secrets\n\nfrom flask import Flask, abort, jsonify, request\n\napp = Flask(__name__)\nUSERS = {}\nSESSIONS = {}\n\n", "note": "Two tables: what is stored for each patient's password, and the sessions, mapped from a random id to a name as in lesson 10."}, {"code": "def set_password(name, password):\n    USERS[name] = hashlib.sha256(password.encode()).hexdigest()\n\n\ndef password_is_right(name, password):\n    return USERS[name] == hashlib.sha256(password.encode()).hexdigest()\n\n", "note": "Stored as a SHA-256, and checked by hashing the candidate the same way. One-way, and it looks like nothing. Keep both impressions for the first test."}, {"code": "def policy_problem(password):\n    if len(password) < 8:\n        return \"use at least 8 characters\"\n    if not any(c.isupper() for c in password):\n        return \"add an uppercase letter\"\n    if not any(c.isdigit() for c in password):\n        return \"add a digit\"\n    if password.isalnum():\n        return \"add a symbol\"\n    return None\n\n", "note": "The policy answers `None` for an acceptable password and a sentence for the patient otherwise. These are the composition rules many sites still use."}, {"code": "def current_patient():\n    name = SESSIONS.get(request.cookies.get(\"sid\"))\n    if name is None:\n        abort(401)\n    return name\n\n", "note": "Lesson 10's session check, without the two clocks."}, {"code": "@app.post(\"/sign-in\")\ndef sign_in():\n    name = request.form.get(\"name\", \"\")\n    if name not in USERS:\n        return jsonify(error=\"no such patient\"), 404\n    if not password_is_right(name, request.form.get(\"password\", \"\")):\n        return jsonify(error=\"wrong password\"), 401\n    sid = secrets.token_urlsafe(32)\n    SESSIONS[sid] = name\n    response = jsonify(patient=name)\n    response.set_cookie(\"sid\", sid, httponly=True, secure=True, samesite=\"Lax\")\n    return response\n\n", "note": "Two helpful error messages. Read them as a stranger would: one of them says whether a name belongs to a patient."}, {"code": "@app.get(\"/me\")\ndef me():\n    return jsonify(patient=current_patient())\n\n", "note": "The smallest page that needs a session, so a test can ask whether one still works."}, {"code": "@app.post(\"/password\")\ndef change_password():\n    name = current_patient()\n    if not password_is_right(name, request.form.get(\"current\", \"\")):\n        return jsonify(error=\"wrong password\"), 401\n    new = request.form.get(\"new\", \"\")\n    problem = policy_problem(new)\n    if problem:\n        return jsonify(error=problem), 400\n    set_password(name, new)\n    return jsonify(changed=True)", "note": "Changing a password asks for the current one, checks the new one against the policy and stores it. Ask what happens to the patient's other sessions."}]}
```

### The tests

The tests below say five things. A password is stored as an Argon2id hash. Two patients with the
same password are stored differently. A stranger's name gets exactly the same answer as a wrong
password. The policy accepts a long passphrase and refuses short or guessable passwords. And a
changed password ends every other session of that account, the test lesson 10 promised. Save them
as `test_app.py`:

```python
# test_app.py
import pytest

import app as portal

PASSWORD = "lilac river morning tea"


@pytest.fixture
def client():
    portal.USERS.clear()
    portal.SESSIONS.clear()
    portal.set_password("lucia", PASSWORD)
    portal.set_password("rafael", PASSWORD)
    return portal.app.test_client()


def sign_in(client, name="lucia", password=PASSWORD):
    return client.post("/sign-in", data={"name": name, "password": password})


def test_a_patient_signs_in_with_the_right_password(client):
    assert sign_in(client).status_code == 200


def test_the_password_is_stored_as_an_argon2id_hash(client):
    stored = portal.USERS["lucia"]
    assert stored.startswith("$argon2id$")
    assert "lilac" not in stored


def test_the_same_password_is_stored_differently(client):
    assert portal.USERS["lucia"] != portal.USERS["rafael"]


def test_an_unknown_name_looks_like_a_wrong_password(client):
    unknown = sign_in(client, name="nobody")
    wrong = sign_in(client, password="not the password at all")
    assert unknown.status_code == wrong.status_code == 401
    assert unknown.json == wrong.json


@pytest.mark.parametrize("password, accepted", [
    ("lilac river morning tea", True),
    ("Vereda2026!", False),
    ("Vereda@2026Vereda!", False),
    ("passwordpassword", False),
])
def test_the_password_policy(password, accepted):
    assert (portal.policy_problem(password) is None) == accepted


def test_changing_the_password_ends_the_other_sessions(client):
    laptop, phone = client, portal.app.test_client()
    sign_in(laptop)
    sign_in(phone)
    answer = laptop.post("/password", data={"current": PASSWORD, "new": "seven quiet harbour lamps"})
    assert answer.status_code == 200
    assert phone.get("/me").status_code == 401
    assert laptop.get("/me").status_code == 200
```

`@pytest.mark.parametrize` runs `test_the_password_policy` once per pair, and pytest reports each
run on its own line with the password in its name, so a failure says which password the policy got
wrong. That makes nine tests from six functions.

### Red

```
(.venv) ana@vm:~/sc/passwords$ pytest -q --tb=no
.FFFFFF.F                                                                [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_password_is_stored_as_an_argon2id_hash - Asserti...
FAILED test_app.py::test_the_same_password_is_stored_differently - AssertionE...
FAILED test_app.py::test_an_unknown_name_looks_like_a_wrong_password - assert...
FAILED test_app.py::test_the_password_policy[lilac river morning tea-True] - ...
FAILED test_app.py::test_the_password_policy[Vereda2026!-False] - AssertionEr...
FAILED test_app.py::test_the_password_policy[Vereda@2026Vereda!-False] - Asse...
FAILED test_app.py::test_changing_the_password_ends_the_other_sessions - asse...
7 failed, 2 passed in 0.15s
```

**Seven of nine fail.** The two that pass are the ones a manual check would make: lucia signs in with
her password, and the policy refuses `passwordpassword`, though only because it has no capital
letter. Commit the flawed version:

```
(.venv) ana@vm:~/sc/passwords$ git add app.py test_app.py
(.venv) ana@vm:~/sc/passwords$ git commit -q -m "Store passwords and check the policy"
```
