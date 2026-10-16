---
title: Stopping in the middle, and starting again
version: 1
---

**Sometimes a cycle has to stop before it ends, and the conditions for stopping and for starting again are worth
writing down as well.** They are called **suspension** and **resumption criteria**, and they exist for the morning
when continuing would waste everybody's time.

## When to suspend

At Cine Aurora a cycle is suspended when either of these happens:

- **a blocking defect stops a large part of the planned testing.** If orders cannot be placed at all, the price rule,
  coupons, refunds and the report cannot be tested through the box office either; testing around the hole produces
  half-results that will all have to be repeated;
- **the build under test changes underneath the testing.** A new build installed in the middle of the cycle, without
  warning, makes every result before it doubtful.

What suspension is *not* is a tester stopping because the work is hard or the defects are many. Many defects is the
cycle working.

## What happens during a suspension

Suspending is a message, not a silence. On Thursday morning of the Friday release, the refund button turned out to
crash the box office program whenever a refund was confirmed, taking the open order with it. Lia's message to the
team was three lines:

> **Testing suspended at 9:40.** Confirming a refund closes the box office program and the order is lost
> (defect 31, steps attached). Prices, orders and coupons are tested; refunds, the report and the seat map are not.
> **Resumes when** a build that fixes defect 31 passes the smoke test.

The first line says what happened and when. The second says what is done and what is waiting, so nobody has to ask.
The third is the resumption criterion, specific enough that everybody knows what *ready* means.

## When to resume

Resumption criteria are usually the entry criteria again, plus the fix: a new build with the blocking defect fixed,
passing the smoke test, installed on the test machine. Lia also re-runs the checks for anything the fix touched, which
for the refund crash meant orders too, because the crash had been losing them.

Rafael's fixed build arrived at 11:30, passed the smoke test, and the cycle resumed at 11:50. Two hours and ten
minutes were lost, and they are now a line in the summary, because the exit criteria said every area gets its planned
hours *or the shortfall is written down*. The shortfall came out of the two lowest-priority areas: the seat map went
from two hours to twenty minutes, the report from one hour to thirty minutes.

## The point of writing it all down

Entry, exit, suspension and resumption criteria can all sound like bureaucracy for a team of five. They earn their
place for one reason: they move decisions from the moment of pressure to a calm moment before it. On Wednesday, nobody
argues for starting on a broken build. On Friday at five, everybody does. Criteria written on Monday are the Monday
team protecting the Friday team from itself.
