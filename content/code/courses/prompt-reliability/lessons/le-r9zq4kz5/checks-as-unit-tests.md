---
title: Checks as unit tests
version: 1
---

A unit test calls one function with one input and asserts one thing about what comes back. **Each
of `pl check`'s checks is a unit test on one reply**: given this text, does it parse, does it have
exactly the fields, are its values from the lists, does it agree with the person.

```
ana@lab:~/triage$ pl check runs/v2.jsonl --failures
check      pass  fail
json         27    13
fields       27    13
labels       27    13
category     27    13
urgency      24    16
all          24    16

t03    json      not JSON
t06    json      not JSON
t08    json      not JSON
t09    json      not JSON
t12    json      not JSON
t14    urgency   normal, expected low
t15    json      not JSON
t16    json      not JSON
t20    json      not JSON
t22    json      not JSON
t24    urgency   low, expected normal
t27    json      not JSON
t28    urgency   normal, expected low
t32    json      not JSON
t35    json      not JSON
t39    json      not JSON
ana@lab:~/triage$ grep -n "^CHECKS" promptlab/cli.py
204:CHECKS = ["json", "fields", "labels", "category", "urgency"]
```

## The order is the design

The five run cheapest and most certain first. `json`, `fields` and `labels` need nothing but the
reply and the specification, so they give the same verdict on any message and could run on every
reply in production. Lesson 10 used `json` exactly that way, refusing replies an injection had
bent. `category` and `urgency` need a person's label, so they exist only where a test set does.

**A reply that fails one check is not scored on the checks after it.** That makes the failure list
a list of first causes. `t03` failed `json`, and that is the whole story: there is no category to
argue about in a reply nobody can read. `t14` parsed, had the right fields and legal labels, and
disagreed with the person about urgency, which is a different problem with a different fix.

Run the other way round, the list would say `t03` had the wrong category, and you would go looking
for a classification problem in a prompt whose problem was a code fence.

## What makes a check worth having

- **It gives the same verdict every time.** Every check here is a few lines of comparison, with no
  model in it. A check that can change its mind is a second thing to measure.
- **It asserts one property.** `fields` does not care about labels; `labels` does not care about the
  person. When one fails you know what failed.
- **It is as strict as whatever reads the reply.** `fields` refuses an extra field, which is how
  lesson 1 caught the copied order number. A check looser than the program after it passes replies
  the program will refuse.
- **Its failure says what it saw.** *urgency normal, expected low* is a to-do item; a bare *fail* is
  a reason to open the file.

::: track ai
The checks are `judge_row` in `promptlab/cli.py`, one `elif` each, and adding one is a few lines.
A check that fails a summary longer than one sentence, say, belongs after `labels` and before
`category`, because it needs a parsed reply and no label. Write it the way you would write any test:
find a reply that should fail it, and watch it fail that reply before you trust it to pass the rest.
:::

::: track *
You use the five checks as they come. What matters is reading them as tests: each asserts one
thing, and when you want to know whether some new property holds, the useful question is which
check would fail if it did not. Lesson 12 adds tone rules built exactly that way.
:::
