---
title: Regenerating one page at a time
version: 1
---

**Incremental regeneration keeps each page a file, and gives each file an age after which it may be
replaced.** A request for a page younger than that age gets the file. A request for an older page
gets the file too, at once, and the server renders a new one in the background; the next request
gets the new one. No request ever waits for a render, unless the page is so old that serving it is
worse than waiting.

The name for that pattern is older than any of the frameworks. It is **stale-while-revalidate**: a
copy past its freshness may still be served while a fresh one is fetched. HTTP has a header for it,
which lesson 9 is about, and the frameworks apply the same rule to their own store of rendered
pages.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of one page under incremental regeneration with an age of ten seconds. The build makes copy 1. Requests in the first ten seconds get copy 1. The data changes. The first request after ten seconds still gets copy 1 and starts a render in the background, which produces copy 2. The request after that gets copy 2.\"><line x1=\"60\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,150.0 682.6,153.1 682.6,146.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><rect x=\"60\" y=\"120\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"225\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 1, fresh for 10 s</text><rect x=\"390\" y=\"120\" width=\"120\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">copy 1, stale</text><rect x=\"510\" y=\"120\" width=\"180\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">copy 2, fresh</text><line x1=\"260\" y1=\"40\" x2=\"260\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"260\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the data changes</text><line x1=\"120\" y1=\"196\" x2=\"120\" y2=\"152\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><polygon points=\"120.0,152.0 123.1,159.4 116.9,159.4\" fill=\"var(--paper)\"></polygon><line x1=\"320\" y1=\"196\" x2=\"320\" y2=\"152\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><polygon points=\"320.0,152.0 323.1,159.4 316.9,159.4\" fill=\"var(--paper)\"></polygon><line x1=\"420\" y1=\"196\" x2=\"420\" y2=\"152\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,152.0 423.1,159.4 416.9,159.4\" fill=\"var(--amber)\"></polygon><line x1=\"620\" y1=\"196\" x2=\"620\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"620.0,152.0 623.1,159.4 616.9,159.4\" fill=\"var(--phosphor)\"></polygon><text x=\"120\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">request: copy 1</text><text x=\"305\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">request: copy 1</text><text x=\"435\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">request: copy 1, starts a render</text><text x=\"620\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">request: copy 2</text><path d=\"M 430 118 C 460 80, 490 80, 510 118\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></path><text x=\"470\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">render in the background</text></svg>", "caption": "Nobody waits for a render, and the request that starts one is the last to see the old page."}
```

## The two numbers

Every implementation asks for the same two durations, under different names:

| | what it decides | Next.js `cacheLife` | Nuxt `routeRules` |
|---|---|---|---|
| **fresh for** | how long a copy is served with no thought of replacing it | `revalidate` | `swr: <seconds>`, or `isr: <seconds>` |
| **usable for** | how long an old copy may still be served while a new one is made | `expire` | unlimited for `swr`; set by the host for `isr` |

**The first number is how wrong a page may be, measured in time.** A catalogue that may lag by an
hour sets an hour, and nobody has to remember to rebuild. The second number is the limit past which
correctness wins over speed: after it, the next request waits for a fresh render instead of being
handed something very old.

## What it does not give you

**The first request after the age is still served the old page.** The person who asks just after
the data changed, and just after the copy went stale, sees the old content; the regeneration that
request started is for the person after them. If the data changed a minute ago and the age is an
hour, the page can be up to an hour wrong. That is the bargain, and the section "On demand: when the
data says so" is the way out of it.

**Each page regenerates on its own.** A course renamed in the data shows its new name on the course
page once that page regenerates, and on the home page once *that* page does. For a while two pages
of the same site disagree. Pages that must agree have to be regenerated together, which the age
alone cannot do.

**And a page regenerates only where its copy lives.** Next.js and Nuxt keep the copies on the
server that rendered them, in memory or on its disk. Two servers behind a load balancer keep two
sets of copies, which go stale at different moments; a host built for these frameworks keeps one
shared store instead, and that is part of what such a host sells.
