---
title: Spending it
version: 1
---

For four minutes, payments is told to fail one charge in twenty. Three minutes in, the five-minute SLI
and how fast it is spending the budget:

```
ana@obs:~/shop$ ./promq 'checkout:sli_availability:ratio_rate5m'
__name__=checkout:sli_availability:ratio_rate5m  0.9706438786432104
ana@obs:~/shop$ ./promq '(1 - checkout:sli_availability:ratio_rate5m) / (1 - 0.995)'
  5.871224271357906
```

**97% of checkouts in the last five minutes succeeded**, which sounds healthy, and is **5.9 times the
rate the objective allows**. That second number is the **burn rate**: the error ratio divided by the
ratio the objective permits, here 0.5%. A burn rate of 1 spends the budget in exactly one window; 5.9
would spend an hour's budget in about ten minutes, and a 28-day budget in under five days. Lesson 16
alerts on it.

The fault is removed, and a minute and a half later the hour is read again:

```
ana@obs:~/shop$ ./promq 'sum by (code) (increase(http_server_requests_total{job="storefront",route="/checkout"}[1h]))'
code=201  15245.523012552301
code=402  900.7531380753138
code=502  54.67989841269841
ana@obs:~/shop$ ./promq '{__name__=~"checkout:.*_1h|checkout:.*rate1h"}'
__name__=checkout:sli_availability:ratio_rate1h  0.9966718460154416
__name__=checkout:sli_latency:ratio_rate1h  1
__name__=checkout:error_budget_remaining:ratio_1h  0.3343692030883135
```

Fifty-five checkouts answered `502` in the hour, out of about sixteen thousand. The availability SLI
for the hour is 99.67%, comfortably above the objective, and **the budget remaining is 0.33: two thirds
of the hour's budget went in four minutes.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The hour's error budget drawn as a bar. About 16 200 checkouts in the hour at an objective of 99.5% allow 81 failures. The four-minute incident caused 55 of them, two thirds of the bar, leaving a third: 26 failures for the rest of the hour.\"><defs><marker id=\"bg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one hour: 16 200 checkouts, 81 may fail</text><rect x=\"60\" y=\"70\" width=\"600\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"70\" width=\"407.4074074074074\" height=\"50\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"263.7037037037037\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">spent by the incident: 55</text><text x=\"563.7037037037037\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">left: 26</text><text x=\"60\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"660\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">81</text><text x=\"360\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">budget remaining: 0.33</text></svg>", "caption": "Four minutes of one charge in twenty failing spent two thirds of an hour's budget. Over 28 days, the same four minutes would have spent about a tenth of one per cent of it."}
```

Two lessons sit in those numbers. **An SLI that reads 99.7% can still mean trouble**: the objective
was met, and there is a third of the budget left for the rest of the window. Another incident like this
one would miss it. And **the window decides how dramatic an incident looks**: the same 55 failures
against a 28-day budget of about fifty thousand would be about a tenth of one per cent of it. The lab's one-hour window makes every
incident look large on purpose, so that a lesson can watch the budget move; a real team sees this as a
small dip in a long line, and the policy in the next section decides what that dip means.
