---
title: Where credentials end up when nobody is looking
version: 1
---

Tarefa's assistant runs on credentials: a key for the model provider, a key for the payments system
that issues refunds, a password for the orders database, a key for the store the log is written to.
Each one is a permission somebody can use without being Tarefa. **A credential is safe exactly where
nobody but the code that needs it can read it**, and an LLM application has more places for one to
leak than an ordinary one: the prompt, the log of prompts, the error a tool returns, and the source
code that builds all three.

The first defence is mechanical. Before anything reaches the repository, a program reads every file
for something shaped like a credential. The repository below is Tarefa's in miniature, written by the
course. **Every key in it is fake**: the ones beginning `sk-lab-` were made up for this lesson, and
the one beginning `AKIA` is the example Amazon prints in its own documentation, which opens nothing.
Paste it:

```sh
mkdir -p ~/guard/data/repo/app ~/guard/data/repo/prompts ~/guard/data/repo/deploy ~/guard/data/repo/logs ~/guard/data/repo/docs
cat > ~/guard/data/repo/app/config.py <<'EOF'
import os

PROVIDER_URL = "https://api.provider.example/v1"
PROVIDER_KEY = os.environ["PROVIDER_KEY"]
EOF
cat > ~/guard/data/repo/app/payments.py <<'EOF'
PAYMENTS_URL = "https://payments.example/v2"
PAYMENTS_KEY = "sk-lab-payments-00000000000000000000"
EOF
cat > ~/guard/data/repo/prompts/support.txt <<'EOF'
You are Tarefa's support assistant. Answer from the help centre.
When a refund is approved, call the payments API with the key
sk-lab-payments-00000000000000000000 and the job number.
EOF
cat > ~/guard/data/repo/deploy/.env <<'EOF'
DB_HOST=orders.internal
DB_PASSWORD=correct-horse-lab-only
EOF
cat > ~/guard/data/repo/logs/2026-10-01.log <<'EOF'
14:02:11 POST /v1/chat/completions 200 Authorization: Bearer sk-lab-provider-11111111111111111111
EOF
cat > ~/guard/data/repo/docs/storage.md <<'EOF'
The storage client reads its key from the environment. The example key in
Amazon's own documentation is AKIAIOSFODNN7EXAMPLE, and it opens nothing.
EOF
cat > ~/guard/data/keyscan-allow.txt <<'EOF'
# One line per accepted finding: the file, the fingerprint, and why.
docs/storage.md  1a5d44a2dca1  Amazon's documented example key; it opens nothing
EOF
```

The scanner uses the key shapes `detect.py` already knows from lesson 11, and adds one rule: an
assignment whose name says it holds a secret. Save it as `~/guard/tools/keyscan.py`:

```python
# keyscan.py: credentials written into files, before they reach a repository.
#
#   guard keyscan DIR [--allow FILE]
#
# It walks DIR and reports every line holding something shaped like a
# credential: the provider and cloud key shapes detect.py knows (lesson 11),
# and an assignment whose name says it is a secret. It prints the file, the
# line, the kind, the value MASKED and its fingerprint, the first twelve hex
# digits of its SHA-256: a scanner that prints the secret it found has just
# copied it into the build log, and a fingerprint names one value exactly
# without revealing it.
#
# --allow names a file of accepted findings, one per line: the path, the
# fingerprint and the reason. A finding listed there is reported as ALLOWED
# with its reason, so an exception is a written decision rather than a
# silence. The exit status is 1 while any finding is not allowed.
import argparse
import hashlib
import os
import re

from detect import SECRET

ASSIGNED = re.compile(r"(?i)\b\w*(?:password|passwd|secret|token|api_key)\w*\s*[=:]\s*['\"]?([^\s'\"]{8,})")


def mask(value):
    return value[:4] + "****"


def fingerprint(value):
    return hashlib.sha256(value.encode()).hexdigest()[:12]


def findings(text):
    for n, line in enumerate(text.splitlines(), 1):
        seen = set()
        for m in SECRET.finditer(line):
            seen.add(m.group())
            yield n, "key", m.group()
        for m in ASSIGNED.finditer(line):
            if m.group(1) not in seen:
                yield n, "assignment", m.group(1)


p = argparse.ArgumentParser(prog="guard keyscan")
p.add_argument("dir")
p.add_argument("--allow")
a = p.parse_args()

allowed = {}
if a.allow:
    with open(a.allow, encoding="utf-8") as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                path, fp, why = line.split(None, 2)
                allowed[(path, fp)] = why.strip()

bad = ok = 0
for root, dirs, files in sorted(os.walk(a.dir)):
    dirs.sort()
    for name in sorted(files):
        full = os.path.join(root, name)
        rel = os.path.relpath(full, a.dir)
        with open(full, encoding="utf-8", errors="replace") as f:
            text = f.read()
        for n, kind, value in findings(text):
            fp = fingerprint(value)
            why = allowed.get((rel, fp))
            if why:
                ok += 1
                print("%-20s %2d  %-10s %-9s %s  ALLOWED  %s" % (rel, n, kind, mask(value), fp, why))
            else:
                bad += 1
                print("%-20s %2d  %-10s %-9s %s  FOUND" % (rel, n, kind, mask(value), fp))
print("%d finding(s), %d allowed, %d to remove" % (bad + ok, ok, bad))
raise SystemExit(1 if bad else 0)
```

```
ana@lab:~/guard$ guard keyscan data/repo; echo "exit status $?"
app/payments.py       2  key        sk-l****  9f8dfa2fe8d2  FOUND
deploy/.env           2  assignment corr****  d16dce059b1f  FOUND
docs/storage.md       2  key        AKIA****  1a5d44a2dca1  FOUND
logs/2026-10-01.log   1  key        sk-l****  015ed8aa2e80  FOUND
prompts/support.txt   3  key        sk-l****  9f8dfa2fe8d2  FOUND
5 finding(s), 0 allowed, 5 to remove
exit status 1
```

Five findings in six files, and the scanner printed none of them whole. **A scanner that prints the
secret it found has just copied it into the build log**, which is read by more people than the code
is. The mask shows enough to recognise the kind; the fingerprint names the exact value without
revealing it, which is what lets two findings be compared. `app/payments.py` and
`prompts/support.txt` share the fingerprint `9f8dfa2fe8d2`: **the same payments key is written in
two places**, so removing it from one and forgetting the other fixes nothing.

## An exception is a written decision

`docs/storage.md` holds Amazon's example key on purpose, as documentation. The scanner cannot know
that, and a person can, so the person writes it down: the file, the fingerprint, and the reason. The
allow list is part of the paste above, and with it the documented example stops failing the build:

```
ana@lab:~/guard$ guard keyscan data/repo --allow data/keyscan-allow.txt; echo "exit status $?"
app/payments.py       2  key        sk-l****  9f8dfa2fe8d2  FOUND
deploy/.env           2  assignment corr****  d16dce059b1f  FOUND
docs/storage.md       2  key        AKIA****  1a5d44a2dca1  ALLOWED  Amazon's documented example key; it opens nothing
logs/2026-10-01.log   1  key        sk-l****  015ed8aa2e80  FOUND
prompts/support.txt   3  key        sk-l****  9f8dfa2fe8d2  FOUND
5 finding(s), 1 allowed, 4 to remove
exit status 1
```

The exception is pinned to one value in one file. A real key pasted into the same document has a
different fingerprint and fails as before, which is the difference between an exception and a hole.
**An allow list without reasons is a list of things nobody remembers deciding**, and it only grows.

The exit status is still 1: four findings are real, and the rest of this lesson is where each one
belongs instead.
