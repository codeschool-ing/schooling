---
title: What a test set is
version: 1
---

A test set is the one part of an evaluation that cannot be automated. **Each case is an input and
the answer a person decided was right**, written down before anything runs:

```
ana@lab:~/triage$ head -n 1 cases/dev.jsonl
{"id": "t01", "message": "I was charged twice for order 4471. Please refund the second payment.", "expect": {"category": "billing", "urgency": "high"}}
```

`message` is what the prompt receives and `expect` is a person's judgement. Everything `pl check`
does after that is arithmetic, and the arithmetic is only as good as the forty judgements under it.

## Where cases come from

The wrong instinct is to sit down and write them. Invented messages are tidier than real ones,
which lesson 1 said about examples, and for test cases it matters more: **a set of tidy messages
measures an inbox that does not exist.** Take cases from the traffic the prompt will actually see.
Remove what belongs to a customer, the names, addresses and order numbers, and keep everything
else: the typo, the two questions in one message, the three lines of apology before the point.

Take them from more than one afternoon, too. A week in which the courier had a bad Monday is a
week of delivery messages, and a set drawn from it will say the prompt is good at delivery.

## Label before you look

**Write each label before you run the prompt on it.** Somebody who reads the model's answer first
is no longer deciding what the message is about; they are deciding whether the model's answer is
acceptable, which is an easier test to pass. `t37`, the order still awaiting dispatch, is delivery
to anyone labelling it cold. Shown the word *billing* beside it first, a hurried reader might let
it through.

When two people label the same message differently, that is a finding about the categories rather
than a nuisance. Write down the rule that settles it, because the prompt needs the same rule.

## How many

Forty is enough to see a large effect and too few to see a small one:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 24/40
runs/v3.jsonl            passes 36/40
fixed 13, broken 1, still passing 23, still failing 3
broken: t37
sign test on the 14 that changed: p = 0.002
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/v3.jsonl
runs/v4.jsonl            passes 34/40
runs/v3.jsonl            passes 36/40
fixed 3, broken 1, still passing 33, still failing 3
broken: t37
sign test on the 4 that changed: p = 0.625
```

Between `v2` and `v3`, fourteen messages changed and thirteen went the same way; a fair coin does
that two times in a thousand. Between `v4` and `v3` the totals are two apart, four messages changed,
and the sign test says a coin would split them at least that unevenly more than half the time.
**Forty messages can see thirteen format failures and cannot tell 34 from 36.**

Seeing a difference half the size takes roughly four times the cases, because the noise in a
proportion shrinks with the square root of the count. That is the trade a test set is built on: a
case costs a person a minute, and the size of the change you want to detect decides how many
minutes.
