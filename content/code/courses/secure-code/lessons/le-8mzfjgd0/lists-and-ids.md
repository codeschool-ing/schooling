---
title: Lists, owners in the request, and identifiers
version: 1
---

The list route had a different version of the flaw. It did take the patient from the session, unless
the request named one:

```python
    name = request.args.get("patient", signed_in())
```

There was a reason: the staff console wanted to reuse the route to list a patient's exams for
the physiotherapist. So `?patient=` was added, worked for staff, and worked identically for every
patient, because the route never asked who was sending it. **An owner taken from the request is an
owner the client chose.**

The fix takes the owner from the session and nothing else. If staff need a patient's exams, that is
a **different route**, in the console, behind lesson 12's `requires`, with its own rule about which
patients a physiotherapist may see. One route serving two audiences is how a check meant for one
of them ends up applied to neither.

```
(.venv) ana@vm:~/sc/exams$ git diff
diff --git a/app.py b/app.py
index aa1244d..945fa43 100644
--- a/app.py
+++ b/app.py
@@ -2,7 +2,7 @@
 import secrets
 import sqlite3
 
-from flask import Flask, abort, g, jsonify, request, session
+from flask import Flask, abort, g, jsonify, session
 
 app = Flask(__name__)
 app.secret_key = secrets.token_bytes(32)
@@ -64,8 +64,7 @@ def own_exam(exam_id):
 
 @app.get("/exams")
 def list_exams():
-    name = request.args.get("patient", signed_in())
-    rows = db().execute("SELECT id, title, taken FROM exams WHERE patient = ?", (name,))
+    rows = db().execute("SELECT id, title, taken FROM exams WHERE patient = ?", (signed_in(),))
     return jsonify([dict(row) for row in rows])
 
 
```

```
(.venv) ana@vm:~/sc/exams$ pytest -q
.......                                                                  [100%]
7 passed in 0.17s
```

Seven of seven. Commit, and look at the history:

```
(.venv) ana@vm:~/sc/exams$ git commit -qam "List only the signed-in patient's exams"
(.venv) ana@vm:~/sc/exams$ git log --oneline
ffa7435 List only the signed-in patient's exams
6ed7268 Read and delete an exam only for its owner
d284baa List, show and delete a patient's exams
```

### Would random identifiers have prevented this?

Partly, and the partly is the trap. If exams had ids like `ex-6yyzbgfd` instead of `1, 2, 3`, nobody
could find marta's exam by counting. That is worth having, and this catalogue's own records use opaque
ids for other reasons. But **an unguessable id is not an access check**:

- Ids leak. They appear in links shared by e-mail, in browser history on a shared computer, in
  screenshots attached to support tickets, in the logs of every proxy between the browser and the
  server.
- Ids outlive their secrecy. An id seen once is known for ever, and the record behind it does not
  move when somebody should stop seeing it.
- Random ids hide the flaw from the tests that would find it. The grid test works with any ids; a
  manual check that tries `/exams/2` stops working, and the missing check stays missing.

So random identifiers are **defence in depth**, a second layer on top of the scoped query, never a
substitute for it. The grid test is what proves the first layer is there.
