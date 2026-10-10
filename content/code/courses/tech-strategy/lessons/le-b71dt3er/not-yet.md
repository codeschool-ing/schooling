---
title: Not yet, and the condition that changes it
version: 1
---

"Not yet" is the most useful answer a strategy gives, and the easiest one to abuse. **It is honest
only when it names a condition somebody else can check and a date on which somebody will look.**
Without those two it is a no that avoids the conversation, and the request comes back at every
planning meeting until somebody gives it a real answer.

## Three answers that sound alike

A tech lead has more than two answers to a request, and the ones in the middle are where most of
the trouble is.

| answer | what it promises | what the asker hears |
|---|---|---|
| "no" | this will not happen under the current strategy | a decision they can accept or escalate |
| "later" | nothing at all | a yes with no date, so they plan around it |
| "not yet, when…" | a yes on the day a stated condition holds | a decision with a way back in |

"Later" is the dangerous one, because it feels kind to the person saying it. The asker hears a yes,
tells the festival something is coming, and finds out at the next planning that nothing was ever
scheduled. **A "later" that nobody wrote down is a no delivered months late**, after the asker has
spent their own credibility on it.

A plain no has its place too. Coreto's strategy says outright that the microservices migration does
not start this year, and lesson 3 put that on the page under what the company will not do. A
request to start a service extraction gets a no, citing the page, and no condition, because there
is nothing the team could observe this year that would change the answer short of changing the
strategy.

## A condition somebody else can check

The usual wrong idea is that a condition softens a no. It does the reverse: **a condition commits
the team to a yes on the day it holds**, and the asker can hold them to it. That is why a vague one
is tempting and why it is worthless.

A checkable condition has three properties. It is observable — somebody can look and see whether
it is true. It does not depend on the speaker's mood or workload. And it has an owner, who will say
when it has been met.

| vague | checkable |
|---|---|
| "when things calm down" | "when the load test passes an on-sale replay with group holds" |
| "when we have capacity" | "after the lock removal, planned to end in August" |
| "when the platform is ready" | "when every Checkout call to the hold path goes through the new interface" |

Read the right-hand column as Júlia would. Each one tells her what to watch and who to ask. The
first one even tells her something she can help with: if the festival's group sizes are known,
the Reservations team can put them into the load test now, so that the replay in August tests the
thing she wants.

## The date to look again

Some conditions come with a date because the strategy already has one: the lock removal ends in
August, so September is when the group-bookings question can be decided. Others do not. A load
test can fail, and the team cannot promise the day it will pass.

When the condition has no date, give the date on which somebody will check it. "We will look at
this at the planning of the first sprint of September, and Mateus will bring the load-test result"
is a commitment the team can keep whatever the result is. **The review date is what stops a
"not yet" from decaying into a "later"**: it puts the question back in front of a named person on a
named day.

## Keep the list where the strategy lives

One not-yet is easy to remember. A quarter's worth of them, across seven teams, is not, and the ones that are
forgotten become exactly the "later" this section warns against. Davi keeps them in a short table
beside the strategy page:

| request | asked by | condition | review | owner |
|---|---|---|---|---|
| group bookings for the festival | Júlia | load test passes an on-sale replay with group holds | first sprint of September | Mateus |

The table does a second job. If three requests in one quarter wait on the same condition, the
condition is costing the business something, and that is evidence for the next review of the
strategy itself. Lesson 20 is about that review, where a strategy has to defend its choices to the
people who pay for them.

## When "not yet" is a disguise

A not-yet can be dishonest in a way that passes every test above on the day it is said. **The
condition is set after the fact, or it moves each time it is met.** The load test passes, and now
the condition is a second load test; August arrives, and now it is the end of the year. Each move
has a plausible reason, and together they are a no that nobody was willing to say.

If you notice that you want a condition that cannot be met, say no instead and give the reason.
The asker can escalate a no. They cannot escalate a condition that keeps receding, and they will
stop believing the next one you give them, including the honest ones.
