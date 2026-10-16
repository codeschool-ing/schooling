---
title: Auditing what the code is built from
version: 1
---

Most of the code an application runs was written by somebody else. A Python service that installs
five libraries from PyPI also installs whatever those five need, and every one of them can have a
flaw that somebody finds, reports and publishes next month. **Software composition analysis**, the
SCA of lesson 16's five scanners, is the check that compares the list of what you installed with
the list of what has been published against it. It does not read your code, and it cannot find a
flaw nobody has reported yet. What it finds is the known ones, which are the ones anybody can look
up.

For Python the tool is **pip-audit**, maintained by the Python Packaging Authority. It reads a
requirements file or an installed environment, asks a vulnerability database about every package
and version, and prints what it found. Its default database is PyPI's own, and that is the one
used here.

## Installing it

pip-audit goes into the virtual environment from lesson 6, next to Locust:

```sh
~/venv/bin/pip install pip-audit==2.10.1
```

The lab machine had it installed with that same line. Check that yours answers:

```
ana@nft:~$ ~/venv/bin/pip-audit --version
pip-audit 2.10.1
```

## A project to audit

None of the services in this course uses a library from outside Python's standard library, which
is good for them and gives an auditor nothing to find. So this lesson audits a small project of
the kind a tester is handed: a helper that tells the team's chat channel when a show sells out,
written a while ago with the popular `requests` library, and pinned to the version it was written
against. Make a directory for it, `mkdir ~/audit && cd ~/audit`, and create two files there. The
first with `nano requirements.txt`:

```
# audit/requirements.txt
# What notify.py needs, pinned to the version the project has always used.
requests==2.31.0
```

The second with `nano notify.py`. You do not run it, because there is no chat channel to post to;
it is the code the findings will be checked against:

```python
# audit/notify.py
# Tells the box office's team channel that a show has sold out.
import os
import requests

session = requests.Session()

def sold_out(show_id):
    url = os.environ["NOTIFY_URL"]          # set by whoever deploys it, never typed by a customer
    session.post(url, json={"text": f"show {show_id} is sold out"}, timeout=5)
```

**This step needs the internet**, because pip-audit asks PyPI. It also installs the requirements
into a temporary environment of its own to find every package they pull in, so the first run takes
a few seconds:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt; echo "exit $?"
Found 6 known vulnerabilities in 1 package
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
exit 1
```

That is the whole report, and the first thing to read in it is not a line but the summary.
**"6 known vulnerabilities" is three advisories, each printed twice**: the same three identifiers
appear in the same order, once and then again. Counting lines would double the work of anybody
triaging it, and it would double the number on a dashboard. Three advisories, each with a version
of `requests` that fixes it. The exit code is 1, which is what lets a pipeline stop on it.

**What PyPI knows changes every day.** These lines were recorded on one day in October 2026; on
another day the same command may list more advisories, because more were published, and that is
the reason lesson 16 said SCA runs on a schedule as well as on every change.

## And the environment you already have

With no `-r`, pip-audit audits the environment it is installed in. Lesson 6's virtual environment
holds Locust, pip-audit and everything they need:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit; echo "exit $?"
Found 12 known vulnerabilities in 1 package
Name Version ID              Fix Versions
---- ------- --------------- ------------
pip  24.0    PYSEC-2026-1795 25.3
pip  24.0    PYSEC-2026-1796 26.0
pip  24.0    PYSEC-2026-2875 26.1
pip  24.0    PYSEC-2026-2876 26.1
pip  24.0    PYSEC-2026-196  26.1.2
pip  24.0    PYSEC-2026-1795 25.3
pip  24.0    PYSEC-2026-1796 26.0
pip  24.0    PYSEC-2026-196  26.1.2
pip  24.0    PYSEC-2026-2875 26.1
pip  24.0    PYSEC-2026-2876 26.1
pip  24.0    PYSEC-2026-3721 26.2
pip  24.0    PYSEC-2026-3721 26.2.0
exit 1
```

Locust and every library under it came back clean. **The finding is pip itself**: version 24.0,
the one Ubuntu's `python3 -m venv` put into the environment when lesson 6 created it, with six
advisories, each printed twice again. Nothing in this course imported pip; it is the tool that
installs everything else, which puts it in the supply chain of every package that came after it.
"Fixing, and accepting what cannot be fixed yet" deals with it.
