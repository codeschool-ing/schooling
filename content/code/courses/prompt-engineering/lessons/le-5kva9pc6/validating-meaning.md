---
title: A valid object can still be wrong
version: 2
---

Once a reply passes the schema, it is tempting to treat it as correct. It is only well formed.
**The schema checked the shape of the answer; nothing so far has checked the answer.** A refund can
be a number, above zero, in the right field, and still be the wrong number.

## A complaint, and a triage that passes

Complaint 7, through the same loop:

```
ana@lab:~/pe$ cat complaints/7.txt
I was charged twice for my lunch today: R$ 140 on my card instead of R$ 70. Please give me back what I paid twice.
ana@lab:~/pe$ python3 triage.py complaints/7.txt
attempt 1
  step 1: parsed as it is
  step 3: valid against schema.json
  {"category": "cold_or_late", "refund": true, "refund_amount": 70, "summary": "Charged twice for lunch"}
```

One attempt, valid, and the amount is right: the customer was charged R$ 140 instead of R$ 70, so
what they paid twice is **R$ 70**, and the model read that correctly. Every field has the right type
and an allowed value. The schema has nothing more to say, and **the category is wrong**: a double
charge is `billing`, and the model filed it under `cold_or_late`, the queue for slow tea. It is one
of the five allowed words. The schema could only check that it was one of them.

The amount could have gone wrong just as easily, since both numbers are in the complaint. Here is a
triage the course wrote with that mistake in it, the whole charge in `refund_amount`:

```
ana@lab:~/pe$ cat triage/7.json
{"category": "billing", "refund": true, "refund_amount": 140, "summary": "Charged twice for lunch; wants the double charge back."}
ana@lab:~/pe$ validate schema.json triage/7.json; echo "exit $?"
valid
exit 0
```

Valid as well. And this one breaks a rule of the café that the model was never given:

```
ana@lab:~/pe$ grep 100 handbook/refunds.md
A refund above R$ 100 needs the shift manager's approval.
ana@lab:~/pe$ cat rules.py
import json, sys

t = json.load(open(sys.argv[1]))
problems = []
if t["refund"] and "refund_amount" not in t:
    problems.append("refund is true but no refund_amount was given")
if not t["refund"] and t.get("refund_amount", 0) > 0:
    problems.append("refund is false but refund_amount is above zero")
if t.get("refund_amount", 0) > 100:
    problems.append("refund_amount %s is above R$ 100: the shift manager must approve" % t["refund_amount"])
print("\n".join(problems) or "no rule broken")
sys.exit(1 if problems else 0)
ana@lab:~/pe$ python3 rules.py triage/7.json; echo "exit $?"
refund_amount 140 is above R$ 100: the shift manager must approve
exit 1
ana@lab:~/pe$ python3 rules.py triage/good.json; echo "exit $?"
no rule broken
exit 0
```

Lesson 11 used this same handbook to ground a model's answers. Here it supplies a rule the program
enforces, whatever the model wrote.

## Writing the café's rules down as a check

These rules are about values and the relations between them, which is what a schema does not
express well. A few lines of code do:

```
ana@lab:~/pe$ cat rules.py
import json, sys

t = json.load(open(sys.argv[1]))
problems = []
if t["refund"] and "refund_amount" not in t:
    problems.append("refund is true but no refund_amount was given")
if not t["refund"] and t.get("refund_amount", 0) > 0:
    problems.append("refund is false but refund_amount is above zero")
if t.get("refund_amount", 0) > 100:
    problems.append("refund_amount %s is above R$ 100: the shift manager must approve" % t["refund_amount"])
print("\n".join(problems) or "no rule broken")
sys.exit(1 if problems else 0)
ana@lab:~/pe$ python3 rules.py triage/7.json; echo "exit $?"
refund_amount 140 is above R$ 100: the shift manager must approve
exit 1
ana@lab:~/pe$ python3 rules.py triage/good.json; echo "exit $?"
no rule broken
exit 0
```

The course's triage of complaint 7 breaks the handbook's rule, and the check says which rule in
words a person can act on. The good triage from this lesson's first reading section breaks none. The other
two rules catch a reply that contradicts itself: a refund with no amount, or an amount with no
refund.

What `rules.py` does **not** catch is the mistake underneath, 140 where 70 was owed, or the model's
own, a double charge filed as slow service. Both need the input: something that reads the
complaint and the reply side by side. Some of that can be code,
for instance a check that `refund_amount` is one of the amounts the complaint mentions, which 140
would pass. The rest needs a person, or a second model asked to check the first, and lesson 5 has
already said why a model's confidence is no evidence. **The checks that matter most are the ones
the model cannot pass by writing plausible text.**

## Three layers, in order

A reply meant for a program goes through three checks, cheapest first:

| check | what it catches | in this lesson |
|---|---|---|
| parse | text that is not JSON at all | lesson 18, and `repair` steps 1 and 2 |
| schema | wrong types, unknown values, missing or extra fields | `validate`, `repair` step 3 |
| rules | values the café does not allow, contradictions, amounts above a limit | `rules.py` |

And a fourth that is not a program: whether the reply is **true to its input**. Each layer passes
things the next one stops. **A reply that has passed all three programs has earned more trust,
and still not all of it**: the model's triage of complaint 7 passed all three and went to the
queue for slow tea, and the course's would have reached the manager at R$ 140, flagged for approval
for the right reason and with the wrong amount.
