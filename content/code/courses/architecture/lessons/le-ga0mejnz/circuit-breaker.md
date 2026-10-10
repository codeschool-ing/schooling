---
title: The circuit breaker
version: 1
---

A retry assumes the next call might work. When the last several calls to a service have all failed,
that assumption is probably wrong, and every further call is load on a service that is already
drowning. A **circuit breaker** acts on that: after enough failures in a row it **opens**, and for a while
every call fails immediately, without being sent. Then it lets a single call through, **half-open**, to
see whether the service is back; if it is, the breaker **closes** and traffic flows again. Michael Nygard
named the pattern in *Release It!* in 2007, after the electrical device that cuts a circuit before the
wiring catches fire.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The three states of a circuit breaker. Closed: calls go through, failures are counted. After five failures in a row it moves to open: calls fail at once without reaching the service. After two seconds it moves to half-open: one call is let through. If that call succeeds the breaker goes back to closed; if it fails, back to open.\"><defs><marker id=\"l11-breaker-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-breaker-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-breaker-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">closed</text><text x=\"120\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls go through</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">open</text><text x=\"600\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls fail at once</text><rect x=\"270\" y=\"160\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">half-open</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one call is let through</text><path d=\"M212 60 L508 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-amber)\"></path><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">5 failures in a row</text><path d=\"M600 112 L600 195 L452 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-paper-dim)\"></path><text x=\"612\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after 2 s</text><path d=\"M268 195 L120 195 L120 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-phosphor)\"></path><text x=\"195\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">it succeeds</text><path d=\"M400 158 L540 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-amber)\"></path><text x=\"505\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">it fails</text></svg>", "caption": "A circuit breaker stops calling a service that is clearly failing, and checks now and then, with a single call, whether it is back."}
```

The client's breaker opens after five failures in a row and stays open for two seconds. The same freeze,
with the same three retries and jitter, and the breaker on:

```
ana@vm:~/lab/resilience$ $C --freeze-at 6 --retries 3 --backoff jitter --breaker
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8         3     117      40
  8-10       49      71      49
 10-12      120       0     120
 12-14      120       0     120
 14-16      120       0     120
 16-18      120       0     120
 18-20      120       0     120
 20-22      120       0     120
 22-24      120       0     120
 24-26      120       0     120
 26-28      120       0     120
 28-30      120       0     120
the stock service answered 1649 calls, 37 of them after the caller had given up
```

**Recovered by second 10**, one second after the freeze ended, and six seconds sooner than with no
retries at all. Look at the calls column during the freeze: 40 and 49 calls in two-second windows where
plain retries sent 470. While the breaker was open, the client's requests failed at once and the service
received almost nothing, so its queue drained instead of growing, and the half-open probe found it
healthy. Of 1,649 answers, 37 were late.

That is the breaker's real job, and it is easy to describe it as something else. It does not make a
failing service succeed; the requests during the freeze failed with it as they failed without it. **It
protects the service from its own callers**, so that it can recover, and it protects the callers from
waiting on something that is not going to answer: a request rejected by an open breaker fails in
microseconds instead of half a second.

## Choosing its settings

| setting | the lab | what to weigh |
| --- | --- | --- |
| when to open | 5 failures in a row | too few and one bad second opens it; libraries also offer a failure rate over a window |
| how long to stay open | 2 seconds | long enough for the service to recover, short enough not to fail requests it could serve |
| what counts as failure | a timeout or a `5xx` | a `404` is an answer, not a failure of the service |
| what to do while open | fail at once | fail at once, or answer from a fallback: a cached stock count, "availability unknown" |

**One breaker per dependency**, never one for everything: the stock service being down should not stop
the checkout from calling payments.
