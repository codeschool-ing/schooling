---
title: Secrets from the environment, and refusing without them
version: 1
---

The usual place for a secret to reach a running program is an **environment variable**. Whatever starts the process sets it: a service manager, a container platform, a CI system, a secret manager. The program reads it at start-up, and it is never written into a file the project shares.

The tests say three things. The application takes its secrets from the environment. It **refuses
to start** when one is missing. And no secret is written in the code. Save them as `test_app.py`:

```python
# test_app.py
import importlib

import pytest

NAMES = ("PORTAL_SECRET_KEY", "SMS_API_KEY")


def load(monkeypatch, **env):
    for name in NAMES:
        monkeypatch.delenv(name, raising=False)
    for name, value in env.items():
        monkeypatch.setenv(name, value)
    import app
    return importlib.reload(app)


def test_secrets_come_from_the_environment(monkeypatch):
    portal = load(monkeypatch, PORTAL_SECRET_KEY="k" * 32, SMS_API_KEY="test-key")
    assert portal.app.secret_key == "k" * 32
    assert portal.SMS_API_KEY == "test-key"


def test_the_app_refuses_to_start_without_them(monkeypatch):
    with pytest.raises(RuntimeError, match="PORTAL_SECRET_KEY"):
        load(monkeypatch)


def test_no_secret_is_written_in_the_code():
    with open("app.py") as source:
        assert "sms_live_" not in source.read()
```

`load` clears the two variables, sets the ones a test asks for, and imports `app.py` afresh, so each
test sees the module as it would start with that environment. Against the first version:

```
(.venv) ana@vm:~/sc/secrets$ pytest -q --tb=no
FFF                                                                      [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_secrets_come_from_the_environment - AssertionError: ...
FAILED test_app.py::test_the_app_refuses_to_start_without_them - Failed: DID ...
FAILED test_app.py::test_no_secret_is_written_in_the_code - assert 'sms_live_...
3 failed in 0.08s
```

Commit it as it is, which is exactly the mistake the next section is about:

```
(.venv) ana@vm:~/sc/secrets$ git add app.py test_app.py
(.venv) ana@vm:~/sc/secrets$ git commit -q -m "Send reminders by SMS"
```

### Fail closed

Here is the new `app.py`:

```python
# app.py
import os

from flask import Flask


def required(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"{name} is not set: the application will not start without it")
    return value


app = Flask(__name__)
app.secret_key = required("PORTAL_SECRET_KEY")
SMS_API_KEY = required("SMS_API_KEY")


@app.get("/health")
def health():
    return {"sms": bool(SMS_API_KEY)}
```

```
(.venv) ana@vm:~/sc/secrets$ pytest -q
...                                                                      [100%]
3 passed in 0.27s
```

**`required` refuses to start rather than fall back.** A program that quietly uses a default key
when the variable is missing, `os.environ.get("PORTAL_SECRET_KEY", "dev")`, starts in production
with a key printed in the repository, and every test passes. Refusing makes the missing variable a
start-up error somebody sees in minutes:

```
(.venv) ana@vm:~/sc/secrets$ python3 -c 'import app'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import app
  File "/home/ana/sc/secrets/app.py", line 15, in <module>
    app.secret_key = required("PORTAL_SECRET_KEY")
                     ~~~~~~~~^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/sc/secrets/app.py", line 10, in required
    raise RuntimeError(f"{name} is not set: the application will not start without it")
RuntimeError: PORTAL_SECRET_KEY is not set: the application will not start without it
```

### On your own machine: a `.env` file git ignores

For development, the variables live in a file called `.env` in the project folder, and **`.gitignore`
keeps it out of every commit**. Generate a random session key into it, with a placeholder for the
SMS key, and check that git ignores it:

```
(.venv) ana@vm:~/sc/secrets$ printf 'PORTAL_SECRET_KEY=%s\nSMS_API_KEY=%s\n' "$(python3 -c 'import secrets; print(secrets.token_hex(32))')" sms_test_0000 > .env
(.venv) ana@vm:~/sc/secrets$ printf '.env\n__pycache__/\n' > .gitignore
(.venv) ana@vm:~/sc/secrets$ git check-ignore -v .env
.gitignore:1:.env	.env
(.venv) ana@vm:~/sc/secrets$ git status --short
 M app.py
?? .gitignore
```

`git check-ignore -v` names the rule that ignores the file, and `git status` does not list `.env`
at all. A shell loads it with `set -a`, which exports every variable the file defines, and the
application reads them:

```
(.venv) ana@vm:~/sc/secrets$ set -a; . ./.env; set +a; python3 -c 'import app; print(app.SMS_API_KEY)'
sms_test_0000
```

The `.env` file is still a secret on disk. It is fine on your laptop for a development key; it is
not how production receives its secrets, which is the last section of this lesson.
