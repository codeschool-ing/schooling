---
title: The easy set
version: 2
---

`cases/dev.jsonl` has the weakness every first test set has. **It was written by the person who
wrote the prompt**, at the same time, with the same picture of the inbox in mind. The prompt was
then improved, version after version, by watching that set's score go up.

`cases/holdout.jsonl`, saved in lesson 5, was written later, from harder messages, and no prompt in
this course was changed while looking at it:

```
ana@lab:~/triage$ head -n 3 cases/holdout.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h02", "message": "The delivery driver left my parcel with a neighbour I don't know. Can you find out who has it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/holdout.jsonl --out runs/v3-holdout.jsonl
30 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3-holdout.jsonl
ana@lab:~/triage$ pl check runs/v3-holdout.jsonl --failures
check      pass  fail
json         30     0
fields       30     0
labels       30     0
category     18    12
urgency      14    16
all          14    16

h01    category  returns, expected billing
h02    urgency   high, expected normal
h03    category  account, expected billing
h05    category  account, expected billing
h06    category  returns, expected delivery
h07    category  account, expected billing
h08    category  billing, expected returns
h11    category  delivery, expected account
h15    urgency   low, expected normal
h16    category  delivery, expected returns
h17    urgency   high, expected normal
h19    category  other, expected account
h21    category  returns, expected delivery
h23    category  billing, expected returns
h27    category  billing, expected account
h29    urgency   high, expected normal
```

The same prompt passes 28 of 40 on the set it was written against, 70%, and 14 of 30 on the one it
was not, 47%. Every reply still parses. What fails is the judgement: `h01` is a refund to the wrong
card, a billing problem written in the words of a return, and `h03`, a charge for an order nobody
placed, comes back as `account`, the noun the message opens with. Twelve categories wrong in thirty,
against four wrong categories, and one unparseable reply, in forty on dev. **The dev score measured
how well the prompt handles messages like the ones its author imagined**, and the author imagined
the easier ones.

## A set you tune against stops measuring

Every change you keep because the dev score rose is a change fitted to those forty messages, and the
holdout is where you find out whether it was fitted to anything else. Here it is asked of the
comparison from the first section, `v4` against `v3`:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/holdout.jsonl --out runs/v4-holdout.jsonl
30 calls, prompt 651820d7, llama3.2:3b, written to runs/v4-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v4-holdout.jsonl runs/v3-holdout.jsonl
runs/v4-holdout.jsonl    passes 4/30
runs/v3-holdout.jsonl    passes 14/30
fixed 10, broken 0
sign test on the 10 that changed: p = 0.002
```

On dev, `v3` beat `v4` by 28 to 20. On the holdout it wins by 14 to 4, ten messages fixed and none
broken, p = 0.002. **This time the holdout confirms the choice**: whatever the three examples
taught, it was not something about those forty messages. That is the other half of a holdout's job,
and the more common one. It does not exist to overturn decisions; it exists so that a decision
it does not overturn has been tested on something it was not made on.

The opposite case needs a change that won on dev by fitting dev, and the next section builds exactly
that.

## Keep a holdout, and look at it rarely

- **Build it apart from dev.** Write it after dev, from other messages, ideally labelled by
  someone else.
- **Run it when deciding, not while editing.** After a version is chosen on dev, the holdout says
  whether the choice holds up.
- **Do not fix its failures one by one.** The moment you read `h01`'s reply and change the prompt
  for it, `h01` has become a dev case. **A holdout you tune against becomes a second dev set**, and
  you need a new one.
