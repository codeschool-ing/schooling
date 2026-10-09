---
title: What a test set is
version: 2
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
which lesson 1 said about examples. For test cases it matters more: **a set of tidy messages
measures an inbox that does not exist.** Take cases from the traffic the prompt will actually see.
Remove what belongs to a customer, the names, addresses and order numbers, and keep everything
else: the typo, the two questions in one message, the three lines of apology before the point.

Take them from more than one afternoon, too. A week in which the courier had a bad Monday is a
week of delivery messages, and a set drawn from it will say the prompt is good at delivery.

## Label before you look

**Write each label before you run the prompt on it.** Somebody who reads the model's answer first
is no longer deciding what the message is about; they are deciding whether the model's answer is
acceptable, which is an easier test to pass. `t22`, the customer who wants to pay with a gift card
and a credit card, is billing to anyone labelling it cold. Shown the word *other* beside it first,
which is what `llama3.2:3b` says, a hurried reader might let it through.

When two people label the same message differently, that is a finding about the categories rather
than a nuisance. Write down the rule that settles it, because the prompt needs the same rule.

## How many

Forty is enough to see a large effect and too few to see a small one. Here are three prompts from
the first lessons, run again over the same forty:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 22/40
runs/v3.jsonl            passes 28/40
fixed 7, broken 1
broken: t01
sign test on the 8 that changed: p = 0.070
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/v3.jsonl
runs/v4.jsonl            passes 20/40
runs/v3.jsonl            passes 28/40
fixed 9, broken 1
broken: t01
sign test on the 10 that changed: p = 0.021
```

Between `v2` and `v3`, eight messages changed and seven went the same way; a fair coin splits eight
at least that unevenly seven times in a hundred, which is lesson 1's p = 0.070. Between `v4` and `v3`
ten changed and nine went one way, and p = 0.021. **Two comparisons of the same prompt, one on each
side of the line people draw at 0.05**, separated by two messages. Forty messages can see a
difference of eight; they cannot say much about one of six.

Seeing a difference half the size takes roughly four times the cases, because the noise in a
proportion shrinks with the square root of the count. That is the trade a test set is built on: a
case costs a person a minute, and the size of the change you want to detect decides how many
minutes.
