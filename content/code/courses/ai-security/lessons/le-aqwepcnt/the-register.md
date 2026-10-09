---
title: What the register left out, and keeping it true
version: 1
---

The open entries are threats somebody thought of and has not answered. **The more dangerous gap is a
threat nobody thought of**, and a list cannot report what is not in it. That is why `threats.py`
checks the register against the diagram rather than against itself: every flow `guard flows` marks
must be named by at least one entry.

By the zone rule the register is complete, as the last line of the previous section said. By the text
rule it is not:

```
ana@lab:~/guard$ guard threats --open --text; echo "exit status $?"
id   flow kind risk  control           threat
T11  f12  T       9  OPEN              an upload carries text written to steer the model
T10  f11  R       4  OPEN              a reply cannot be traced to the prompt that made it
T12  f5   T       2  OPEN              a help page is edited to say something false
UNREVIEWED f4 app -> assistant (message and session)
UNREVIEWED f6 files -> assistant (attachment text)
12 threats, 3 open, 2 marked flows with no entry
exit status 1
```

`f4` and `f6` are marked by `--text` and named by no entry, and the program exits with status 1
because of them. Both carry a client's words into the assistant, and both stay inside Tarefa's zone.
The register's author wrote `T2` against `f1`, where the message arrives, and `T11` against `f12`,
where the file arrives, and stopped at the boundary.

## Where an entry belongs

The question that settles it is **where the control sits**, not where the data came from. `T2`'s
first control is `check-in`, and it reads the message on its way from `app` to the assistant, which
is `f4`. So the threat lives on `f4` as much as on `f1`. Writing it on `f4` too costs one line and
makes the register agree with the diagram.

`f6` is a different case. **No control sits on it at all**: the attachment goes from the file store
to the assistant unread by anything. The right entry is a new threat, tampering, impact 3,
likelihood 3, control `null`, and it lands at the top of the ranking beside `T11`. Lesson 14's two
boundaries close both.

## A register that stays true

A threat model written once and filed is accurate on the day it was written. Three habits keep it
from turning into a description of an application that no longer exists:

- **it lives in the repository**, beside the code, like the inventory of lesson 1. `flows.json` and
  `threats.json` are files a pull request can change;
- **a feature that adds a flow adds its entries in the same pull request.** A new tool, a new data
  source or a new provider is a new row in `flows.json`, and `threats.py` then reports it as
  unreviewed until somebody writes what can go wrong there;
- **the check runs where the tests run.** `threats.py` already exits with 1 while a marked flow has
  no entry, and lesson 24 runs it in the build, so that an unreviewed flow fails a pull request the
  way a failing test does.

## What it does not do

The register records judgement; it does not make it. A likelihood of 1 that should have been 3 ranks
a real threat at the bottom, and no program can tell. Two people rating independently and comparing
catches most of those, and the cheapest moment for that conversation is before the feature ships.
And a threat model covers the application as drawn. **A component nobody drew has no flows to
review**, which is the argument for drawing from the code and the infrastructure rather than from
memory.
