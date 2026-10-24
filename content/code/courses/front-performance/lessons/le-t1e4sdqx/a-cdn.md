---
title: A CDN of your own
version: 1
---

**A CDN is a cache that many visitors share**, in servers close to them: a visitor in São Paulo is
answered from São Paulo, and only the first one to ask for a file makes the CDN ask the origin, the
application's own server. Every CDN differs in its details, and all of them follow the headers of the
section "The headers that decide it".

`tools/edge.ts` is a CDN reduced to the part that matters for those headers: a server on port 8000 that
forwards each request to `server.ts`, keeps the answers a shared cache may keep, for as long as they may
be kept, and answers from its store when it can. It adds `x-cache: HIT` or `MISS`, as most CDNs do under
some name, and `Age`. Save it in `tools/`:

```typescript
// tools/edge.ts: a small CDN in front of server.ts. It keeps the answers the headers allow a
// shared cache to keep, for as long as they allow, and says in x-cache whether an answer came
// from its store and in age how many seconds it has been there.
//
//   node tools/edge.ts        (listens on 8000, asks http://localhost:3000)
import { createServer, request, type IncomingHttpHeaders } from "node:http";

type Kept = { status: number; headers: IncomingHttpHeaders; body: Buffer; at: number; life: number };
const store = new Map<string, Kept>();

// How many seconds a shared cache may keep an answer: s-maxage if there is one, else max-age;
// nothing for private, no-store or no-cache, which this edge does not try to revalidate.
const life = (cacheControl = "") => {
  if (/private|no-store|no-cache/.test(cacheControl)) return 0;
  const m = cacheControl.match(/s-maxage=(\d+)/) ?? cacheControl.match(/max-age=(\d+)/);
  return m ? Number(m[1]) : 0;
};

createServer((req, res) => {
  // The address, and the one header the origin says its answers vary on.
  const key = `${req.method} ${req.url} ${req.headers["accept-encoding"] ?? ""}`;
  const kept = store.get(key);
  const age = kept ? Math.floor((Date.now() - kept.at) / 1000) : 0;
  if (kept && age < kept.life) {
    res.writeHead(kept.status, { ...kept.headers, age: String(age), "x-cache": "HIT" }).end(kept.body);
    return;
  }
  const ask = request(`http://localhost:3000${req.url}`, { method: req.method, headers: req.headers }, (answer) => {
    const chunks: Buffer[] = [];
    answer.on("data", (c) => chunks.push(c));
    answer.on("end", () => {
      const body = Buffer.concat(chunks);
      // These describe one connection, not the answer, so they are not kept or passed on.
      const { connection, "keep-alive": _, "transfer-encoding": __, ...headers } = answer.headers;
      const keep = req.method === "GET" && answer.statusCode === 200 ? life(headers["cache-control"]) : 0;
      if (keep > 0) store.set(key, { status: 200, headers, body, at: Date.now(), life: keep });
      res.writeHead(answer.statusCode!, { ...headers, "x-cache": "MISS" }).end(body);
    });
  });
  req.pipe(ask);
}).listen(8000, () => console.log("edge on http://localhost:8000, in front of :3000"));
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three boxes in a row: browsers on the left, the edge in the middle, server.ts on the right. A request the edge has a fresh copy of is answered by the edge, a HIT, and never reaches server.ts. A request it has no fresh copy of is passed on, a MISS, and the answer is kept if its headers allow a shared cache to keep it.\"><rect x=\"30\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">browsers</text><rect x=\"290\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge.ts · :8000</text><rect x=\"550\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server.ts · :3000</text><line x1=\"172\" y1=\"88\" x2=\"288\" y2=\"88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,88.0 280.6,91.1 280.6,84.9\" fill=\"var(--phosphor)\"></polygon><text x=\"230\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">request</text><line x1=\"288\" y1=\"112\" x2=\"172\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"172.0,112.0 179.4,108.9 179.4,115.1\" fill=\"var(--phosphor)\"></polygon><text x=\"230\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HIT · age</text><line x1=\"432\" y1=\"88\" x2=\"548\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"548.0,88.0 540.6,91.1 540.6,84.9\" fill=\"var(--amber)\"></polygon><text x=\"490\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MISS</text><line x1=\"548\" y1=\"112\" x2=\"432\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"432.0,112.0 439.4,108.9 439.4,115.1\" fill=\"var(--amber)\"></polygon><text x=\"490\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">answer + headers</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept if s-maxage or max-age allows,</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never if private, no-store or no-cache</text></svg>", "caption": "A HIT is a request the origin never hears of."}
```

Two simplifications, and both are honest about a real CDN: it keeps one copy per encoding, where a real one
normalises `Accept-Encoding` to a few values first; and it does not revalidate, so an answer marked
`no-cache` is passed through rather than kept and checked. Start it in a second terminal:

```
ana@dev:~/planner$ node tools/edge.ts
edge on http://localhost:8000, in front of :3000
```

and ask it twice for a script, two seconds apart, and twice for a page:

```
ana@dev:~/planner$ A=$(ls dist/assets | grep -m1 '^index.*js'); for i in 1 2; do curl -s -o /dev/null -D - http://localhost:8000/assets/$A | grep -iE '^(x-cache|age)'; sleep 2; done
x-cache: MISS
age: 2
x-cache: HIT
ana@dev:~/planner$ for i in 1 2; do curl -s -o /dev/null -D - http://localhost:8000/courses/git | grep -iE '^(x-cache|age)'; done
x-cache: MISS
x-cache: MISS
```

**The script was a MISS and then a HIT, two seconds old.** The second request never reached `server.ts`.
**The page was a MISS both times**: `no-cache` is an instruction to check, and this edge does not check, so it
asks the origin every time. That is correct for the browser and wasteful for a CDN: a page that is the same
for everybody could be kept at the edge for a while, and the next section says so with `s-maxage`.

The browser behind the edge sees nothing different, because the edge passes the origin's headers on:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:8000/courses/git
/courses/git                   304, kept its copy
/fonts/plex-400.woff2          304, kept its copy
/fonts/plex-700.woff2          304, kept its copy
/assets/index-B_kobX3K.js      from the cache, not asked
/assets/planner-BNdUlffC.js    from the cache, not asked
/covers/git-800.avif           304, kept its copy
```
