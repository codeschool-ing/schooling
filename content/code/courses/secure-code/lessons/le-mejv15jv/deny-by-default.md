---
title: Deny by default, enforced by a test
version: 1
---

The obvious fix fixed what the tests named. The export was never named by anyone: it was written
in an afternoon for a report, it worked, and it had no check because nothing reminded anybody it
needed one. **This is how access control fails in practice**: not a wrong check, but a route with
none.

A decorator cannot help a route it was never applied to. What helps is turning the question round:
instead of finding the routes that need protecting, **refuse to ship any route that has not said who
may use it.** The last test does that. It walks every route Flask knows, `app.url_map.iter_rules()`,
and asks of each view function whether `requires` marked it with `allowed_roles`. Run it alone:

```
(.venv) ana@vm:~/sc/console$ pytest -q --tb=short -k every_route
F                                                                        [100%]
=================================== FAILURES ===================================
_____________________ test_every_route_says_who_may_use_it _____________________
test_app.py:52: in test_every_route_says_who_may_use_it
    assert not open_routes, f"no rule says who may use {open_routes}"
E   AssertionError: no rule says who may use ['/console', '/agenda', '/export']
E   assert not ['/console', '/agenda', '/export']
=========================== short test summary info ============================
FAILED test_app.py::test_every_route_says_who_may_use_it - AssertionError: no...
1 failed, 5 deselected in 0.14s
```

The message names three routes. `/export` is the leak. `/console` and `/agenda` are open only to
staff in practice, through `signed_in()`, but **nothing on them says which staff**, and the next
person to edit them has to guess. The test does not care whether a route is dangerous. It asks that
every route answer one question in writing.

### The fix

Every remaining route says who may use it, and `signed_in()` goes, so nothing is left that checks
less than `requires` does:

```
(.venv) ana@vm:~/sc/console$ git diff
diff --git a/app.py b/app.py
index a1e2720..17bc2b8 100644
--- a/app.py
+++ b/app.py
@@ -27,13 +27,6 @@ PAGE = """<h1>Vereda console</h1>
 """
 
 
-def signed_in():
-    name = session.get("staff")
-    if name is None:
-        abort(401)
-    return name
-
-
 def requires(*roles):
     def decorate(view):
         @wraps(view)
@@ -52,14 +45,15 @@ def requires(*roles):
 
 
 @app.get("/console")
+@requires("reception", "physio", "admin")
 def console():
-    name = signed_in()
-    return render_template_string(PAGE, name=name, role=STAFF.get(name))
+    name = session["staff"]
+    return render_template_string(PAGE, name=name, role=STAFF[name])
 
 
 @app.get("/agenda")
+@requires("reception", "physio", "admin")
 def agenda():
-    signed_in()
     return jsonify(AGENDA)
 
 
@@ -77,6 +71,7 @@ def add_note(name):
 
 
 @app.get("/export")
+@requires("admin")
 def export():
     rows = [f"{patient},{len(notes)}" for patient, notes in NOTES.items()]
     return "\n".join(["patient,notes", *rows]) + "\n", {"Content-Type": "text/csv"}
```

```
(.venv) ana@vm:~/sc/console$ pytest -q
......                                                                   [100%]
6 passed in 0.16s
```

Commit, and look at the history:

```
(.venv) ana@vm:~/sc/console$ git commit -qam "Every route says who may use it"
(.venv) ana@vm:~/sc/console$ git log --oneline
6488c2e Every route says who may use it
38ad6af Check the role on the server for clinical notes
663e1eb Staff console: agenda, clinical notes and the export
```

### The same request, again

```
(.venv) ana@vm:~/sc/console$ curl -si http://127.0.0.1:5000/export
HTTP/1.1 401 UNAUTHORIZED
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:23:14 GMT
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

`401 UNAUTHORIZED`. The request is the same one that listed every patient with notes at the start of
the lesson.

### The rule written out

With every route declaring its roles, the console's access rules can be read off the code, and they
fit in a table somebody can review:

| route | reception | physio | admin |
|---|---|---|---|
| `GET /console` | yes | yes | yes |
| `GET /agenda` | yes | yes | yes |
| `GET /patients/<name>/notes` | no | yes | no |
| `POST /patients/<name>/notes` | no | yes | no |
| `GET /export` | no | no | yes |

Notice the administrator cannot read clinical notes. That is a decision, not an oversight: ana runs
the system and has no clinical reason to read a patient's notes. **Least privilege** means a role
gets what its work needs, not everything below it. A role hierarchy where admin implies all the
rest is convenient and gives the most-attacked account the most data.
