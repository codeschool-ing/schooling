---
title: Bulkheads
version: 1
---

A ship's hull is divided by walls, **bulkheads**, so that water coming in through one hole floods one
compartment and not the ship. In software it is the same idea applied to a shared resource: give each
dependency its own share of the threads, connections or memory, so that one dependency misbehaving uses
up its share and nothing else. Nygard's *Release It!* named it alongside the circuit breaker.

The shop's bulkhead is a semaphore: at most `BULKHEAD` threads may be waiting on the stock service, and a
request that finds them all taken is refused with a `503` at once, instead of taking a thread and
waiting too. Restart the shop with three, slow the stock service down, and run the load:

```
ana@vm:~/lab/bulkheads$ BULKHEAD=3 docker compose up -d
 Container bulkheads-stock-1 Running 
 Container bulkheads-shop-1 Recreate 
 Container bulkheads-shop-1 Recreated 
 Container bulkheads-shop-1 Starting 
 Container bulkheads-shop-1 Started 
ana@vm:~/lab/bulkheads$ curl -s -X POST localhost:8001/slow/5
every answer now takes 5.0 s
ana@vm:~/lab/bulkheads$ $L mixed
catalogue  200: 200                 median     2 ms, slowest    61 ms
stock      timeout: 6, 503: 194     median     2 ms, slowest  3063 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The same eight threads with a bulkhead. Three of them may be used by requests waiting on the stock service, and all three are full. A fourth stock request is refused at once with 503. The other five threads stay available, and catalogue requests run on them.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"100\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">stock: at most 3</text><rect x=\"40\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"82\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"124\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"190\" y=\"70\" width=\"230\" height=\"60\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"305\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">everything else: 5</text><rect x=\"200\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"244\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"288\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"332\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"376\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"80\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4th stock request: 503 at once</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a flooded compartment does not sink the ship</text></svg>", "caption": "A bulkhead caps how much of a shared resource one dependency can hold. The excess is refused at once, and the rest of the service keeps its threads."}
```

**The catalogue never noticed**: 200 answers, a median of 2 milliseconds. The stock page did no better
than before, which is right, because its dependency really was taking five seconds; but almost all of
its failures were fast `503`s instead of three-second timeouts, and three threads waiting on the stock
service left five for everything else. The failure stayed inside its compartment.

## The forms a bulkhead takes

| form | what is divided | where you meet it |
| --- | --- | --- |
| a semaphore or a pool per dependency, in one process | threads | Resilience4j's `Bulkhead`, Polly's bulkhead policy, the lab |
| a connection pool per dependency | connections | a separate HTTP client, or database pool, for each service called |
| separate instances for separate traffic | whole servers | the checkout's API on its own instances, so a reporting surge cannot take them |
| separate deployments per customer group | everything | one cell of servers per group of customers, so a failure reaches one cell |

The first row is the cheapest, and it is the answer lesson 2 promised for a monolith: **isolation does not
require separate services**. A monolith with a bulkhead around each dependency keeps the catalogue up
while the stock service is slow, exactly as the shop just did. The last row, usually called a
**cell-based architecture**, is how the largest systems limit how many customers any single failure
can reach.

Put the stock service back before going on:

```sh
curl -s -X POST localhost:8001/slow/0.02
```
