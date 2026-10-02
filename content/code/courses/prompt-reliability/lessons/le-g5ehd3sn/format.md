---
title: Format, counted apart
version: 1
---

The first three checks of lesson 1, `json`, `fields` and `labels`, are the format metric. They ask
whether a program can use the reply at all, before anybody asks whether it is right.

```
ana@lab:~/triage$ pl check runs/v6-all.jsonl
check      pass  fail
json         68     2
fields       68     2
labels       68     2
category     56    14
urgency      46    24
all          46    24
ana@lab:~/triage$ pl check runs/v6-all.jsonl --failures | grep json
json         68     2
t26    json      not JSON
t39    json      not JSON
ana@lab:~/triage$ pl show runs/v6-all.jsonl t26
│ ```json
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "They'd like to cancel their subscription to the monthly box before the next payment."
│ }
│ ```
stop: end, tokens in 123, out 48
```

Two of seventy fail on format. `t26` has the right category and the right urgency, inside a Markdown
code fence, where the prompt asked for only a JSON object. **A format failure is not a wrong answer, and a
metric that mixes the two sends you to fix the wrong thing.** A fence is fixed by an example or a
stricter output format, lesson 3's subject; a wrong label is fixed by a clearer definition of the
categories. Neither fix touches the other problem.

That is why the confusion matrix gives format failures a column of their own, `(bad)`, instead of
counting `t26` as a billing message sorted as something else. In `pl check` the same separation is
the order of the checks: the 14 replies that fail `category` are the 2 that never parsed and 12
that parsed and chose the wrong label.

## Report it as a rate of its own

Format is the easiest metric to state exactly: 68 of 70 replies parse, fit the fields and use the
lists. **It is also the one a running system can check on every reply**, since it needs no person's
label, so a format rate can be measured in production as well as in a test set. A wrong label in
valid JSON is invisible there; a fence is not.

Keep it separate even when it is high. A format rate that slips from 70 of 70 to 68 of 70 after a
change is a regression, and inside a combined score it would look like a rounding error.
