---
title: The person who knows
version: 1
---

Every system has somebody who knows where everything is: which server is the primary this week, the
order in which to bring things back, the password that is not in the password manager. On the night
something breaks, that person is asleep, on a plane, ill, or has left the company. Recovery that
depends on them is a recovery with an availability of its own, and it is lower than anything in
lesson 21's table.

Lesson 1 told the story of a team with five ways of getting their data back and none that worked; the
other half of that night was people working out, by hand and under pressure, what state each copy was
in and what could be tried next. Every step they took was reasonable, and every one was decided for
the first time at that moment.

A **runbook** moves those decisions to a calm afternoon. It is a document per system that lets
somebody competent, who has never touched this system before, take it from "it is broken" to "it is
working and we know what happened", using only what the document says. That definition contains the
test of whether a runbook is any good: **give it to somebody else, and watch.**

Three things make one, and this lesson builds each for the cluster of lessons 16 to 19:

- **A format** that is the same for every scenario, so that nobody has to read the whole page to find
  the step they need.
- **A first page that prints itself**, because the state of the system changes and a page about it
  does not.
- **A check** that the page is still true, run by a machine, on a schedule.
