---
title: Six questions for every flow that matters
version: 1
---

A threat model fails most often by asking whatever comes to mind. One person thinks of leaks, the
next of floods, and the third question nobody asks is the one that matters. **A fixed list of
questions makes the review repeatable**: two people walking the same diagram arrive at roughly the
same register, and a flow nobody questioned stands out.

The list most teams use is **STRIDE**, written at Microsoft in 1999. Each letter is a kind of
failure, and each is the opposite of a property the application is meant to keep:

| letter | the failure | the property it breaks | at Tarefa |
|---|---|---|---|
| **S** | spoofing | who somebody is | a client acting as another client's account |
| **T** | tampering | that data is what it was | text in a message or a file that changes what the model does |
| **R** | repudiation | that an action can be traced | a reply nobody can tie to the prompt that produced it |
| **I** | information disclosure | that data reaches only its readers | a CPF in a reply, a prompt sent to the provider whole |
| **D** | denial of service | that the service stays available | one partner spending the month's budget in an afternoon |
| **E** | elevation of privilege | that a party does only what it may | a tool call that reaches another client's order |

The six letters were written for ordinary software, and they fit an LLM application with one
adjustment. **Tampering there includes text that steers the model**, because to the model an
instruction inside a client's message and an instruction from Tarefa are the same kind of thing.
That one adjustment is why `T` sits on four flows in Tarefa's register and why lessons 5, 9 and 10
exist.

## The register

The answers go into a file, one entry per threat. Each entry names the flow, the STRIDE letter, the
threat in one line, an **impact** and a **likelihood** from 1 to 3, and the **control** that answers
it, which is the name of a command from an earlier lesson, or `null` while nothing does. The course
wrote this register; paste it:

```sh
cat > ~/guard/data/threats.json <<'EOF'
[
 {"id": "T1", "flow": "f1", "stride": "S", "impact": 3, "likelihood": 1, "control": "sign-in session", "threat": "a client acts as another client's account"},
 {"id": "T2", "flow": "f1", "stride": "T", "impact": 3, "likelihood": 3, "control": "check-in, filter", "threat": "a message carries text written to steer the model"},
 {"id": "T3", "flow": "f2", "stride": "I", "impact": 3, "likelihood": 2, "control": "filter", "threat": "a reply repeats personal data or the system prompt"},
 {"id": "T4", "flow": "f3", "stride": "D", "impact": 2, "likelihood": 2, "control": "ratelimit", "threat": "one partner spends the whole budget"},
 {"id": "T5", "flow": "f3", "stride": "S", "impact": 2, "likelihood": 2, "control": "onboard", "threat": "a company signs up under a false identity"},
 {"id": "T6", "flow": "f7", "stride": "I", "impact": 3, "likelihood": 3, "control": "minimise", "threat": "personal data reaches the provider"},
 {"id": "T7", "flow": "f8", "stride": "T", "impact": 2, "likelihood": 3, "control": "check-out", "threat": "a reply breaks the shape the code expects"},
 {"id": "T8", "flow": "f9", "stride": "E", "impact": 3, "likelihood": 2, "control": "gate", "threat": "a call reaches another client or moves money"},
 {"id": "T9", "flow": "f11", "stride": "I", "impact": 2, "likelihood": 3, "control": "redact, sweep", "threat": "the log keeps personal data too long"},
 {"id": "T10", "flow": "f11", "stride": "R", "impact": 2, "likelihood": 2, "control": null, "threat": "a reply cannot be traced to the prompt that made it"},
 {"id": "T11", "flow": "f12", "stride": "T", "impact": 3, "likelihood": 3, "control": null, "threat": "an upload carries text written to steer the model"},
 {"id": "T12", "flow": "f5", "stride": "T", "impact": 2, "likelihood": 1, "control": null, "threat": "a help page is edited to say something false"}
]
EOF
```

The program ranks it and checks it against the diagram. Save it as `~/guard/tools/threats.py`:

