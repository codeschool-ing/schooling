---
title: Reading from the environment
version: 1
---

The standard place for a value that differs between machines, secret or not, is an **environment
variable**. The code reads it, and falls back to a default when the value is not secret and a default
makes sense. loanbook's step 14 did that for its two settings:

```
ana@laptop:~/loanbook$ git show --format=%s HEAD -- app.py .gitignore
Read the database path and port from the environment

diff --git a/.gitignore b/.gitignore
index a707f54..4384d7d 100644
--- a/.gitignore
+++ b/.gitignore
@@ -1,2 +1,3 @@
 *.db
+.env
 __pycache__/
diff --git a/app.py b/app.py
index e48521f..7ff706c 100644
--- a/app.py
+++ b/app.py
@@ -1,5 +1,6 @@
 """loanbook: who has which piece of equipment, and until when."""
 import json
+import os
 import re
 import sqlite3
 import sys
@@ -10,8 +11,8 @@ from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
 from pathlib import Path
 
 HERE = Path(__file__).parent
-DB = str(HERE / "loanbook.db")
-PORT = 8000
+DB = os.environ.get("LOANBOOK_DB", str(HERE / "loanbook.db"))
+PORT = int(os.environ.get("LOANBOOK_PORT", "8000"))
 LOAN_DAYS = 7
 
 SCHEMA = """
```

`os.environ.get("LOANBOOK_DB", …)` reads the variable if it is set and uses the file beside the code if
not. The same commit added `.env` to `.gitignore`, because the usual way to set these variables on your
own machine is a file called `.env`, and that file is exactly where a secret would end up. Here is the
effect, with both variables set for one run:

```
ana@laptop:~/loanbook$ LOANBOOK_DB=/tmp/other.db LOANBOOK_PORT=8001 timeout 2 python3 app.py
loanbook on http://127.0.0.1:8001
ana@laptop:~/loanbook$ ls *.db /tmp/other.db
/tmp/other.db
loanbook.db
```

The server listened on 8001 and created its database in `/tmp`, and the default `loanbook.db` beside the
code is untouched. On the server, lesson 15, the container sets `LOANBOOK_DB` to a volume, and nothing in
the code changes.

For a real secret the pattern is the same with one difference: **no default.** `os.environ["SMTP_PASSWORD"]`,
with square brackets, fails immediately if the variable is missing. That is what you want: a program that
starts without its password and fails on the first e-mail is harder to diagnose than one that refuses to
start. And the repository gets a file called `.env.example`, committed, that lists every variable the
project needs with a fake value, so the next person knows what to set.
