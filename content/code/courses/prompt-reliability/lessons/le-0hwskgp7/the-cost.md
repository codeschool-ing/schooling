---
title: What a vote costs
version: 1
---

An ensemble of n members makes n calls for every message. **The bill is the sum of the members'
bills**, and the gain is whatever the vote measured. Put the two side by side before keeping one.

```
ana@lab:~/triage$ pl cost runs/v6.jsonl
tokens          count   per call
input            8443      120.6
cache_read          0        0.0
cache_write         0        0.0
output           2635       37.6

cost of these 70 calls: 6.4854 cents
cost of a million calls like them: 92,649 cents
ana@lab:~/triage$ pl cost runs/s5.jsonl
tokens          count   per call
input           42215      120.6
cache_read          0        0.0
cache_write         0        0.0
output          13175       37.6

cost of these 350 calls: 32.4270 cents
cost of a million calls like them: 92,649 cents
```

`pl cost` adds up the tokens a run used and prices them with `prices.json`, which holds the course's
prices and no provider's. `v6-escaped` costs 6.4854 cents for seventy calls. The five-sample run
used the same 120.6 input tokens per call, made five times as many calls, and cost 32.4270 cents,
exactly five times as much. For that it got four fewer messages right.

The three-prompt ensemble costs the sum of three different prompts:

```
ana@lab:~/triage$ pl cost runs/v3.jsonl
tokens          count   per call
input           16703      238.6
cache_read          0        0.0
cache_write         0        0.0
output           2621       37.4

cost of these 70 calls: 8.9424 cents
cost of a million calls like them: 127,749 cents
ana@lab:~/triage$ pl cost runs/v4.jsonl
tokens          count   per call
input            6553       93.6
cache_read          0        0.0
cache_write         0        0.0
output           2660       38.0

cost of these 70 calls: 5.9559 cents
cost of a million calls like them: 85,084 cents
```

Per million messages, 127,749 + 85,084 + 92,649 = 305,482 cents, against 92,649 for `v6-escaped`
alone: **3.3 times the cost for two more right answers in seventy**. `v3-examples` is the most
expensive member, because its three examples ride along on every call.

Latency is the one thing an ensemble need not multiply. The calls are independent, so they can run
at the same time, and the wait is the slowest member's. The money is still the sum.

## When it pays

Three things decide it, and each is something you can measure:

- What an error costs: two more right answers in seventy are worth 3.3 times the bill when a
  wrong label leaves a hijacked account in the wrong queue. They are not when a wrong label means a
  person re-sorts a newsletter question.
- What a call costs: an ensemble of three calls to a small, cheap model can cost less than one
  call to a large one. That is a comparison worth running with `pl cost` on both.
- How different the members are: the arithmetic only pays out when the members make different
  mistakes. Count it the way the three-prompt section did, case by case, before counting money.

The order of those checks matters. **Measure the vote's gain against the best single call first**;
if it is zero or negative, as it was for the five samples, the cost does not need computing.
