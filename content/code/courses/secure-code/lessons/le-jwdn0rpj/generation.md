---
title: Born: an id nobody can work out, in a cookie scripts cannot read
version: 1
---

The first failure is the most dangerous one, and it hides behind a function that looks careful:

```python
def new_session_id(name):
    return hashlib.md5(f"{name}{now():%Y%m%d%H%M}".encode()).hexdigest()
```

An MD5 hash looks random: 32 hexadecimal characters, different for every input. **It is not
random. It is a fixed function of two things anybody knows**, the patient's name and the minute she
signed in. Anyone who can compute the same hash holds the same session, and the test showed it from
the defender's side: two people signing in as lucia in the same minute received the same id.

The rule is one call. Python's `secrets` module draws from the operating system's
cryptographically secure generator, and `secrets.token_urlsafe(32)` returns 32 random bytes,
256 bits, written in 43 characters that are safe in a cookie. OWASP asks for at least 64 bits of
entropy in a session id; 256 leaves a margin nobody will ever need to discuss. The `random` module
is the wrong tool for the same reason MD5 was: it is built to be repeatable, and its output can be
predicted from enough earlier values.

### The cookie's three attributes

The id is then only as safe as the cookie that carries it. Three attributes decide who else can
read it or make the browser send it:

| attribute | what it stops |
|---|---|
| `HttpOnly` | JavaScript on the page reading the cookie, so a script injected into the portal cannot copy the id (lesson 7) |
| `Secure` | the browser sending the cookie over plain HTTP, where anybody on the same network can read it |
| `SameSite=Lax` | the browser attaching the cookie to a form another site submits to the portal (lesson 9) |

None of the three is the default in `set_cookie`, which is why the first version had none. The fix
puts them in one helper, so no route can set the cookie without them. Browsers treat
`127.0.0.1` and `localhost` as secure origins, so a `Secure` cookie still works while you develop
on your own machine.

### The fix

Replace `hashlib` with `secrets`, write the id with `token_urlsafe`, and set the cookie only
through `set_sid`. Then run the tests and commit:

```
(.venv) ana@vm:~/sc/sessions$ git diff
diff --git a/app.py b/app.py
index 51c9f42..eb14d68 100644
--- a/app.py
+++ b/app.py
@@ -1,5 +1,5 @@
 # app.py
-import hashlib
+import secrets
 from datetime import datetime
 
 from flask import Flask, abort, jsonify, make_response, request
@@ -17,8 +17,12 @@ def check_password(name, password):
     return (name, password) in {("lucia", "lucia-pw"), ("rafael", "rafael-pw")}
 
 
-def new_session_id(name):
-    return hashlib.md5(f"{name}{now():%Y%m%d%H%M}".encode()).hexdigest()
+def new_session_id():
+    return secrets.token_urlsafe(32)
+
+
+def set_sid(response, sid):
+    response.set_cookie("sid", sid, httponly=True, secure=True, samesite="Lax")
 
 
 def current_patient():
@@ -32,9 +36,9 @@ def current_patient():
 def home():
     response = make_response("Vereda patient portal\n")
     if request.cookies.get("sid") not in SESSIONS:
-        sid = new_session_id("visitor")
+        sid = new_session_id()
         SESSIONS[sid] = {"patient": None}
-        response.set_cookie("sid", sid)
+        set_sid(response, sid)
     return response
 
 
@@ -45,10 +49,10 @@ def sign_in():
         abort(401)
     sid = request.cookies.get("sid")
     if sid not in SESSIONS:
-        sid = new_session_id(name)
+        sid = new_session_id()
     SESSIONS[sid] = {"patient": name}
     response = jsonify(patient=name)
-    response.set_cookie("sid", sid)
+    set_sid(response, sid)
     return response
 
 
```

```
(.venv) ana@vm:~/sc/sessions$ pytest -q --tb=no
...FFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_signing_in_issues_a_new_id - AssertionError: assert ...
FAILED test_app.py::test_an_idle_session_expires - AssertionError: assert 200...
FAILED test_app.py::test_a_session_has_an_absolute_limit - AssertionError: as...
FAILED test_app.py::test_signing_out_ends_the_session_on_the_server - Asserti...
4 failed, 3 passed in 0.14s
(.venv) ana@vm:~/sc/sessions$ git commit -qam "Draw session ids from secrets, and mark the cookie"
```

**Two failures fewer.** The id is now 43 characters nobody can compute, and the response that
signs a patient in says how the browser must keep it. With the server running, `curl` shows the
header a real browser receives:

```
(.venv) ana@vm:~/sc/sessions$ curl -si -d name=lucia -d password=lucia-pw http://127.0.0.1:5000/sign-in
HTTP/1.1 200 OK
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:03:30 GMT
Content-Type: application/json
Content-Length: 20
Set-Cookie: sid=3vZGSodFsBzECJzgVUuXZIFu60Hy3zrvRAymneatEcM; Secure; HttpOnly; Path=/; SameSite=Lax
Connection: close

{"patient":"lucia"}
```

`Set-Cookie` carries the id and the three attributes; `Path=/` means every page of the portal
receives it. The id in that response belongs to nobody but the run that printed it: run the same
command twice and the two ids share nothing.
