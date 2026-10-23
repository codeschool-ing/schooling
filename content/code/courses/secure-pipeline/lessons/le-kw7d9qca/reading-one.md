---
title: Reading an advisory, and asking whether linkbox can reach it
version: 1
---

A row in an audit says a version is affected. **Whether your service is affected is a second
question, and the advisory's text is where it starts.** Most advisories say what has to be true
for the flaw to matter: a feature in use, a platform, a configuration, an attacker in a particular
position. Reading those conditions against what your service does is the cheapest triage there is,
and nothing in the audit's table does it for you.

### The Flask advisory, in full

`--desc` is on by default in pip-audit's JSON, so the description is already in `/tmp/audit.json`:

@@CAPTURE flask@@

The flaw: Flask is meant to add `Vary: Cookie` to a response whenever the code touches the session,
so that a cache in front of the service does not store one user's page and hand it to another. In
some cases, such as testing whether a key is in the session, it forgot. The advisory then says when
that matters, as a list of conditions that must **all** hold:

1. A caching proxy in front of the service that caches responses carrying cookies.
2. No `Cache-Control` header marking the page private.
3. The code reads the session's keys without reading values or changing it.

linkbox fails the third condition before the others come up: **`app.py` never touches the
session.** It does not import `session` and stores nothing in a cookie. Nor is there a cache in
front of it, in staging or anywhere this course deploys it. For linkbox as it stands, this advisory
describes code it never runs.

That is **reachability**: whether your service, as written and deployed, can execute the vulnerable
code under the conditions the flaw needs. A finding that is not reachable is still true. It is a
statement about linkbox today, and it stops being true the day somebody adds a login that uses
the session.

### The other fourteen

The same reading, done for every flaw in the audit. The descriptions are in the same JSON file,
and the conditions below are the advisories' own.

| package | flaws | what the advisory needs | linkbox |
|---|---|---|---|
| flask | CVE-2026-27205 | a caching proxy, and session keys read without values | never touches the session: **not reachable** |
| werkzeug | CVE-2024-34069 | the interactive debugger running, and a developer lured to a crafted site | the debug run was removed in lesson 3, and gunicorn has no debugger: **not reachable** |
| werkzeug | five `safe_join` flaws, CVE-2024-49766 and four others | the service running on Windows and serving files through `safe_join` | runs on Linux and serves no files: **not reachable** |
| werkzeug | CVE-2024-49767 | the service parsing `multipart/form-data` request bodies | `POST /links` reads a form: **reachable** |
| jinja2 | CVE-2024-22195, CVE-2024-34064 | user input used as attribute *names* in the `xmlattr` filter | never uses `xmlattr`: **not reachable** |
| jinja2 | CVE-2024-56201, CVE-2024-56326, CVE-2025-27516 | an attacker able to write a template, with or without the sandbox | the only template is a constant in `app.py`: **not reachable** |
| gunicorn | CVE-2024-1135, CVE-2024-6827 | a request with conflicting `Transfer-Encoding` headers reaching gunicorn | every request passes through gunicorn: **reachable** |

**Three of fifteen are reachable today**, and two of those three are gunicorn's request-smuggling
flaws, which matter most when a proxy sits in front of gunicorn and the two read the same request
differently. That is the shape of most audits: a long list, a short list of what is actually on a
path the service runs, and a reason for each line.

### What reachability is for, and what it is not for

It is tempting to read that table as permission to fix three packages and leave the rest. That
would be a mistake for linkbox, for two reasons. Every one of the fifteen has a fixed version, and
the last section of this lesson shows the move costs a few lines and a test run. And a reachability
judgement is **a judgement made by reading**, which a later commit can quietly invalidate: a new
page that uses `|xmlattr`, a login that uses the session, a file download served with
`send_from_directory`. Nothing tells you when that happens.

So reachability earns its keep in two places:

- **Ordering the work** when there is more of it than time: reachable first.
- **Deciding about a finding that has no fix.** When upgrading is not possible, "can we reach it"
  is most of the argument for accepting it for a while, and lesson 7 turns that argument into an
  exception with an owner and a date.

Write the reasoning down either way. A finding marked "not reachable" with no sentence beside it is
indistinguishable, a month later, from one nobody read.
