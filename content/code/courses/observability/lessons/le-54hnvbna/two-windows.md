---
title: Two windows at once
version: 1
---

A burn rate needs a window, and every window is a compromise. **A long window is slow to notice and
slow to forget**: an hour-long window takes many minutes to rise past a threshold, and keeps firing
for an hour after the problem is fixed. **A short window is fast in both directions**, and so it fires
on every blip.

The answer, from the Google SRE workbook, is to require both: the burn rate must be high over a long
window, which says the damage is large, and over a short one, which says it is still happening. In
production the fast page uses one hour and five minutes; the lab uses five minutes and one, so the
lesson can watch it work. The shop has been buying for half an hour, so every window holds real
traffic.

First, a blip. For forty seconds, payments fails one charge in four. Five seconds after it stops:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  34.591993584174304
__name__=checkout:burn_rate:5m  5.923616523772379
__name__=checkout:burn_rate:30m  0.9460973484376911
```

The one-minute burn rate is 34.6, far past 14.4: for that minute, checkouts failed at thirty-five
times the rate the objective can sustain. The five-minute rate is 5.9, under the threshold, and the
thirty-minute rate is 0.95.

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'
```

**No alert.** The short window alone would have woken somebody for forty seconds of trouble that had
already ended. The long one says the damage was small, and the rule needs both.

Then a real failure: one charge in ten fails, and stays failing. Four and a half minutes later:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  19.70443349753692
__name__=checkout:burn_rate:5m  18.082618862042075
__name__=checkout:burn_rate:30m  4.008465081538648
```

All three windows are up: 19.7 over one minute and 18.1 over five, both past 14.4, and 4.0 over
thirty, past the slow alert's 3.

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'
{"alertname":"CheckoutBudgetBurningSlowly","severity":"ticket","state":"suppressed","inhibitedBy":["50e1ed8789a027ea"],"silencedBy":[]}
{"alertname":"CheckoutBudgetBurningFast","severity":"page","state":"active","inhibitedBy":[],"silencedBy":[]}
```

**The page is active**, and the ticket is `suppressed`, which the next section explains. Each alert
reached the pager once:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep -E '"(PAGE|TICKET)"' | jq -c '{message, status, alertname, severity}'
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"PAGE","status":"resolved","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"TICKET","status":"firing","alertname":"CheckoutBudgetBurningSlowly","severity":"ticket"}
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
```

Read in order, the log shows something the alert list does not. **The page fired, resolved, and fired
again.** One charge in ten failing is a burn rate of about 20, and over one minute that number moves
with chance. For a moment it dipped under 14.4, the condition broke, and Alertmanager announced a
resolution. In that gap the page no longer held the ticket back, so the ticket went out too.

That is **flapping**, and it happens whenever the real rate sits close to a threshold. The usual fix is
a short `for:` on the fast rule, a minute or two. It delays the page a little and stops a single dip
from resolving it.

One trap is worth knowing, because the lab fell into it while this lesson was written. **A counter
series that does not exist yet cannot show a rate.** The storefront creates its `code="502"` counter
on the first failed checkout, and `rate()` needs two samples of a series to see it grow. A blip that is
the first failure ever can therefore pass almost unseen by every window. The lab avoids it by staging
one failed charge thirty minutes earlier; in code, the fix is to create the series for the codes you
expect at zero, when the service starts.
