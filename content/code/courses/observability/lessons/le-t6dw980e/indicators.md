---
title: Indicators, measured from the customer's side
version: 2
---

Lesson 5 wrote the expression this lesson is built on, bad events over all events, and promised it a
name. **A service level indicator, an SLI, is the share of events that went well, measured where the
customer meets the service.** For the shop, the event that matters is a checkout, and the place is the
storefront.

This lesson watches an hour go by, because an objective is measured over a window and the window
here is one hour. Start the lab again from nothing and set the customers going for seventy minutes;
the first queries need five of them:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 4200
sleep 300
```

Five minutes of checkouts, by status code:

```
ana@obs:~/shop$ ./promq 'sum by (code) (increase(http_server_requests_total{job="storefront",route="/checkout"}[5m]))'
code=201  1275.2889684210525
code=402  74.73684210526315
```

About 1350 checkouts: 1275 answered `201`, an order placed, and 75 answered `402`, a card declined.
**Is a declined card a failure?** For the customer, perhaps; for the shop, no. The card network said
no and the storefront told the customer so, which is the system working. An availability SLI counts
the failures that are ours, so the good events are everything except a `5xx`:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m])) / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))'
  1
```

A ratio of 1: every checkout in the window was answered without a fault of ours. The second indicator
most services need is **latency**, phrased the same way: the share of checkouts answered within half
a second, read straight from the histogram's `le="0.5"` bucket:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[5m])) / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[5m]))'
  1
```

Also 1. Two choices in that expression are decisions rather than details:

- **A threshold, not an average.** *99% of checkouts under 500 ms* is something a customer can feel
  and an objective can be set on; *an average of 180 ms* hides the slow tenth, as lesson 7 showed.
- **The bucket boundary is the threshold.** A histogram can only answer for boundaries it has, so the
  threshold an SLI wants has to be one of the buckets `web.py` declares. Choosing the SLI first and
  the buckets after is the right order.

**Where the SLI is measured decides what it can see.** Measured at the storefront it includes every
service behind it; measured at `orders` it would miss a storefront that fails on its own. And
measured per service it has to be careful about what it counts:

```
ana@obs:~/shop$ ./promq 'sum by (route) (rate(http_server_requests_total{job="orders"}[5m]))'
route=/orders  4.5014254035087715
```

Only `/orders`, because `web.py` skips `/metrics` and nothing probes `orders` in this lab. Had
lesson 14's healthcheck stayed on, `/ready` would be on this list too: twelve requests a minute that
succeed whenever the database is up. **An SLI over every route would count probes as satisfied
customers.** An indicator names the route, or the operation, that a customer actually uses.