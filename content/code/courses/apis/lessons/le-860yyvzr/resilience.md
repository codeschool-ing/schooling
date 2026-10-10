---
title: Resilience across the boundary
version: 1
---

**A call across a network has three outcomes, not two: it worked, it failed, or you do not know.**
A fault is the second. A timeout is the third, and code that treats it as the second makes the
mistake this section is about.

Two sections ago the bridge gave up on an order after two seconds and answered 504. Its own
terminal, the third, logged that answer:

```
127.0.0.1 - - [10/Oct/2026 01:41:06] "POST /orders HTTP/1.1" 504 -
```

The distributor had not finished; it was asleep. The last lines in the second terminal, where it
has been printing, came a few seconds after that:

```
order PO100003: 10 x 9786500000016 for R-2002
127.0.0.1 - - [10/Oct/2026 01:41:09] "POST /distributor HTTP/1.1" 200 -
the caller left before the answer
```

**The order was placed, after the shelf had already told its caller that it failed.** The
distributor even noticed that nobody was waiting for its answer, and said so; the shelf heard
nothing about the order at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 370\" role=\"img\" aria-label=\"A sequence in time with three lifelines: curl, bridge.py and distributor.py. At 0 seconds curl posts an order with reference R-2002 and the bridge sends PlaceOrder to the distributor, which is sleeping. At 2 seconds the bridge stops waiting and answers 504 to curl. At 5 seconds the distributor wakes, places order PO100003 and answers a caller that has gone. Later, curl sends the same order again with the same reference; the distributor finds R-2002, places nothing, and answers PO100003 with Repeated true, which the bridge passes on as 200.\"><defs><marker id=\"l05-time-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"75\" y=\"14\" width=\"130\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><line x1=\"140\" y1=\"42\" x2=\"140\" y2=\"358\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"305\" y=\"14\" width=\"130\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bridge.py</text><line x1=\"370\" y1=\"42\" x2=\"370\" y2=\"358\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"535\" y=\"14\" width=\"130\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distributor.py</text><line x1=\"600\" y1=\"42\" x2=\"600\" y2=\"358\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"30\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 s</text><text x=\"30\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 s</text><line x1=\"140\" y1=\"62\" x2=\"368\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"254.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">POST /orders R-2002</text><line x1=\"370\" y1=\"70\" x2=\"598\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"484.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PlaceOrder</text><rect x=\"594\" y=\"74\" width=\"12\" height=\"158\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"614\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asleep: slow</text><line x1=\"370\" y1=\"130\" x2=\"142\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"256.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">504, after 2 s</text><text x=\"378\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gives up waiting</text><text x=\"588\" y=\"234\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">places PO100003</text><line x1=\"600\" y1=\"246\" x2=\"440\" y2=\"246\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"520.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nobody is listening</text><text x=\"30\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">later</text><line x1=\"140\" y1=\"292\" x2=\"368\" y2=\"292\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"254.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">same order, R-2002</text><line x1=\"370\" y1=\"300\" x2=\"598\" y2=\"300\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"484.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PlaceOrder</text><line x1=\"600\" y1=\"318\" x2=\"372\" y2=\"318\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"486.0\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PO100003, Repeated</text><line x1=\"370\" y1=\"332\" x2=\"142\" y2=\"332\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"256.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200 PO100003</text></svg>", "caption": "A timeout tells the caller nothing about what happened on the far side. The order the bridge gave up on was placed three seconds later, and only the reference makes sending it again safe."}
```

## Retry only what is idempotent

The obvious reaction to a 504 is to try again, and lesson 1 already said when that is safe: when the
call is **idempotent**, so that two copies leave the far side as one would. `GetStock` only reads,
so retrying it is always safe. `PlaceOrder` creates something, and a blind retry after this 504
would have ordered twenty books instead of ten.

What makes this order safe to retry is **the reference**. The distributor remembers every
`CustomerRef` it has placed, and a reference it has seen gets the same order back instead of a new
one. Remove the `slow` file and send exactly the same request again:

```
ana@api:~/shelf$ rm slow
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "quantity": 10, "reference": "R-2002"}'
{"order": "PO100003", "isbn": "9786500000016", "quantity": 10, "reference": "R-2002"}
200
ana@api:~/shelf$ curl -s localhost:8000/stock/9786500000016
{"isbn": "9786500000016", "available": 30, "price_cents": 2150, "next_delivery": "2026-10-12"}
```

**200, not 201, and the same order number.** The bridge passed on the distributor's `Repeated`, and
the stock confirms it: the distributor had 40 copies of *Dom Casmurro* and has 30, so ten were
ordered, once.

That deduplication has to happen **on the far side**, because only the far side knows whether the
first request arrived. The shelf cannot find out by remembering what it sent: what it sent is
exactly the thing it is unsure about. When a partner's contract has no field like `CustomerRef`,
the safe procedure after a timeout is to ask before resending, by querying the partner's orders if
it allows that, and to hand the case to a person if it does not. Lesson 2 shows the HTTP header
that does the same job for a REST API.

## The other rules

**Every call across the boundary gets a timeout.** The bridge waits two seconds for the
distributor; whoever calls the bridge has to wait longer than that, or it gives up first and the
bridge's answer goes nowhere. Each layer's timeout is shorter than the one above it.

**Retries get a limit and a pause between them.** Three attempts, waiting longer before each, is a
common choice. Retrying at once and without limit turns a distributor that is struggling into one
that is down, with your traffic doing it.

**A dependency that is down should fail fast.** Stop the distributor with `Ctrl+C` in the second
terminal and ask the bridge for stock:

```
ana@api:~/shelf$ curl -s -w '%{http_code} after %{time_total} s\n' localhost:8000/stock/9786500000016
{"error": "the distributor cannot be reached"}
502 after 0.003271 s
```

A refused connection fails at once, as the time curl printed says, so a dead distributor is cheap
to the shelf. A slow
one is what costs: every request waits the whole two seconds, holding a thread, before it fails.

That is the problem a **circuit breaker** solves, and it is worth knowing by name even though the
bridge does not have one. It counts recent failures of one dependency. Past a threshold it
**opens**, and for a while every call fails immediately without trying, which spares the shelf's
threads and gives the distributor a rest. Then it lets one call through to test the water, the
**half-open** state, and closes again if that one succeeds. Libraries implement it in every
language; what you decide is the threshold, how long to stay open, and what the shelf answers in
the meantime, usually the same 502 or 504 it answers now.
