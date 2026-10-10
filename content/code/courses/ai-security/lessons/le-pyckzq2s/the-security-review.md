---
title: The security review, as a list the change has to satisfy
version: 1
---

Most of what this course built is checked by a program. Some decisions are not: whether the
assistant should be allowed to refund money on its own is a question for people. The security
review is where those decisions are made, and it has two failure modes, as alerts do. **Too heavy,
and teams route around it**, which is how `growth-test` happened. **Too light, and it is a
signature on a form.**

## What triggers one

A review is needed when a change alters what a system can reach, not every time somebody edits a
line. The course's list:

- a new system, or a system moving to a different provider;
- a new tool, or a tool given more power, such as writing where it used to read;
- a new kind of data reaching the model, above all personal data;
- memory, retrieval or anything else that keeps what users say;
- money: anything that spends it, refunds it or moves it.

A prompt edit or a new help-centre page is not on the list. Lesson 20's approval covers those, and
lesson 23's suite measures their effect.

## What it asks for

What the change adds decides what it must show, and every item is something an earlier lesson
taught how to produce. Bruno proposes letting the assistant refund small amounts itself; his change,
with the evidence he attached, is written by the course. Paste it:

```sh
mkdir -p ~/guard/data/changes
cat > ~/guard/data/changes/CHG-12.json <<'EOF'
{
 "id": "CHG-12",
 "system": "support-assistant",
 "author": "bruno.alves",
 "what": "the assistant refunds up to R$ 200 itself, through issue_refund",
 "adds": ["tool", "money", "personal-data"],
 "evidence": {
  "threat-model": "flows.json f9 and threats.json T-15, both reviewed",
  "gate": "tools.json: issue_refund allowed, confirmation above R$ 200",
  "authorisation": "refunds only jobs the asking account paid for; search.py --audit extended",
  "lgpd": "basis unchanged; no new data sent to a provider",
  "suite": "suite.json: refund-limit check"
 },
 "approved_by": []
}
EOF
```

Save the review as `~/guard/tools/review.py`:

```python
# review.py: the security review a change needs, and what it still lacks.
#
#   guard review CHANGE
#
# CHANGE is a JSON file describing a change to a system in the register:
# what it does, what it adds, the evidence its author attached for each
# item, and who approved it. What a change adds decides what it must show,
# from the table below, each item pointing at the lesson that produces it.
# Approval takes two people: the system's owner, and a reviewer who is not
# the author. The exit status is 1 until every item has evidence and both
# have approved.
import json
import os
import sys

NEEDS = {
    "always": [("threat-model", "13: the new flows, and a threat against each"),
               ("suite", "23: a check that fails if the control is removed")],
    "tool": [("gate", "10: the tool on the allowlist, and when a person confirms"),
             ("runbook", "24: a runbook for the alert that watches it")],
    "money": [("budget", "18: a limit per account and a ceiling per day")],
    "personal-data": [("authorisation", "15: it acts only for the person asking"),
                      ("lgpd", "12: the legal basis, and what reaches a provider")],
    "provider": [("assessment", "19: the provider's answers, with evidence")],
    "memory": [("retention", "16: what is kept, for whom, and for how long")],
    "prompt": [("approval", "20: the new version approved by name")],
}

with open(sys.argv[1], encoding="utf-8") as f:
    chg = json.load(f)
with open(os.path.expanduser("~/guard/data/ai-register.json"), encoding="utf-8") as f:
    reg = json.load(f)
system = next(s for s in reg["systems"] if s["name"] == chg["system"])

print("%s  %s" % (chg["id"], chg["what"]))
missing = 0
for kind in ["always"] + chg["adds"]:
    for item, lesson in NEEDS[kind]:
        got = chg["evidence"].get(item)
        missing += got is None
        print("  %-14s %-8s lesson %s" % (item, "ok" if got else "MISSING", lesson))

owner, approvers = system["owner"], set(chg["approved_by"])
reviewers = approvers - {chg["author"], owner}
print("approvals: owner %s %s; a reviewer who is not %s %s" % (
    owner, "yes" if owner in approvers else "no",
    chg["author"], "yes" if reviewers else "no"))
ready = missing == 0 and owner in approvers and reviewers
print("%d item(s) missing; %s" % (missing, "approved" if ready else "not approved"))
raise SystemExit(0 if ready else 1)
```

```
ana@lab:~/guard$ guard review data/changes/CHG-12.json; echo "exit status $?"
CHG-12  the assistant refunds up to R$ 200 itself, through issue_refund
  threat-model   ok       lesson 13: the new flows, and a threat against each
  suite          ok       lesson 23: a check that fails if the control is removed
  gate           ok       lesson 10: the tool on the allowlist, and when a person confirms
  runbook        MISSING  lesson 24: a runbook for the alert that watches it
  budget         MISSING  lesson 18: a limit per account and a ceiling per day
  authorisation  ok       lesson 15: it acts only for the person asking
  lgpd           ok       lesson 12: the legal basis, and what reaches a provider
approvals: owner ana.lima no; a reviewer who is not bruno.alves no
2 item(s) missing; not approved
exit status 1
```

Two items are missing, and both are the kind that gets forgotten because the feature works without
them. **No budget**: a refund tool with no ceiling per account and per day is lesson 18's
unbounded consumption with money instead of tokens. **No runbook**: when the alert for refunds
fires at night, lesson 24's question, *what is safe to do now?*, has no answer written down.

## Two names, and why

The review needs two approvals: the system's owner, and somebody who is not the author. The owner
answers for the system afterwards, so they must agree to what is added to it. The second reviewer is
there because **an author reviewing their own change checks what they meant to write, not what they
wrote**. If Ana were both owner and author, the second name would have to be somebody else again.

Neither approval is a signature on the whole thing. Each item has its evidence beside it: a file, a
check in the suite, a line in the threat register. A reviewer who wants to disagree has something
concrete to disagree with, and a reviewer a year later can see what was checked rather than only who
signed.
