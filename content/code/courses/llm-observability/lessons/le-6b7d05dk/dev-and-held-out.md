---
title: Development and held-out
version: 1
---

Every case in version 2 belongs to one of two **splits**, decided by its id alone: every third id is
**held out**, the rest are for **development**. That is `rag`'s rule, kept so that the first thirty cases
stay where they were, and it gives 28 and 14.

The two splits answer different questions:

- **Development** is where a team looks while changing things. Every failing case is read, the prompt
  or the retrieval is adjusted, and the score is measured again. After a few rounds the changes are
  shaped by these cases, and the score on them is no longer an estimate of anything but these cases.
- **Held-out** is not looked at while changing things. It is run when a change is finished, to say
  whether the improvement on development carries over to questions the change was not shaped by. Lesson
  11's threshold for judge-1 was chosen on all sixty labelled replies, with nothing held out, which is
  why that lesson refused to adopt it.

A split decided by id rather than at random has one property worth more than balance: **a case never
changes split**. New cases join by the same rule, and a case that was held out last year is held out
now, so nobody can tune on it by accident.

## How many cases is enough

Lesson 9's arithmetic applies to a set as it does to a sample. With 14 held-out cases, a pass rate of
70% is known to within about ±24 points; with 28, about ±17. A set this size can show a release that
breaks a third of the answers, and it cannot show one that breaks a tenth.

Two things follow. **A set is never finished**: every week's harvest is a source of cases, and a team
that adds a few each week has a few hundred within the year. And **a small set is still worth having**,
because what it lacks in precision it makes up in being the same every time: the same 42 questions,
run on every version, find a change that breaks a case outright, which is the kind lesson 14 is about.
