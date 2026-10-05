---
title: The error budget
version: 1
---

An objective of 99.5% says something that a target of *as reliable as possible* never does: **0.5% of
checkouts may fail, and that is fine.** That half per cent is the **error budget**, and treating it as
a budget, something to spend, is the idea that makes SLOs change how a team works.

The lab has been running for fifty-five minutes, so the one-hour window of `slo.yml` is full:

```
ana@obs:~/shop$ ./promq 'sum(increase(http_server_requests_total{job="storefront",route="/checkout"}[1h]))'
  14849.60561599319
```

About fifteen thousand checkouts in the hour. At 99.5%, **seventy-four of them may fail** before the
objective is missed. The recorded series say where things stand:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:.*_1h|checkout:.*rate1h"}'
__name__=checkout:sli_availability:ratio_rate1h  1
__name__=checkout:sli_latency:ratio_rate1h  1
__name__=checkout:error_budget_remaining:ratio_1h  1
```

Every checkout succeeded and was answered within half a second, so the budget is untouched: 1, all of
it. Over 28 days at the same pace, the budget would be some fifty thousand failed checkouts, or 3 hours
and 22 minutes of everything failing.

**What is the budget for?** For everything that risks a failure and is worth doing anyway:

- releases, since every release can break something;
- migrations, experiments, a new database version, a change of cloud region;
- the failures nobody chose: a provider's outage, a bad disk, a bug from last month.

It turns a quarrel into arithmetic. The people building features want to release; the people
answering the pager want stability. Without a budget each side argues from experience. **With one,
the question is whether there is budget left**, and the answer is a number both read off the same
dashboard.

The budget is measured in failures, not time, and that matters at night: an outage at four in the
morning, when ten customers are buying, spends far less of it than the same outage at lunchtime.
