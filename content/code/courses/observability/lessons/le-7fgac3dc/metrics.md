---
title: A metric: how many, and how slow
version: 1
---

Every service of the shop keeps a few counters in memory and publishes them at `/metrics`, in the
text format Prometheus reads. One of them is a **histogram** of how long the storefront took to
answer, kept per route. These are its lines for `/checkout`, a few of the buckets and the two
totals:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep -E '^http_server_request_duration_seconds_(bucket|count|sum)\{.*route="/checkout"' | grep -E 'le="(0.1|0.5|1.0|2.5|\+Inf)"|_count|_sum'
http_server_request_duration_seconds_bucket{le="0.1",method="POST",route="/checkout"} 2.0
http_server_request_duration_seconds_bucket{le="0.5",method="POST",route="/checkout"} 2.0
http_server_request_duration_seconds_bucket{le="1.0",method="POST",route="/checkout"} 2.0
http_server_request_duration_seconds_bucket{le="2.5",method="POST",route="/checkout"} 111.0
http_server_request_duration_seconds_bucket{le="+Inf",method="POST",route="/checkout"} 111.0
http_server_request_duration_seconds_count{method="POST",route="/checkout"} 111.0
http_server_request_duration_seconds_sum{method="POST",route="/checkout"} 167.5032239500007
```

Each `bucket` line counts the requests that took **at most** the time in `le`, "less than or equal".
Two checkouts took under 0.1 seconds: the two sent before payments was slowed. All 111 took under
2.5 seconds, so 109 landed between one second and two and a half. `_count` is how many there were
and `_sum` how many seconds they added up to, so the mean is 167.50 / 111, about 1.51 seconds.

That is the shape of a metric: **a handful of numbers that grow, whatever the traffic.** A thousand
checkouts or a million cost the same seven lines. Prometheus reads them every fifteen seconds and
keeps the history, which is what lets it answer *how slow were checkouts over the last two
minutes*:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[2m])))' | jq -r '.data.result[0].value[1]'
2.485
```

The query asks for the 99th percentile: the time under which 99 checkouts in a hundred finished.
The answer, 2.485 seconds, is **not a time any request took.** The checkout timed with `curl` took 1.54, and every slow checkout waited the same
one and a half seconds in payments.
A histogram knows only which bucket a request fell into, so Prometheus assumes the 109 requests
between 1 and 2.5 were spread evenly across that range and reads the percentile off that
assumption. Lesson 5 writes this query step by step, and lesson 6 is about choosing buckets so that
the assumption costs less.

Even with that error, the metric did its job: **checkouts went from milliseconds to seconds**, and an
alert written on this number would have fired. What it cannot say is why. The labels are route and
method, so every checkout looks the same to it. No line here mentions payments, and none can point
at one particular request. That is the next two signals' work.
