---
title: The retry storm
version: 1
---

Now the failure that matters in production. The checkout calls at 60 a second, three quarters of the
service's capacity, and at the sixth second the service freezes for three seconds, as a long garbage
collection pause or a database failover would make it. First without retries:

```
ana@vm:~/lab/resilience$ $C --freeze-at 6
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8         3     117     120
  8-10        0     120     120
 10-12        1     119     120
 12-14        3     117     120
 14-16        1     119     120
 16-18       93      27     120
 18-20      120       0     120
 20-22      120       0     120
 22-24      120       0     120
 24-26      120       0     120
 26-28      120       0     120
 28-30      120       0     120
the stock service answered 1800 calls, 619 of them after the caller had given up
```

During the freeze almost everything failed, which was unavoidable: nothing was answering. But look at
how long it took to recover. The freeze ended at second 9, and requests kept failing until about second 17.
**Three seconds of freeze cost about ten seconds of failures.** While frozen, the service kept accepting
calls into its queue; when it woke up, it had some 180 requests waiting and a capacity only 20 a second
above the arrival rate, so the queue took about nine seconds to drain. Every request in it waited longer
than the client's half second, so the service spent those seconds answering calls whose callers had
already given up: 619 of its 1,800 answers went to nobody.

Now the same freeze, with three retries:

```
ana@vm:~/lab/resilience$ $C --freeze-at 6 --retries 3
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8         4     116     291
  8-10        9     111     475
 10-12       10     110     469
 12-14        7     113     474
 14-16        8     112     474
 16-18       12     108     466
 18-20       18     102     469
 20-22        9     111     460
 22-24        9     111     471
 24-26       11     109     462
 26-28       11     109     465
 28-30        8     112     458
 30-32        0       0     173
the stock service answered 5947 calls, 5471 of them after the caller had given up
```

**It never recovers.** The freeze ended at second 9 as before, and twenty seconds later the checkout is
still failing nine requests in ten. The last column explains it: the service can answer 160 calls in two
seconds, and it is receiving about 460, because every request that times out comes back up to three more
times. Its queue can only grow, every answer is late, every late answer causes a retry, and the retries
keep the queue full. Of 5,947 answers, 5,471 were for callers who had stopped waiting.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A loop of four steps. The service is slow or overloaded. Its callers time out. The callers retry, adding calls. The extra calls make the service more overloaded, which brings the loop back to the start. A note says the loop keeps going after the original cause has gone.\"><defs><marker id=\"l11-loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"250\" y=\"30\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">service overloaded</text><rect x=\"470\" y=\"110\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callers time out</text><rect x=\"250\" y=\"190\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callers retry</text><rect x=\"30\" y=\"110\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">more calls arrive</text><path d=\"M472 50 L580 50 L580 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><path d=\"M580 152 L580 210 L472 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><path d=\"M248 210 L140 210 L140 152\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><path d=\"M140 108 L140 50 L248 50\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">keeps going after the cause has gone</text></svg>", "caption": "The retry storm feeds itself: the retries keep the service overloaded, and the overload keeps causing retries, long after whatever started it has passed."}
```

This is a **retry storm**, and the dangerous thing about it is in the timing: **the original cause was
gone after three seconds**, and the system stayed down because of how it reacts to failure. It ends only
when the load stops, which in production means when somebody notices and turns things off. The name
for a failure that sustains itself after its trigger has gone is a **metastable failure**, and retries
are its most common engine.

Two things made it worse that are worth naming. **The service did work for callers who had left**: it
had no way to know the caller's deadline had passed, so it answered thousands of requests nobody was
waiting for. And **the retries arrived together**: every caller that failed at the same moment retried at
the same moment. The rest of the lesson takes both on.
