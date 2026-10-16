---
title: Throttling a client that asks too often
version: 1
---

The bulkhead protected the shop from a dependency. The opposite danger comes from a caller: a partner's
integration in a loop, a scraper, a mobile app with a bug that refreshes every 20 milliseconds. One
client sending more than its share takes threads from everybody else.

**Throttling**, or rate limiting, caps how often each client may ask. The shop's limit is a **token
bucket** per client, the most common algorithm: a bucket holds up to ten tokens and is refilled at ten
a second, and each request takes one. A client can burst up to ten requests at once, and after that gets
ten a second, however hard it tries.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A token bucket. Tokens drip in at a steady rate, ten a second, up to a capacity of ten. Each request takes one token and goes through. A request that finds the bucket empty is answered 429 Too Many Requests, with Retry-After.\"><defs><marker id=\"l12-bucket-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-bucket-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">10 tokens a second</text><path d=\"M180 44 L180 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-bucket-ah-phosphor)\"></path><rect x=\"120\" y=\"80\" width=\"120\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><circle cx=\"150\" cy=\"165\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"210\" cy=\"165\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"150\" cy=\"135\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"210\" cy=\"135\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capacity 10</text><rect x=\"400\" y=\"60\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">token taken: 200</text><rect x=\"400\" y=\"140\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">bucket empty: 429, Retry-After: 1</text><path d=\"M242 110 L398 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-bucket-ah-phosphor)\"></path><path d=\"M242 150 L398 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-bucket-ah-amber)\"></path></svg>", "caption": "A token bucket allows a burst up to its size and, after that, the rate it is refilled at."}
```

A request that finds the bucket empty gets **`429 Too Many Requests`**, with a `Retry-After` header
saying how many seconds to wait. That is the status code made for it, and it matters which one is used:
a `429` says "you, slow down", where a `503` says "I am in trouble". A well-behaved client, and every
retry library from lesson 11, reads `Retry-After` and waits.

Restart the shop with a limit of ten a second per client. Then, for five seconds, a greedy client asks
fifty times a second while Ana asks twice a second:

```
ana@vm:~/lab/bulkheads$ RATE=10 docker compose up -d
 Container bulkheads-stock-1 Running 
 Container bulkheads-shop-1 Recreate 
 Container bulkheads-shop-1 Recreated 
 Container bulkheads-shop-1 Starting 
 Container bulkheads-shop-1 Started 
ana@vm:~/lab/bulkheads$ $L greedy
ana        200: 10                  median     2 ms, slowest    41 ms
greedy     200: 59, 429: 191        median     2 ms, slowest    42 ms
```

The greedy client got 59 answers out of 250: the ten in its bucket at the start, then about ten a
second. The rest were refused in a couple of milliseconds, at almost no cost to the shop. **Ana got all
of hers**, because the limit is per client and her bucket was never empty.

## Where the limit lives

A rate limit is usually not in the service at all. The **API gateway** in front of the services, which
lesson 19 builds, is the natural place: it sees every client, it knows who each one is, and one setting
there protects every service behind it. Cloud gateways, Envoy, NGINX and Kong all have it built in. With
several gateway instances the buckets have to be shared, usually in Redis, or each instance allows the
full rate and the real limit is that rate times the number of instances.

Two neighbours of the idea are worth knowing by name:

- **Quotas** are rate limits over long periods, "10,000 requests a day", and are usually about a plan
  somebody pays for rather than about protecting the service.
- **Load shedding** refuses work by its importance, not by who sent it: when the shop is overloaded it
  drops the recommendations box first and the checkout last. It needs the service to know which
  requests matter, which is a decision for the business, not a setting.