```python
# threats.py: the threat register, ranked, and the flows it has not reviewed.
#
#   guard threats [--open] [--text]
#
# Each entry in data/threats.json names a flow of data/flows.json, a STRIDE
# category, the threat in one line, an impact and a likelihood from 1 to 3,
# and the control that answers it, or null while nothing does. Risk is impact
# times likelihood, and the register is printed riskiest first, ties in the order written. --open prints
# only the entries with no control.
#
# Then the part a list cannot do for itself: every flow `guard flows` marks
# for review (with --text, the same rule as there) and no entry names is
# printed as UNREVIEWED, and the exit status is 1 while any is. A register
# is judged by what it left out.
import argparse
import json
import os
import sys

STRIDE = {"S": "spoofing", "T": "tampering", "R": "repudiation",
          "I": "information disclosure", "D": "denial of service",
          "E": "elevation of privilege"}

p = argparse.ArgumentParser(prog="guard threats")
p.add_argument("--open", action="store_true")
p.add_argument("--text", action="store_true")
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "flows.json"), encoding="utf-8") as f:
    model = json.load(f)
with open(os.path.join(home, "threats.json"), encoding="utf-8") as f:
    register = json.load(f)
zone = {c["id"]: c["zone"] for c in model["components"]}
flows = {fl["id"]: fl for fl in model["flows"]}

for t in register:
    if t["flow"] not in flows:
        sys.exit("threats: %s names flow %s, which flows.json does not have" % (t["id"], t["flow"]))
    if t["stride"] not in STRIDE:
        sys.exit("threats: %s has STRIDE letter %r; use one of %s" % (t["id"], t["stride"], "".join(STRIDE)))
    for k in ("impact", "likelihood"):
        if t[k] not in (1, 2, 3):
            sys.exit("threats: %s has %s %r; use 1, 2 or 3" % (t["id"], k, t[k]))

order = {t["id"]: n for n, t in enumerate(register)}
ranked = sorted(register, key=lambda t: (-t["impact"] * t["likelihood"], order[t["id"]]))
print("%-4s %-4s %-4s %4s  %-17s %s" % ("id", "flow", "kind", "risk", "control", "threat"))
for t in ranked:
    if a.open and t["control"]:
        continue
    print("%-4s %-4s %-4s %4d  %-17s %s" % (t["id"], t["flow"], t["stride"],
                                          t["impact"] * t["likelihood"],
                                          t["control"] or "OPEN", t["threat"]))

named = {t["flow"] for t in register}
missing = 0
for fl in model["flows"]:
    crosses = zone[fl["from"]] != zone[fl["to"]]
    outside = a.text and fl["text_from"] != "tarefa"
    if (crosses or outside) and fl["id"] not in named:
        missing += 1
        print("UNREVIEWED %s %s -> %s (%s)" % (fl["id"], fl["from"], fl["to"], fl["carries"]))
print("%d threats, %d open, %d marked flows with no entry" % (
    len(register), sum(1 for t in register if not t["control"]), missing))
sys.exit(1 if missing else 0)
```

```
ana@lab:~/guard$ guard threats
id   flow kind risk  control           threat
T2   f1   T       9  check-in, filter  a message carries text written to steer the model
T6   f7   I       9  minimise          personal data reaches the provider
T11  f12  T       9  OPEN              an upload carries text written to steer the model
T3   f2   I       6  filter            a reply repeats personal data or the system prompt
T7   f8   T       6  check-out         a reply breaks the shape the code expects
T8   f9   E       6  gate              a call reaches another client or moves money
T9   f11  I       6  redact, sweep     the log keeps personal data too long
T4   f3   D       4  ratelimit         one partner spends the whole budget
T5   f3   S       4  onboard           a company signs up under a false identity
T10  f11  R       4  OPEN              a reply cannot be traced to the prompt that made it
T1   f1   S       3  sign-in session   a client acts as another client's account
T12  f5   T       2  OPEN              a help page is edited to say something false
12 threats, 3 open, 0 marked flows with no entry
```

Twelve threats, three of them open, and every flow that crosses a zone has at least one entry. The
column `control` reads like an index of this course: `check-in` is lesson 9, `filter` lesson 5,
`minimise` lesson 12, `gate` lesson 10. **A threat with a control is a threat somebody already paid
for.** The register's value is in the other three.

## Reading the open ones

- **`T11`, an upload carrying text written to steer the model**, scores 9: the highest impact,
  because the assistant that reads an attachment can propose tool calls, and the highest likelihood,
  because anybody with an account can attach a file. Lesson 14's two boundaries are its control:
  whatever reads an attachment holds no tools and hands on only closed values.
- **`T10`, a reply that cannot be traced to the prompt that made it**, is a repudiation threat. When
  a client complains about something the assistant said, Tarefa has the reply in the log and cannot
  say which version of the system prompt produced it. Lesson 20 versions the prompts.
- **`T12`, a help page edited to say something false**, scores 2. The help centre is written by
  Tarefa, so few people can edit it and the likelihood is 1, but the assistant repeats whatever the
  page says. Lesson 20 puts the help centre under the same review as the prompts, so that a changed
  page is a change somebody approved.

A STRIDE letter on its own does not decide the order. **Risk does**, and risk here is impact times
likelihood. The scale is coarse on purpose: a team that argues over whether a likelihood is 0.35 or
0.4 is spending the meeting on a number nobody measured.
