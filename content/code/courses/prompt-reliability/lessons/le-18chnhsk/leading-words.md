---
title: Words that lead
version: 1
---

Context looks harmless. A sentence telling the model something true about the inbox seems like the
kind of thing a careful prompt writer adds. **A model reads it as a hint about every message**, and
acts on it in the one place it has room to: the messages that could go either way.

```
ana@lab:~/triage$ diff prompts/v6-escaped.txt prompts/v18-leading.txt
1c1,2
< You sort customer messages for Folio, an online bookshop.
---
> You sort customer messages for Folio, an online bookshop. Most messages we
> get are about delivery.
ana@lab:~/triage$ grep -n "^LEADING_PULL" promptlab/standin.py
88:LEADING_PULL = 1.2      # "most messages are about X" adds this to X
```

The sentence might well be true; delivery is a large share of any bookshop's mail. In the stand-in
a sentence of the form *most messages are about X* adds 1.2 to X for every message, nearly five
times what being listed first was worth.

```
ana@lab:~/triage$ pl run prompts/v18-leading.txt cases/all.jsonl --out runs/leading.jsonl
70 calls, prompt 3a054c39, written to runs/leading.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/leading.jsonl --answers
70 cases, same answer 62, different answer 8
  t19  account -> delivery
  t23  returns -> delivery
  t33  returns -> delivery
  h10  account -> delivery
  h13  other -> delivery
  h16  other -> delivery
  h19  other -> delivery
  h20  other -> delivery
ana@lab:~/triage$ grep -E '"(t19|t23|t33|h10|h13|h16|h19|h20)"' cases/all.jsonl | grep -o '"category": "[a-z]*"'
"category": "account"
"category": "returns"
"category": "returns"
"category": "account"
"category": "returns"
"category": "returns"
"category": "account"
"category": "delivery"
```

Eight answers moved, and **every one of them moved to delivery**. Line them up with what the person
said. `t19`, `t23`, `t33` and `h10` were right and are now wrong. `h13`, `h16` and `h19` were wrong
and are still wrong. One was fixed:

```
ana@lab:~/triage$ grep h20 cases/all.jsonl
{"id": "h20", "message": "Do you deliver to Portugal, and how much does it cost?", "expect": {"category": "delivery", "urgency": "low"}}
```

A question about shipping to Portugal is a delivery question, and the sentence pushed it over the
line. One right answer for four wrong ones is the trade a leading sentence makes, and it is a bad
one even when the sentence is true.

## What went wrong

The sentence is a statement about the population, and **the model applies it to each message**.
That most messages are about delivery does not make `t19` about delivery; *"Someone else seems to
have logged into my account and changed the delivery address"* mentions delivery, and is about an
account somebody took over. Told what to expect, the stand-in found it.

Real models are not built on a constant like `LEADING_PULL`, and nobody can tell you how far a
given sentence moves a given model. What practitioners report is the direction: a prompt that says
what to expect tends to get more of it. That is a claim to test, never one to assume, and the test
is the one above, the prompt with and without the sentence, compared answer by answer.

## Finding them in your own prompt

Leading words are easy to write and hard to see, because each one was added for a reason. Read a
prompt for:

- **Base rates**: *most*, *usually*, *nearly all*, *rarely*. In the stand-in these are the words
  that trigger the rule.
- **Expectations about the customer**: *customers are often confused about*, *people usually want*.
- **Examples in the instructions**: *for instance, a late parcel*. A sentence that names one kind
  of message is a candidate like the others, and is tested the same way.

**A prompt should say what to do with each message**, and leave facts about the inbox to whoever
reads the dashboard. When a sentence is there for a reason, delete it and compare the answers; if
nothing moves you have lost nothing, and if answers move you have found out what it was doing.
