---
title: Logging what a defender needs
version: 1
---

Leaving things out of the log is half of the lesson. The other half is putting in what somebody
will need on the day something goes wrong: **a record of security events detailed enough to say
who did what, when, and whether it was allowed**.

### Which events

| event | why it matters |
|---|---|
| sign-in, succeeded and failed | a burst of failures for one account, or for many accounts from one place, is the commonest early sign of trouble |
| sign-out and session expiry | to know when access ended |
| access refused | lesson 1's 404 for somebody else's booking is worth a line: one is a mistake, fifty are a pattern |
| a change to who may do what | a role granted or removed, by whom |
| an export or a bulk read | the event that turns a leak from one record into thousands |
| an unexpected error | with its reference, as in this lesson's fix |

### What each line carries

**When** (a timestamp with its time zone), **who** (an account identifier, never a password), **what**
(the action and the object, by identifier), **from where** (the request's address where the law and
the policy allow), **and the outcome** (allowed, refused, failed). A line missing any of the five is a
line that cannot answer the question it was written for.

### Somebody has to read them

A log nobody looks at protects nothing. The minimum is an alert on the events that should be rare:
many failed sign-ins, a role change outside working hours, a spike in refusals. Where the logs go and
who watches them is beyond one application's code.

::: track security devsecops
In your track, `soc-response` is the course about reading these records: collecting them in one
place, correlating them and deciding when an event is an incident. What this lesson asks of the code
is to write them, completely and safely.
:::

::: track *
Collecting these records in one place, correlating them and deciding when an event is an incident is
the work of a security operations team, and a subject of its own. What this lesson asks of the code
is to write them, completely and safely.
:::
