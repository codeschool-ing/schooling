---
title: The easy set
version: 1
---

`cases/dev.jsonl` has the weakness every first test set has. **It was written by the person who
wrote the prompt**, at the same time, with the same picture of the inbox in mind. The prompt was
then improved, version after version, by watching that set's score go up.

`cases/holdout.jsonl` was written later, from harder messages, and the prompt never saw it while it
was being changed:

```
ana@lab:~/triage$ head -n 3 cases/holdout.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h02", "message": "The delivery driver left my parcel with a neighbour I don't know. Can you find out who has it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     39     1
urgency      36     4
all          36     4

t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
t37    category  billing, expected delivery
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/holdout.jsonl --out runs/v3-holdout.jsonl
30 calls, prompt 1d9c6ec4, written to runs/v3-holdout.jsonl
ana@lab:~/triage$ pl check runs/v3-holdout.jsonl --failures
check      pass  fail
json         30     0
fields       30     0
labels       30     0
category     17    13
urgency      11    19
all          11    19

h01    category  returns, expected billing
h03    urgency   normal, expected high
h04    category  delivery, expected returns
h06    urgency   normal, expected high
h07    category  account, expected billing
h09    urgency   normal, expected low
h10    urgency   normal, expected low
h11    category  delivery, expected account
h13    category  billing, expected returns
h14    category  billing, expected other
h15    category  billing, expected account
h16    category  other, expected returns
h19    category  billing, expected account
h20    category  billing, expected delivery
h22    urgency   normal, expected high
h24    urgency   normal, expected high
h26    category  billing, expected other
h27    category  billing, expected account
h30    category  billing, expected other
```

The same prompt passes 36 of 40 on the set it was written against, 90%, and 11 of 30 on the one it
was not, 37%. Every reply still parses. What fails is the judgement: `h01` is a refund to the wrong
card, a billing problem written in the words of a return, and `h03`, a charge for an order nobody
placed, comes back as normal urgency. **The dev score measured how well the prompt handles
messages like the ones its author imagined**, and the author imagined the easy ones.

In the stand-in that gap is mechanical: it sorts by keywords, and the holdout was written with the
wrong keywords on purpose. A real model reads better than that, but the habit the gap comes from is
not about the model. Whoever wrote both the prompt and the cases wrote cases the prompt handles.

## A set you tune against stops measuring

Every change you keep because the dev score rose is a change fitted to those forty messages. Two
fixes for the format problem show what that costs:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/holdout.jsonl --out runs/v4-holdout.jsonl
30 calls, prompt 651820d7, written to runs/v4-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v4-holdout.jsonl runs/v3-holdout.jsonl
runs/v4-holdout.jsonl    passes 11/30
runs/v3-holdout.jsonl    passes 11/30
fixed 1, broken 1, still passing 10, still failing 18
broken: h07
sign test on the 2 that changed: p = 1.000
```

On dev, `v3` beat `v4` by 36 to 34. On the holdout they tie at 11, one message fixed and one broken.
Whatever made `v3` better on dev is not visible on messages it was not chosen against, and nobody
choosing between the two by the dev score could have known.

## Keep a holdout, and look at it rarely

- **Build it apart from dev**: later, from other messages, ideally labelled by someone else.
- **Run it when deciding, not while editing.** After a version is chosen on dev, the holdout says
  whether the choice holds up.
- **Do not fix its failures one by one.** The moment you read `h01`'s reply and change the prompt
  for it, `h01` has become a dev case. **A holdout you tune against becomes a second dev set**, and
  you need a new one.
