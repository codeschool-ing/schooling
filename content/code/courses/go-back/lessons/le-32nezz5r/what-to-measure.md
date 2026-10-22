---
title: What to measure, and what not
version: 1
---

A service can expose thousands of numbers, and nobody reads thousands of numbers. **For anything that
answers requests, three cover most of what matters**, a set often called RED:

| | the question | in boxoffice |
|---|---|---|
| **R**ate | how many requests per second | `rate(boxoffice_http_requests_total[5m])` |
| **E**rrors | how many of them failed | the same counter, with `status=~"5.."` |
| **D**uration | how long they took | `boxoffice_http_request_duration_seconds` |

The expressions in the last column are PromQL, Prometheus' query language. This course did not install
Prometheus, so they were not run; the `observability` course sets a Prometheus server up in its lesson 5.
What the server stores is what the endpoint shows, and that can be read here.

## A histogram, as stored

```
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | grep "duration_seconds.*GET /events/{id}\""
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.001"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.005"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.01"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.05"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.1"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.5"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="1"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="5"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="30"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="+Inf"} 5
boxoffice_http_request_duration_seconds_sum{route="GET /events/{id}"} 0.0017760939999999998
boxoffice_http_request_duration_seconds_count{route="GET /events/{id}"} 5
```

Each `bucket` line is a running count: requests that took at most `le` seconds. All five took under a
millisecond, so every bucket says 5, and `_sum` and `_count` give the mean, under half a millisecond. **A histogram keeps
the shape that an average hides.** If a hundred requests take 2 ms and one takes 4 seconds, the mean is
42 ms and describes none of them; the buckets show a hundred fast requests and one slow one, and the
99th percentile, estimated from them, is what a user waiting in the queue behind the slow one feels.

The buckets are chosen once, in code, and they should bracket what matters for the service: here from a
millisecond, a fast read, to thirty seconds, a stream that is closed early. **Long-lived streams land in
the top buckets**, which is another reason to label by route: the live streams do not drag up the
purchase route's numbers, because they are counted under their own.

## What not to put in a label

The rule from section 04 generalises: **a label value must come from a small set you know in advance.**
Route, status, method, an event's category: yes. A user id, an e-mail address, a ticket id, a request id:
never. Each is unbounded, and the e-mail address is lesson 12's personal data again, now copied into a
monitoring system kept for months. The request id belongs in the log, which is where you go after the
metric has told you when and where to look.

```
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | wc -l
158
```

158 lines for one small service, most of them the Go runtime's. That is a normal size; a few thousand is
normal for a large one, and tens of thousands means a label has escaped.
