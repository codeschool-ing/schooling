---
title: A short page, a full log
version: 1
---

The fix keeps every fact the support team wanted and moves it to where the team reads it. Here is
the new `app.py`:

```python
# app.py
import logging
import secrets

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
    reference = secrets.token_hex(4)
    log.exception("unexpected error ref=%s path=%r", reference, request.path)
    return {"error": "something went wrong on our side", "reference": reference}, 500


@app.post("/login")
def login():
    name = request.form.get("name", "")
    password = request.form.get("password", "")
    if name in USERS and check_password_hash(USERS[name], password):
        log.info("sign-in succeeded name=%r", name)
        return {"signed_in": name}
    log.warning("sign-in failed name=%r", name)
    return {"error": "wrong name or password"}, 401


@app.get("/patients/<name>/phone")
def phone(name):
    return {"phone": PHONES[name]}
```

Three changes, each one line or two:

- **The error page says that something went wrong, and gives a reference**: eight hexadecimal
  characters from `secrets`, different every time. A patient who calls the clinic reads it out, and
  the team finds the exact failure in the log.
- **`log.exception` writes the traceback to the log**, with the same reference and the path that
  failed. Everything the old page showed is still recorded; it is just not shown to the person who
  asked.
- **The sign-in logs the outcome and the name, and never the password**, and it logs the name with
  `%r`, which writes it as a Python string literal, quotes and escaped line breaks included. The
  section after next says why.

```
(.venv) ana@vm:~/sc/errors$ pytest -q
....                                                                     [100%]
4 passed in 0.38s
```

The same three requests against the new version:

```
(.venv) ana@vm:~/sc/errors$ flask --app app run > server.log 2>&1 &
(.venv) ana@vm:~/sc/errors$ curl -s http://127.0.0.1:5000/patients/marta/phone
{"error":"something went wrong on our side","reference":"9e047314"}
(.venv) ana@vm:~/sc/errors$ curl -s -d 'name=lucia&password=correct horse battery staple' http://127.0.0.1:5000/login
{"signed_in":"lucia"}
(.venv) ana@vm:~/sc/errors$ grep -A 8 'portal' server.log
ERROR portal unexpected error ref=9e047314 path='/patients/marta/phone'
Traceback (most recent call last):
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 917, in full_dispatch_request
    rv = self.dispatch_request()
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 902, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "/home/ana/sc/errors/app.py", line 39, in phone
    return {"phone": PHONES[name]}
--
INFO portal sign-in succeeded name='lucia'
INFO werkzeug 127.0.0.1 - - [23/Oct/2026 11:28:18] "POST /login HTTP/1.1" 200 -
```

The page says *"something went wrong on our side"* and gives the reference. The log carries the
same reference, the path, and the traceback down to the line that failed, which `grep -A 8` cut
short here. The sign-in line says who signed in and that it succeeded, and nothing about what they
typed.

### And the debugger

Flask's debug mode, lesson 19's B201, turns every error into an interactive page that shows the
source and can run Python on the server. It is the error page that says too much, taken as far as
it goes. **It is for your own machine, and it is switched on by `--debug` or `FLASK_DEBUG=1`**, never
by code that ships. Nothing in this lesson's transcripts runs it.
