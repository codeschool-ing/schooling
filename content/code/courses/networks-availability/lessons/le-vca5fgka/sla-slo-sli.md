---
title: What is measured, aimed at and signed
version: 1
---

A contract that says "99.9% availability" reads like a guarantee that the service will be up. **An SLA
is not a guarantee of anything. It is the price the provider pays when the service falls short**, and
the price is almost always small. No incident was staged in the lab for this lesson, so there is no
capture: its numbers are arithmetic, run as a program where there is a calculation, and the two
failovers measured in lessons 15 and 16.

Three terms travel together and are routinely mixed up, and the difference between them is most of what
this section is about:

| term | what it is | an example |
|---|---|---|
| **SLI**, service level indicator | a measurement | the share of requests answered with a success status within half a second, counted at the balancer |
| **SLO**, service level objective | an internal target for that measurement | 99.95% of requests, over any 30 days |
| **SLA**, service level agreement | a contract with a customer | 99.9% a calendar month, or a credit on the bill |

The SLI comes first because nothing can be promised about what is not measured. Lesson 16's HAProxy log
already holds the raw material of one: every request with its time, its server, its status and five
timers. Counting the lines with a `200` against all the lines, over a month, is an availability SLI that
reflects what users actually got, which is more than a ping to the front door can say.

The SLO is set tighter than the SLA on purpose. It is the alarm that rings while there is still time to
act: a team that aims at 99.95% and misses finds out before a contract promising 99.9% is broken.

## The fine print is the promise

Two SLAs that both say 99.9% can promise very different things, and the difference is in five places:

- **The window.** A calendar month resets on the first; a rolling 30 days never forgets a bad week.
- **What counts as down.** Unreachable only, or also answering with errors, or also answering so slowly
  that nobody waits. A site that takes thirty seconds per page is up by the first definition.
- **Where it is measured.** The provider's own monitoring inside its network, or something that sees what
  a customer sees from outside.
- **What is excluded.** Maintenance announced in advance, outages the customer caused, features marked as
  beta, events outside anyone's control. An exclusion list can remove most of the hours that matter.
- **How a credit is claimed.** Often only if the customer asks, within a set number of days, with evidence.

And the credit itself is capped at the fee. A typical shape, as an illustration rather than any real
provider's table, is 10% of the month's fee below the promised figure and 25% well below it. **A four-hour
outage that costs a shop a day's sales is compensated with a fraction of one month's hosting bill.** So an
SLA is worth reading for what it says the provider measures and aims for, and worth nothing as insurance.
What a business actually needs is an architecture that meets the number, which is what the rest of this
lesson weighs.
