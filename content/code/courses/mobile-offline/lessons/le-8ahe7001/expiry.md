---
title: Expiry, and asking whether a copy is still good
version: 1
---

**An expired copy is not a wrong copy; it is one that has to be checked before it is trusted
again.** The common picture is that a cache entry dies at its expiry and is thrown away. HTTP
works differently, and better for a phone: the server says how long a copy is fresh, how long it
may go on being shown while it is checked, and gives it a tag, so the check costs a few hundred
bytes instead of the whole body.

Three headers carry all of it:

| header | from | what it says |
|---|---|---|
| `Cache-Control: max-age=60` | server | the copy is **fresh** for 60 seconds: show it and ask nobody |
| `stale-while-revalidate=300` | server, same header | for 300 seconds after that, show the old copy at once and check in the background |
| `ETag: "250e0d8c86f9"` | server | a tag for this exact body |
| `If-None-Match: "250e0d8c86f9"` | client | "I have this one; send it only if it changed" |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-expiry\" aria-label=\"A timeline of one cached copy, downloaded at second 0 with max-age=60 and stale-while-revalidate=300. From 0 to 60 the copy is fresh: it is shown and nothing is asked. From 60 to 360 it is stale: it is shown at once and checked in the background with If-None-Match. After 360 it is too old to show: the screen waits for the network, and a 304 costs no body. The client's runs at seconds 30 and 45 fall in the fresh band, 90 in the stale band.\"><defs><marker id=\"l17-expiry-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l17-expiry-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"60\" width=\"96.0\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"136.0\" y=\"60\" width=\"480.0\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"616.0\" y=\"60\" width=\"84.0\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"88.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">fresh</text><text x=\"88.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-age</text><text x=\"376.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">stale while revalidating</text><text x=\"376.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">shown at once, checked behind it</text><text x=\"658.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">too old</text><text x=\"658.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the screen waits</text><text x=\"88.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">shown, nothing asked</text><path d=\"M40.0 150 L704.0 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper-dim)\"></path><path d=\"M40.0 145 L40.0 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M136.0 145 L136.0 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"136.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60</text><path d=\"M616.0 145 L616.0 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"616.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">360</text><text x=\"360.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seconds since the copy was downloaded</text><text x=\"40.0\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runs of fetch.ts</text><path d=\"M88.0 40 L88.0 58\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper)\"></path><text x=\"82.0\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">30</text><path d=\"M112.0 40 L112.0 58\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper)\"></path><text x=\"118.0\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">45</text><path d=\"M184.0 40 L184.0 58\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper)\"></path><text x=\"190.0\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">90</text></svg>", "caption": "One download, three ways to answer the next read. Each 200 or 304 starts the timeline again from zero."}
```

If the body has not changed, the server answers **304 Not Modified** with no body, and the client
keeps its copy and starts its 60 seconds again.

## A server and a client, in `~/planner/cache`

The server reads the catalogue from a file and tags it with the start of its SHA-256, so editing
the file changes the tag. It prints each request it receives. Save it as `server.ts`:

```typescript
// server.ts: the planner's catalogue, served with an ETag, on port 8017.
import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";

createServer((req, res) => {
  const body = readFileSync("catalogue.json");
  const etag = `"${createHash("sha256").update(body).digest("hex").slice(0, 12)}"`;
  const status = req.headers["if-none-match"] === etag ? 304 : 200;
  console.log(`${req.method} ${req.url} if-none-match=${req.headers["if-none-match"] ?? "-"} -> ${status}`);
  res.writeHead(status, { ETag: etag, "Cache-Control": "max-age=60, stale-while-revalidate=300" });
  res.end(status === 200 ? body : undefined);
}).listen(8017, "127.0.0.1");
```

And beside it, the three courses as `catalogue.json`:

```json
{"courses": ["Spanish A2", "Statistics", "Guitar"]}
```

The client keeps one row per URL in SQLite. Time is an argument, `NOW` in seconds, so the run
below can jump from second 0 to second 1000 without waiting. Save it as `fetch.ts`:

```typescript
// fetch.ts: read the catalogue through a cache that honours max-age, stale-while-revalidate and ETag.
// usage: node fetch.ts NOW   (NOW is seconds on a pretend clock, so every run is repeatable)
import Database from "better-sqlite3";

