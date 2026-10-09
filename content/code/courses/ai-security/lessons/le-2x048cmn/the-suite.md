---
title: The course's checks, run as one suite
version: 1
---

Twenty-two lessons left behind programs that exit with a status: `threats.py` exits 1 when a flow
crossing a boundary has no threat written against it, `search.py --audit` when a reader can see a
document that is not theirs, `prompts.py status` when a file under review changed without a name
beside it. **Each one is a test already.** What none of them does yet is run on its own. A check
somebody remembers to run before a release is a check that is skipped the week it matters.

## One file of checks

A regression test for a defence says: this control held yesterday, and a change today must not
quietly undo it. The suite is a list of commands and the exit status each must return. Paste it:

```sh
cat > ~/guard/data/suite.json <<'EOF'
[
 {"name": "every boundary flow has a threat", "run": "guard threats", "expect": 0},
 {"name": "retrieval shows each reader only theirs", "run": "guard search --audit data/questions.jsonl", "expect": 0},
 {"name": "files under review are approved", "run": "guard prompts status", "expect": 0},
 {"name": "screens follow the rules", "run": "guard uxcheck data/ui-copy-fixed.json", "expect": 0},
 {"name": "no credentials in the repository", "run": "guard keyscan data/repo --allow data/keyscan-allow.txt", "expect": 0,
  "known": {"ticket": "SEC-41", "until": "2026-10-31", "why": "lesson 17's findings, moving to the secret store"}},
 {"name": "keys narrow, stored and rotated", "run": "guard keys --now 2026-10-09", "expect": 0,
  "known": {"ticket": "SEC-42", "until": "2026-10-05", "why": "lesson 17's three keys: rotate, narrow, move out of the code"}}
]
EOF
```

The last two checks carry a `known` entry, and that is the part worth reading slowly. Lesson 17
found real problems in the repository and in the keys, and fixing them takes days. **A suite that is
red from the first day teaches everybody to ignore red.** A suite that leaves those two out says
nothing about them for ever. So a failure may be *known*: it names a ticket, the reason and the date
by which it will be fixed, and until that date it is reported without failing the build. After it,
it fails like any other.

The runner prints a verdict per check and exits 1 when anything would block a merge. Save it as
`~/guard/tools/defences.py`:

```python
# defences.py: the course's checks, run together as the build would run them.
#
#   guard defences SUITE --now DATE
#
# SUITE lists checks, each a guard command and the exit status it must
# return. A check that fails may be KNOWN: it names a ticket, the reason and
# the date by which it will be fixed. A known failure does not fail the
# suite until that date; after it, it is OVERDUE and fails like any other.
# The exit status is 1 when anything FAILs or is OVERDUE, which is what makes
# a pull request red.
import argparse
import datetime as dt
import json
import os
import subprocess

p = argparse.ArgumentParser(prog="guard defences")
p.add_argument("suite")
p.add_argument("--now", required=True)
a = p.parse_args()
now = dt.date.fromisoformat(a.now)

with open(a.suite, encoding="utf-8") as f:
    checks = json.load(f)
env = dict(os.environ, PATH=os.path.expanduser("~/guard/bin") + os.pathsep + os.environ["PATH"])

red = 0
for c in checks:
    code = subprocess.run(c["run"], shell=True, env=env, cwd=os.path.expanduser("~/guard"),
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode
    if code == c["expect"]:
        verdict, note = "PASS", ""
    elif "known" in c and dt.date.fromisoformat(c["known"]["until"]) >= now:
        verdict, note = "KNOWN", "%s until %s: %s" % (c["known"]["ticket"], c["known"]["until"], c["known"]["why"])
    elif "known" in c:
        verdict, note = "OVERDUE", "%s was due %s" % (c["known"]["ticket"], c["known"]["until"])
    else:
        verdict, note = "FAIL", "exit %d, expected %d" % (code, c["expect"])
    red += verdict in ("FAIL", "OVERDUE")
    print(("%-8s %-40s %s" % (verdict, c["name"], note)).rstrip())
print("%d checks, %d failing the build" % (len(checks), red))
raise SystemExit(1 if red else 0)
```

## The first run

```
ana@lab:~/guard$ guard defences data/suite.json --now 2026-10-09; echo "exit status $?"
PASS     every boundary flow has a threat
PASS     retrieval shows each reader only theirs
FAIL     files under review are approved          exit 1, expected 0
PASS     screens follow the rules
KNOWN    no credentials in the repository         SEC-41 until 2026-10-31: lesson 17's findings, moving to the secret store
OVERDUE  keys narrow, stored and rotated          SEC-42 was due 2026-10-05
6 checks, 2 failing the build
exit status 1
```

Three verdicts, and each one is the suite doing its job:

- **FAIL on the files under review.** In a freshly built lab nobody has approved the classifier
  prompt, the help centre pages or `model.json`, so `prompts status` exits 1. That is lesson 20's
  rule, now enforced by something other than memory;
- **KNOWN for the repository.** The four findings of lesson 17 are still there, and the suite says
  so in one line with the ticket that owns them;
- **OVERDUE for the keys.** The fix for lesson 17's three keys was promised for 5 October. Today is
  the 9th, so the exception has lapsed and the failure counts. An exception with no date is a
  permanent hole; one with a date comes back to the person who asked for it.

## Approving, and running again

The reviewer reads the five files and approves them, as in lesson 20:

```
ana@lab:~/guard$ for f in data/prompts/classify.txt data/helpdesk/*.md data/model.json; do guard prompts approve $f --by ana.lima --on 2026-10-09 --reason "read in full"; done
approved data/prompts/classify.txt aa32449d3f by ana.lima
approved data/helpdesk/hc-fees.md ff40a81202 by ana.lima
approved data/helpdesk/hc-payouts.md 0fe2b8eec1 by ana.lima
approved data/helpdesk/hc-refunds.md f32fa16253 by ana.lima
approved data/model.json 3138932013 by ana.lima
```

```
ana@lab:~/guard$ guard defences data/suite.json --now 2026-10-09; echo "exit status $?"
PASS     every boundary flow has a threat
PASS     retrieval shows each reader only theirs
PASS     files under review are approved
PASS     screens follow the rules
KNOWN    no credentials in the repository         SEC-41 until 2026-10-31: lesson 17's findings, moving to the secret store
OVERDUE  keys narrow, stored and rotated          SEC-42 was due 2026-10-05
6 checks, 1 failing the build
exit status 1
```

**One failure left, and it is the one somebody promised to fix.** The suite cannot rotate a key. It
can make sure the promise does not quietly become the way things are, which is what a known failure
with no date turns into.

Every line here runs in well under a second, needs no model and no network, and gives the same
answer on every machine. That is what lets it run on every pull request. The next section is about
the check that has none of those properties.
