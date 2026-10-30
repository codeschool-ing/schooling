---
title: Who tests, and what you ask them
version: 1
---

**A beta with nobody looking at it is a release with a delay.** The tracks and TestFlight move
builds; what turns a build into information is who is on the other end and what they were asked
to do.

## The right people for each rung

- **Internal: the team, every build.** Including the people who do not write code. A designer
  notices the screen that was never meant to look like that; somebody in support notices the flow
  customers ask about.
- **Closed: people who use the app for real.** For the planner, students who agreed to try new
  versions during term, with their real courses in it. A test account full of `Course 1` and
  `Course 2` finds nothing the team did not already know.
- **Open: anybody who wants the new thing early.** Many people, little guidance, and the numbers
  of lesson 12 more than their words.

## What to ask

**A specific question gets an answer; "please test" gets silence.** Each beta build goes out with a
sentence saying what changed and what to try: *"Sessions now sync between phone and tablet. Add a
session on one and check it appears on the other within a minute."* TestFlight's *What to Test*
field and Play's release notes for a testing track exist for that sentence.

## Feedback is a channel, not an inbox

Feedback that arrives and is read by nobody teaches testers to stop sending it. One person reads
it every day of a beta, answers the testers who wrote, and turns what is real into issues. **A
tester who hears back keeps testing**; one who does not becomes a production user who found the
bug first and left a review instead.

## What testing does not replace

A beta finds what people notice. It does not find the crash on a phone model nobody in the beta
owns, the slowdown after three weeks of data, or the bug in a country with a different calendar.
Those surface in production, a few per cent of it at a time, which is why lesson 8 releases in
stages rather than all at once.
