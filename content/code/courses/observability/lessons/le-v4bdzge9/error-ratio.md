---
title: A ratio: what share of charges fail
version: 1
---

Payments is told to fail every twentieth charge, the fault file lesson 1 used for latency:

```
ana@obs:~/shop$ echo '{"fail_every": 20}' > faults/payments.json
```

A minute and a half later, payments' rate of answers by status code:

```
ana@obs:~/shop$ ./promq 'sum by (code) (rate(http_server_requests_total{job="payments"}[1m]))'
code=200  4.266666666666666
code=503  0.2222222222222222
```

**A rate of errors is the wrong number to alert on**, and the reason is in this output. 0.22
failures a second is alarming at five requests a second and nothing at five thousand. The same
failure rate means different things at different traffic. What stays meaningful is the **share**:
failures divided by everything. PromQL divides one vector by another as long as their labels match,
and two `sum()`s with no `by` have no labels at all, so they match:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="payments", code=~"5.."}[1m])) / sum(rate(http_server_requests_total{job="payments"}[1m]))'
  0.049504950495049514
```

**0.0495, about one charge in twenty**, which is what was asked for. That shape, *bad events over
all events, each a `sum(rate(...))` over the same window*, is the most used expression in this
course. Lesson 15 calls it an SLI and builds the shop's availability objective on it, and the alert
at the end of this lesson fires on it.

Two details make it trustworthy. The two halves use **the same window**, here one minute, or the
ratio compares two different periods. And the code is matched with `=~"5.."`, every server error,
not `="503"`. The alert should not depend on which server error the next failure happens to return.
