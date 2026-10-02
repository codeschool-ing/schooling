---
title: The timeline, from the marks
version: 1
---

When the incident is over, its first document is a **timeline**: what happened, when, in order. Built
from memory it is wrong in the ways memory is wrong, with events merged, times rounded and the order of
two actions swapped. Built from the marks the people and machines left behind, it is exact.

The lab has two sources: the annotations in Grafana, written by the deploy robot and the commander, and
the pager's log, written by Alertmanager's webhook. One command merges them, sorted by time:

```
ana@obs:~/shop$ { curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/annotations?from='$(date -d '-30 min' +%s000) | jq -r '.[] | [(.time/1000 | strftime("%H:%M:%S")), "mark", .text] | @tsv'; docker compose logs --no-log-prefix pager | grep '"PAGE"' | jq -r '[.time[11:19], "pager", "\(.status) \(.alertname)"] | @tsv'; } | sort
20:46:49	mark	payments 1.4.2
20:49:58	pager	firing CheckoutBudgetBurningFast
20:50:00	mark	SEV-2 declared: checkouts failing, IC ana
20:51:01	mark	payments rolled back to 1.4.0
20:51:58	pager	resolved CheckoutBudgetBurningFast
20:55:55	mark	resolved: 5-minute burn rate below 1, checkouts normal
```

Read it as the postmortem will, all times in UTC:

| time | what happened |
|---|---|
| 20:46:49 | payments 1.4.2 is released, and checkouts start failing |
| 20:49:58 | the fast burn-rate alert pages the person on call |
| 20:50:00 | SEV-2 is declared, with ana as commander |
| 20:51:01 | payments is rolled back to 1.4.0 |
| 20:51:58 | the page resolves |
| 20:55:55 | the incident is closed, the five-minute burn rate under 1 |

Each gap is a question for the review. The first one is **time to detect**: three minutes and nine seconds
from the release to the page. Rolling back took another minute, the investigation of the previous
section, and the incident was closed nine minutes after it began. Lesson 18 turns these intervals into the numbers teams track, and writes the
postmortem that starts from this list.

Two habits make the timeline this easy:

- **Every human action is marked when it is taken**, by the person or by the scribe. A mark costs a
  command; reconstructing it a day later costs an argument.
- **Every machine keeps times in one zone.** The annotations come back in UTC from `jq`'s `strftime`,
  and the services log in UTC. A timeline merging a log in local time with one in UTC puts the rollback
  three hours before the release.
