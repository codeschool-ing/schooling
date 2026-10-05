---
title: Histograms, and what a bucket cannot say
version: 1
---

Durations cannot be a counter or a gauge: the question is not *how many* but *how they were spread*.
A **histogram** answers it by counting each observation into the buckets whose upper bound it fits
under, `le` for *less than or equal*. Every bucket includes the ones below it. The storefront's
checkout histogram, healthy:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep 'request_duration_seconds_bucket{.*checkout'
http_server_request_duration_seconds_bucket{le="0.005",method="POST",route="/checkout"} 0.0
http_server_request_duration_seconds_bucket{le="0.01",method="POST",route="/checkout"} 0.0
http_server_request_duration_seconds_bucket{le="0.025",method="POST",route="/checkout"} 16.0
http_server_request_duration_seconds_bucket{le="0.05",method="POST",route="/checkout"} 270.0
http_server_request_duration_seconds_bucket{le="0.1",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="0.25",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="0.5",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="1.0",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="2.5",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="5.0",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="+Inf",method="POST",route="/checkout"} 271.0
```

Read by subtraction, the buckets say: 16 checkouts took between 10 and 25 milliseconds, 254 between
25 and 50, one between 50 and 100, and nothing slower.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The 271 checkouts of the healthy capture, by bucket. Each bar is the number of requests that fell between the previous bound and this one: none up to 0.01 seconds, 16 between 0.01 and 0.025, 254 between 0.025 and 0.05, 1 between 0.05 and 0.1, and none above. Inside a bucket the histogram knows nothing, so the 99th percentile is placed near the top of the 0.025 to 0.05 bucket by assuming the 254 are spread evenly.\"><defs><marker id=\"bk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"110.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.005</text><text x=\"170.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"170.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.01</text><rect x=\"206\" y=\"228.66141732283464\" width=\"48\" height=\"11.338582677165354\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"218.66141732283464\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16</text><text x=\"230.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.025</text><rect x=\"266\" y=\"60.0\" width=\"48\" height=\"180.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">254</text><text x=\"290.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.05</text><rect x=\"326\" y=\"239.29133858267716\" width=\"48\" height=\"0.7086614173228346\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"229.29133858267716\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"350.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.1</text><text x=\"410.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"410.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.25</text><text x=\"470.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"470.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.5</text><text x=\"530.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"530.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"590.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"590.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2.5</text><text x=\"650.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"650.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><path d=\"M80 240 L680 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">upper bound of the bucket, seconds</text><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">271 checkouts, counted per bucket</text></svg>", "caption": "What the storefront's histogram actually holds: a count per bucket, read off the cumulative lines by subtraction. Everything finer than a bucket is an assumption."}
```

`histogram_quantile()` turns those counts into a percentile, as lesson 1 did:

```
ana@obs:~/shop$ ./promq 'histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.03683862433862434
ana@obs:~/shop$ ./promq 'histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.049866402116402114
```

A median of 37 milliseconds and a 99th percentile of 50, both inside the bucket where most checkouts
fell. **Both are interpolated**: the histogram knows that 254 requests landed between 25 and 50
milliseconds, and Prometheus assumes they were spread evenly across that range. Now payments is
slowed by 300 milliseconds, so every checkout takes a little over a third of a second:

```
ana@obs:~/shop$ echo '{"latency_ms": 300}' > faults/payments.json
ana@obs:~/shop$ ./promq 'histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.375
ana@obs:~/shop$ ./promq 'histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.4975
```

**0.375 and 0.4975**: the middle and nearly the top of the bucket between 0.25 and 0.5, because that
bucket now holds every checkout and there is nothing finer to read. The real checkouts all took
about the same time. A median of 375 milliseconds is the bucket's midpoint, not a measurement.
Lesson 1's 2.485 seconds was the same effect in a wider bucket.

Two consequences decide how histograms are used. **Choose buckets around the values you care
about.** If the target is *checkouts under 300 milliseconds*, a bucket boundary at 0.3 makes that
question exact, and no amount of interpolation replaces it. And **ask the question a histogram
answers exactly**, which is not a percentile but a share below a bound:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[1m])) / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[1m]))'
  1
```

*What share of checkouts finished within half a second?* All of them, 1, with no interpolation at
all, because 0.5 is a bucket boundary. Lesson 15 builds the shop's latency objective on that shape.
The fault file was removed after these queries.
