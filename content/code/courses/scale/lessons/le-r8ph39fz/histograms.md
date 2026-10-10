---
title: Reading a histogram
version: 1
---

A histogram does not keep latencies; it keeps **counts per bucket**. Here are the sale's buckets,
summed over the three copies, ten seconds after the load generators stopped:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum by (le) (tickets_request_seconds_bucket{route="/events/{id}/tickets"})'
{le="0.005"} => 0 @[1791612628.076]
{le="0.01"} => 839 @[1791612628.076]
{le="0.025"} => 4857 @[1791612628.076]
{le="0.05"} => 9303 @[1791612628.076]
{le="0.1"} => 12404 @[1791612628.076]
{le="0.25"} => 13236 @[1791612628.076]
{le="0.5"} => 13251 @[1791612628.076]
{le="1.0"} => 13251 @[1791612628.076]
{le="2.5"} => 13251 @[1791612628.076]
{le="5.0"} => 13251 @[1791612628.076]
{le="+Inf"} => 13251 @[1791612628.076]
```

Read it as a cumulative table. Of 13 251 sales, 839 took up to 10 ms, 4857 up to 25 ms, 9303 up to
50 ms, **12 404 up to 100 ms**, 13 236 up to 250 ms, and every one of them up to 500 ms. The total
matches what the load generator counted, 13 250, plus the one sale of section 05.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The sale's latency histogram as bars of requests per bucket: none under 5 milliseconds, 839 from 5 to 10, 4018 from 10 to 25, 4446 from 25 to 50, 3101 from 50 to 100, 832 from 100 to 250 and 15 from 250 to 500. A line marks the 95th percentile, which falls inside the 100 to 250 millisecond bucket; the histogram only knows it is somewhere in that bucket.\"><rect x=\"50\" y=\"210.0\" width=\"70\" height=\"1\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><text x=\"85\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">≤5</text><rect x=\"142\" y=\"180.81739130434784\" width=\"70\" height=\"29.18260869565217\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"170.81739130434784\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">839</text><text x=\"177\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5–10</text><rect x=\"234\" y=\"70.24347826086955\" width=\"70\" height=\"139.75652173913045\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"269\" y=\"60.24347826086955\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4018</text><text x=\"269\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10–25</text><rect x=\"326\" y=\"55.356521739130415\" width=\"70\" height=\"154.64347826086959\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"361\" y=\"45.356521739130415\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4446</text><text x=\"361\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25–50</text><rect x=\"418\" y=\"102.1391304347826\" width=\"70\" height=\"107.8608695652174\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"453\" y=\"92.1391304347826\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3101</text><text x=\"453\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50–100</text><rect x=\"510\" y=\"181.0608695652174\" width=\"70\" height=\"28.93913043478261\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"171.0608695652174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">832</text><text x=\"545\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100–250</text><rect x=\"602\" y=\"209.47826086956522\" width=\"70\" height=\"1\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"637\" y=\"199.47826086956522\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">15</text><text x=\"637\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250–500</text><path d=\"M40 210 L690 210\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"365\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds</text><text x=\"555\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">p95 is somewhere in here</text><path d=\"M555 30 L555 158\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "13 251 sales sorted into buckets. The 95th percentile is in the 100–250 ms bucket, and that is all the histogram can say."}
```

## How a percentile comes out of buckets

The 95th percentile is the latency below which 95% of the requests fall: 95% of 13 251 is 12 588.
The table says 12 404 fall below 100 ms and 13 236 below 250 ms, so the 12 588th is **somewhere
between 100 and 250 ms**. That is all the histogram knows. `histogram_quantile` then assumes the
requests are spread evenly inside the bucket and interpolates: 184 of the 832 requests in that
bucket, about 22% of the way from 100 to 250 ms, which is about 133 ms over the whole run, and 120
ms over the thirty seconds section 06 asked about.

So **a percentile from a histogram is an estimate, and its error is set by the buckets.** Here the
answer lies in a bucket 150 ms wide, and any value in it is equally consistent with the counts. The
generator measured 118 ms exactly because it kept every latency. Two consequences:

- **Choose bucket boundaries around the values you care about.** If the target is "95% of sales
  under 250 ms", a boundary at exactly 0.25 makes that question exact, whatever the interpolation
  does elsewhere. Section 10 uses it.
- **A bucket's count can be added across copies, and a percentile cannot.** `sum by (le)` added three
  copies' buckets before computing one percentile for the whole box office. Three per-copy
  percentiles averaged would be wrong, for the reason lesson 2 gave about medians across shards.
  This is why histograms are the standard way to keep latency in a system with many copies.

## Inside and outside

For reads, the box office said 20 ms and the generator measured 30 ms, and **both are right**. The
histogram is measured inside the handler, from the moment the request is read to the moment the
answer is written. The generator's clock also includes nginx, two trips across the network and the
time a request waits to be accepted. On a read that takes a few milliseconds, that outside part is
a large share; on a sale of a hundred milliseconds, a small one, which is why those two agreed. **A
latency from inside a service is a lower bound on what its users experience.**
