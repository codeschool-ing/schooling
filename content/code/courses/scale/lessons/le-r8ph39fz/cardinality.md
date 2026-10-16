---
title: Cardinality, the way metrics get expensive
version: 1
---

Every distinct combination of a metric's labels is a **series**, and Prometheus stores and indexes
each series separately. Counting them is a query like any other:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'count by (__name__) ({__name__=~"tickets_.*"})'
tickets_requests_total => 7 @[1791612636.481]
tickets_request_seconds_bucket => 66 @[1791612636.481]
tickets_request_seconds_count => 6 @[1791612636.481]
tickets_request_seconds_sum => 6 @[1791612636.481]
tickets_in_flight => 3 @[1791612636.481]
```

Every number can be explained from the labels:

- `tickets_in_flight` has no labels, so one series per copy: **3**.
- `tickets_requests_total` has `method`, `route` and `status`: each copy has seen a `GET` that
  answered 200 and a `POST` that answered 201, which is 6, and one copy also has the 500 of the last
  section: **7**.
- `tickets_request_seconds_bucket` has a series per bucket, eleven of them counting `+Inf`, for each
  of the two routes on each of the three copies: **66**.

A hundred series is nothing. A Prometheus server holds millions. The danger is a label whose values
are many, because **the number of series is the product of the number of values of every label**.

## The label that would have cost a million series

`observe` labels each request with `self.route`, the template `/events/{id}`. The obvious
alternative is `self.path`, the path as requested. It would have produced one series per show for
reads, another per show for sales, times eleven buckets, times three copies:

| label | values | series of `tickets_request_seconds_bucket` |
|---|---|---|
| route template | 2 | 2 × 11 × 3 = **66** |
| path, with 100 shows | 200 | 200 × 11 × 3 = **6 600** |
| path, with 100 000 shows | 200 000 | 200 000 × 11 × 3 = **6 600 000** |

The last line would make the monitoring system the box office's biggest problem: memory, disk, slow
queries, and a bill in proportion if the metrics go to a hosted service. And nothing about it would
look wrong in a test with three shows.

**Labels are for dimensions with a small, bounded set of values**: a route template, a method, a
status class, a region, a copy. Anything per user, per request, per ticket or per show belongs in
logs or traces, where an event's details are expected to be unique. The same rule appeared as tags
against fields in lesson 4's time series, because a monitoring system is one.
