---
title: One command, before every commit
version: 1
---

Checks help when they run on every change without anybody remembering to run them. The smallest
arrangement that does that is **one script that runs everything, and a git hook that runs the
script before each commit**. Save this as `check.sh`:

```sh
# check.sh
# Every automated check of the project, in one command. Stops at the first failure.
set -e
pytest -q
bandit -q -r . -x ./test_app.py -f custom --msg-template '{relpath}:{line}: {test_id} {msg}'
pip-audit -r requirements.txt
```

`set -e` makes the script stop, and return a failure, at the first command that fails, so a failing
check cannot be scrolled past. The project needs its `requirements.txt` for pip-audit, and git runs
whatever is in `.git/hooks/pre-commit` before it records a commit, refusing the commit if it fails:

```
(.venv) ana@vm:~/sc/checks$ printf 'flask==3.1.3\n' > requirements.txt
(.venv) ana@vm:~/sc/checks$ printf '#!/bin/sh\nexec sh ./check.sh\n' > .git/hooks/pre-commit
(.venv) ana@vm:~/sc/checks$ chmod +x .git/hooks/pre-commit
```

Now commit the hurried version:

```
(.venv) ana@vm:~/sc/checks$ git add .
(.venv) ana@vm:~/sc/checks$ git commit -m "Reset codes and receipt ids"
..                                                                       [100%]
2 passed in 0.11s
app.py:8: B105 Possible hardcoded password: 'vereda-dev'
app.py:12: B311 Standard pseudo-random generators are not suitable for security/cryptographic purposes.
app.py:16: B324 Use of weak MD5 hash for security. Consider usedforsecurity=False
app.py:20: B201 A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
```

The tests passed, bandit failed, and **git recorded nothing**: there is no commit to undo, because
the hook stopped it before it existed. Now the fixed `app.py`, with the secret key random again as
in lesson 1, the reset code from `secrets`, the receipt id declared as not a security use, and the
debugger line gone (start the server with `flask --app app run` instead):

```python
# app.py
import hashlib
import secrets

from flask import Flask

app = Flask(__name__)
app.secret_key = secrets.token_bytes(32)


def reset_code():
    return "".join(secrets.choice("0123456789") for _ in range(6))


def receipt_id(booking):
    return hashlib.md5(str(booking).encode(), usedforsecurity=False).hexdigest()
```

```
(.venv) ana@vm:~/sc/checks$ git add app.py
(.venv) ana@vm:~/sc/checks$ git commit -m "Reset codes and receipt ids, from secrets and without the debugger"
..                                                                       [100%]
2 passed in 0.09s
No known vulnerabilities found
[main (root-commit) c034774] Reset codes and receipt ids, from secrets and without the debugger
 4 files changed, 35 insertions(+)
 create mode 100644 app.py
 create mode 100644 check.sh
 create mode 100644 requirements.txt
 create mode 100644 test_app.py
```

All three checks passed and the commit was made. `root-commit` in the last lines is the proof that
the refused attempt left nothing behind: this is the repository's first commit.

### What a local hook is, and is not

A hook lives in `.git/hooks`, which git never commits, so **each person installs it on their own
machine** and anybody can skip it with `git commit --no-verify`. It also checks the files as they
are on disk, not exactly the version being committed. That makes it a courtesy to yourself: the
fastest possible warning. The check that the team relies on runs the same `check.sh` on a server,
for every change, where nobody can skip it; that is the next section.
