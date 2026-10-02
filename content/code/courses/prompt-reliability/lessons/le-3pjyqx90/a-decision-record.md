---
title: A decision record
version: 1
---

A decision record is a short file written at the moment a choice is made, saying what was chosen
and why. The form comes from software architecture: Michael Nygard's post *Documenting
Architecture Decisions* (2011) proposed one small numbered file per decision, with its context, the
decision, its status and its consequences, kept in the repository with the code. **It works for
prompts for the same reason it works for code**: the choices that look strangest are often the ones
somebody learnt the hard way.

## The evidence first

The record below answers the February question, why the examples are written in JSON. Its evidence
is a comparison anybody can run again, the version with plain examples against the version with
JSON ones:

```
ana@lab:~/triage$ git show 31a6a59:prompts/triage.txt > runs/plain.txt
ana@lab:~/triage$ pl run runs/plain.txt cases/dev.jsonl --out runs/plain.jsonl
40 calls, prompt 055cb22b, written to runs/plain.jsonl
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/dev.jsonl
40 calls, prompt c1916fcd, written to runs/dev.jsonl
ana@lab:~/triage$ pl compare runs/plain.jsonl runs/dev.jsonl
runs/plain.jsonl         passes 0/40
runs/dev.jsonl           passes 36/40
fixed 36, broken 0, still passing 0, still failing 4
sign test on the 36 that changed: p = 0.000
```

Thirty-six fixed and none broken. The p value prints as `0.000` because it is too small to show at
three decimal places: thirty-six changes all in one direction leave no room for luck.

## The record

```localised
0001  Examples are written as JSON, exactly like the answer

Date     2026-08-17
Status   accepted

Context
  prompts/triage.txt shows three examples of the answer. On 14 August
  (31a6a59) they were rewritten as plain lines to be easier to read.
  The instruction to reply with only the JSON object stayed.

Options considered
  1. No examples, the format described in words (90a013e): 24/40 on dev.
  2. Examples as plain lines (31a6a59): 0/40 on dev.
  3. Examples as JSON, field for field the answer (03e1151): 36/40 on dev.

Decision
  Option 3. The model copies the shape of the first example's answer,
  so each example is written exactly as the program that reads the
  reply expects it. Readability is not a reason to change them.

Evidence
  pl compare runs/plain.jsonl runs/dev.jsonl
  fixed 36, broken 0, still passing 0, still failing 4
  sign test on the 36 that changed: p = 0.000

Revisit when
  the reply format changes, the model changes, or the examples are
  replaced. Any of those goes through the gate of lesson 14.
```

Each part is there for a reader who was not in the room.

- **Context** says what was true when the choice was made, so a reader can tell whether it still
  is.
- **Options considered** lists the ones that lost, with their numbers. The rejected option is the
  one the next person will propose, and this is where they find it was tried.
- **Decision** is one paragraph, and it gives the mechanism as well as the verdict: the reply copies
  the first example.
- **Evidence** is a command and what it printed. Pasting the output keeps the claim checkable after
  the run files are gone; the command lets anybody produce it again.
- **Revisit when** names the conditions that would make the decision wrong. **A record without
  one reads as permanent**, and nothing about a prompt is.

## Keeping them honest

Number the records and never edit one once it is accepted. When a decision is reversed, write a
new record that says so and mark the old one superseded, which is the rule Nygard's post gives.
The old reasoning stays readable, and the new one has to explain what changed. Link each record
from the commit that carries it out, so the log points at the reason even though it cannot hold
it.

**Write one when there was a real choice**, not for every commit. `c8470c9`, escaping the message,
needed a sentence in its commit message; the shape of the examples, which a reasonable person would
change, needed a record.
