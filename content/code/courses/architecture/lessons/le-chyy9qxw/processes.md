---
title: VI to VIII, processes, ports and scaling out
version: 1
---

Three factors that are one idea seen from three sides: **the program runs as ordinary processes that
keep nothing, serve on a port they are given, and are multiplied to handle more load.**

**VII, port binding.** The catalogue is a complete HTTP server; it does not need to be loaded into
another web server to answer. It listens on `PORT`, and the platform, here Compose, decides which
outside port leads to it. That is what lets the same program run behind any load balancer or proxy
without knowing about it.

**VIII, concurrency.** To handle more requests, run more processes, rather than making one process
bigger. Compose does it with `--scale`; the port range `8000-8002` in `compose.yaml` gives each copy
its own port on the machine:

```
ana@vm:~/lab/twelve$ docker compose up -d --scale catalogue=3
 Container twelve-db-1 Running 
 Container twelve-catalogue-3 Creating 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-2 Creating 
 Container twelve-catalogue-2 Created 
 Container twelve-catalogue-3 Created 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
 Container twelve-catalogue-3 Starting 
 Container twelve-catalogue-3 Started 
 Container twelve-catalogue-2 Starting 
 Container twelve-catalogue-2 Started 
ana@vm:~/lab/twelve$ docker compose ps catalogue --format "{{.Name}} {{.Ports}}"
twelve-catalogue-1 127.0.0.1:8001->8000/tcp
twelve-catalogue-2 127.0.0.1:8000->8000/tcp
twelve-catalogue-3 127.0.0.1:8002->8000/tcp
```

**VI, processes.** Each of those three copies must be able to answer any request, which means none
of them may keep anything another request will need. The catalogue's `/hits` breaks that rule on
purpose: it counts in the process's own memory. Ask each copy once, then the first one twice more:

```
ana@vm:~/lab/twelve$ curl -s localhost:8000/hits
{"served_by": "a3b89e5e7e5f", "hits": 1}
ana@vm:~/lab/twelve$ curl -s localhost:8001/hits
{"served_by": "4ed40453cdac", "hits": 1}
ana@vm:~/lab/twelve$ curl -s localhost:8002/hits
{"served_by": "280702d81305", "hits": 1}
ana@vm:~/lab/twelve$ curl -s localhost:8000/hits
{"served_by": "a3b89e5e7e5f", "hits": 2}
ana@vm:~/lab/twelve$ curl -s localhost:8000/hits
{"served_by": "a3b89e5e7e5f", "hits": 3}
ana@vm:~/lab/twelve$ curl -s localhost:8001/products
{"served_by": "4ed40453cdac", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three copies of the catalogue process side by side. Each holds its own counter in memory: one says 3, one says 1, one says 1. Below them, a shared database that all three read the products from.\"><defs><marker id=\"l4-processes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"30\" width=\"190\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">catalogue-1</text><text x=\"135\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in memory</text><rect x=\"85\" y=\"90\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hits = 3</text><path d=\"M135 142 L135 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-processes-ah-phosphor)\"></path><rect x=\"265\" y=\"30\" width=\"190\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">catalogue-2</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in memory</text><rect x=\"310\" y=\"90\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hits = 1</text><path d=\"M360 142 L360 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-processes-ah-phosphor)\"></path><rect x=\"490\" y=\"30\" width=\"190\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">catalogue-3</text><text x=\"585\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in memory</text><rect x=\"535\" y=\"90\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hits = 1</text><path d=\"M585 142 L585 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-processes-ah-phosphor)\"></path><rect x=\"40\" y=\"178\" width=\"640\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the database: the same products for every copy</text></svg>", "caption": "Five requests, three processes, three different answers to how many there were. What must be the same for every copy has to live in a backing service."}
```

Five requests reached the catalogue and **no copy knows it**. The first says 3, the others say 1. A
load balancer in front would spread the requests in a way nobody controls, and every answer would be
a different wrong number. The same thing happens to anything kept in memory between requests: a
shopping basket, a login session, a file uploaded to the local disk, a rate limit. The products are
right in every copy because they come from the database, which all three share.

**What must survive a request goes into a backing service**: a session in Redis or in the database,
a file in an object store, a count in the database or in a cache that every copy reads. A process may
still cache things in memory for speed, as long as losing the cache costs only time, never a wrong
answer. The rule is what you *rely* on, not what you *hold*.

## Sticky sessions are a workaround, not a fix

Some load balancers can send every request from one user to the same copy, which makes in-memory
sessions appear to work. **It breaks the moment that copy restarts, is replaced or is scaled away**,
and the platform does all three without asking, as the next section shows.
