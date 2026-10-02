---
title: Trade-offs
version: 1
---

A saving that changes the prompt is a change like any other. It goes through the gate of lesson 14,
and **a cheaper prompt has to say what it cost in answers as well as what it saves**. The examples
that the last section took out are a good case, because the numbers do not settle it on their own.

## What the cheaper prompt broke

```
ana@lab:~/triage$ pl compare runs/v3.jsonl runs/v4.jsonl
runs/v3.jsonl            passes 36/40
runs/v4.jsonl            passes 34/40
fixed 1, broken 3, still passing 33, still failing 3
broken: t08 t19 t22
sign test on the 4 that changed: p = 0.625
ana@lab:~/triage$ pl check runs/v4.jsonl --failures | tail -n 6
t08    json      not JSON
t14    urgency   normal, expected low
t19    json      not JSON
t22    json      not JSON
t24    urgency   low, expected normal
t28    urgency   normal, expected low
```

Thirty-four passes against thirty-six, one message fixed and three broken, and a sign test of
0.625. That p value does not say the prompts are equally good. **No evidence of a difference is not
evidence of no difference**: with four messages changed, the sign test could not reach anything
below 0.125 even if all four had gone the same way. Forty messages are too few to tell these two
prompts apart by count.

So read what broke. `t08`, `t19` and `t22` are not JSON: without an example, the stand-in falls
back on its habits of a sentence in front or a code fence around the answer, which lesson 1
showed. A wrong urgency still routes a message, slowly; **a reply that does not parse routes
nothing**. Three in forty is 7.5%, and if that rate held on a million calls it would be some 75,000
messages that a program could not read, each needing a retry, which costs another call, or a
person. The saving is real and so is the bill it comes with, and only somebody who knows what a
lost message costs can set one against the other. What the harness can do is make sure they are
looking at both.

## p95, not the mean

The cheaper prompt is also quicker:

```
ana@lab:~/triage$ pl latency runs/v4.jsonl
calls 40
p50 1170 ms   p95 1324 ms   max 1473 ms
output tokens: mean 38.0, max 50
```

A median of 1170 ms against 1230, a p95 of 1324 against 1341. Notice that `pl latency` prints no
mean at all. A mean blends the fast calls with the slow ones into a number no single call had.
**A person waiting feels the slow calls**, and one in twenty of them waits at least the p95. The
mean can fall while the p95 rises, and then the average customer is better off on paper while the
unlucky ones wait longer.

The tail matters more as calls are combined. A pipeline that makes three calls in a row waits for
the sum, and one that makes them side by side waits for the slowest of the three. *The Tail at
Scale* (Dean and Barroso, 2013) made that argument for large web services: when one request fans
out to many servers, the rare slow response of each becomes a common one for the whole. In the
stand-in the jitter stops at 150 ms, so its tail is short and tidy. A real service's tail is set by
its traffic, not by a course's number, and only measuring yours will tell you where it is.

## An order to cut in

1. **Remove what earns nothing.** Lesson 14's log found an instruction that cost 15 tokens a call
   and moved no score on either set it was run against. That saving needs no trade-off, only a
   check that nothing broke.
2. **Shorten the output**, which is the larger lever on both time and money, and check the score.
3. **Then trade answers for money**, a smaller prompt or a cheaper model, with the broken messages
   named and somebody deciding, in writing, that they are worth it. Lesson 15's decision record is
   the place for that sentence.
