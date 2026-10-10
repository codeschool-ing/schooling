---
title: The first ninety days, and what to leave alone in them
version: 1
---

Michael Watkins wrote *The First 90 Days* (2003) for executives changing jobs, and the title stuck
because the window is real: **a new leader is watched closely for about three months, and the
impressions formed then are hard to move afterwards.** For a manager promoted from inside the team,
the window is shorter and stranger. Everybody already knows you, and what they are watching for is
what changed.

The most common mistake in it is acting too early. The second most common is never acting at all.

## Why the urge to fix things is strongest now

Renata had opinions about Agenda long before she managed it. The deploy pipeline was slow, the
planning meeting ran over every fortnight, and the on-call rota put the same two people on every
holiday. In her first week she had the authority to change all three, and every instinct she had
said to use it.

Three reasons to wait, each one concrete:

- **She knows the problems from one seat.** As an engineer she saw the pipeline from the person
  waiting on it. She did not know that the platform team had a migration planned for next quarter,
  or that the planning meeting ran over because Helena used it to get answers she could not get
  anywhere else.
- **Early changes are read as verdicts.** Changing the on-call rota in week one tells the two
  people who designed it that their work was wrong, before anybody asked them why it looks the way
  it does.
- **She has no record yet.** A manager who has listened for a month and then changes something can
  say what she heard. One who changes things in week one can only say what she thinks.

## A listening tour, done on purpose

The alternative is not doing nothing. It is a deliberate first month of asking, with the same
questions to everybody, so the answers can be compared. Renata booked forty-five minutes with each
engineer, with Helena, with Otávio, and with the two managers whose teams Agenda depends on. She
asked each of them the same five questions:

1. What is going well here that I should be careful not to break?
2. What is getting in your way at the moment?
3. If you were in my seat, what would you change first?
4. What do you need from me that you did not get before?
5. Is there anything you think I should know that I have not asked about?

**The first question matters most and is the one people skip.** A new manager arrives looking for
problems, and finds them, and breaks something nobody mentioned because it was working. On Agenda,
four of seven people named the same thing in answer to it: Diego reviewed every pull request
within a few hours, which was the main reason the team rarely waited on anything. Renata had been
planning to ask Diego to spend less time on reviews and more on design.

## Writing down what you heard

The answers go into one document, grouped by theme rather than by person, with a count beside each
theme. At the end of the month Renata's looked like this, in shortened form:

| theme | people who raised it |
|---|---|
| on-call falls on the same people at holidays | 5 of 7 |
| planning meetings run long | 4 of 7, plus Helena |
| nobody knows what Payments will deliver, or when | 6 of 7 |
| fast reviews are what keeps the team moving | 4 of 7 |
| the pipeline is slow | 2 of 7 |

The table changed her plans. The pipeline, which had annoyed her most as an engineer, was raised by
two people. The dependency on Payments, which she had barely thought about, was raised by six.
**What annoys you most is a sample of one.**

## What to change, and when

By the end of the second month a new manager should have changed something, and it should be
something people asked for. Renata picked the on-call rota, because five people raised it and
because fixing it needed nobody outside the team. She asked the two people who had built the old
rota to draft the new one, which turned the change from a verdict on their work into their own
project.

The rest she wrote down as a plan with dates and showed to the team, including the things she was
deliberately leaving alone. **Saying what you are not changing is as useful as saying what you
are**, because it stops people guessing.

## The colleague who is now your report

One thing about a promotion from inside the team does not go away by listening. Some people were
your peers last month, and one of them may have wanted the job. On Agenda that was Diego, and both
of them knew it.

There is no technique that makes this comfortable. What helps is saying it plainly, early and
once, in private: that you know he wanted the role, that you value what he does, and that you want
to talk about what he wants from the next year. Lesson 2 picks this up, because what Diego wanted
turned out to be a different job from the one Renata got.
