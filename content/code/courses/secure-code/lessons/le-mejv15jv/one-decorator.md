---
title: One decorator, and the role from the server
version: 1
---

The first version checked access in two different ways, and both were in the wrong place.
`signed_in()` asked only whether *somebody* was signed in, and each route that needed more had to
remember to ask it. `add_note` asked the **form** whether the sender was a physiotherapist, and the
form said what the sender wanted it to say.

The fix puts the question in **one place** and makes each route state its answer where it is
declared:

```schooling-example
{"language": "python", "parts": [{"code": "def requires(*roles):\n    def decorate(view):\n        @wraps(view)\n        def checked(*args, **kwargs):", "note": "A decorator that takes the roles a route accepts. `wraps` keeps the view's name, which Flask uses to tell routes apart."}, {"code": "            name = session.get(\"staff\")\n            if name not in STAFF:\n                abort(401)", "note": "Who is asking comes from the session. A name the server does not know, or none, is `401`."}, {"code": "            if STAFF[name] not in roles:\n                abort(403)\n            return view(*args, **kwargs)\n", "note": "What they may do comes from `STAFF`, the server's table, never from the request. The wrong role is `403`, before the view runs a single line."}, {"code": "        checked.allowed_roles = roles\n        return checked\n\n    return decorate", "note": "The roles are also written on the function, so a test can ask every route what it allows."}]}
```

Read `requires` as the three rules in a dozen lines. It runs **on the server, on every request** to
the route. It reads the name from the session and the role from `STAFF`, **the server's own table**:
nothing in the request is consulted. And it distinguishes the two refusals, **`401`** for nobody
signed in and **`403`** for somebody signed in without the role.

Two more lines in the change matter. The **hidden field is gone** from the page, because nothing
reads it any more, and a field nobody reads is one somebody will one day start reading again. And
`add_note` lost its own check: the decorator is the only check, so there is one place to read, to
test and to change.

### The fix

ana makes the obvious change first: the two routes the tests named.

```
(.venv) ana@vm:~/sc/console$ git diff
diff --git a/app.py b/app.py
index dcf1f07..a1e2720 100644
--- a/app.py
+++ b/app.py
@@ -1,5 +1,6 @@
 # app.py
 import secrets
+from functools import wraps
 
 from flask import Flask, abort, jsonify, render_template_string, request, session
 
@@ -19,7 +20,6 @@ PAGE = """<h1>Vereda console</h1>
 </ul>
 {% if role == "physio" %}
 <form method="post" action="/patients/lucia/notes">
-  <input type="hidden" name="role" value="physio">
   <textarea name="text"></textarea>
   <button>Add note</button>
 </form>
@@ -34,6 +34,23 @@ def signed_in():
     return name
 
 
+def requires(*roles):
+    def decorate(view):
+        @wraps(view)
+        def checked(*args, **kwargs):
+            name = session.get("staff")
+            if name not in STAFF:
+                abort(401)
+            if STAFF[name] not in roles:
+                abort(403)
+            return view(*args, **kwargs)
+
+        checked.allowed_roles = roles
+        return checked
+
+    return decorate
+
+
 @app.get("/console")
 def console():
     name = signed_in()
@@ -47,16 +64,14 @@ def agenda():
 
 
 @app.get("/patients/<name>/notes")
+@requires("physio")
 def read_notes(name):
-    signed_in()
     return jsonify(NOTES.get(name, []))
 
 
 @app.post("/patients/<name>/notes")
+@requires("physio")
 def add_note(name):
-    signed_in()
-    if request.form.get("role") != "physio":
-        abort(403)
     NOTES.setdefault(name, []).append(request.form["text"])
     return jsonify(NOTES[name]), 201
 
```

```
(.venv) ana@vm:~/sc/console$ pytest -q --tb=no
....FF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_nobody_signed_in_gets_the_export - AssertionError: a...
FAILED test_app.py::test_every_route_says_who_may_use_it - AssertionError: no...
2 failed, 4 passed in 0.12s
(.venv) ana@vm:~/sc/console$ git commit -qam "Check the role on the server for clinical notes"
```

**The receptionist is refused, and the form's claim is ignored.** Two failures remain, and they are
the interesting ones: the export nobody remembered, and the test that is about to explain why.
