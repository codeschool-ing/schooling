---
title: Runbooks, written before the night they are needed
version: 1
---

Lesson 22 ended with a rule: every alert carries a link to its runbook. This lesson writes them, and
then uses one, because an incident is the one moment nobody has time to think from first principles.
**A runbook is the thinking done in daylight**, by somebody who was awake, for the person who will be
reading it at three in the morning.

## Four questions, always the same four

A runbook that is a page of advice gets skimmed. One that answers the same four questions in the same
order gets used, because the reader knows where to look:

| heading | answers |
|---|---|
| What it means | what has happened, in one or two sentences, and how bad it is |
| Look first | the commands that confirm it and size it, in the order to run them |
| Safe now | what the person on call may do alone, before anybody else is awake |
| Call | who must be told, and when |

*Safe now* is the heading that matters most and the one most often missing. Revoking a key breaks
whatever uses it; rolling back a prompt undoes somebody's work. The runbook settles in advance that
the person on call is **allowed** to do those things without asking, because waiting for permission
is how a leaked key stays live for another four hours.

Two runbooks, for two of lesson 22's three rules. Paste them:

```sh
mkdir -p ~/guard/data/runbooks
cat > ~/guard/data/runbooks/canary.md <<'EOF'
# canary: the system prompt reached a reply

## What it means
A reply carried CANARY-7F3A-TAREFA, so the system prompt, or part of it,
reached a client. Everything the prompt holds has leaked with it.

## Look first
- the call the alert names: guard trace CALL
- what the prompt includes, and whether any of it is a credential
- guard keys --now TODAY, for what each credential may do

## Safe now
- revoke every credential the prompt held; guard blast KEY says what stops
- open an incident with guard incident, and write each step with its time
- keep the call log: it is the evidence, so pause the sweep

## Call
- the owner of each revoked key, to issue its replacement
- the encarregado, if the prompt or a key reaches personal data
EOF
cat > ~/guard/data/runbooks/rejects.md <<'EOF'
# rejects: replies the schema refused, above their usual level

## What it means
More of the classifier's replies than usual fail lesson 9's schema. The
clients reach a person instead of an answer: slower, not harmful.

## Look first
- guard prompts status: did a file under review change unapproved?
- the latest deployment, and data/model.json

## Safe now
- guard prompts rollback FILE VERSION, to the last approved version

## Call
- whoever approved the latest change, in working hours
EOF
```

Each line under *Look first* and *Safe now* is a command from this course. That is deliberate: a
runbook that says "check whether the key was used" leaves the reader to work out how; one that says
`guard blast KEY` has already done it.

## A check that every alert has one

Runbooks rot like everything else: a rule is added and nobody writes its runbook, a rule is deleted
and its runbook stays, describing an alert that no longer fires. Save the check as
`~/guard/tools/runbooks.py`:

```python
# runbooks.py: every alert has a runbook, and every runbook says the same four things.
#
#   guard runbooks [--rules SET]
#
# For each rule of SET in data/alerts.json (tuned unless told otherwise) it
# looks for data/runbooks/METRIC.md and checks the four headings a person
# woken at night needs: what the alert means, what to look at first, what is
# safe to do now, and whom to call. A runbook with no rule is reported too:
# it describes an alert that no longer fires. The exit status is 1 while
# anything is missing.
import argparse
import glob
import json
import os

HEADINGS = ["## What it means", "## Look first", "## Safe now", "## Call"]

p = argparse.ArgumentParser(prog="guard runbooks")
p.add_argument("--rules", default="tuned")
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "alerts.json"), encoding="utf-8") as f:
    rules = json.load(f)[a.rules]

missing = 0
metrics = []
for r in rules:
    metrics.append(r["metric"])
    path = os.path.join(home, "runbooks", r["metric"] + ".md")
    if not os.path.exists(path):
        print("%-8s %-6s no runbook" % (r["metric"], r["severity"]))
        missing += 1
        continue
    with open(path, encoding="utf-8") as f:
        lines = [line.rstrip() for line in f]
    absent = [h[3:] for h in HEADINGS if h not in lines]
    if absent:
        print("%-8s %-6s runbook lacks: %s" % (r["metric"], r["severity"], ", ".join(absent)))
        missing += 1
    else:
        print("%-8s %-6s ok" % (r["metric"], r["severity"]))
for path in sorted(glob.glob(os.path.join(home, "runbooks", "*.md"))):
    name = os.path.basename(path)[:-3]
    if name not in metrics:
        print("%-8s %-6s runbook for no rule" % (name, "-"))
        missing += 1
print("%d rules, %d problem(s)" % (len(rules), missing))
raise SystemExit(1 if missing else 0)
```

```
ana@lab:~/guard$ guard runbooks; echo "exit status $?"
canary   page   ok
rejects  ticket ok
denies   page   no runbook
3 rules, 1 problem(s)
exit status 1
```

**The rule that pages for denied tool calls has no runbook.** Lesson 22 made it a page because an
agent pushing against the gate is serious, and right now the person it wakes would be on their own.
The drill asks what `denies.md` should say. Like every check in lesson 23's suite, this one
exits 1 while anything is missing, so it belongs there too.
