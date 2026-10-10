---
title: Format, counted apart
version: 2
---

The first three checks of lesson 1, `json`, `fields` and `labels`, are the format metric. They ask
whether a program can use the reply at all, before anybody asks whether it is right.

```
ana@lab:~/triage$ pl check runs/v6-all.jsonl --failures | grep json
json         69     1
t38    json      not a JSON object
```

One of seventy fails on format, `t38`, the ebook whose summary broke on an apostrophe in lesson 3.
**A format failure is not a wrong answer, and a metric that mixes the two sends you to fix the wrong
thing.** Lesson 3 fixed `t38` with the schema mode of Ollama's API; a wrong label is fixed by a
clearer definition of the categories. Neither fix touches the other problem.

That is why the confusion matrix gives format failures a column of their own, `(bad)`, instead of
counting `t38` as a returns message sorted as something else. In `pl check` the same separation is
the order of the checks: the 25 replies that fail `category` are the one that never parsed and 24
that parsed and chose the wrong label.

## Report it as a rate of its own

Format is the easiest metric to state exactly: 69 of 70 replies parse, fit the fields and use the
lists. **It is also the one a running system can check on every reply**, since it needs no person's
label, so a format rate can be measured in production as well as in a test set. A wrong label in
valid JSON is invisible there; a reply that does not parse is not.

Keep it separate even when it is high. A format rate that slips from 69 of 70 to 66 of 70 after a
change is a regression, and inside a combined score it would look like a rounding error.
