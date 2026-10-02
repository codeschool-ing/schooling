---
title: The objective, written as rules
version: 1
---

An SLI computed by hand is a query. An objective a team lives by is **a set of recording rules**,
evaluated every few seconds and stored as series. That way dashboards and alerts read the same
numbers and nobody retypes the expression with a different window. The shop's, in
`prometheus/rules/slo.yml`:

```
ana@obs:~/shop$ cat prometheus/rules/slo.yml
# The checkout's service level objective: 99.5% of checkouts do not fail on
# our side. The window is one hour so that a lesson can watch it move; in
# production it would be 28 days, and every expression below is the same.
groups:
  - name: checkout-slo
    interval: 30s
    rules:
      - record: checkout:sli_availability:ratio_rate5m
        expr: |
          sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m]))
          / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))
      - record: checkout:sli_availability:ratio_rate1h
        expr: |
          sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[1h]))
          / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1h]))
      - record: checkout:sli_latency:ratio_rate1h
        expr: |
          sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[1h]))
          / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[1h]))
      - record: checkout:error_budget_remaining:ratio_1h
        expr: 1 - (1 - checkout:sli_availability:ratio_rate1h) / (1 - 0.995)
```

Four series, named by the convention `level:metric:operation`, which says what was aggregated, from
what, and how:

- **`checkout:sli_availability:ratio_rate5m`** and **`…ratio_rate1h`**: the availability SLI over
  two windows. The short one is for watching an incident; the long one is the objective's window.
- **`checkout:sli_latency:ratio_rate1h`**: the share answered within half a second.
- **`checkout:error_budget_remaining:ratio_1h`**: what is left of the budget, as a fraction. 1 means
  untouched, 0 means spent, and a negative number means the objective was missed.

**The window is one hour.** A real objective uses 28 days, and a lesson cannot wait 28 days to watch
it move. So the lab compresses it: every expression is the same with `[28d]` in place of `[1h]`, and
every conclusion scales. Prometheus is told to read the file again:

```
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name == "checkout-slo") | .rules[] | [.name, .health] | @tsv'
checkout:sli_availability:ratio_rate5m	unknown
checkout:sli_availability:ratio_rate1h	unknown
checkout:sli_latency:ratio_rate1h	unknown
checkout:error_budget_remaining:ratio_1h	unknown
```

The four rules are loaded, with health `unknown` because none has been evaluated yet. Thirty seconds
later the first values exist.

Two practical notes. A 28-day `rate` over raw counters reads 28 days of samples on every evaluation,
which is expensive. Real setups record the short-window ratios and average those, or keep the long
window in a store built for it. And **the objective, 0.995, is written in one place**: if it appears
in every alert and every panel, the day it changes is the day they start to disagree.