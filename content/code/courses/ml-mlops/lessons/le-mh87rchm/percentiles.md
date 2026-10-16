---
title: The slow requests, which the average hides
version: 1
---

**A percentile is the time under which that share of requests finished**: p95 is 120 milliseconds
when 95 of every hundred requests took less. It is the number to watch because it describes people:
on a page that makes ten requests, a one-in-a-hundred delay is felt by roughly one visit in ten, and
the mean says nothing about them at all.

The same 600 requests sent one at a time, four at a time and sixteen at a time show what load does to
those numbers:

```
ana@dev:~/ml$ for n in 1 4 16; do python load.py 600 $n; python latency.py 600; done
600 requests in 3.7 s, 163 a second; status {200: 407, 404: 193}
600 requests, 0 errors; status {200: 407, 404: 193}
mean    5.0 ms
p50     6.5 ms
p95     7.8 ms
p99    10.8 ms
max    29.0 ms
600 requests in 5.6 s, 107 a second; status {200: 407, 404: 193}
600 requests, 0 errors; status {200: 407, 404: 193}
mean   30.9 ms
p50    36.2 ms
p95    56.3 ms
p99    64.4 ms
max    72.1 ms
600 requests in 6.9 s, 88 a second; status {200: 407, 404: 193}
600 requests, 0 errors; status {200: 407, 404: 193}
mean  134.4 ms
p50   142.4 ms
p95   237.5 ms
p99   351.8 ms
max   406.6 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-latency\" aria-label=\"Grouped bars of latency for 600 requests at one, four and sixteen at once. One at a time: p50 6.5, p95 7.8 and p99 10.8 milliseconds, 163 requests a second. Four: 36.2, 56.3 and 64.4, 107 a second. Sixteen: 142.4, 237.5 and 351.8, 88 a second.\"><path d=\"M80.0 40.0 L80.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 240.0 L80.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 190.0 L700.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 190.0 L80.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 140.0 L700.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 140.0 L80.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M80.0 90.0 L700.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 90.0 L80.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M80.0 40.0 L700.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">milliseconds</text><rect x=\"121.3\" y=\"236.8\" width=\"37.2\" height=\"3.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"139.9\" y=\"227.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6.5</text><rect x=\"162.7\" y=\"236.1\" width=\"37.2\" height=\"3.9\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"181.3\" y=\"227.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7.8</text><rect x=\"204.0\" y=\"234.6\" width=\"37.2\" height=\"5.4\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"222.6\" y=\"225.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.8</text><text x=\"183.3\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 at once</text><text x=\"183.3\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">163 a second</text><rect x=\"328.0\" y=\"221.9\" width=\"37.2\" height=\"18.1\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"346.6\" y=\"212.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">36.2</text><rect x=\"369.3\" y=\"211.8\" width=\"37.2\" height=\"28.2\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"387.9\" y=\"202.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">56.3</text><rect x=\"410.7\" y=\"207.8\" width=\"37.2\" height=\"32.2\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"429.3\" y=\"198.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">64.4</text><text x=\"390.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 at once</text><text x=\"390.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">107 a second</text><rect x=\"534.7\" y=\"168.8\" width=\"37.2\" height=\"71.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"553.3\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">142.4</text><rect x=\"576.0\" y=\"121.2\" width=\"37.2\" height=\"118.8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"594.6\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">237.5</text><rect x=\"617.3\" y=\"64.1\" width=\"37.2\" height=\"175.9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.9\" y=\"55.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">351.8</text><text x=\"596.7\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">16 at once</text><text x=\"596.7\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">88 a second</text><rect x=\"110.0\" y=\"52.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"128.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p50</text><rect x=\"180.0\" y=\"52.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p95</text><rect x=\"250.0\" y=\"52.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"268.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p99</text><path d=\"M80.0 240.0 L700.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "More requests in flight did not raise the throughput; it fell, and the time each request spent waiting is what the percentiles grew by."}
```

**One at a time, the service answers in 6.5 milliseconds at the median and 10.8 at p99.** At four, the
median is 36.2; at sixteen, 142.4, with p99 at 351.8. And the throughput, which a naive reading
expects to rise with more requests in flight, fell: 163 a second, then 107, then 88.

**The extra requests did not make the service work faster; they made each one wait longer.** One
Uvicorn process runs Python, and Python runs one thread of Python code at a time, so the model's
predictions are taken in turn however many arrive together, and the switching between threads costs
something too. Past the point where the process is busy all the time, more traffic is only queueing,
and the time a request spends queued is what p99 measures.

**The remedy is more processes, and it is paid for in memory.** `uvicorn serve:app --workers 4`
starts four copies of the service, each with its own model, so four predictions run at once on four
cores, and the memory the service holds is multiplied by four. Section 09 measures what one copy
holds. And the latency a service promises is always stated with the load it was measured under:
"p99 under 15 ms" means one thing at one request at a time and another entirely at sixteen.
