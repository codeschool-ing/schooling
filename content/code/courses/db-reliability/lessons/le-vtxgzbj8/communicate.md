---
title: Saying what is known, on a schedule
version: 1
---

The people affected by an incident (customers, support, the rest of the company) need three things,
and they need them **early and repeatedly** rather than complete:

- **What is known**, in the words they use: "orders could not be placed", not "the leader key
  expired".
- **What is being done**, and what it means for them.
- **When they will hear next**, as a time, and then they hear at that time even if the news is "no
  change".

A first message within minutes, with the facts above, reads like this:

```
14:05  Orders cannot currently be placed in the shop. We are investigating.
       Orders already placed are not affected. Next update by 14:20.
```

and an update, when the cause is known:

```
14:18  The main database server failed at 13:58 and a standby took over at 13:59.
       Orders placed between 13:58 and 13:59 may have failed; customers who saw an
       error should place them again. The shop is working normally. Next update
       by 15:00, or sooner if anything changes.
```

Three rules make these messages trustworthy. **Never guess a cause in public**: "investigating" is
honest and a wrong cause has to be retracted. **Never promise a time to recovery** that nobody has
measured; lesson 8's RTO is the measured one, if there is one. And **say when an update will come, then
keep the appointment**, because silence during an incident is read as either incompetence or
something worse.

The internal running note is the other half: one line per action or observation, with the time, kept
by the incident lead while it happens. It costs seconds per line and it is the only source for the next
section that does not depend on anybody's memory at four in the morning.
