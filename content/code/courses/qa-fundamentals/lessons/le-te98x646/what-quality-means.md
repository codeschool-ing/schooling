---
title: What the word quality means, three times over
version: 1
---

**The commonest definition of quality in software is "it has no bugs", and it fails on the first
example.** A ticket shop with no defects at all that takes four minutes to sell one ticket has no bugs.
Nobody would call it a good shop. A shop with a typo on its help page sells tickets all day and is
plainly better. Absence of defects is part of quality and a long way from all of it.

Three definitions have done most of the work since the 1950s, and each is worth holding, because each
one tells you to look somewhere different.

## Conformance to requirements

Philip Crosby, writing about manufacturing in 1979, defined quality as **conformance to
requirements**. A product is good if it does what it was specified to do. This is the definition a
tester uses every time they compare an output with a written rule, and it has one great strength: it
can be checked. `tickets.py` charges R$ 36,00 to a sixty-year-old, the rule says half, and that is a
defect by Crosby's definition with no argument possible.

Its weakness showed in lesson 1. The rule said *over-60s*, Rafael's code conformed to one reading of
it, and the result was wrong anyway. **Conformance is only as good as the requirement it conforms to.**
A product can meet every written word and still fail the people it was written for.

## Fitness for use

Joseph Juran had put it the other way round almost thirty years earlier, in his handbook of 1951: quality is **fitness for use**. A
product is good if the person using it can do what they came to do. This catches what Crosby's
definition misses. Célia, at the box office, would have known in a second that a sixty-year-old pays
half, whatever the sentence said, because she knows what the shop is *for*.

Its weakness is the mirror image. Fitness for use is hard to check before somebody uses the thing, and
different users want different things. A regular customer wants to buy in two taps; the cinema's
accountant wants every ticket recorded with its reduction, for the monthly report to the distributor.
Both are uses. Neither is written down until somebody asks.

## Value to some person

Gerald Weinberg, in 1992, gave the definition most testers quote now: **quality is value to some
person**. It sounds vague and it is the most useful of the three, because of its last two words. It
forces the question every other definition skips: *to whom?* The customer, the box-office manager, the
accountant, the developer who will change this code next year. They value different things, and a
decision about quality is a decision about whose value counts most this time.

James Bach and Michael Bolton later added three words, **"who matters"**: value to some person *who
matters*. That is not cynicism. It is the observation that a tester's report goes to somebody who has
to decide, and the decision depends on whose problem it is.

## What a tester does with three definitions

Use all three, in order. **Conformance** gives you something to check: the written rule. **Fitness for
use** tells you where the written rule is probably wrong or silent: wherever the people who use the
product would be surprised. **Value to some person** tells you who to ask when you cannot decide, and
whose surprise matters more.

The sixty-year-old's ticket fails all three. It does not conform to the law the rule was meant to
follow; it is not fit for a pensioner buying a ticket; and the person it costs, at the counter with a
receipt, matters a great deal to a cinema whose regulars are mostly retired. A defect that fails one
definition is worth discussing. One that fails all three is not a discussion.

The rest of this lesson splits the word in a second way: quality of the **product**, which is what all
three definitions were about, and quality of the **process** that made it, which is the half quality
assurance works on.
