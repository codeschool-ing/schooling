---
title: Asking the source, and writing the answer down
version: 1
---

**The data can rule some mechanisms out; only the source can rule one in.** That asymmetry is the
practical lesson of this whole lesson. Comparing rows with and without a value can show that blanks
are not completely random — Roderick Little published a formal test for exactly that in 1988 — and
can show which visible columns they line up with. It cannot show that nothing invisible is behind
them, because the invisible thing is, by definition, not in the file.

So every column with blanks gets the same five questions, in this order:

1. **Could a value exist here at all?** If not, the blank is an answer: not applicable.
2. **What does the system that wrote it mean by a blank?** Zero, unknown, refused, not asked, timed
   out. The person who built the form knows; the file does not.
3. **Do the blanks line up with a column you can see?** Split them, as `pattern.py` did. All or
   nothing in a group is an explanation.
4. **Is there a sign the value itself is involved?** A maximum that stops at a round number, a tail
   cut flat, a group that should be slower answering less often.
5. **Who confirmed it, and when?** A mechanism nobody confirmed is a hypothesis, and should be
   written down as one.

## The missingness log

The answers go into a table that travels with the data. Lesson 4 decides what to do with each column
from it, and the person who reads the cleaned data next year needs to know why a column was filled
in one way and not another:

| column | blank means | mechanism | evidence | confirmed by |
|---|---|---|---|---|
| `delivery_minutes`, pickups | no delivery | not applicable | 100% blank where `fulfilment` is `pickup` | the data |
| `delivery_minutes`, Rapidex | partner reports no times | MAR on `courier` | 100% blank for Rapidex | operations |
| `delivery_minutes`, own fleet | took 120 minutes or more | MNAR | max 119; evening rate 4× | operations: the timer stops at 2 h |
| `discount`, website | no coupon: zero | not missing | blank only on the website, `0` only in the app | the data |
| `nps` | customer did not answer | MNAR, partly visible | response falls with delivery time | not confirmable; known in the field |
| `email`, shops | customer declined or was not asked | MAR on `signup_channel` | 45% blank in shops, 0% elsewhere | shops' manager |
| `birth_year` of 1900 | form placeholder | not a value | 344 of 348 from shops | shops' manager |
| `cliente`, store sales | sale with no loyalty number | not a defect | average ticket R$ 65.58 against R$ 65.68 | the data |

**The `confirmed by` column is the one that makes the table worth keeping.** "The data" means the
pattern is exact and needs nobody's word. A name means somebody who knows the system said so, and
can be asked again when the system changes. And "not confirmable" is an honest entry: it tells the
reader that the number built on this column carries a bias of unknown size, which is more than most
reports ever say about themselves.

## What this lesson did not do

It did not fill, drop or impute a single value. That is deliberate. Every option in lesson 4 —
dropping rows, filling with a constant, imputing from similar rows, flagging — is right for one
mechanism and wrong for another. Choosing one before reading the blanks is how the fleet ends up
reported as faster than it is.