---
title: Roles, and the messages that go out
version: 1
---

The person best able to fix the problem is the worst person to coordinate it: their attention belongs to
the system. Incidents above the smallest separate the jobs, and **each role is held by one person at a
time**, named in the channel:

| role | the job | not the job |
|---|---|---|
| incident commander | decides, assigns, keeps the clock, declares the end | typing commands |
| operations lead | investigates and changes the system, says what they are about to do before doing it | updating customers |
| communications lead | writes the updates, internal and external, on schedule | guessing the cause |
| scribe | records decisions and times in the channel as they happen | deciding |

In a small team one person holds two roles, and the commander's is the one never shared with operations.
**Handing a role over is explicit**: "I am handing command to Bruno", "Bruno has command", in the channel,
so nobody has to guess who decides.

## Updates on a clock

Customers forgive an outage much more readily than silence. The communications lead sends updates at a
fixed interval, every thirty minutes for a SEV1, **even when there is nothing new**, because "still
investigating, next update at 15:30" tells customers somebody is on it. An update says four things:

> **Checkout errors: investigating.** Since 14:02 BRT, some customers see an error when paying. Orders
> already placed are not affected. We are investigating and will update by 14:45 BRT.

What was observed, from when, what is **not** affected, and when the next update comes. What it never
says: the cause before it is known, a time to fix nobody can promise, a person or a team to blame.

## Mitigate first, understand later

The commander's first question is not "why" but "**what stops the bleeding?**" A rollback (lesson 3),
moving traffic away from a bad zone, turning off the feature behind a flag: each restores service before
anybody understands the cause, and that is the right order. **The time to mitigate is the number
customers feel**; the investigation can continue after the graph is green, with the system no longer on
fire and the people no longer under the clock.
