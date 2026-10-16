---
title: Counters, rates and what is happening now
version: 1
---

With Prometheus scraping three copies, the box office can be put under load and asked about it
**while it happens**, from its own numbers. Two load generators run for forty seconds, one selling
tickets with 16 workers and one reading show pages with 4; thirty seconds in, four questions in
**PromQL**, Prometheus's query language.

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum by (route, status) (rate(tickets_requests_total[30s]))'
{route="/events/{id}", status="200"} => 479.32289066666664 @[1791612608.076]
{route="/events/{id}/tickets", status="201"} => 337.5599133333333 @[1791612608.076]
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum(tickets_in_flight)'
{} => 17 @[1791612608.539]
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'rate(process_cpu_seconds_total[30s])'
{instance="172.18.0.5:8000", job="tickets"} => 0.7752 @[1791612608.875]
{instance="172.18.0.7:8000", job="tickets"} => 0.7855999999999999 @[1791612608.875]
{instance="172.18.0.8:8000", job="tickets"} => 0.7888 @[1791612608.875]
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'histogram_quantile(0.95, sum by (le, route) (rate(tickets_request_seconds_bucket[30s])))'
{route="/events/{id}"} => 0.019730909090909073 @[1791612609.274]
{route="/events/{id}/tickets"} => 0.1203033472803349 @[1791612609.274]
```

And what the two load generators printed when they finished:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 40 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  13250 in 40.0 s = 331.0 per second
latency   p50 38.7 ms  p95 118.0 ms  p99 179.3 ms  max 412.5 ms
status    201: 13250
```

```
ana@lab:~/tickets$ python3 load.py -c 4 -d 40 --events 100 'http://localhost:8080/events/{event}'
requests  18814 in 40.0 s = 470.3 per second
latency   p50 4.0 ms  p95 29.9 ms  p99 61.8 ms  max 285.8 ms
status    200: 18814
```

## Rate: how fast a counter grows

`rate(tickets_requests_total[30s])` is the per-second increase of each counter over the last thirty
seconds, which turns "13 000 requests since the copy started" into **"requests per second now"**.
`sum by (route, status)` adds the three copies together and keeps one line per route and status.

The box office says **479 reads and 338 sales a second**. The load generators say 470 and 331. The
small difference is what each measured: the generators averaged over forty seconds including the
first moments, while the rate covers the last thirty, at full speed. **Two independent measurements
of the same thing that agree is the first check that instrumentation is right**, and it is worth
doing once on any system.

`rate` handles the awkward property of counters: when a copy restarts, its counter falls back to
zero, and `rate` treats the fall as a reset rather than as a negative rate. **Never graph a counter's
raw value**; graph its rate.

## Saturation and utilisation

`sum(tickets_in_flight)` is **17 requests in progress** across the copies at that instant: the sixteen
sale workers and the four read workers, minus those whose answer was on its way back. It is the
box office's saturation, the work waiting or being done, and under a growing load it is the number
that grows first.

`rate(process_cpu_seconds_total[30s])` is each copy's processor use: **0.78 of a processor each**,
three times. Each copy is capped at one, and the three share the lab's four with nginx, PostgreSQL,
Prometheus and the generators, which is lesson 1's horizontal measurement seen from the inside.

## The percentile, from the inside

The last query asks for the 95th percentile of latency per route, computed from the histograms:
**120 ms for a sale and 20 ms for a read**. The generators measured 118 ms and 30 ms. Why those
agree for sales and not for reads, and why neither number is exact, is the next section.
