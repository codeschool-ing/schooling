---
title: A metric is a type, a resource and labels
version: 1
---

**Every number in Cloud Monitoring is a point in a time series, and a time series is named by three
things: a metric type, a monitored resource, and the values of their labels.** The metric type says what
is measured, such as `run.googleapis.com/request_count`. The monitored resource says what it was measured
on: a Cloud Run revision, a Compute Engine instance, a bucket. The labels narrow both down: the service's
name, the response's status class, the region. Change any one of them and it is a different series, with
its own history and its own line on the bill. **Nothing in this lesson reaches Cloud Monitoring**, because
nothing on your computer imitates it; what runs here is the arithmetic it applies, on data a program
generates, and a Terraform plan of the shop's checks and dashboard.

The shop's request count on Cloud Run is one metric type and many series:

| metric type | resource | labels | one series |
|---|---|---|---|
| `run.googleapis.com/request_count` | `cloud_run_revision` | `service_name`, `revision_name`, `response_code_class` | the `shop-api` revision `shop-api-00042`, responses `5xx` |

Google publishes the metrics of its own services without anybody writing code, and they are free to
receive: they are the "non-chargeable Google Cloud metrics" on the pricing page. A metric your own program
writes, `custom.googleapis.com/...` or one sent through OpenTelemetry (lesson 12), is charged by the volume
received.

## Three kinds

A metric's **kind** says what a point means, and getting it wrong is how a graph shows nonsense:

- **GAUGE**: the value at an instant. Memory in use, the number of instances, a queue's depth.
- **DELTA**: how much happened in the interval the point covers. Requests in this minute.
- **CUMULATIVE**: how much has happened since a start time, growing until the process restarts. Most
  counters a program exports are cumulative, because a program can count without knowing when anybody will
  read the count.

Nobody wants to look at a cumulative series directly: it is a line going up, steeper when busier. What
people want is the rate, and turning one into the other is what an **aligner** does.

## The aligners, by hand

The program below generates ten minutes of the shop's API, a cumulative request counter and the latency of
every request, and applies the arithmetic of two aligners and two summaries. Write it into
`~/gcp/align.py`:

```schooling-example
{"language": "python", "file": "align.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"align.py: what Cloud Monitoring's aligners do to a series, done by hand.\n\nTen minutes of the shop's API, one point a minute. Nothing here talks to\nGoogle: the data is generated, and the arithmetic is the aligners'.\n\"\"\"\n", "note": "The docstring says what the program is and is not: generated data, and the arithmetic Cloud Monitoring applies. Nothing in it calls Google."}, {"code": "import random\nimport statistics\n\n", "note": "Standard library only: `random` makes the data, `statistics` computes means and percentiles."}, {"code": "rng = random.Random(7)\n# a CUMULATIVE counter: total requests since the process started\ntotal, counter = 0, []\nfor minute in range(11):\n    counter.append((minute, total))\n    total += 600 + rng.randint(-50, 50)\n# each minute's latencies in ms: most fast, a few slow\nlatencies = [[rng.choice([40, 45, 50, 55]) if rng.random() > 0.02 else 2400\n              for _ in range(600)] for _ in range(10)]\n\n\n", "note": "Two series, both seeded so that every run prints the same numbers. The first is a **CUMULATIVE** counter, the kind a process exports: the total since it started, which only grows. The second is the latency of each of 600 requests a minute, 98% of them fast and 2% taking 2.4 seconds."}, {"code": "def align_delta(points):\n    return [(t2, v2 - v1) for (t1, v1), (t2, v2) in zip(points, points[1:])]\n\n\ndef align_rate(points):\n    return [(t, d / 60) for t, d in align_delta(points)]\n\n\n", "note": "`ALIGN_DELTA` turns a cumulative series into how much it grew in each interval, and `ALIGN_RATE` divides that by the interval's length in seconds. Cloud Monitoring applies them to every series before anything else, so that series sampled at different moments can be compared."}, {"code": "def pct(values, p):\n    return statistics.quantiles(values, n=100)[p - 1]\n\n\n", "note": "A percentile: the value below which that share of the requests fall. `quantiles(n=100)` returns the 99 cut points, so the 50th is the median and the 99th is what one request in a hundred is slower than."}, {"code": "print('minute  counter  ALIGN_DELTA  ALIGN_RATE/s  mean_ms  p50_ms  p99_ms')\nfor (t, v), (_, d), (_, r), lat in zip(counter[1:], align_delta(counter),\n                                       align_rate(counter), latencies):\n    print(f'{t:>6}  {v:>7}  {d:>11}  {r:>12.2f}  {statistics.mean(lat):>7.1f}'\n          f'  {pct(lat, 50):>6.0f}  {pct(lat, 99):>6.0f}')\n", "note": "One row a minute: the raw counter, what each aligner makes of it, and three summaries of the same 600 latencies."}]}
```

```
ana@laptop:~/gcp$ python3 align.py
minute  counter  ALIGN_DELTA  ALIGN_RATE/s  mean_ms  p50_ms  p99_ms
     1      591          591          9.85    110.3      50    2400
     2     1160          569          9.48     86.3      45    2400
     3     1760          600         10.00     86.7      50    2400
     4     2393          633         10.55     90.4      45    2400
     5     2949          556          9.27     67.0      45      55
     6     3508          559          9.32     86.6      45    2400
     7     4126          618         10.30     90.4      50    2400
     8     4688          562          9.37    102.5      50    2400
     9     5284          596          9.93     75.4      50    2400
    10     5908          624         10.40     90.2      45    2400
/home/user/schooling/content/code/courses/gcp-operations/lessons/le-zywq3egq/checks.md: expected one block for tf/monitoring/dashboard.json, found 0
```
