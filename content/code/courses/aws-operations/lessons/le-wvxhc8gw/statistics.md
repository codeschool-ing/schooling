---
title: The average, and the requests it describes
version: 1
---

The statistic most people read first is the average, and for latency it is the one that misleads
most. A hundred requests to the shop's API: ninety-five answered in 40 to 45 milliseconds, five took
900. A single call publishes them all, as values with counts:

```
ana@laptop:~/aws/metrics$ aws cloudwatch put-metric-data --namespace Shop --metric-data 'MetricName=Latency,Dimensions=[{Name=Service,Value=api}],Unit=Milliseconds,Values=[40,42,45,900],Counts=[50,30,15,5]'
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Latency --dimensions Name=Service,Value=api --start-time $START --end-time $END --period 600 --statistics SampleCount Average Maximum --query 'Datapoints[0]'
{
    "Timestamp": "2026-10-16T13:30:25.187000-03:00",
    "SampleCount": 100.0,
    "Average": 84.35,
    "Maximum": 900.0,
    "Unit": "Milliseconds"
}
```

**An average of 84.35 milliseconds, which is the latency of no request at all.** Ninety-five customers
had about 40, five had 900, and the average describes neither group. Read the maximum and you see the
five, but not how many there were. What tells the story is the **percentile**: p95 is the latency 95%
of requests met or beat, p99 the one 99% did.

## The percentile moto does not compute

CloudWatch computes percentiles from the data points, asked as extended statistics:

```
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Latency --dimensions Name=Service,Value=api --start-time $START --end-time $END --period 600 --extended-statistics p99 --query 'Datapoints'
[
    {
        "Timestamp": "2026-10-16T13:30:25.187000-03:00",
        "Unit": "Milliseconds"
    }
]
```

**A data point with a timestamp and a unit, and no `ExtendedStatistics` in it.** moto stores the values
and does not compute percentiles, so for this lab they come from a short program over the same
hundred values, using the nearest-rank method:

```python
# percentile.py: the percentiles of the latencies this lesson published
values = [40, 42, 45, 900]
counts = [50, 30, 15, 5]

samples = sorted(v for v, n in zip(values, counts) for _ in range(n))


def percentile(p):
    # nearest rank: the smallest sample with p% of all samples at or below it
    rank = max(1, -(-p * len(samples) // 100))
    return samples[rank - 1]


print(f"requests {len(samples)}, average {sum(samples) / len(samples):.2f} ms")
for p in (50, 90, 95, 99):
    print(f"p{p:<3} {percentile(p)} ms")
```

```
ana@laptop:~/aws/metrics$ python3 percentile.py
requests 100, average 84.35 ms
p50  40 ms
p90  45 ms
p95  45 ms
p99  900 ms
```

The median and p95 say the service is fast for nearly everybody; **p99 says one customer in a hundred
waits almost a second**. On a page that makes twenty requests, that customer is most customers: the
chance that all twenty requests avoid the slowest 1% is 0.99 to the twentieth power, about 82%, so
nearly one page load in five meets at least one slow request.

On AWS, `get-metric-statistics --extended-statistics p99` and `get-metric-data` with `"Stat": "p99"`
return the percentile directly; CloudWatch computes it from the values it stored, with an
approximation documented to stay within a small error of the exact value. **Alarm on p99 or p95 for
latency, not on the average**, which lesson 10 builds and lesson 12 turns into an objective.

## Which statistic for which metric

| metric | statistic | why |
|---|---|---|
| a count: orders, errors | `Sum` | how many happened in the period |
| a latency | `p95`, `p99` | what most and nearly all requests met |
| a level: free memory, queue depth | `Maximum` or `Minimum` | the worst moment in the period |
| a utilisation | `Average`, with `Maximum` beside it | the trend, and the peak it hides |

`SampleCount` is worth adding to any of them: a p99 computed from 30 requests is a guess, and the
sample count is how a reader knows.
