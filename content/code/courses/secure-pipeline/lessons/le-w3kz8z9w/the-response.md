---
title: Revoke first, then clean
version: 1
---

The instinct on finding a secret in the code is to delete the line and push, and it is the wrong
first move. **Deleting the line protects nothing that was already copied**, and the last two
sections showed how many copies there are. What protects the system is making the value worthless,
so the response runs in this order, and the order is the point:

1. Revoke. The value stops working, wherever it is. Until this step is done every other step
   is housekeeping, so it happens first, and within minutes rather than at the next planning
   meeting.
2. Replace. Whatever needs access gets a new value, delivered somewhere that is not the
   repository.
3. Remove it from the code, so the next commit does not carry a value at all, live or dead.
4. Look at the window. From the commit's date to the revocation, was the value used, and by
   whom? That question needs logs, and it is the one that decides whether this is a tidy-up or an
   incident.
5. Decide about the history, which is the next section, and is the last decision rather than
   the first.
6. Make the next one harder: a hook on the laptop and a stage in the pipeline, the last two
   sections of this lesson.

**The window opens at the commit and closes at the revocation, and nothing between the two closes
it.** Deleting the line is a commit inside the window, not the end of it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l06-window\" aria-label=\"A timeline of the token. It is committed on 5 October, then pushed, cloned and forked; later a scan finds it; later still a commit deletes the line; only when the token is revoked does the window close. From the commit to the revocation, anybody with a copy can use it; after the revocation the copies open nothing.\"><defs><marker id=\"sp-l06-window-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l06-window-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"100\" width=\"545\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"332\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the window: anybody with a copy can use the token</text><text x=\"662\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">the copies open nothing</text><path d=\"M30 160 L700 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l06-window-ah-paper-dim)\"></path><line x1=\"60\" y1=\"150\" x2=\"60\" y2=\"170\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"60\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">committed</text><text x=\"60\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 October</text><line x1=\"190\" y1=\"150\" x2=\"190\" y2=\"170\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"190\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pushed, cloned,</text><text x=\"190\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">forked</text><line x1=\"330\" y1=\"150\" x2=\"330\" y2=\"170\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"330\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a scan</text><text x=\"330\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">finds it</text><line x1=\"465\" y1=\"150\" x2=\"465\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"465\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">a commit</text><text x=\"465\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">deletes the line</text><line x1=\"605\" y1=\"150\" x2=\"605\" y2=\"170\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"605\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">revoked</text><text x=\"605\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the window closes</text><text x=\"465\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">settings.py: -1 +1</text><path d=\"M465 78 L465 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-window-ah-amber)\"></path></svg>", "caption": "Only the revocation closes the window. The commit that deletes the line falls inside it, and every copy made before it is unchanged."}
```

### When somebody else issued the secret

Most secrets are issued by a provider: a cloud access key, a GitHub token, a payment API key.
Revoking one is done at the provider, on its console or through its API, and every provider
documents how; it takes a minute and needs no change to the code at all. Do it before anything
else, even before telling anybody. GitHub's documentation also describes a partner programme in
which tokens of known providers found in public repositories are reported to the provider that
issued them, so that it can revoke them. That programme was not used for this course, and it is not
a reason to wait: by the time it acts, the token has been public.

### When you issued it: linkbox

linkbox checks the token itself, against `settings.ADMIN_TOKEN`. There is no console to revoke it
on. **Revoking it means the running service stops accepting the old value, and that means the value
can no longer live in the code**, because whatever is in the code is what the service compares
against. So for linkbox, steps 1 to 3 are one change: the token moves to the service's environment,
where each deployment sets its own.

The new settings read it from `LINKBOX_TOKEN` and refuse to start without one. `os.environ[...]`
raises an error when the variable is missing, which is the behaviour wanted: a service that falls
back to a default token is a service whose default token ends up in production. Save the new
settings as `settings.py`:

```python
import os

DATABASE = os.environ.get("LINKBOX_DB", "linkbox.db")
ADMIN_TOKEN = os.environ["LINKBOX_TOKEN"]
```

The tests import the settings, so they now fail before running a single test, which is the refusal
working:

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q 2>&1 | tail -n 4
=========================== short test summary info ============================
ERROR tests/test_app.py - KeyError: 'LINKBOX_TOKEN'
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
1 error in 0.52s
```

pytest reads `tests/conftest.py` before it imports any test module, so a token set there is in
place when `settings.py` is imported. `setdefault` leaves a token that is already in the
environment alone. Save it as `tests/conftest.py`:

```python
import os

# The application refuses to start without a token. The tests bring one of
# their own, which opens nothing anywhere else.
os.environ.setdefault("LINKBOX_TOKEN", "a-token-for-the-tests-only")
```

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
.....                                                                    [100%]
5 passed in 0.23s
```

That test value is a string in a file in the repository, and it is not a secret. **What makes a
value a secret is what it opens**, and this one opens a database in a temporary directory that
exists for the length of a test.

### The rotation, on screen

A new token, generated by Python's `secrets` module and put straight into the environment, so it
is never printed and never typed into a file. Then the service, started with it, and the old token
tried against the new service:

```
ana@vm:~/linkbox$ export LINKBOX_TOKEN=$(python3 -c 'import secrets; print("lbx_" + secrets.token_urlsafe(24))')
ana@vm:~/linkbox$ .venv/bin/gunicorn --daemon --pid linkbox.pid --bind 127.0.0.1:8000 app:app
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org http://127.0.0.1:8000/links
401
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: $LINKBOX_TOKEN" -d url=https://example.org http://127.0.0.1:8000/links
201
ana@vm:~/linkbox$ kill $(cat linkbox.pid)
```

**401 for the value that sits in five commits, 201 for the new one.** That is the moment the
history stopped being dangerous. Every copy of the repository still holds `lbx_7Rq2…`, and it opens
nothing. On a real deployment the new value would go into the platform's secret store rather than
a shell variable, which lesson 17 builds; the shape of the step is the same.

Step 4 is the one linkbox cannot answer. gunicorn writes no access log unless asked to with
`--access-logfile`, and linkbox logs nothing about who created a link, so there is no record of
whether the old token was used while it was valid. **That absence is itself a finding**: the next
leak will ask the same question, and the answer has to exist before it does.

### Commit it, and look again

```
ana@vm:~/linkbox$ git add settings.py tests/conftest.py
ana@vm:~/linkbox$ git commit -q -m "the token out of the code, and a token of their own for the tests"
```

Now the two scans disagree:

```
ana@vm:~/linkbox$ gitleaks dir --no-banner --no-color .
2:00AM INF scanned ~50638 bytes (50.64 KB) in 37.4ms
2:00AM INF no leaks found
ana@vm:~/linkbox$ gitleaks git --no-banner --no-color --redact -v .
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
Finding:     ADMIN_TOKEN = "REDACTED"
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     5.058814
File:        settings.py
Line:        4
Commit:      3f932db1ab33201959dc1dd9270d46dc0485e297
Author:      Ana Lima
Email:       ana@example.org
Date:        2026-10-05T13:00:00Z
Fingerprint: 3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py:generic-api-key:4

2:00AM INF 6 commits scanned.
2:00AM INF scanned ~9214 bytes (9.21 KB) in 202ms
2:00AM WRN leaks found: 1
```

The files are clean and the history is not, and that will stay true however many commits follow.
`--redact` is new here: it prints `REDACTED` where the value would be, which is how a scan should
run anywhere its output is read by more people than the value's owner, a CI log above all.
