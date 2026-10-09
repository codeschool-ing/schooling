---
title: Trade-offs
version: 2
---

A saving that changes the prompt is a change like any other. It goes through the gate of lesson 14,
and **a cheaper prompt has to say what it cost in answers as well as what it saves**. The examples
that the last section took out are the case to look at.

## What the cheaper prompt broke

```
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/v3.jsonl
runs/v4.jsonl            passes 20/40
runs/v3.jsonl            passes 28/40
fixed 9, broken 1
broken: t01
sign test on the 10 that changed: p = 0.021
```

Twenty passes against twenty-eight. Going from `v4` back to `v3` fixed nine messages and broke one,
so taking the examples out broke nine and fixed one, and a sign test of 0.021 says a split that
lopsided is unlikely to be chance. Here is what the cheaper prompt does to the checks:

```
ana@lab:~/triage$ pl check runs/v4.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     32     8
urgency      20    20
all          20    20
```

Format held: one reply in forty does not parse, as under `v3`. **What the examples were paying for
is the judgement**: categories fell from 35 to 32 and urgencies from 28 to 20. A third of the cost
for a net eight messages in forty is a trade somebody has to make knowingly. Whether a wrong urgency
costs more than 40,837.5 cents a million calls is a question about the support team, not about the
prompt, and only somebody who knows what a mis-sorted message costs can answer it. What the harness
can do is make sure they are looking at both numbers.

## p95, not the mean

The cheaper prompt is also quicker:

```
ana@lab:~/triage$ python3 stats.py runs/v4.jsonl
runs/v4.jsonl, 40 calls
  tokens in    mean  121.2   total   4846
  tokens out   mean   28.8   total   1153   max 38
  seconds      p50   3.6   p95   4.5   total  145.9
```

A median of 3.6 seconds against 4.1, a p95 of 4.5 against 5.0. Notice that `stats.py` prints no
mean of the seconds at all. A mean blends the fast calls with the slow ones into a number no single
call had. **A person waiting feels the slow calls**, and one in twenty of them waits at least the
p95. The mean can fall while the p95 rises, and then the average customer is better off on paper
while the unlucky ones wait longer.

The tail matters more as calls are combined. A pipeline that makes three calls in a row waits for
the sum, and one that makes them side by side waits for the slowest of the three. *The Tail at
Scale* (Dean and Barroso, 2013) made that argument for large web services: when one request fans
out to many servers, the rare slow response of each becomes a common one for the whole. On one
machine with one model loaded, this lab's tail is short; a shared service's tail is set by its
traffic, and only measuring yours will tell you where it is.

## An order to cut in

1. **Remove what earns nothing.** Lesson 14's log found commits that cost tokens and moved no score
   on the set they were run against. Before cutting one, find out what it was for; if nothing
   measures it, that saving needs only a check that nothing broke.
2. **Shorten the output**, which is the larger lever on both time and money, and check the score.
3. **Then trade answers for money**, a smaller prompt or a cheaper model, with the broken messages
   named and somebody deciding, in writing, that they are worth it. Lesson 15's decision record is
   the place for that sentence.
