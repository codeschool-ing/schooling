---
title: One number or many
version: 2
---

With four kinds of metric on the table the temptation is to combine them: so much for format, so much
for accuracy, a little for tone, one score to compare versions by. **A single weighted score lets
one metric hide another**, and two prompts already on disk show how. Here is `v3-examples.txt` over
the same seventy messages:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3-all.jsonl
70 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3-all.jsonl
ana@lab:~/triage$ pl check runs/v3-all.jsonl
check      pass  fail
json         69     1
fields       69     1
labels       69     1
category     53    17
urgency      42    28
all          42    28
ana@lab:~/triage$ python3 confusion.py runs/v3-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing          10        0        1        4        1        0     0.62
delivery          0       11        2        0        0        1     0.79
returns           2        2       12        0        0        0     0.75
account           1        1        0       10        2        0     0.71
other             0        0        0        0       10        0     1.00
precision      0.77     0.79     0.80     0.71     0.77

accuracy 53/70 = 0.76
```

By every total, `v3` is the better prompt: 53 categories right against 45, 42 replies passing every
check against the 26 `v6` passed in lesson 7, the same 69 of 70 on format. Any score built from
those would pick it, and on most of the matrix it deserves to win: billing recall from 0.25 to 0.62,
returns precision from 0.48 to 0.80.

One cell went the other way. **Billing precision fell from 1.00 to 0.77**: `v3` sends the billing
team thirteen tickets, three of which are not theirs, where `v6` sent four and all four were. If the
billing team works its queue by hand, that is a fair price for six more billing messages reaching
them. If anything acts on a billing label automatically, a refund form, a charge reversal, the three
are the number that matters and the totals are not. **Neither choice is wrong; hiding it inside one
number is.**

## Side by side, with gates

Report the metrics next to each other, the same ones every time:

- format, as a rate of its own;
- accuracy, and recall and precision for the labels somebody depends on;
- the expensive cells by name, such as high urgency sorted normal;
- tone rule failures, and the safety counts in both directions.

Where one metric must not get worse, make it a **gate** rather than a weight: a release that sorts
one more urgent message as normal is refused, whatever happened to accuracy. A gate is a threshold
on one metric, so it cannot be bought back by a gain somewhere else. Lesson 14 keeps these numbers
beside each version of the prompt, so that a change is judged against all of them at once.
