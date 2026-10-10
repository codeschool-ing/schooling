---
title: What the rule does not say
version: 1
---

**The most valuable black-box tests are often the ones the requirement did not ask for.** Sentences 2 and
3 each describe a reduction. Neither says what happens when both apply. Lia ran the three customers most
likely to meet both: a student, a child and an older person, on a Wednesday.

```
lia@lab:~/aurora$ python tickets.py 20 yes wed 20:00
R$ 9,00
lia@lab:~/aurora$ python tickets.py 8 no wed 14:00
R$ 7,00
lia@lab:~/aurora$ python tickets.py 70 no wed 20:00
R$ 9,00
```

**R$ 9,00 for a student on a Wednesday evening: a quarter of the full price.** The program applied the
Wednesday half and then the student half on top of it. A child at a Wednesday matinée pays R$ 7,00, and
a seventy-year-old on a Wednesday evening pays R$ 9,00 too.

## Is that a defect?

Here black-box testing reaches the edge of what it can decide on its own. The expected result for this
input is not written anywhere. Two readings of the rule are possible:

- **reductions add up:** half for Wednesday, half again for being a student, R$ 9,00. The program is
  right;
- **half is half:** a ticket is either half price or not, and a student on a Wednesday pays R$ 18,00 like
  everybody else that day. The program is wrong.

Lia cannot settle that by testing harder. No run can tell her what Joana meant, because Joana never said.
What she can do is what lesson 2 called the deliverable: **write it down as a question to the product
owner, with the case that raises it.**

> Sentences 2 and 3 do not say what happens when both apply. Today a student on a Wednesday evening
> pays R$ 9,00, a quarter of the full price (`python tickets.py 20 yes wed 20:00`). Is that intended?

Joana's answer came the same afternoon, and settled it: **half price is the most any ticket is reduced.**
Célia had always sold it that way, since a quarter-price ticket would not cover the distributor's share.
The rule gained a fifth sentence, and the program had a defect it had had since the first day, which no
test of the original four sentences could have found.

## Why the gap was there

The defect is not in the code, strictly. Rafael implemented exactly what was written: two reductions,
each applied when its condition holds. **The defect is in what was not written**, and it went unnoticed
for the same reason as the 9:30 defect in lesson 4: nobody's test exercised the combination, because no
sentence described it.

This is one of the most productive habits in black-box testing. For every pair of conditions in a rule,
ask what happens when both are true. Cine Aurora's rule has three reductions, being a student, an age
and Wednesday, and so three pairs; the requirement answered none of them. The two that involve Wednesday
are the ones above. The third, a student of sixty-five, the program happens to charge one half, which
agrees with Joana's answer; nobody had decided that either, and agreeing by luck is not the same as
having been tested.

## An ambiguity becomes a test

Look at the child at the Wednesday matinée: R$ 7,00. Before Joana's answer, that number could have been
argued either way. After it, it is a defect with an expected result, R$ 14,00, and a reproduction of one
command. **A question answered turns an ambiguity into a test.** That is the whole route from an unwritten
rule to a defect someone can fix.
