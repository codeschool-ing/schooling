---
title: Why nothing should run at 100%
version: 1
---

Little's law says how many requests are inside; it does not say how long they wait, and that
depends on how busy the server is. A server that is 50% busy is idle half the time, so an arriving
request usually finds it free. At 95% it is almost never free, and every request waits behind the
ones before it.

This program simulates one server that takes 10 ms a request on average, with requests arriving at
random, at a rising share of what it can do. Save it as `queueing.py`:

```python
# queueing.py
"""One server that takes 10 ms a request on average, and requests arriving at
random, at a rising share of what it can do. How long does a request spend,
waiting plus being served?"""
import random

SERVICE = 0.010          # seconds of work per request, on average
REQUESTS = 200_000
random.seed(1)

print("busy   mean ms   p99 ms   formula ms")
for busy in (0.5, 0.7, 0.8, 0.9, 0.95):
    arrival_rate = busy / SERVICE              # requests per second
    clock = free_at = 0.0
    times = []
    for _ in range(REQUESTS):
        clock += random.expovariate(arrival_rate)        # the next arrival
        start = max(clock, free_at)                      # waits if the server is busy
        free_at = start + random.expovariate(1 / SERVICE)
        times.append(free_at - clock)
    times.sort()
    mean = sum(times) / len(times)
    print(f"{busy:4.0%}  {mean * 1000:8.1f}  {times[int(0.99 * len(times))] * 1000:7.1f}"
          f"  {SERVICE / (1 - busy) * 1000:11.1f}")
```

```
ana@lab:~/tickets$ python3 queueing.py
busy   mean ms   p99 ms   formula ms
 50%      20.0     91.8         20.0
 70%      33.6    154.2         33.3
 80%      50.8    235.6         50.0
 90%      96.3    437.0        100.0
 95%     176.1    966.2        200.0
```

At 50% busy, a 10 ms request takes 20 ms on average. At 80%, 51 ms; at 90%, 96 ms; at 95%, 176 ms
on average and nearly a second at the 99th percentile. The right-hand column is the textbook formula
for this kind of queue, the M/M/1: **time = service time ÷ (1 − utilisation)**. The simulation
follows it closely and falls a little short at 95%, where the queue is so long that even 200,000
requests are not enough to see its worst moments.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A curve of average time against how busy the server is, for a request that takes 10 ms of work. It stays low and nearly flat up to about 70 percent, at 33 ms, then rises steeply: 50 ms at 80 percent, 100 ms at 90 percent and 200 ms at 95 percent. A band from 60 to 70 percent is marked as the planning target.\"><path d=\"M440.0 220 L440.0 30.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M500.0 220 L500.0 30.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"470.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">plan here</text><path d=\"M80 220 L680 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 220 L80 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M 80.0 210.5 L 86.0 210.4 L 92.0 210.3 L 98.0 210.2 L 104.0 210.1 L 110.0 210.0 L 116.0 209.9 L 122.0 209.8 L 128.0 209.7 L 134.0 209.6 L 140.0 209.4 L 146.0 209.3 L 152.0 209.2 L 158.0 209.1 L 164.0 209.0 L 170.0 208.8 L 176.0 208.7 L 182.0 208.6 L 188.0 208.4 L 194.0 208.3 L 200.0 208.1 L 206.0 208.0 L 212.0 207.8 L 218.0 207.7 L 224.0 207.5 L 230.0 207.3 L 236.0 207.2 L 242.0 207.0 L 248.0 206.8 L 254.0 206.6 L 260.0 206.4 L 266.0 206.2 L 272.0 206.0 L 278.0 205.8 L 284.0 205.6 L 290.0 205.4 L 296.0 205.2 L 302.0 204.9 L 308.0 204.7 L 314.0 204.4 L 320.0 204.2 L 326.0 203.9 L 332.0 203.6 L 338.0 203.3 L 344.0 203.0 L 350.0 202.7 L 356.0 202.4 L 362.0 202.1 L 368.0 201.7 L 374.0 201.4 L 380.0 201.0 L 386.0 200.6 L 392.0 200.2 L 398.0 199.8 L 404.0 199.3 L 410.0 198.9 L 416.0 198.4 L 422.0 197.9 L 428.0 197.4 L 434.0 196.8 L 440.0 196.2 L 446.0 195.6 L 452.0 195.0 L 458.0 194.3 L 464.0 193.6 L 470.0 192.9 L 476.0 192.1 L 482.0 191.2 L 488.0 190.3 L 494.0 189.4 L 500.0 188.3 L 506.0 187.2 L 512.0 186.1 L 518.0 184.8 L 524.0 183.5 L 530.0 182.0 L 536.0 180.4 L 542.0 178.7 L 548.0 176.8 L 554.0 174.8 L 560.0 172.5 L 566.0 170.0 L 572.0 167.2 L 578.0 164.1 L 584.0 160.6 L 590.0 156.7 L 596.0 152.1 L 602.0 146.9 L 608.0 140.8 L 614.0 133.6 L 620.0 125.0 L 626.0 114.4 L 632.0 101.2 L 638.0 84.3 L 644.0 61.7 L 650.0 30.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"500.0\" cy=\"188.33333333333334\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"492.0\" y=\"188.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">33 ms</text><circle cx=\"560.0\" cy=\"172.5\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"552.0\" y=\"172.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">50 ms</text><circle cx=\"620.0\" cy=\"124.99999999999999\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"612.0\" y=\"124.99999999999999\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">100 ms</text><circle cx=\"650.0\" cy=\"30.00000000000017\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"642.0\" y=\"30.00000000000017\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">200 ms</text><text x=\"80\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><text x=\"230.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25%</text><text x=\"380.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><text x=\"530.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">75%</text><text x=\"680.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"70\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"70\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200 ms</text><text x=\"680\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">utilisation</text></svg>", "caption": "Time grows with 1 ÷ (1 − utilisation): flat, then vertical."}
```

The curve is the reason for every *headroom* rule in capacity planning. **Latency does not grow in
proportion to load; it grows with 1 ÷ (1 − utilisation)**, which is flat for a long time and then
vertical. Going from 50% to 70% costs 13 ms; going from 90% to 95% costs 80. A system planned to run
at 90% at the peak has no room for the peak being a little higher than planned, and peaks always
are.

Real servers are not exactly M/M/1. Requests do not arrive completely at random, service times are
not exponential, and a box office has several threads on one CPU. The shape survives all of that,
and the usual targets follow from it: **plan for 60 to 70% at the expected peak**, and treat
anything above 80% as the alarm.
