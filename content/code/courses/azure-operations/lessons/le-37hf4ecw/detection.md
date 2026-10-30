---
title: Detection, and the three durations that describe an incident
version: 1
---

**An incident is described by when it started, when somebody knew, and when it stopped hurting.** The
start is in the request logs; the knowing is in the incident channel, which the next sections load as a
table. The three durations between them are the ones a team tracks over time:

```kql
// measures.kql: when it started, when somebody knew, when it stopped
let started = toscalar(AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize min(TimeGenerated));
let ended = toscalar(AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize max(TimeGenerated));
let paged = toscalar(IncidentLog | where Who == "pager" | summarize min(TimeGenerated));
let fixed = toscalar(IncidentLog | where What startswith "scaled" | summarize min(TimeGenerated));
print to_detect = paged - started, to_mitigate = fixed - started, customers_affected_for = ended - started
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < measures.kql
to_detect  to_mitigate  customers_affected_for
00:09:48   00:38:48     00:41:16
```

**Ten minutes to detect, 39 minutes to mitigate, 41 minutes of customers affected.** The first is the
alerting of lessons 12 and 14 doing its job: the burn-rate rule paged at 17:15 UTC. Ten minutes is not
bad, and it is not free either: about 25 failed checkouts happened before anybody knew. The second is
the one this lesson can shorten, because most of those 39 minutes were spent finding out what had
changed.

Detection should come from the alerts, and a good test of an alerting setup is to ask, after every
incident, **who noticed first**. If the answer is a customer, a support ticket or a colleague in a chat,
then an alert is missing or one exists and is not trusted. On Thursday the pager came first, which is the
answer you want.

`print` evaluates expressions with no table at all, and subtracting two datetimes gives a **timespan**,
printed as hours, minutes and seconds. `toscalar()` is lesson 11's: one value, out of a query, into a
name.
