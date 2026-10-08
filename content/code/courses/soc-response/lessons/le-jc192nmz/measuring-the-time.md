---
title: Measuring the time it saves
version: 1
---

A SOC measures its speed with three intervals, and they answer different questions:

| measure | from | to | what it says |
|---|---|---|---|
| **MTTD**, mean time to detect | the event | the alert | how good the rules are |
| **MTTA**, mean time to acknowledge | the alert | a person taking it | how well the queue is staffed and sorted |
| **MTTR**, mean time to respond | the alert | containment | how fast the team, and its automation, act |

The *mean* is over many incidents; one incident gives one value of each. Here is a worked example on
Thursday's night, **with times assumed for illustration**, not taken from any log. The login was at 02:33:07
and lesson 4's rule ran every five minutes, so the alert fired at 02:35. Nobody was on call; ana arrived at
08:05, took the alert at 08:12, ran the playbook, read the proposal and approved the block at 08:16.

| | interval | value |
|---|---|---|
| detect | 02:33 to 02:35 | 2 minutes |
| acknowledge | 02:35 to 08:12 | 5 hours 37 minutes |
| respond | 02:35 to 08:16 | 5 hours 41 minutes |

The playbook saved perhaps ten minutes of the respond interval, and **five and a half hours were spent
waiting for a person.** That is the lesson most teams learn from their first measurement: the slowest step
is rarely the work, it is getting the work to somebody. The cheapest automation of that night was not the
block; it was sending the critical alert to a phone at 02:35, with the playbook's ticket attached.

Measure the playbook too. For every run, the ticket says what it proposed; a person later says whether the
proposal was right. **The share of proposals a person overruled** is the number that decides when an
approval step may be removed, and when a playbook should be rewritten.
