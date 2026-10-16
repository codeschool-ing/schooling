---
title: After a defect, before the fix is forgotten
version: 1
---

**Root cause analysis is the work of finding out why a defect was possible, so that the next one like it is
not.** Fixing a defect removes it. Understanding why it happened removes the conditions that produced it, and
those conditions are usually still there, waiting to produce the next one in some other part of the program.

This is lesson 1's prevention, applied after the fact. Every defect that escaped is evidence about how the team
works, and lesson 12 put the question at the centre of the retrospective: **why was it possible?** This lesson
gives that question two methods, the five whys and the Ishikawa diagram.

## Not every defect deserves one

Root cause analysis takes an hour or two of several people's time. Cine Aurora does it for defects that meet
any of three conditions:

- it **reached a customer**, like the Sunday 9:30 session of lesson 4;
- it **cost money or trust**, like refused orders that still counted in the nightly seats report in lesson 8;
- it is **the second of its kind**, which says the cause survived the first fix.

A typo caught in review gets fixed and forgotten, and that is right. Analysis that runs on everything becomes a
form people fill in, and a form people fill in finds nothing.

## Blameless, or useless

The most important rule of root cause analysis is about people: **the analysis looks for causes in the system,
not for someone to blame.** That is not kindness. It is method.

Ask "who wrote the line that compared times as text?" and the answer is *Rafael*, and the analysis is over. Rafael
will be more careful for a month, and the conditions that let a reasonable developer write that line are untouched.
Ask "why was it reasonable to write that line?" and the analysis is just beginning: nobody had said how session
times were typed, no example had a one-digit hour, and the person who typed the schedule was never in the
conversation.

Blame also destroys the evidence. A team that is punished for defects learns to hide them, report them late, or
argue about whether they are defects at all. A team that is asked *how did our process let this through?* talks
about what happened, which is the only material an analysis has.

## Start with a precise problem statement

An analysis starts with one sentence that says what went wrong, in facts, without causes in it. Compare:

| vague | precise |
|---|---|
| "the pricing was broken" | "on the first Sunday of the 9:30 session, an order of four tickets was charged the evening price, R$ 108,00 instead of R$ 84,00" |
| "Rafael's code had a bug" | "`price()` returns the evening price for any session time written with a one-digit hour" |

The precise version says what, when, how much and how often, and it names no person. Every later step checks
itself against it.
