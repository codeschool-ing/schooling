---
title: A token only the portal's own pages know
version: 1
---

The idea is simple. When the portal renders a form, it puts in a random value tied to the patient's
session. When the form comes back, the portal checks that the value is there and is the right one.
A page on another site can make the browser send a request, but it **cannot read the portal's
pages**, so it cannot know the value, and its request arrives without it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l09-token\" aria-label=\"The synchroniser token pattern in three steps. One: lucia's browser asks for GET /account; the portal draws a random token, keeps it in her session and writes it into a hidden field of each form. Two: she submits the form; the request carries the token, the portal compares it with the one in her session, they match, and the change is made. Three: a request started by a page on another site arrives with her cookie but without the token, because that page cannot read the portal's pages; the portal answers 403 and changes nothing.\"><defs><marker id=\"l09-token-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-token-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"30\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"50\" y=\"24\" width=\"220\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">GET /account</text><path d=\"M270 48 L380 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-token-ah-phosphor)\"></path><rect x=\"380\" y=\"24\" width=\"310\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"41.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">token drawn, kept in the session,</text><text x=\"535.0\" y=\"54.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">written into each form</text><text x=\"30\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><rect x=\"50\" y=\"100\" width=\"220\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">POST with the token</text><path d=\"M270 124 L380 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-token-ah-phosphor)\"></path><rect x=\"380\" y=\"100\" width=\"310\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">matches the session's: 303, changed</text><text x=\"30\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">3</text><rect x=\"50\" y=\"176\" width=\"220\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">POST from another site</text><path d=\"M270 200 L380 200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-token-ah-amber)\"></path><rect x=\"380\" y=\"176\" width=\"310\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no token: 403, nothing changed</text></svg>", "caption": "Another site can make the browser send a request; it cannot read the portal's page, so it cannot know the token."}
```

This is the **synchroniser token pattern**, and it has four rules, each a line in the fix:

- **Random, from `secrets`**, like a session id, because it is one: knowing it is what makes a
  request look like the portal's own.
- **Tied to the session.** A token from another session is refused, or anybody with an account could
  take their own token and put it in a form that targets somebody else. The fourth test checks it.
- **Checked on every change, in one place.** `@app.before_request` runs before every route, so the
  check covers the phone form, and the next form somebody adds, without anybody remembering. This is
  lesson 12's deny by default again: a new route is protected unless somebody does something to
  unprotect it.
- **Compared in constant time.** `secrets.compare_digest` takes as long for a token wrong in the
  first character as for one wrong in the last, so the time of the answer says nothing about how
  close a guess was. It wants bytes, or text with only ASCII characters, so both sides are encoded.

One more line matters as much as the others: **an empty expected token refuses.** A session that has
never rendered a form has no token, and comparing the empty string a request sends with the empty
string the session holds would say they match.

### The fix

```
(.venv) ana@vm:~/sc/csrf$ git diff
diff --git a/app.py b/app.py
index 57c0930..7f46529 100644
--- a/app.py
+++ b/app.py
@@ -9,10 +9,12 @@ ACCOUNTS = {"lucia": {"email": "lucia@mail.example", "phone": "+55 11 5555-0101"
 
 PAGE = """<h1>Your account</h1>
 <form method="post" action="/account/email">
+  <input type="hidden" name="csrf" value="{{ csrf_token() }}">
   <input name="email" value="{{ account.email }}">
   <button>Change e-mail</button>
 </form>
 <form method="post" action="/account/phone">
+  <input type="hidden" name="csrf" value="{{ csrf_token() }}">
   <input name="phone" value="{{ account.phone }}">
   <button>Change phone</button>
 </form>
@@ -26,6 +28,25 @@ def signed_in():
     return name
 
 
+def csrf_token():
+    if "csrf" not in session:
+        session["csrf"] = secrets.token_urlsafe(32)
+    return session["csrf"]
+
+
+app.jinja_env.globals["csrf_token"] = csrf_token
+
+
+@app.before_request
+def refuse_cross_site_changes():
+    if request.method in ("GET", "HEAD", "OPTIONS"):
+        return
+    expected = session.get("csrf")
+    sent = request.form.get("csrf", "")
+    if not expected or not secrets.compare_digest(sent.encode(), expected.encode()):
+        abort(403)
+
+
 @app.get("/account")
 def account():
     return render_template_string(PAGE, account=ACCOUNTS[signed_in()])
```

```
(.venv) ana@vm:~/sc/csrf$ pytest -q --tb=no
.....FF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_change_from_another_origin_is_refused - assert 303...
FAILED test_app.py::test_the_session_cookie_is_samesite_lax - AssertionError:...
2 failed, 5 passed in 0.12s
(.venv) ana@vm:~/sc/csrf$ git commit -qam "Refuse a change without the session's token"
```

**Five of seven pass.** Every form carries the token, a change without it is refused, and so is a
change carrying another session's. The two failures left are the other two defences.
