---
title: Reading the aligned numbers, and the mean that hides the slow requests
version: 1
---

The program's output, again, as the last section printed it:

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

Read it column by column.

- **`counter`** is what the process exported: 5,908 requests after ten minutes. On a graph it is a line
  going up, and it says almost nothing about any one minute.
- **`ALIGN_DELTA`** is each minute's growth: 591, then 569, then 600. Those are the requests per minute,
  and the shape of traffic becomes visible.
- **`ALIGN_RATE/s`** is the same divided by sixty: about ten requests a second. A rate is what a dashboard
  shows and what an alert compares with a threshold, because it reads the same whatever the alignment period.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"On the left, a cumulative counter drawn as a staircase that only rises. An arrow labelled ALIGN_RATE, sixty seconds, leads to the right, where the same data is a rate per second that rises and falls with traffic.\"><defs><marker id=\"ah3\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">CUMULATIVE counter</text><text x=\"570\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">rate per second</text><line x1=\"30\" y1=\"180\" x2=\"280\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"30\" y1=\"180\" x2=\"30\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"30\" y1=\"175\" x2=\"70\" y2=\"175\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"70\" y1=\"175\" x2=\"70\" y2=\"165\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"70\" y1=\"165\" x2=\"110\" y2=\"165\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"110\" y1=\"165\" x2=\"110\" y2=\"140\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"110\" y1=\"140\" x2=\"150\" y2=\"140\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"150\" y1=\"140\" x2=\"150\" y2=\"125\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"150\" y1=\"125\" x2=\"190\" y2=\"125\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"125\" x2=\"190\" y2=\"90\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"90\" x2=\"230\" y2=\"90\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"230\" y1=\"90\" x2=\"230\" y2=\"80\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"230\" y1=\"80\" x2=\"270\" y2=\"80\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"270\" y1=\"80\" x2=\"270\" y2=\"55\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"300\" y1=\"110\" x2=\"410\" y2=\"110\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah3)\"></line><text x=\"355\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ALIGN_RATE, 60s</text><line x1=\"440\" y1=\"180\" x2=\"690\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"440\" y1=\"180\" x2=\"440\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"440\" y1=\"170\" x2=\"480\" y2=\"158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"480\" y1=\"158\" x2=\"520\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"520\" y1=\"130\" x2=\"560\" y2=\"148\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"560\" y1=\"148\" x2=\"600\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"600\" y1=\"100\" x2=\"640\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"640\" y1=\"160\" x2=\"680\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line></svg>", "caption": "The counter only says how many since the start. The aligner turns it into how many per second."}
```

## The alignment period

An aligner works on a window, the **alignment period**, and produces one point per window per series. Here
the period is sixty seconds because the data has one point a minute. A dashboard showing a week
uses a longer period, such as an hour, and each point is then an hour's rate: **a spike that lasted two
minutes is averaged into the hour and disappears.** The same chart at a one-minute period would show it.
When a graph looks calm and users say it was not, the period is the first thing to check.

## Mean, median and the 99th percentile

The last three columns summarise the same 600 latencies per minute. **The mean is around 90 ms and
describes nobody.** Ninety-eight requests in a hundred took 40 to 55 ms, which is what the median, 45 or 50,
says. Two in a hundred took 2,400 ms, which is what the 99th percentile says. The mean is pulled up by the
slow ones and down by the fast ones and lands between them, where no request actually was.

In minute 5 the p99 is 55: by chance, fewer than one request in a hundred was slow that minute, so the
99th percentile fell among the fast ones. One minute in ten looks healthy at p99 and is not different from
the others, which is why latency alerts look at percentiles over several minutes rather than at one point.

For latency, Cloud Monitoring keeps a **distribution**, a histogram per point, and the aligners
`ALIGN_PERCENTILE_50`, `ALIGN_PERCENTILE_95` and `ALIGN_PERCENTILE_99` read percentiles out of it. A
dashboard of the shop's latency shows p50 and p99 together: the gap between the two lines is the story.

## Reducers: many series into one

After aligning, a **reducer** combines series. `REDUCE_SUM` of the request rate across every revision of
`shop-api` is the service's total traffic; grouped by `response_code_class`, it is the traffic per class,
`2xx` against `5xx`. A reducer never undoes an aligner, so the order is fixed: align each series first,
then reduce across them. **Averaging percentiles across series is wrong**: the mean of three instances'
p99 is not the service's p99. Reducing distributions first, then reading the percentile, is the right
order, and Cloud Monitoring does that when the metric is a distribution.
