---
title: Actions that actually happen
version: 1
---

**A postmortem is worth the actions that come out of it and get done, and nothing more.** The most
common failure is not a bad analysis; it is a good analysis whose actions are vague, unowned and
forgotten by the next incident, which then has the same contributing factors and the same write-up.

## Three kinds of action

Every contributing factor can be answered in one of three ways, and a good list has some of each:

| kind | what it does | from 6 March |
|---|---|---|
| **prevent** | removes the hole, so it cannot happen this way again | a connection quota per service on the orders database |
| **detect** | finds it sooner, if it happens anyway | an alert on database connections above 90%, not only on checkout errors |
| **mitigate** | makes it smaller, or recovery faster | a "stop all batch jobs" switch in the incident runbook |

A list that is all *prevent* assumes the team has found every way in. A list that is all *detect* accepts
the failure and only shortens it. **Defence in depth means one of each, at least, for the factors that
matter most.**

## Each action has an owner, a date and a ticket

The 6 March review produced six actions. This is how they were written:

| action | owner | due | status in May |
|---|---|---|---|
| runbook: no backfill between 17:00 and 22:00 | Henrique | 7 March | done |
| alert on database connections above 90% | Lucas | 20 March | done |
| connection quota per service (an RFC, lesson 2) | Lívia | 1 May | done |
| backfill job opens at most 10 connections | Paulo | 27 March | done |
| "stop all batch jobs" switch in the incident runbook | Lucas | 3 April | done |
| read replica for the route planner | platform team | April | done |

**"Be more careful" is not an action.** Neither is "improve monitoring" or "raise awareness". An action
names one change, one person who owns it, a date, and a ticket where its status can be seen. If it
cannot be written that way, it is not ready to be an action; it is a question for somebody to answer
first.

Note who owns the fourth action. Paulo, whose job started the incident, chose to own the fix to the job
itself. **In a blameless review, the person closest to the event is usually the best person to fix the
system around it**, and asking them to is a sign of trust rather than penance.

## Track them where they cannot be forgotten

Marola's postmortem actions go into the owning team's normal backlog, labelled with the incident, and
the incident's write-up links to each ticket. Once a month, the engineering meeting spends five
minutes on one number: **the share of postmortem actions done by their due date.** It was 40% the year
before; after the 6 March review made it visible, it went above 80%.

## Small, now, rather than large, later

An action list that contains one large project ("rewrite the order system") and nothing small is a
list where nothing happens for six months. The 6 March list had four actions done within a month, each
of which removed a hole on its own. The replica, the large one, mattered most and was already approved;
it did not have to carry the whole response.
