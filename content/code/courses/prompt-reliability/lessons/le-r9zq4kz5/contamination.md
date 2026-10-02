---
title: When the test leaks into the prompt
version: 1
---

Lesson 1 warned that an example which is also a test case is answered by copying.
`v11-contaminated.txt` does it on purpose. Its three examples are three dev cases, word for word:

```
ana@lab:~/triage$ grep -n "Message:" prompts/v11-contaminated.txt
9:Message: I returned a book three weeks ago and I still haven't had the refund.
14:Message: The parcel came but it was soaked and the books inside are ruined.
19:Message: The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.
23:Message: {{message}}
ana@lab:~/triage$ grep -E "\"t(21|23|37)\"" cases/dev.jsonl
{"id": "t21", "message": "I returned a book three weeks ago and I still haven't had the refund.", "expect": {"category": "returns", "urgency": "high"}}
{"id": "t23", "message": "The parcel came but it was soaked and the books inside are ruined.", "expect": {"category": "returns", "urgency": "high"}}
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/dev.jsonl --out runs/v11.jsonl
40 calls, prompt c725469f, written to runs/v11.jsonl
ana@lab:~/triage$ pl compare runs/v3.jsonl runs/v11.jsonl
runs/v3.jsonl            passes 36/40
runs/v11.jsonl           passes 37/40
fixed 1, broken 0, still passing 36, still failing 3
sign test on the 1 that changed: p = 1.000
ana@lab:~/triage$ pl check runs/v11.jsonl --failures
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     40     0
urgency      37     3
all          37     3

t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
```

The score went from 36 to 37, and the one message that changed is `t37`, the third example.
**Those three cases cannot fail any more**: the prompt contains their answers. `t21` and `t23`
passed already, so copying them in gained nothing you can see, and the 37 now includes three cases
that measure nothing.

Take them out and compare like with like. On the 37 messages it was not shown, `v11` fails `t14`,
`t24` and `t28` and passes 34. `v3` failed the same three plus `t37`, so on those same 37 it also
passes 34. **On everything the contaminated prompt had not seen, the two prompts are equal**, and
the holdout agrees:

```
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/holdout.jsonl --out runs/v11-holdout.jsonl
30 calls, prompt c725469f, written to runs/v11-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v3-holdout.jsonl runs/v11-holdout.jsonl
runs/v3-holdout.jsonl    passes 11/30
runs/v11-holdout.jsonl   passes 12/30
fixed 2, broken 1, still passing 10, still failing 17
broken: h28
sign test on the 3 that changed: p = 1.000
```

Eleven against twelve, three messages changed, and a sign test of 1.000: no evidence of a difference.

## Why one point is the dangerous size

In this lab the number moved by one, and that is the honest result. It is small because two of the
three copied cases passed anyway, and only `t37` had anything to gain.

That smallness is the danger. Contamination does not announce itself with a jump; it arrives as a
score that rose by a point after somebody improved the examples, which looks exactly like progress.
**The size of the inflation depends on how many cases leaked and how many of them were failing**,
and a set where ten of forty are pasted into the prompt is measuring thirty while reporting forty.

It happens innocently. The best examples are hard boundary cases, and so are the best test cases,
so the same message is the obvious choice for both. The guard is mechanical: keep examples and
cases in separate files, and before any run, check that no example message appears in a case file.
That check is a single search, and it is cheaper than finding out from a holdout.
