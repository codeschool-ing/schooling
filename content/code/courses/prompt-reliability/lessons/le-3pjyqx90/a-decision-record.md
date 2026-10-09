---
title: A decision record
version: 2
---

A decision record is a short file written at the moment a choice is made, saying what was chosen
and why. The form comes from software architecture: Michael Nygard's post *Documenting
Architecture Decisions* (2011) proposed one small numbered file per decision, with its context, the
decision, its status and its consequences, kept in the repository with the code. **It works for
prompts for the same reason it works for code**: the choices that look strangest are often the ones
somebody weighed the longest.

## The evidence first

The record below answers the February question: should the examples be JSON, or plain lines? Its
evidence starts with lesson 14's comparison, run again, the version with plain examples against the
file as it is now:

```
ana@lab:~/triage$ git show 86913c0:prompts/triage.txt > runs/plain.txt
ana@lab:~/triage$ pl run runs/plain.txt cases/dev.jsonl --out runs/plain.jsonl
40 calls, prompt 055cb22b, llama3.2:3b, written to runs/plain.jsonl
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/dev.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/dev.jsonl
ana@lab:~/triage$ pl compare runs/plain.jsonl runs/dev.jsonl
runs/plain.jsonl         passes 27/40
runs/dev.jsonl           passes 24/40
fixed 1, broken 4
broken: t12 t23 t28 t38
sign test on the 5 that changed: p = 0.375
```

Four broken and one fixed by going back to JSON, p = 0.375. One of the four:

```
ana@lab:~/triage$ grep t12 cases/dev.jsonl
{"id": "t12", "message": "Tracking says delivered but there is nothing at my door.", "expect": {"category": "delivery", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/plain.jsonl t12
│ {"category": "delivery", "urgency": "high", "summary": "expects delivery but nothing received"}
stop: stop, tokens in 258, out 24, 3.5 s
ana@lab:~/triage$ pl show runs/dev.jsonl t12
│ {"category": "delivery", "urgency": "normal", "summary": "Wants to know why the order was not delivered as expected."}
stop: stop, tokens in 303, out 32, 4.2 s
```

A parcel marked delivered that never came is urgent, and the plain-lines prompt said so. That is one
message. Before anybody writes a decision on dev alone, the holdout gets asked the same question:

```
ana@lab:~/triage$ pl run runs/plain.txt cases/holdout.jsonl --out runs/plain-holdout.jsonl
30 calls, prompt 055cb22b, llama3.2:3b, written to runs/plain-holdout.jsonl
ana@lab:~/triage$ pl compare runs/plain-holdout.jsonl runs/holdout.jsonl
runs/plain-holdout.jsonl passes 12/30
runs/holdout.jsonl       passes 15/30
fixed 5, broken 2
broken: h12 h16
sign test on the 7 that changed: p = 0.453
```

**The holdout points the other way**: JSON examples pass 15 of 30, plain lines 12, five messages
fixed and two broken by JSON. Dev favours plain lines by three, the holdout favours JSON by three,
and neither sign test is anywhere near small. On this model, these seventy messages cannot tell the
two apart. That is a finding, and a record that left it out would be the kind that makes the next
person run the same experiment again.

## The record

```localised
0001  Examples stay as JSON, exactly like the answer

Date     2026-08-17
Status   accepted

Context
  prompts/triage.txt shows three examples of the answer. On 14 August
  (86913c0) they were rewritten as plain lines to be easier to read;
  on 17 August (85dfa4e) they were put back. The instruction to reply
  with only the JSON object was there throughout.

Options considered
  1. No examples, the format described in words (61d470e): 22/40 dev.
  2. Examples as plain lines (86913c0): 27/40 dev, 12/30 holdout,
     11553 tokens on dev.
  3. Examples as JSON (85dfa4e): 24/40 dev, 15/30 holdout,
     13408 tokens on dev.

Decision
  Option 3, on a reason the numbers do not settle: the reply's shape
  is what the program depends on, and an example in that shape is the
  one place a model is shown it. Options 2 and 3 are not separable on
  these test sets; option 2 costs 14% fewer tokens.

Evidence
  pl compare runs/plain.jsonl runs/dev.jsonl
  fixed 1, broken 4; sign test on the 5 that changed: p = 0.375
  pl compare runs/plain-holdout.jsonl runs/holdout.jsonl
  fixed 5, broken 2; sign test on the 7 that changed: p = 0.453

Revisit when
  the model changes; a test set large enough to separate 2 and 3
  exists; or cost becomes the constraint, which makes option 2 the
  default. Any of those goes through the gate of lesson 14.
```

Each part is there for a reader who was not in the room.

- *Context* says what was true when the choice was made, so a reader can tell whether it still
  is.
- *Options considered* lists the ones that lost, with their numbers. The rejected option is the
  one the next person will propose, and this is where they find it was tried.
- *Decision* gives the reason, and says plainly when the reason is a judgement rather than a
  measurement. **A record that dressed this choice up as proven would be lying**, and the next
  person would trust it exactly as far as that lie went.
- *Evidence* is a command and what it printed. Pasting the output keeps the claim checkable after
  the run files are gone; the command lets anybody produce it again.
- *Revisit when* names the conditions that would make the decision wrong. **A record without one
  reads as permanent**, and nothing about a prompt is.

## Keeping them honest

Number the records and never edit one once it is accepted. When a decision is reversed, write a
new record that says so and mark the old one superseded, which is the rule Nygard's post gives.
The old reasoning stays readable, and the new one has to explain what changed. Link each record
from the commit that carries it out, so the log points at the reason even though it cannot hold
it: `85dfa4e`'s message could have been *Put the examples back in JSON (decision 0001)*.

**Write one when there was a real choice**, not for every commit. `c8f1927`, escaping the message,
needed a sentence in its commit message; the shape of the examples, which a reasonable person would
change, and did, needed a record.
