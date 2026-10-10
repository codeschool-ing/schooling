---
title: The smallest reproduction
version: 1
---

**A defect that cannot be reproduced cannot be fixed with any confidence, because nobody can tell
whether the fix worked.** So the last step of an investigation is to boil it down to the smallest set of
steps that shows the defect, every time, on anybody's machine. That is a **reproduction**, and the small
ones are worth far more than the long ones.

## Smaller is better, and here is how small

The family's purchase involved four people, two ages, a Sunday, a session and a website. The evidence
showed that only one of those mattered. The smallest reproduction Lia wrote for Rafael was this:

```
lia@lab:~/aurora$ python tickets.py 35 no thu 09:30
R$ 28,00
lia@lab:~/aurora$ python tickets.py 35 no thu 9:30
R$ 36,00
```

Two commands. One adult, any day, the same moment written two ways, two different prices. Everything
that did not matter has been removed: the children, the Sunday, the family, the website. **Each thing you
remove is a hypothesis you have ruled out**, and a reader who sees a two-line reproduction knows the
other details were checked and found irrelevant.

A useful test of a reproduction: could somebody who has never heard of the problem run it and see it
without asking you a question? Rafael could. The family's story, handed over as it arrived, would have
started a conversation instead.

## What goes with it

A reproduction is the centre of a defect report, not the whole of it. The rest is short and every part
earns its place:

- **what you expected**, and why: *R$ 28,00 for both, because both are before 17:00 and the rule says a
  session before 17:00 is a matinée;*
- **what happened instead**, copied, never paraphrased: *R$ 36,00 for `9:30`*;
- **where it came from**, so somebody can judge how much it matters: *a family was charged R$ 24,00 too
  much on Sunday; every session before 10:00 is affected, and there is one every Sunday from now on;*
- **what you ruled out**, briefly: *not the day, not the age, not the hour as such.*

Writing a full defect report, with severity, priority and the fields teams track them by, is
`manual-testing` lesson 15. What belongs here is the habit underneath it: **evidence first, copied
exactly, and the smallest version of it you can find.**

## When it will not reproduce

Some defects happen one time in ten, or only on one machine, or only on the first Sunday of the month.
The method does not change; the evidence gets harder to collect.

- **Count rather than describe.** "It sometimes fails" is not evidence. "It failed 3 times in 50 runs" is,
  and it lets you tell later whether a change made it rarer.
- **Look for what differs between the runs that fail and the ones that pass.** The time of day, the order
  of the steps, the data already present, what else was running. Each difference is a hypothesis.
- **Write down what you tried even when it did not reproduce.** A record of what was ruled out saves the
  next person from ruling it out again.

A defect that refuses to reproduce is not proof that it is imaginary. Célia saw what she saw. It is proof
that one of the conditions has not been found yet, and the tester's job is to keep looking for it with
experiments that could prove them wrong.
