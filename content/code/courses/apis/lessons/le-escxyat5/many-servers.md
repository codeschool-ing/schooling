---
title: More than one server
version: 1
---

**Every counter in `limits.py` is a dictionary in one process's memory, and that is correct for
exactly one process.** A real API runs several copies of itself behind a load balancer, so that one
can fail or be replaced without the API going down. Each copy then has its own `LIMITS`, and each
one enforces the limit on the share of the client's requests that happens to reach it.

Two copies of `limits.py` show it. Leave the first running on port 8000, and start a second in a
third terminal on port 8001:

```sh
cd ~/shelf && python3 limits.py bucket 8001
```

Twenty requests with the free key, all to the first copy, then, after ten seconds for its bucket to
fill again, twenty more that alternate between the two ports the way a round-robin load balancer
would send them:

```
ana@api:~/shelf$ for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: demo-bia' localhost:8000/books; done; echo
200 200 200 200 200 200 200 200 200 200 429 429 429 429 429 429 429 429 429 429 
ana@api:~/shelf$ sleep 10; for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: demo-bia' localhost:$((8000 + i % 2))/books; done; echo
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
```

One copy alone allowed ten, its bucket. Two copies allowed all twenty: each saw ten requests and
had ten tokens for them. **With N copies, a client gets N times its limit**, and nothing in any one
copy's view looks wrong. It gets stranger when the balancer is not round-robin: a client whose
requests mostly land on one copy is refused there while the other copy's bucket for it sits full.

Restarting has the same root. `Ctrl+C` and start again, and every bucket in the process is full
again; every deployment of a new version hands every client a fresh allowance.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Top: a client sends twenty requests through a load balancer to two copies of limits.py, each with its own bucket of ten in memory; each copy accepts ten, so all twenty are accepted. Bottom: both copies keep the counter in one shared store, so the client has one bucket of ten and ten are accepted.\"><defs><marker id=\"l12-lb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"90\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><text x=\"65.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20 requests</text><rect x=\"150\" y=\"50\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">load balancer</text><line x1=\"110\" y1=\"70\" x2=\"148\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"25\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy 1</text><text x=\"370.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">own bucket of 10</text><line x1=\"260\" y1=\"70\" x2=\"308\" y2=\"43\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"80\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy 2</text><text x=\"370.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">own bucket of 10</text><line x1=\"260\" y1=\"70\" x2=\"308\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><text x=\"560\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">20 accepted:</text><text x=\"560\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">twice the limit</text><rect x=\"20\" y=\"180\" width=\"90\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><text x=\"65.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20 requests</text><rect x=\"150\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">load balancer</text><line x1=\"110\" y1=\"200\" x2=\"148\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"155\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy 1</text><text x=\"370.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no counters</text><line x1=\"260\" y1=\"200\" x2=\"308\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"210\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy 2</text><text x=\"370.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no counters</text><line x1=\"260\" y1=\"200\" x2=\"308\" y2=\"228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"480\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shared store</text><text x=\"535.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one bucket of 10</text><line x1=\"430\" y1=\"173\" x2=\"478\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><line x1=\"430\" y1=\"228\" x2=\"478\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><text x=\"650\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">10 accepted</text></svg>", "caption": "Counters in each copy add up to N times the limit; one shared store keeps it at one."}
```

## A store every copy shares

The fix is to keep the counters outside the copies, in one store they all ask. In practice that
store is almost always **Redis**, an in-memory database built for small values that many clients
change at once, and `servers-cache`, the next course, is where it is installed and used. What
matters here is what the limiter needs from such a store, because it is the same whichever store
it is:

- **The check and the update must be one operation.** Two copies that each read "one token left"
  and each then write "zero" have both served a request on the same token. In memory that is what
  `LOCK` prevents; across machines the store has to do it, by running the read and the write as a
  single step.
- **Each counter expires on its own.** A client that never comes back should not keep a bucket in
  the store forever; the store deletes the key after its window has passed.
- **A round trip on every request.** The limiter now asks another machine before every answer. It
  is fast, and it is never free, and a store that is down leaves a decision to make: refuse
  everything, which turns a cache outage into an API outage, or allow everything, which turns it
  into no limit at all. Most APIs choose to allow, and log loudly.

## Exact or approximate

A shared store makes the limit exact and puts every request through one place. The alternative
is to let each copy keep its own counters with **the limit divided by the number of copies**, two
copies with five tokens each, and accept the error. It needs no store and survives losing it, and it
is wrong exactly when traffic is uneven between copies: a client whose requests all land on one copy
gets half its limit. Between the two sit schemes where each copy counts locally and reports to the
shared store every so often, trading a few seconds of overshoot for far fewer round trips.

**For a limit that protects the service, approximate is usually enough**: the aim is to stop the
client sending a thousand a second, and whether it was stopped at 100 or 110 does not matter. **For
a quota a customer pays for, exact is worth the round trip**, because the number on the invoice and
the number on the refusal have to agree.
