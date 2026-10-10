---
title: IV, backing services are attached resources
version: 1
---

A **backing service** is anything the program uses over the network to do its job: a database, a
queue, a cache, an e-mail service, an object store. The factor asks that the program **makes no
distinction between one run by your own team and one bought from a provider**: each is a resource at
the end of a URL, attached through config, and replaceable by changing that config.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The catalogue process on the left holds only a URL. It points at the database db; a dashed arrow shows the same URL setting changed to point at another database, other-db, with no change to the code.\"><defs><marker id=\"l4-backing-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l4-backing-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"70\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">catalogue</text><text x=\"150\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DATABASE_URL=…</text><rect x=\"470\" y=\"30\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">db</text><rect x=\"470\" y=\"130\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"570\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">other-db</text><path d=\"M262 95 L468 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-backing-ah-phosphor)\"></path><path d=\"M262 125 L468 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l4-backing-ah-wire)\"></path><text x=\"365\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">change the URL</text></svg>", "caption": "A backing service is a resource at the end of a URL. Pointing the URL somewhere else attaches another one, with no change to the code."}
```

The catalogue's database is named only in `DATABASE_URL`. To prove it, start a second, empty
PostgreSQL on the same network, under another name, and point the catalogue at it.
`--network twelve_default` puts the new container on the network Compose made for the project, where the
catalogue can find it by name:

```
ana@vm:~/lab/twelve$ docker run -d --name other-db --network twelve_default -e POSTGRES_USER=quitanda -e POSTGRES_PASSWORD=quitanda postgres:17
1957aa2b6ec8e840082457b9c55585aa2d4fbfd0168b033e2163d6660e14e9b6
ana@vm:~/lab/twelve$ DATABASE_URL=postgresql://quitanda:quitanda@other-db:5432/quitanda docker compose up -d catalogue
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
ana@vm:~/lab/twelve$ docker compose port catalogue 8000
127.0.0.1:8001
ana@vm:~/lab/twelve$ curl -sS 127.0.0.1:8001/products
curl: (52) Empty reply from server
```

The catalogue was recreated with the new URL and nothing else changed. **Its port may have changed,
though**: `compose.yaml` publishes the range `8000-8002`, and Docker gives the new container whichever
port of the range is free at that moment, so `docker compose port` is how to ask which one it got.
That is factor VII, two sections early: the platform, not the program, decides the outside port.

The first request fails, which is correct: `other-db` is a different database and has no `products`
table. The traceback is in the catalogue's log; `curl` only sees the connection closed. Run the admin
task against the new database and ask again:

```
ana@vm:~/lab/twelve$ DATABASE_URL=postgresql://quitanda:quitanda@other-db:5432/quitanda docker compose run --rm catalogue python catalogue.py migrate
 Container twelve-db-1 Running 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-run-5b9df4d36017 Creating 
 Container twelve-catalogue-run-5b9df4d36017 Created 
migrated: 5 products
ana@vm:~/lab/twelve$ curl -s 127.0.0.1:8001/products
{"served_by": "9586548804c3", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

The same image, attached to a different resource, by changing one variable. That is what makes
moving to a managed database, restoring a backup into a new server, or pointing a test run at a
throwaway copy into a configuration change rather than a code change.

Attach the original again by recreating the catalogue without the variable, so that the default in
`compose.yaml` applies, and remove the second database:

```
ana@vm:~/lab/twelve$ docker compose up -d catalogue
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
ana@vm:~/lab/twelve$ docker rm -f other-db
other-db
ana@vm:~/lab/twelve$ docker compose port catalogue 8000
127.0.0.1:8002
ana@vm:~/lab/twelve$ curl -s 127.0.0.1:8002/products
{"served_by": "2a00288d3d2d", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

## What the factor does not promise

Swapping the address does not make two backing services interchangeable. A program written for
PostgreSQL does not run against MySQL because the URL changed; a queue with different delivery
guarantees, lesson 7, behaves differently behind the same client. The factor is about **where the
resource is**, not about pretending that every resource of a kind is the same.
