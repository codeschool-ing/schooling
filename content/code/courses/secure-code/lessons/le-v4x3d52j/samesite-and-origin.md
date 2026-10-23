---
title: SameSite, and where the request came from
version: 1
---

The token makes a forged request fail. Two more lines make most forged requests **never arrive with a
session at all**, and are worth having because a token can be forgotten on a route that skips the
check, or leak in a URL.

### SameSite

`SameSite` is an attribute of a cookie that tells the browser when to attach it to a request **another
site** started:

| value | the cookie travels on another site's… |
|---|---|
| `Strict` | nothing: not even a link the patient follows to the portal |
| `Lax` | top-level navigations with `GET`, such as following a link; never a `POST` |
| `None` | everything, as before the attribute existed; it requires `Secure` |

`Lax` is the setting for most applications: following a link from an e-mail into the portal still
arrives signed in, and a form another site posts arrives **without the session cookie**, so the
portal answers it as a stranger. `Strict` is safer and makes every link into the portal arrive signed
out, which on a patient portal would mostly teach people to distrust links from their clinic.

Chrome and the browsers built on it treat a cookie with no `SameSite` attribute as `Lax`; Firefox and
Safari do not. **Set it anyway**: the default is each browser's decision, browsers have changed it
before, and the attribute in the response is a decision written down in the code. Flask's session cookie is configured through
`SESSION_COOKIE_SAMESITE` and, while at it, `SESSION_COOKIE_SECURE`; `HttpOnly` is already Flask's
default.

### The origin of the request

When a browser sends a `POST`, it adds an `Origin` header naming the site of the page that started it:
`https://portal.vereda.example` for the portal's own form, something else for a page anywhere else. The
check is one comparison: **if the request names an origin and it is not the portal's, refuse.**

A request with no `Origin` at all is let through to the token check, which still has to pass. Some
legitimate clients send none, and the token is the defence that does not depend on the browser.

Browsers also send **Fetch Metadata** headers, such as `Sec-Fetch-Site: cross-site`, which say the same
thing in more detail, and a policy built on them is a sound alternative to the origin check.

### The fix

```
(.venv) ana@vm:~/sc/csrf$ git diff
diff --git a/app.py b/app.py
index 7f46529..8751734 100644
--- a/app.py
+++ b/app.py
@@ -5,6 +5,7 @@ from flask import Flask, abort, redirect, render_template_string, request, sessi
 
 app = Flask(__name__)
 app.secret_key = secrets.token_bytes(32)
+app.config.update(SESSION_COOKIE_SAMESITE="Lax", SESSION_COOKIE_SECURE=True)
 ACCOUNTS = {"lucia": {"email": "lucia@mail.example", "phone": "+55 11 5555-0101"}}
 
 PAGE = """<h1>Your account</h1>
@@ -41,6 +42,9 @@ app.jinja_env.globals["csrf_token"] = csrf_token
 def refuse_cross_site_changes():
     if request.method in ("GET", "HEAD", "OPTIONS"):
         return
+    origin = request.headers.get("Origin")
+    if origin is not None and origin != request.host_url.rstrip("/"):
+        abort(403)
     expected = session.get("csrf")
     sent = request.form.get("csrf", "")
     if not expected or not secrets.compare_digest(sent.encode(), expected.encode()):
```

```
(.venv) ana@vm:~/sc/csrf$ pytest -q
.......                                                                  [100%]
7 passed in 0.15s
```

Seven of seven. Commit, and look at the history:

```
(.venv) ana@vm:~/sc/csrf$ git commit -qam "Keep the session cookie to its own site, and check the origin"
(.venv) ana@vm:~/sc/csrf$ git log --oneline
4bf090a Keep the session cookie to its own site, and check the origin
44aebcc Refuse a change without the session's token
84a1e45 Change the e-mail address and the phone number
```

**Three defences, each against a different condition.** The token holds even in a browser that
ignores `SameSite`; `SameSite` holds even on a route somebody exempted from the token; the origin check
refuses a cross-site request before either is consulted.
