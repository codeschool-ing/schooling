---
title: The circuit breaker
version: 1
---

A timeout limits how long one call can waste. When payments is down for minutes, every sale still
spends its full second finding that out, holds a slot while it does, and adds one more request to a
service that is already failing. **A circuit breaker stops calling.** After enough failures in a row
it opens, and for a while every call fails at once, without being made.

The name is borrowed from the electrical one, and so are the states: **closed** means current flows
and calls go through; **open** means it does not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Three states of a circuit breaker. Closed, where calls go through: five failures in a row move it to open. Open, where every call fails at once: after the cooldown of ten seconds it moves to half-open. Half-open, where one test call goes through: if it succeeds the breaker returns to closed, if it fails it returns to open.\"><rect x=\"40\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">closed</text><text x=\"130\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calls go through</text><rect x=\"500\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">open</text><text x=\"590\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calls fail at once</text><rect x=\"270\" y=\"130\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">half-open</text><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one test call</text><path d=\"M220 55 L498 55\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M498 55 L491.7 58.0 L491.7 52.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5 failures in a row</text><path d=\"M525 90 L454 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M454 136 L457.6 130.0 L460.9 135.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"470\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after 10 s</text><path d=\"M452 168 L636 93\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M636 93 L631.3 98.2 L629.0 92.6 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"560\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">test fails</text><path d=\"M268 145 L160 93\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M160 93 L167.0 93.0 L164.4 98.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"200\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">test works</text></svg>", "caption": "Closed, open, half-open: the breaker tests its way back."}
```

The box office's breaker opens after five failures in a row and stays open for ten seconds. Payments
is still taking five seconds a charge; eight more sales, each from a different buyer so the rate
limit stays out of the way:

```
ana@lab:~/tickets$ for i in $(seq 2 9); do curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H "X-Buyer: fan-$i" localhost:8080/events/1/tickets; done
{"error": "payment failed"} 502 in 1.006585 s
{"error": "payment failed"} 502 in 1.005113 s
{"error": "payment failed"} 502 in 1.005369 s
{"error": "payment failed"} 502 in 1.005703 s
{"error": "payments unavailable"} 503 in 0.001858 s
{"error": "payments unavailable"} 503 in 0.001599 s
{"error": "payments unavailable"} 503 in 0.001738 s
{"error": "payments unavailable"} 503 in 0.001636 s
ana@lab:~/tickets$ curl -s localhost:8080/metrics | grep ^tickets_breaker
tickets_breaker_open 1.0
```

**Four sales failed after a full second each**: with the sale of section 07, those are five failures
in a row, and the breaker opened. **The next four failed in under 2 ms**, with a `503` that says
payments is unavailable, and without touching payments at all. The gauge says the breaker is open,
which is what a dashboard or an alert would read.

What that bought, for the box office: a sale that cannot succeed no longer holds a slot for a
second, so reads and everything else keep their capacity. For payments: no new calls while it is
struggling, which is often the difference between a service that recovers and one that is kept down
by the traffic of callers retrying it. And for the buyer: an answer in milliseconds instead of a
spinner, which section 10 and lesson 11 turn into something more useful than an error.

## What counts as a failure

Only what says the dependency is unhealthy: a timeout, a refused connection, a `5xx`. A card that is
declined is the payment service working correctly, and a breaker that counted it would open during
a busy evening of expired cards. The box office's breaker counts any exception from `charge`, which
here means a network error or a timeout; a real one would look at the status code as well.
