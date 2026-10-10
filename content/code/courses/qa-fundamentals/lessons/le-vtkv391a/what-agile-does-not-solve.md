---
title: What agile does not solve
version: 1
---

**Agile methods fix the problem of late feedback. They do not fix everything, and some of what they leave
behind lands on the tester.** Knowing the common failures in advance is the best protection against
mistaking them for the method working as designed.

## Testing debt

Every cycle produces something new to test and leaves everything old to re-test. When a cycle ends with
testing unfinished, the gap does not vanish; it moves into the next cycle, on top of that cycle's own work.
After a few cycles, the team carries a backlog of things built and never properly checked. This is called
**testing debt**, by analogy with technical debt, and it
compounds the same way: every cycle that adds to it makes the next cycle less able to pay it down.

The symptom is easy to spot and easy to ignore: stories marked *done* that the tester has not seen, or has
seen and has open questions about. The cure is lesson 12's definition of done, enforced honestly: a story
that has not been tested is not done, however finished the code is.

## Speed without a safety net

Short cycles mean frequent changes, and frequent changes mean frequent opportunities to break what worked.
Lesson 10's regression pile grows every cycle. Teams that do not automate their regression checks hit a
wall, usually around the sixth month, when re-testing by hand takes longer than a cycle. At that point they
either stop re-testing, and defects start escaping, or they lengthen the cycles, and stop being agile in
anything but name.

## The tester as an afterthought

Some teams adopt the ceremonies of agile, the short cycles, the daily meeting, the board, and keep the
tester outside them: invited to the planning meeting as an observer, handed stories when they are finished,
asked to "sign off" at the end. That is lesson 5's gate with new furniture. The signal is simple: if the
tester learns what a story means on the day it is handed over, the team is running a mini-waterfall inside
agile vocabulary.

## Requirements that never settle

Responding to change is a value, and a team can practise it until nothing is ever stable enough to test. A
rule that changes three times in a cycle has three sets of expected results, and a tester who has written
tests against the first has to rewrite them twice. The defence is the one lesson 6 used: **make each answer
a written example**. "Half price is the most any ticket is reduced" is a decision; written down as a case
with an expected price, it can be changed deliberately, and everyone can see that it was.

## The tester's position

None of these is an argument against agile. Each is a place where the method relies on the team doing
something it does not enforce: finishing testing inside the cycle, automating the regression pile, including
the tester from the first conversation, writing decisions down. The next three lessons look at three
specific agile methods, Scrum, Kanban and XP, and at what each of them does, or does not, do about these.
