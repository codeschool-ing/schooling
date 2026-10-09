---
title: What a vote costs
version: 2
---

An ensemble of n members makes n calls for every message. **The bill is the sum of the members'
bills**, and the gain is whatever the vote measured. Put the two side by side before keeping one.
Lesson 16's `cost.py` prices a run with `prices.json`, the course's invented prices:

```
ana@lab:~/triage$ python3 cost.py runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl runs/s5.jsonl
runs/v3.jsonl, 70 calls
  input      17381 tokens      248.3 a call
  output      2156 tokens       30.8 a call
  these calls      8.4483 cents
  a million calls  120690.0000 cents
runs/v4.jsonl, 70 calls
  input       8491 tokens      121.3 a call
  output      2039 tokens       29.1 a call
  these calls      5.6058 cents
  a million calls  80082.8571 cents
runs/v6.jsonl, 70 calls
  input      10381 tokens      148.3 a call
  output      2021 tokens       28.9 a call
  these calls      6.1458 cents
  a million calls  87797.1429 cents
runs/s5.jsonl, 350 calls
  input      51905 tokens      148.3 a call
  output      9995 tokens       28.6 a call
  these calls      30.5640 cents
  a million calls  87325.7143 cents
```

The last line of each run is the price of a million calls like its calls. For the three-prompt
ensemble a message is one call to each member, so a million messages cost 120,690 + 80,083 +
87,797 = 288,570 cents. The best member alone, `v3-examples`, costs 120,690 and got five more
messages right than the vote. **The ensemble cost 2.4 times the best prompt to be worse than it.**

The five samples are one prompt five times. Each call cost what a `v6-escaped` call costs, 148.3
tokens in and about 29 out, and a message is five of them: 5 × 87,326 = 436,629 cents a million
messages, five times `v6-escaped` alone, for one more right answer in seventy.

Time is the other bill:

```
ana@lab:~/triage$ python3 stats.py runs/v6.jsonl runs/s5.jsonl
runs/v6.jsonl, 70 calls
  tokens in    mean  148.3   total  10381
  tokens out   mean   28.9   total   2021   max 37
  seconds      p50   3.2   p95   4.4   total  263.7
runs/s5.jsonl, 350 calls
  tokens in    mean  148.3   total  51905
  tokens out   mean   28.6   total   9995   max 45
  seconds      p50   2.9   p95   3.7   total 1042.8
```

Each sampled call was a little faster than a call of the plain run, p50 2.9 seconds against 3.2,
most likely lesson 17's cache: `pl` sends a message's five samples one after another, with the
same prompt each time. Five calls per message took 1,042.8 seconds against 263.7. A provider that
runs the five at the same time makes you wait for the slowest of them instead of all of them, and
still bills all five.

## When it pays

Three things decide it, and each is something you can measure:

- **How different the members are.** The arithmetic only pays out when the members make different
  mistakes. Count it the way the three-prompt section did, case by case, before counting money.
  Here twelve cases were wrong under all three prompts.
- **What an error costs.** One more right answer in seventy can be worth five times the bill when a
  wrong label leaves a hijacked account in the wrong queue. It is not when a wrong label means a
  person re-sorts a newsletter question.
- **What a call costs.** An ensemble of three calls to a small, cheap model can cost less than one
  call to a large one. That is a comparison worth running with `cost.py` on both.

The order of those checks matters. **Measure the vote's gain against the best single call first**;
if it is negative, as it was for the three prompts, the cost does not need computing.