const URL = "http://127.0.0.1:8017/catalogue";
const now = Number(process.argv[2]);
const db = new Database("cache.db");
db.exec(`create table if not exists http_cache (
  url text primary key, etag text, body text, fetched_at integer, max_age integer, swr integer)`);
type Row = { etag: string; body: string; fetched_at: number; max_age: number; swr: number };
const row = db.prepare("select * from http_cache where url = ?").get(URL) as Row | undefined;

async function revalidate(): Promise<string> {
  const res = await fetch(URL, { headers: row ? { "If-None-Match": row.etag } : {} });
  const cc = res.headers.get("cache-control") ?? "";
  const maxAge = Number(/max-age=(\d+)/.exec(cc)?.[1] ?? 0);
  const swr = Number(/stale-while-revalidate=(\d+)/.exec(cc)?.[1] ?? 0);
  const body = res.status === 304 && row ? row.body : await res.text();
  db.prepare(`insert or replace into http_cache values (?, ?, ?, ?, ?, ?)`)
    .run(URL, res.headers.get("etag"), body, now, maxAge, swr);
  console.log(`  network: ${res.status} ${res.status === 304 ? "not modified, kept the copy" : "downloaded"}`);
  return body;
}

const show = (body: string) => console.log(`  on screen: ${JSON.parse(body).courses.join(", ")}`);
const age = row ? now - row.fetched_at : Infinity;
if (row && age < row.max_age) {
  console.log(`t=${now}: fresh (age ${age}s), from the cache, no request`);
  show(row.body);
} else if (row && age < row.max_age + row.swr) {
  console.log(`t=${now}: stale (age ${age}s), shown from the cache, then revalidated`);
  show(row.body);
  await revalidate();
} else {
  console.log(`t=${now}: ${row ? `too old (age ${age}s)` : "nothing cached"}, the screen waits for the network`);
  show(await revalidate());
}
```

Start the server in a terminal of its own with `node server.ts`, and in another, run the client at
six moments. Between second 30 and 45 the catalogue changes on the server: a fourth course, Chess,
is added to `catalogue.json`, written here with `echo` so you can see it happen.

```
ana@dev:~/planner/cache$ node fetch.ts 0
t=0: nothing cached, the screen waits for the network
  network: 200 downloaded
  on screen: Spanish A2, Statistics, Guitar
ana@dev:~/planner/cache$ node fetch.ts 30
t=30: fresh (age 30s), from the cache, no request
  on screen: Spanish A2, Statistics, Guitar
ana@dev:~/planner/cache$ echo '{"courses": ["Spanish A2", "Statistics", "Guitar", "Chess"]}' > catalogue.json
ana@dev:~/planner/cache$ node fetch.ts 45
t=45: fresh (age 45s), from the cache, no request
  on screen: Spanish A2, Statistics, Guitar
ana@dev:~/planner/cache$ node fetch.ts 90
t=90: stale (age 90s), shown from the cache, then revalidated
  on screen: Spanish A2, Statistics, Guitar
  network: 200 downloaded
ana@dev:~/planner/cache$ node fetch.ts 100
t=100: fresh (age 10s), from the cache, no request
  on screen: Spanish A2, Statistics, Guitar, Chess
ana@dev:~/planner/cache$ node fetch.ts 1000
t=1000: too old (age 910s), the screen waits for the network
  network: 304 not modified, kept the copy
  on screen: Spanish A2, Statistics, Guitar, Chess
```

And what the server saw, from its own terminal:

```
ana@dev:~/planner/cache$ node server.ts
GET /catalogue if-none-match=- -> 200
GET /catalogue if-none-match="250e0d8c86f9" -> 200
GET /catalogue if-none-match="eb1ee6129b5c" -> 304
```

**Six runs of the client, three requests.** At second 30 and 45 nothing was asked, and at 45
that meant the screen showed three courses while the server had four. That is the price of
`max-age`, and it is paid knowingly: for 60 seconds the planner trusts a copy rather than the
network. At second 90 the copy was stale but inside the revalidation window, so the old list was
shown at once and the new one arrived behind it, a 200 because the tag no longer matched. At
second 1000 the copy was too old to show, so the screen waited, and the check cost a 304 with no
body.

**How long `max-age` should be is a question about the data, not about HTTP.** A catalogue that
changes once a term can be fresh for a day. The list of a person's own sessions should not be
cached this way at all: it is the first kind of data from the last section, and lesson 11 brings
it down with a cursor instead.
