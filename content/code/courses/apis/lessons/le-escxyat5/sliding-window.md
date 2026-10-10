---
title: Sliding windows
version: 1
---

**A sliding window asks the question the fixed window only approximates: how many requests has this
client made in the last ten seconds, counting back from now?** The window moves with the clock
instead of jumping, so there is no boundary to straddle. It comes in two forms, one exact and one
cheap.

## The log: exact, and paid for in memory

The **sliding log** keeps the time of every accepted request. When a new one arrives, it throws
away the times older than ten seconds, counts what is left, and accepts the request if the count
is under the limit.

Run the edge burst from the previous section against it. At the first request after the fixed
window's boundary, the log still holds the ten requests of the last second, all younger than ten
seconds, so the count is ten and the request is refused. It goes on refusing until the oldest of
those ten turns ten seconds old. **No ten-second span ever contains more than ten**, which is the
promise people thought the fixed window was making.

The cost is the log itself. A limit of 10 per 10 seconds stores up to ten timestamps per client; a
limit of 1,000 per hour stores up to a thousand, for every client, and every request walks them. For
small limits that is nothing. For large limits across many clients it is the memory the fixed
window was saving.

## The counter: two numbers and an assumption

The **sliding window counter** keeps only two fixed-window counts per client, the current window's
and the previous one's, and estimates the sliding count from them. It assumes the previous window's
requests were spread evenly across it, so the part of that window still inside the last ten seconds
held a proportional share of them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A previous fixed window of ten seconds held 8 requests and the current one has 3 so far. Four seconds into the current window, the last ten seconds cover 60 percent of the previous window, so the estimate is 8 times 0.6 plus 3, which is 7.8.\"><defs><marker id=\"l12-slide-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"50\" width=\"300\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">previous window: 8 requests</text><rect x=\"360\" y=\"50\" width=\"300\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">current window:</text><text x=\"570\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 so far</text><rect x=\"180\" y=\"112\" width=\"300\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the last ten seconds</text><line x1=\"480\" y1=\"36\" x2=\"480\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"480\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">now</text><line x1=\"180\" y1=\"168\" x2=\"360\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-slide-ah)\" marker-start=\"url(#l12-slide-ah)\"></line><text x=\"270.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6 s of 10: 0.6</text><text x=\"120\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">already outside</text><text x=\"350\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">estimate  =  8 × 0.6  +  3  =  7.8</text><text x=\"350\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">under the limit of 10, so the request is accepted</text></svg>", "caption": "The counter assumes the previous window's requests were spread evenly across it."}
```

With a limit of ten, an estimate of 7.8 lets the request through. Against the edge burst it does
what the log does: one tenth of a second into the new window, the previous window's ten count as
10 × 0.99 = 9.9, and the next request is refused.

The assumption is where it can be wrong, in both directions:

| the previous window's requests were | the estimate | the effect |
|---|---|---|
| spread evenly | right | none |
| bunched at its start | too high: they are already outside the last ten seconds | a client is refused when it had room |
| bunched at its end | too low: they are all still inside | a client gets a few more than the limit |

Neither error grows past one window's worth, and the cost is two counters whatever the limit is.
**That trade is why the counter is the common choice for large limits on many clients, and the log
for small limits where exactness matters**, such as a few login attempts a minute.

Neither is in `limits.py`. The limiter it does use keeps two numbers per client, as the counter
does, and has no edge, as the log has none.
