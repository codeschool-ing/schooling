---
title: Escalation: when the page is not answered
version: 1
---

A page is a question to a person, and people are sometimes asleep through it, on the underground, or
in the shower. **Escalation is the rule for what happens when the page is not acknowledged**: after a
few minutes, the next person is paged, and then the next.

An acknowledgement is the person saying *I have this*; it stops the escalation and tells everybody
else that somebody is looking. Alertmanager has no idea of it. It sends, groups and repeats, but it
does not know whether a human read the message, which is why the lab's pager is a log and why real
teams put a paging service between Alertmanager and the phone: PagerDuty, Opsgenie, Grafana OnCall,
or the paging feature of their chat tool. Those keep the rota, take the acknowledgement and run the
escalation policy:

| step | after | who is paged |
|---|---|---|
| 1 | immediately | the primary on call, by push notification and then phone call |
| 2 | 10 minutes without acknowledgement | the secondary on call |
| 3 | 20 minutes | the team lead |
| 4 | 30 minutes | the head of engineering |

The times are chosen against the objective: a burn rate of 14.4 spends 2% of the month's budget per
hour, so twenty minutes without anybody looking costs about 0.7%, which a team can decide is
acceptable before somebody senior is woken up.

Escalation also runs **sideways**: the person on call pages another team when the problem is theirs.
That only works if every team has a rota of its own and a documented way to reach it, and a service
without one is a service whose incidents end at three in the morning in somebody's personal phone
book.
