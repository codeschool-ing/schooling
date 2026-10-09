---
title: Checks as unit tests
version: 2
---

A unit test calls one function with one input and asserts one thing about what comes back. **Each
of `pl check`'s checks is a unit test on one reply**: given this text, does it parse, does it have
exactly the fields, are its values from the lists, does it agree with the person.

```
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     35     5
urgency      28    12
all          28    12

t01    urgency   normal, expected high
t02    urgency   high, expected normal
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t37    json      not a JSON object
t39    urgency   low, expected normal
ana@lab:~/triage$ grep -n "^CHECKS" pl.py
17:CHECKS = ["json", "fields", "labels", "category", "urgency"]
```

`CHECKS` is line 17 of `pl.py`: the five checks in the order `judge()` tries them, which is the
order `pl check` counts in.

## The order is the design

The five run cheapest and most certain first. `json`, `fields` and `labels` need nothing but the
reply and the specification, so they give the same verdict on any message and could run on every
reply in production. Lesson 10 used `json` exactly that way, refusing a reply that had added an
invented refund policy. `category` and `urgency` need a person's label, so they exist only where a
test set does.

**A reply that fails one check is not scored on the checks after it.** That makes the failure list
a list of first causes. `t37` failed `json`, and that is the whole story: there is no category to
argue about in a reply nobody can read. `t22` parsed, had the right fields and legal labels, and
disagreed with the person about the category, which is a different problem with a different fix.

Run the other way round, the list would say `t37` had the wrong category, and you would go looking
for a classification problem in a prompt whose problem was the shape of the reply.

## What makes a check worth having

- **It gives the same verdict every time.** Every check here is a few lines of comparison, with no
  model in it. A check that can change its mind is a second thing to measure, and lesson 13
  measures one.
- **It asserts one property.** `fields` does not care about labels; `labels` does not care about the
  person. When one fails you know what failed.
- **It is as strict as whatever reads the reply.** `fields` refuses an extra field, which is how
  lesson 1 caught the copied order number. A check looser than the program after it passes replies
  the program will refuse.
- **Its failure says what it saw.** *urgency high, expected normal* is a to-do item; a bare *fail*
  is a reason to open the file.

::: track ai
The checks are `judge()` in `pl.py`, a few lines each, and adding one is a few more. A check that
fails a summary longer than one sentence, say, belongs after `labels` and before `category`, because
it needs a parsed reply and no label: add its name to `CHECKS` and return it from `judge()`. Write it
the way you would write any test: find a reply that should fail it, and watch it fail that reply
before you trust it to pass the rest.
:::

::: track *
You use the five checks as they come. What matters is reading them as tests: each asserts one
thing, and when you want to know whether some new property holds, the useful question is which
check would fail if it did not. Lesson 12 adds tone rules built exactly that way.
:::
