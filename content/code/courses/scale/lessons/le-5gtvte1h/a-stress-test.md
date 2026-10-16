---
title: A stress test
version: 1
---

A stress test raises the load until something gives, to find two things: **where the limit is**,
and **what breaks first**. The second is usually the more useful, because it is usually not what
anybody expected.

One copy of the box office, and four runs of fifteen seconds at 100, 200, 300 and 400 sales a
second:

```
ana@lab:~/tickets$ for rate in 100 200 300 400; do docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none -e RATE=$rate -e DURATION=15s - < sale.js; echo; done
asked     100 a second for 15s
answered  1501 = 99.8 a second
latency   p50 38.2 ms  p95 48.1 ms  p99 56.2 ms  max 67.4 ms
sold 1501  refused 0  failed 0  never sent 0

asked     200 a second for 15s
answered  2973 = 189.3 a second
latency   p50 272.1 ms  p95 959.4 ms  p99 1281.4 ms  max 2549.9 ms
sold 2820  refused 153  failed 0  never sent 28

asked     300 a second for 15s
answered  4334 = 259.7 a second
latency   p50 577.8 ms  p95 2789.1 ms  p99 4275.1 ms  max 7922.7 ms
sold 2593  refused 194  failed 1547  never sent 166

asked     400 a second for 15s
answered  5828 = 354.6 a second
latency   p50 2.4 ms  p95 2571.0 ms  p99 3616.7 ms  max 6882.1 ms
sold 2695  refused 156  failed 2977  never sent 172

ana@lab:~/tickets$ docker compose logs lb --no-log-prefix | grep -m1 alert
2026/10/16 00:40:17 [alert] 20#20: 512 worker_connections are not enough
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Sales a second asked for against sales a second answered, at 100, 200, 300 and 400 asked. Answered follows asked at 100 and 200, then bends away: 189 at 200 asked, 260 at 300 and 355 at 400. Beside each point, the share that failed: none at 100 and 200, 36 percent at 300, 51 percent at 400.\"><path d=\"M90 220 L650 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90 220 L90 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 220.0 L650.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"552.0\" y=\"52.599999999999994\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">answered = asked</text><path d=\"M 230.0 175.1 L 370.0 134.8 L 510.0 103.1 L 650.0 60.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"230.0\" cy=\"175.09\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"238.0\" y=\"189.09\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0% failed</text><circle cx=\"370.0\" cy=\"134.815\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"378.0\" y=\"148.815\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0% failed</text><circle cx=\"510.0\" cy=\"103.135\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"518.0\" y=\"117.135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">36% failed</text><circle cx=\"650.0\" cy=\"60.42999999999998\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"658.0\" y=\"74.42999999999998\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">51% failed</text><text x=\"90.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"82\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"230.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"82\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"370.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"82\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"510.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"82\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"650.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><text x=\"82\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><text x=\"650\" y=\"252\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">asked, a second</text><text x=\"96\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">answered, a second</text></svg>", "caption": "Past the knee, answered stops following asked, and much of what is answered is a failure."}
```

Read it run by run.

- **100 a second**: every sale answered at the rate asked, median 38 ms. Comfortable.
- **200 a second**: k6 managed 189 a second. The median rose to 272 ms and the 95th percentile to
  959 ms, and lesson 9's load shedding refused 153 sales with `503`. **This is the knee**: somewhere
  under 200 a second, this copy on this machine stops keeping up. Your machine will put it somewhere
  else; the shape will be the same.
- **300 a second**: now 1,547 sales **failed**, neither sold nor refused. That is new, and nothing
  in the box office's logs would explain it, because the box office never saw them.
- **400 a second**: 2,977 failed, and the **median fell to 2.4 ms**. Not because anything got
  faster: the failures were instant, and they are counted in the latency like everything else. A
  median that improves as the error count climbs is a reason to read the error count first.

The last command finds the failures in nginx's log: **`512 worker_connections are not enough`**.
nginx's default allows each worker process 512 connections, counting both sides: the buyer's
connection in and the connection out to the box office. With hundreds of sales waiting in the box
office at once, nginx ran out, and closed new connections without an answer.

**The first thing to break was not the box office.** It was a default in the load balancer that
nobody had touched since lesson 1, because nothing before this lesson had sent more than a few
hundred connections at once.
