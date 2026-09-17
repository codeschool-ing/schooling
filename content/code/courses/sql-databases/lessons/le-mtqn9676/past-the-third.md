---
title: Past the third, briefly and honestly
version: 1
---

There are normal forms beyond the third. You will hear them named, mostly by people trying to
establish that they know them, and you should know what they are so that the naming does not work.

This section is short on purpose. **Meeting a table that needs BCNF is a notable event, not a
Tuesday**, and the two above it are rarer still.

## Boyce-Codd normal form

3NF has one loophole. It bans a non-key column depending on another non-key column — and says
nothing about a **key** column depending on a non-key one. BCNF closes it:

> **Every dependency in the table must be from a whole candidate key.**

The shape that breaks 3NF-but-not-BCNF needs several overlapping candidate keys, which is why it is
rare. The classic example:

| student | subject | tutor |
|---|---|---|

with two rules: a student has one tutor per subject, and **each tutor teaches only one subject**.

```
student, subject  →  tutor        the key determines the tutor
tutor             →  subject      and the tutor determines the subject
```

That second dependency has a non-key column on the left and a **key** column on the right. 3NF has
nothing to say about it, and the anomaly is real: record that Dias tutors Networks and you can only
do it by inventing a student. The fix is the usual one — split `tutor → subject` into its own
table.

**Almost every table that is in 3NF is already in BCNF.** You reach the difference only when a
table has more than one candidate key and they overlap, which is a thing you can go years without
seeing.

## Fourth and fifth

**4NF** is about two independent multi-valued facts crammed into one table. A course has several
textbooks and several scheduled times, and the books have nothing to do with the times — put both
in one table and you are forced to write a row for every combination, so three books and four
times means twelve rows saying nothing. The fix is two tables, and the giveaway is exactly that
feeling of multiplying things that are unrelated.

**5NF** concerns cases where a table can only be reconstructed by joining three or more pieces
rather than two. It is genuinely obscure and you can stop reading about it here.

There is also a **domain-key normal form**, which is the theoretical end of the road and is not
something anybody designs against.

## Why 3NF is the working standard

Not because the higher forms are wrong. Because of what each one buys, against what it costs:

| | what it removes | how often you meet it |
|---|---|---|
| 1NF → 3NF | the update, insertion and deletion anomalies | constantly |
| BCNF | one more anomaly, in tables with overlapping keys | rarely |
| 4NF, 5NF | redundancy from independent multi-valued facts | rarely, and usually visible as obvious nonsense |

**The three anomalies this lesson opened with are all gone at 3NF.** Everything past it handles
shapes that are unusual, and each split costs a join on every read, forever.

So the honest position, and the one held by most people who build databases for a living:

> Design to third normal form. Recognise the higher ones if a table happens to need them — the
> symptom is always the same, a repeated value that can disagree with itself. Do not go looking.

**And be suspicious of the opposite claim.** "This is in fifth normal form" is almost never a
statement about a real system's design; it is usually a statement about an exam. The useful
question about any table is not which form it satisfies but the one this lesson has been asking
throughout: *what can go wrong here that could not go wrong if it were split?*
