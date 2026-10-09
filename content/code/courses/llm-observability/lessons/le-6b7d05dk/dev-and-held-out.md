---
title: Development and held-out
version: 2
---

Every case in version 2 belongs to one of two **splits**, decided by its id alone: every third id is
**held out**, the rest are for **development**. It gives 22 and 10.

The two splits answer different questions:

- **Development** is where a team looks while changing things. Every failing case is read, the prompt
  or the retrieval is adjusted, and the score is measured again. After a few rounds the changes are
  shaped by these cases, and the score on them is no longer an estimate of anything but these cases.
- **Held-out** is not looked at while changing things. It is run when a change is finished, to say
  whether the improvement on development carries over to questions the change was not shaped by. A
  threshold chosen on every labelled reply, with nothing held out, is fitted to those replies and says
  nothing about the next ones.

A split decided by id rather than at random has one property worth more than balance: **a case never
changes split**. New cases join by the same rule, and a case that was held out last year is held out
now, so nobody can tune on it by accident.

## How many cases is enough

Lesson 9's arithmetic applies to a set as it does to a sample. With 10 held-out cases, a pass rate of
70% is known to within about ±28 points; with 22, about ±19. A set this size can show a release that
breaks a third of the answers, and it cannot show one that breaks a tenth.

Two things follow. **A set is never finished**: every week's harvest is a source of cases, and a
team that adds a few each week has a few hundred within the year. And **a small set is still worth
having**, because what it lacks in precision it makes up in being the same every time. The same 32
questions, run on every version, find a change that breaks a case outright, which is the kind lesson
14 is about.