---
title: Event, alert, incident
version: 1
---

Lesson 1 used three words loosely; this phase needs them exactly, because the plan's obligations attach
to the third.

| word | definition | in the week |
|---|---|---|
| **event** | anything observable that happened | 382 rows in `siem.db` |
| **alert** | an event, or pattern of events, a rule selected for a person | lesson 4's five alerts |
| **incident** | a violation, or an imminent threat of violation, of security policy, acceptable use, or standard security practice | what lesson 7 escalated |

The incident definition is the one NIST used for years, and it has two parts worth noticing. **A violation
need not have succeeded**: a threat that is imminent, such as a working password in the hands of somebody
outside, is enough. And **it is measured against policy**, not against damage: a single login by somebody
using a colleague's password is an incident, even if they did nothing afterwards.

Most events are never alerts and most alerts are never incidents. The mistake identification guards against
runs both ways: **an incident treated as an alert** is closed by triage and never investigated, and **an
alert treated as an incident** drags a team into a full response over a typo. Lesson 7's five alerts went
both ways in a few minutes: three closed, one became an incident, one joined it.
