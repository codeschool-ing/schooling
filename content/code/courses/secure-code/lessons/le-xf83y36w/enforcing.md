---
title: Enforcing it
version: 1
---

The reports are quiet, so the policy is ready to be enforced. It is one word in the header's name:

```
(.venv) ana@vm:~/sc/csp$ git diff
diff --git a/app.py b/app.py
index 59e3fbf..a042943 100644
--- a/app.py
+++ b/app.py
@@ -31,7 +31,7 @@ POLICY = "; ".join([
 
 @app.after_request
 def send_the_policy(response):
-    response.headers["Content-Security-Policy-Report-Only"] = POLICY
+    response.headers["Content-Security-Policy"] = POLICY
     return response
 
 
```

```
(.venv) ana@vm:~/sc/csp$ pytest -q
......                                                                   [100%]
6 passed in 0.13s
```

Six of six. The browser now blocks what the policy refuses, and the page still works:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

The header every response now carries, as any client sees it:

```
(.venv) ana@vm:~/sc/csp$ curl -sI http://127.0.0.1:5000/
HTTP/1.1 200 OK
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:51:55 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 277
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'; report-uri /csp-report
Connection: close
```

Commit, and look at the history:

```
(.venv) ana@vm:~/sc/csp$ git commit -qam "Enforce the policy"
(.venv) ana@vm:~/sc/csp$ git log --oneline
6cc65c4 Enforce the policy
b599870 Move the page's scripts into a file
029839b Send a report-only policy, and log what it reports
ad26f87 Greet the patient with her next session
```

### Keeping it

A policy decays the way access rules do, one exception at a time. Three habits keep it honest:

- **Keep the reports coming in.** An enforced policy still reports. A report after a release means a
  page started loading something new; a sudden burst from one page may mean somebody found a missed
  escape, and the policy stopped it. Lesson 15's alerting applies.
- **Treat a new source as a review.** Adding a host to `script-src` lets every script on that host
  run in the portal with the patient's session. Ask what the host is, who controls what it serves,
  and whether a copy in `static` would do.
- **Test the header, not the intention.** The tests of this lesson fail if `'unsafe-inline'` sneaks
  into `script-src` or if a page grows an `onclick` again, which is the change a hurried fix makes.

The report endpoint accepts anything anybody posts to it, so it is a place to write to the log for
free. Keep what it logs short, as `csp_report` does by logging two fields with `%r`, and give it a
rate limit on a real portal.

Browsers are moving from `report-uri` to the **Reporting API**, with a `report-to` directive and a
`Reporting-Endpoints` header. Today `report-uri` still works in every major browser, and a policy can
carry both.
