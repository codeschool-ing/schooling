---
title: The network is not free
version: 1
---

Inside the monolith, asking for a stock count was a function call. Now it is a request over a
network, and the two look alike in the code: `stock_call(...)` reads like any other function. **The
cost is not alike, and neither is the way it fails.**

`bench.py` asks the same question a thousand times each way, from inside the shop's container:

```
ana@vm:~/lab/split$ docker compose exec shop python bench.py
function call        0.10 µs per call
HTTP call         1809.60 µs per call
```

On this machine the function call took a fraction of a microsecond and the HTTP call took
1809.60 microseconds, nearly two milliseconds, which is more than ten thousand times as long.
Your numbers will differ, and the HTTP call will still be thousands of times slower. Most of
the two milliseconds is not the network itself, since both containers are on one machine; it is
everything around it: resolving the name `stock`, opening a TCP connection, writing and parsing
HTTP, and a Python server answering. A real service reuses connections and answers faster, and a
real network between two machines adds its own delay on top.

**Two milliseconds is nothing once and a great deal a hundred times.** A page that shows forty
products and asks the stock service once per product spends eighty milliseconds on that alone,
before anything else happens, which is why the shop asks for every count in one call. Lesson 16
gives this its antipattern name, chatty I/O.

## Everything that can happen to one call

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A function call inside one process is one arrow, taking about a tenth of a microsecond. The same question asked over the network is drawn as five steps: resolve the name, open a connection, send the request, the other service works, the answer comes back. Each step is marked as a place the call can fail or wait.\"><defs><marker id=\"l2-call-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">inside one process: units[sku]</text><rect x=\"40\" y=\"44\" width=\"640\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one step, about 0.1 µs</text><text x=\"26\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">across the network: GET http://stock:8001/stock/coffee</text><rect x=\"30\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"91\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resolve the name</text><rect x=\"30\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"91\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no such host</text><path d=\"M153 139 L164 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"166\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"227\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">open a connection</text><rect x=\"166\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"227\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">refused, slow</text><path d=\"M289 139 L300 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"302\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">send the request</text><rect x=\"302\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"363\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lost, cut</text><path d=\"M425 139 L436 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"438\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"499\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the service works</text><rect x=\"438\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"499\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slow, crashes</text><path d=\"M561 139 L572 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"574\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the answer returns</text><rect x=\"574\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"635\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lost, late</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a place to fail or wait, under every step</text></svg>", "caption": "The same question, asked two ways. Inside the process there is one step and it cannot fail on its own; across the network there are five, and each has its own way to fail or to wait."}
```

A function call can be wrong, but it cannot be *lost*. A network call can fail at any of those
steps, and from the caller's side several of them look identical: when no answer arrives, the
request may never have reached the stock service, or it may have been processed and the answer lost
on the way back. **The caller cannot tell which**, and it matters: in the second case the units were
taken. Lesson 7 is about that case.

## The fallacies

In 1994 Peter Deutsch, at Sun Microsystems, listed the assumptions that programmers new to
distributed systems make and that are false; James Gosling added the eighth later:

1. The network is reliable.
2. Latency is zero.
3. Bandwidth is infinite.
4. The network is secure.
5. Topology does not change.
6. There is one administrator.
7. Transport cost is zero.
8. The network is homogeneous.

Every one of them was true inside the monolith, because there was no network. **Splitting a program
makes every one of them false at once**, and the code that used to be correct does not change to
say so. `stock_call` has a two-second timeout because of the first two; the rest of the course is
largely about the others.
