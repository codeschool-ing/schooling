---
title: Mitigate first, understand later
version: 1
---

There is a release of payments, three minutes old, and payments is failing. **What the bug is does not
matter yet.** The customers need the shop back, and the fastest way back is the version that worked.
The rollback is marked as it happens:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["deploy"], "text": "payments rolled back to 1.4.0"}' localhost:3000/api/annotations | jq -c .
{"id":3,"message":"Annotation added"}
```

The fault file is removed, which is the lab's rollback, and ninety seconds later:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  0
__name__=checkout:burn_rate:5m  18.720748829953227
__name__=checkout:burn_rate:30m  12.50921021855389
```

**The one-minute burn rate is 0**: no checkout has failed for a minute. The five-minute rate is still
18.7, because the window still holds the minutes before the rollback. Lesson 7 called this the lag of
a window, and here it is the difference between *fixed* and *looks fixed*.

Then the page resolves, and the commander waits for the slower window before declaring the end:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  0
__name__=checkout:burn_rate:5m  0.31201248049921304
__name__=checkout:burn_rate:30m  8.704804751988403
```

The five-minute rate is 0.3, under 1: the last failures have left the window. The thirty-minute rate
is still 8.7 and will take half an hour to fall, which is the slow alert's job and no reason to keep the
incident open. The commander marks the end:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["incident"], "text": "resolved: 5-minute burn rate below 1, checkouts normal"}' localhost:3000/api/annotations | jq -c .
{"id":4,"message":"Annotation added"}
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep '"PAGE"' | jq -c '{time, status, alertname}'
{"time":"2026-10-02T20:49:58.986Z","status":"firing","alertname":"CheckoutBudgetBurningFast"}
{"time":"2026-10-02T20:51:58.987Z","status":"resolved","alertname":"CheckoutBudgetBurningFast"}
```

The page fired once and resolved once, a minute after the rollback.

**Rolling back before understanding is the default, not a shortcut.** Three things make it safe:

- **The release can be undone.** A deploy pipeline that cannot roll back in one step turns every bad
  release into a debugging session under pressure.
- **The bug is not lost.** Release 1.4.2 still exists, with its code and its logs. The investigation
  happens tomorrow, without customers waiting on it.
- **The rollback is itself a change**, so it is marked like one. Otherwise the next person to read
  the graph sees errors stop with no reason given.

When there is nothing to roll back, the same principle applies to whatever restores service fastest:
failing over, turning a feature off, scaling up, or taking a broken dependency out of the path.
**Restore first; the root cause is the postmortem's job.**
