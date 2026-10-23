---
title: Report first, enforce later
version: 1
---

A policy written by reading the code is a guess about what the page loads, and a wrong guess
enforced on the first day breaks the portal for every patient. So a policy is introduced in two steps,
and the header's name says which:

- **`Content-Security-Policy-Report-Only`**: the browser checks every resource against the policy,
  **reports** each violation, and blocks nothing.
- **`Content-Security-Policy`**: the browser blocks every violation, and reports it.

The first is how you learn what the policy would break, from real pages in real browsers, before it
breaks anything. Leave it running for days on a real portal, read the reports, and fix what they name.

### The fix, first step

The policy goes in once, as a constant, and an `after_request` function adds it to **every**
response, so no route can forget it. A new route, `/csp-report`, receives the browser's reports and
writes each one to the portal's log, where lesson 15's rules about logs apply:

```
(.venv) ana@vm:~/sc/csp$ git diff
diff --git a/app.py b/app.py
index b003960..278aa93 100644
--- a/app.py
+++ b/app.py
@@ -1,7 +1,7 @@
 # app.py
 import logging
 
-from flask import Flask, render_template_string
+from flask import Flask, render_template_string, request
 
 app = Flask(__name__)
 log = logging.getLogger("portal")
@@ -20,6 +20,34 @@ PAGE = """<!doctype html>
 </html>
 """
 
+POLICY = "; ".join([
+    "default-src 'self'",
+    "script-src 'self'",
+    "object-src 'none'",
+    "base-uri 'none'",
+    "frame-ancestors 'none'",
+    "form-action 'self'",
+    "report-uri /csp-report",
+])
+
+
+@app.after_request
+def send_the_policy(response):
+    response.headers["Content-Security-Policy-Report-Only"] = POLICY
+    return response
+
+
+@app.post("/csp-report")
+def csp_report():
+    report = request.get_json(force=True, silent=True) or {}
+    details = report.get("csp-report", {})
+    log.warning(
+        "csp violation directive=%r blocked=%r",
+        details.get("violated-directive"),
+        details.get("blocked-uri"),
+    )
+    return "", 204
+
 
 @app.get("/")
 def home():
```

```
(.venv) ana@vm:~/sc/csp$ pytest -q --tb=no
.FFFF.                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_every_page_sends_an_enforced_policy - assert 'Conten...
FAILED test_app.py::test_scripts_come_only_from_the_portal - assert None == "...
FAILED test_app.py::test_no_page_carries_inline_script - assert not <re.Match...
FAILED test_app.py::test_the_script_file_is_served - AssertionError: assert 4...
4 failed, 2 passed in 0.13s
```

**The report endpoint works; the rest still fails**, as it should: the policy is not enforced yet,
the page still has its inline code, and there is no script file. Commit this step:

```
(.venv) ana@vm:~/sc/csp$ git add look.py
(.venv) ana@vm:~/sc/csp$ git commit -qam "Send a report-only policy, and log what it reports"
```

### What the browser reports

Restart the portal and run `look.py` again:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
console: Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-nQGnU0QE1FIi/fdNcq76F6u4piPJwMEAzr61AGlkZp0='), or a nonce ('nonce-...') is required to enable inline execution. The policy is report-only, so the violation has been logged but no further action has been taken.
console: Executing inline event handler violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-...'), or a nonce ('nonce-...') is required to enable inline execution. Note that hashes do not apply to event handlers, style attributes and javascript: navigations unless the 'unsafe-hashes' keyword is present. The policy is report-only, so the violation has been logged but no further action has been taken.
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

Two console messages, one for each habit. The first is the inline `<script>`, refused by `script-src`;
the second is the `onclick` attribute, refused the moment the button was clicked. Each one ends with
the same sentence: **the policy is report-only, so nothing was blocked.** The title was still set and
the text still got larger.

Each violation was also sent to `/csp-report`. In the terminal where the portal runs:

```
csp violation directive='script-src-elem' blocked='inline'
csp violation directive='script-src-attr' blocked='inline'
```

That is the list of what has to move before the policy can be enforced, written by the browser.

### And if you enforced it now

To see why the order matters, change `Content-Security-Policy-Report-Only` to
`Content-Security-Policy` in `app.py`, restart, and run `look.py`:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
console: Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-nQGnU0QE1FIi/fdNcq76F6u4piPJwMEAzr61AGlkZp0='), or a nonce ('nonce-...') is required to enable inline execution. The action has been blocked.
console: Executing inline event handler violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-...'), or a nonce ('nonce-...') is required to enable inline execution. Note that hashes do not apply to event handlers, style attributes and javascript: navigations unless the 'unsafe-hashes' keyword is present. The action has been blocked.
title: Vereda
larger text: False
```

The title is the bare `Vereda` from the HTML, because the script that sets it never ran, and the
button does nothing. **This is the portal's own code, broken by its own policy.** On a real portal it
would be every patient's page. Change the header name back before going on.
