---
title: Where secrets hide
version: 1
---

A **secret** is any value that grants access by being known: the key Flask signs session cookies
with, the password of a database, the token an SMS provider charges a message to, a private key.
Whoever has it can act as the application, and nothing records that it was copied. The defence is
to decide **where a secret lives**, and to keep it out of every other place.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l16-paths\" aria-label=\"Where a secret should live and where it should not. On the left, the places a secret leaks from: the code, a committed configuration file, the repository's history, a log line, a screenshot in a ticket. On the right, the path a secret should take: it is kept in a secret manager or an environment file that git ignores, it reaches the running process as an environment variable, and the process refuses to start without it. Only the process ever reads it.\"><defs><marker id=\"l16-paths-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">where secrets leak from</text><rect x=\"20\" y=\"40\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the code</text><rect x=\"20\" y=\"86\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a committed config file</text><rect x=\"20\" y=\"132\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the repository's history</text><rect x=\"20\" y=\"178\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a log line</text><rect x=\"20\" y=\"224\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a screenshot in a ticket</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">where a secret belongs</text><rect x=\"400\" y=\"40\" width=\"280\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secret manager, or .env</text><text x=\"540.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(ignored by git)</text><rect x=\"400\" y=\"120\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">environment variable</text><rect x=\"400\" y=\"190\" width=\"280\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"208.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the process</text><text x=\"540.0\" y=\"221.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refuses to start without it</text><path d=\"M540 90 L540 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-paths-ah-paper-dim)\"></path><path d=\"M540 160 L540 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-paths-ah-paper-dim)\"></path></svg>", "caption": "A secret reaches the process through its environment, and nothing that is shared or kept ever holds it."}
```

The places on the left share one property: **they are copied, kept and shared by design.** Code is
pushed to a hosting service and cloned onto laptops. A repository's history keeps every version of
every file for as long as the repository exists. Logs are shipped to a service several people read.
A screenshot in a ticket is seen by everybody on the ticket. A secret written into any of them has
been handed to everybody who will ever read it.

### The portal's version

This lesson's folder is `~/sc/secrets`:

```
(.venv) ana@vm:~/sc$ mkdir secrets
(.venv) ana@vm:~/sc$ cd secrets
(.venv) ana@vm:~/sc/secrets$ git init -b main
Initialized empty Git repository in /home/ana/sc/secrets/.git/
```

Here is the part of the portal that sends reminders by SMS, as it was first written, with the
provider's key typed in beside the session key from lesson 18. The key here is invented and opens
nothing. Save it as `app.py`:

```python
# app.py
from flask import Flask

app = Flask(__name__)
app.secret_key = "vereda-dev"
SMS_API_KEY = "sms_live_4f9a1c7e2b8d6a3f"


@app.get("/health")
def health():
    return {"sms": bool(SMS_API_KEY)}
```

Everything works. The reminder worker can send messages and the sessions are signed. And the day
this file is pushed, both secrets belong to everybody who can read the repository, which at a
company of Vereda's size usually includes a contractor or two from years ago.
