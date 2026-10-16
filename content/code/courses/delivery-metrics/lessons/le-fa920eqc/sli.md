---
title: What counts as a good charge
version: 1
---

Every argument about reliability starts with a word nobody defined. The support team says card payments were "down" on Tuesday; the developers say the service was up the whole day and the card provider was slow. Both are describing the same hour, and they cannot settle anything until they agree on what they are counting.

A **service level indicator**, or SLI, is that agreement written as a ratio:

```localised
SLI = good events ÷ valid events
```

It is a share, between 0% and 100%, of the things the service did that went right, counted over a period. Google's SRE books, which gave the idea its names, recommend this form over any other, because a ratio of events means the same thing on a quiet Sunday and on the last afternoon of the month.

## The Billing team's definition

For card charges, the Billing team wrote it this way:

- **a valid event** is a charge attempt that reaches the service from a shop's terminal;
- **a good event** is one that is answered within 10 seconds and charges the card exactly once, or declines it for a reason the bank gave.

Three choices are hidden in those two lines, and each one is the kind of thing a team argues about only once if it is written down.

- **A decline can be good.** A card with no funds should be refused, and refusing it in two seconds is the service working. Counting declines as bad would make the SLI fall every time shoppers run out of money, which has nothing to do with the team.
- **Slow is bad.** A shop owner with a queue at the till cannot tell a payment that failed from one that takes forty seconds; both make them try again. So the threshold belongs to what the user can bear, and ten seconds came from the support team's notes, not from the team's servers.
- **Charging twice is bad.** It is the worst answer there is, worse than a failure, and an SLI that counted only "did the provider say yes" would have scored the afternoon of 30 September as a success.

## Measured where the user is

An SLI is measured as close to the user as the team can get. The CPU of a server, the number of instances running or a health check that answers "ok" are causes, and each of them can look fine while every shop's terminal waits. The Billing team counts at the point where the terminal's request arrives and the answer leaves, which is the nearest place the team controls.

## A few of them, not forty

A service needs **one to three SLIs per thing a user is trying to do**, and the usual kinds are few:

| kind | the question | for the Billing team |
|---|---|---|
| availability | did it answer? | the charge got an answer |
| latency | was the answer fast enough? | within 10 seconds |
| correctness | was the answer right? | charged once, the right amount |
| freshness | was the data recent enough? | the monthly statement ready by 06:00 on the 1st |

The team folded the first three into one SLI for charges, because the shop owner experiences them as one thing, and kept freshness as a second SLI for the statement. Two numbers is a dashboard somebody reads; forty is a dashboard everybody learns to ignore, and lesson 18 is about where that leads.
