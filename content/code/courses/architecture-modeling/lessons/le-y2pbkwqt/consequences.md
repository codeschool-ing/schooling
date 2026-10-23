---
title: Consequences, including the ones you would rather not write
version: 1
---

**The consequences section says what becomes true once the decision is in force: what gets easier,
what gets harder, and what new work or risk the decision creates.** It is the part most often left
thin, because writing the bad consequences of your own decision feels like arguing against it. It
is also the part that protects the decision best.

## Three kinds, all of them written

For the seat holds in Redis, Tainá wrote:

- **Positive.** Hold traffic leaves the booking database; at the next peak the database's CPU fell
  from 85% to 52%. Expiry is handled by Redis itself, so the clean-up job is deleted.
- **Negative.** A Redis restart without persistence loses every hold in flight. Passengers paying at
  that moment see *seat no longer held* and must choose again. We accept this: a lost hold costs a
  passenger a minute, and holds are recreated in seconds.
- **Neutral, but new work.** The booking service must now check the hold in Redis before writing a
  booking, and handle Redis being unreachable by refusing new holds rather than skipping the check.
  Platform adds Redis to the on-call runbook.

The negative paragraph is the one that will matter. When Redis restarts during a deploy two months
later and somebody asks *why did forty passengers lose their seats?*, the record already answers:
**it was a known, accepted cost**, chosen against the alternatives for stated reasons. Without it,
the same incident reads as a mistake, and the decision gets reversed in a hurry by people who do not
know what it was protecting.

## Consequences are claims you can check later

A good consequence is specific enough to be found true or false: *CPU falls below 60% at peak*,
*holds lost on restart*. That is what turns the decision log into something you can review, and
lesson 13 uses it: an architecture review asks, for each important record, whether its consequences
came true. A record whose predicted benefit never arrived is a candidate for being superseded.

## What does not belong

- **Implementation steps.** *Create the Redis client, add a feature flag, migrate on Tuesday* is a
  plan. Link to the ticket instead.
- **Restating the decision.** *We will use Redis* is not a consequence of deciding to use Redis.
- **Wishes.** *This will make the system more scalable* is a hope with no measure. Say what will
  scale, to what, and how anybody would know.
