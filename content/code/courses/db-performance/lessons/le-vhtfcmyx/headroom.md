---
title: Headroom, and the knee in the curve
version: 1
---

A disk fills at a rate you can read off a table. The other limit of a server does not behave like
that at all, and it is the one that hurts first. **A busy server does not run out of speed; it runs
out of waiting room.**

The usual belief is that a server at 80% of its capacity is 20% from trouble, and that each request
takes the same time at 80% as it does at 10%. Neither is true, and you can measure why on your own
machine.

## The most the server can do

Run the workload with no limit, and `pgbench` sends the next transaction the moment the last one
returns. What it reports is the most this server can do with eight clients:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 7.276 ms
tps = 1099.568477 (without initial connection time)
```

**1099 transactions a second.** That is the wall for throughput, on this machine, with this
workload. It is not a number to run at.

## The same workload, offered at a fixed rate

`-R` changes how `pgbench` sends: instead of as fast as possible, it schedules transactions at a
fixed rate, the way real users arrive whether or not the server is ready for them. When the server
falls behind, a transaction waits for its turn, and that wait — the **schedule lag** — is counted
in its latency, as a user would count it. Here is the workload at 300, 600, 900 and 1050 a second:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 300 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 3.969 ms
latency stddev = 10.333 ms
rate limit schedule lag: avg 0.535 (max 103.418) ms
tps = 298.196636 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 600 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 11.184 ms
latency stddev = 27.263 ms
rate limit schedule lag: avg 6.653 (max 289.220) ms
tps = 595.973414 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 900 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 29.304 ms
latency stddev = 50.155 ms
rate limit schedule lag: avg 23.920 (max 355.874) ms
tps = 889.709604 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 1050 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 132.969 ms
latency stddev = 179.683 ms
rate limit schedule lag: avg 127.031 (max 900.691) ms
tps = 1042.545758 (without initial connection time)
```

Read the latency down the four runs: **4, 11, 29 and 133 milliseconds**. From 300 to 600 a second
the server does twice the work and each request takes about three times as long. From 900 to 1050 —
a sixth more work — each request takes four and a half times as long. And at 1050, 95% of the
maximum, the server still delivered the rate: `tps = 1042`. It did not fail. It kept up by making
everybody wait.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A line chart of average latency against the rate of transactions offered to the server. At 300 a second the latency is 4 milliseconds, at 600 it is 11, at 900 it is 29, and at 1050 it is 133. The server&#x27;s maximum, measured without a rate limit, is 1099 a second, marked by a dashed vertical line. The curve is nearly flat until about 600 and then bends upwards sharply.\"><rect x=\"14\" y=\"20\" width=\"692\" height=\"268\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M80 250 L660 250\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M80 250 L80 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"225.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">300</text><text x=\"370.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">600</text><text x=\"515.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">900</text><text x=\"660.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1200</text><text x=\"72\" y=\"250.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"197.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">35</text><text x=\"72\" y=\"145.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">70</text><text x=\"72\" y=\"92.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">105</text><text x=\"72\" y=\"40.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">140</text><text x=\"370.0\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">transactions a second offered</text><text x=\"74\" y=\"30\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">ms</text><path d=\"M225.0 244.0 L370.0 233.2 L515.0 206.0 L587.5 50.5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"225.0\" cy=\"244.0465\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"370.0\" cy=\"233.224\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"515.0\" cy=\"206.044\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"587.5\" cy=\"50.54650000000001\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"225.0\" y=\"230.0465\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">4 ms</text><text x=\"370.0\" y=\"219.224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">11 ms</text><text x=\"505\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper)\">29 ms</text><text x=\"577.5\" y=\"50.54650000000001\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper)\">133 ms</text><path d=\"M611.6666666666666 250 L611.6666666666666 40\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"617.6666666666666\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">maximum</text><text x=\"617.6666666666666\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1099</text></svg>", "caption": "Average latency against the rate offered, on the recording computer. The last tenth of the capacity costs more than the first nine."}
```

That shape has a name in queueing theory, and you do not need the theory to use it. When requests
arrive at random moments, some arrive together; the ones that come while the server is busy wait;
and the closer the server is to fully busy, the more often an arrival finds it busy and the longer
the queue it finds. The waiting grows slowly at first and then without limit as the rate approaches
the maximum. **The knee in the curve is where headroom ends**, and on this machine and workload it
is somewhere between 600 and 900 a second — between half and four fifths of the maximum.

## The average hides the people who waited

The average is the kindest summary of a latency, and the least useful one near the knee. To see
what the slowest users saw, `pgbench` can log every transaction's latency with `-l`, and this
script reads the log and prints three percentiles — the latency that half, ninety-five and
ninety-nine out of every hundred transactions came in under:

```sh
cat > ~/workload/percentiles.sh <<'SH'
#!/bin/sh
# percentiles.sh PREFIX: the 50th, 95th and 99th percentile latency of a
# pgbench run that was logged with  -l --log-prefix=PREFIX
cat "$1".* | awk '{ print $3 }' | sort -n | awk -v run="$1" '
  { t[NR] = $1 }
  END { printf "%s  p50 %.1f ms  p95 %.1f ms  p99 %.1f ms\n", run,
        t[int(NR * .50)] / 1000, t[int(NR * .95)] / 1000, t[int(NR * .99)] / 1000 }'
SH
chmod +x ~/workload/percentiles.sh
```

Two runs, one at 600 a second and one at 1000, each logged, then the script on each:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 600 -l --log-prefix=r600 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market > /dev/null
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 1000 -l --log-prefix=r1000 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market > /dev/null
ana@vm:~/workload$ ./percentiles.sh r600
r600  p50 0.7 ms  p95 30.9 ms  p99 93.5 ms
ana@vm:~/workload$ ./percentiles.sh r1000
r1000  p50 62.3 ms  p95 470.9 ms  p99 621.0 ms
```

At 600 a second, **half the transactions took 0.7 milliseconds** and one in a hundred took more
than 93. At 1000 a second the middle transaction took 62 and one in a hundred took more than **621
milliseconds** — two thirds of a second, for a workload whose typical query runs in under one. The
percentiles moved far more than the average did, because the queue does not delay everybody equally:
it delays whoever arrives behind a slow query.

So the headroom that matters is not "how far from the maximum", it is **how far from the knee**.
On this machine, running the workload at 1000 a second leaves a tenth of the maximum unused and
already makes the slowest users wait more than half a second. A capacity plan that says "we are at
80%, we have room" is reading the wrong axis.
