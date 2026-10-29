---
title: Three strategies
version: 1
---

**A strategy is an order of asking: the cache, the network, or both, and which answer wins.** Five have
names that every guide uses, and the planner uses three of them:

| strategy | what it does | right for | the planner's |
|---|---|---|---|
| **cache first** | the copy if there is one, else the network, keeping the answer | files that never change at their address | `/assets/`, the hashed scripts |
| **network first** | the network, else the copy | what must be as new as possible, and still work offline | the pages |
| **stale while revalidate** | the copy at once, and the network in the background for next time | what may be a visit old | fonts, covers, the plan, the notice |
| **network only** | the network, as if there were no worker | what must never be stale, such as a payment | not used |
| **cache only** | the copy, never the network | what was fetched at install | not used |

**Cache first is lesson 9's `immutable`, done by hand**, and right for the same reason: a hashed name cannot
point at a different file. On a slow network it is the strategy that removes the round trip entirely.

**Network first keeps a page honest.** A visitor online always sees the page the server draws now; the copy
is only for when the network is gone. Its cost is that a slow network is still waited for: a phone with a
weak signal waits its full timeout before getting the copy. A common refinement gives the network a few
seconds and answers from the cache after that.

**Stale while revalidate is the CDN's `stale-while-revalidate` of lesson 9, in the browser.** The visitor
gets the copy with no wait, and the worker fetches a fresh one behind them, so a change reaches them one visit
late. For a font or a cover that is nothing; for the plan it would be the course list of the last visit,
which is why the planner's pages, which carry the plan inside them, are network first.

## How the worker chooses

`fetch` sees a `Request`, and three of its properties decide everything above:

- **`request.method`**: only `GET` is ever answered from a cache; the `POST` to `/vitals` goes to the network
  untouched, because the handler returns without calling `respondWith`;
- **`request.mode === "navigate"`**: the request for a page itself, as opposed to the files the page asks for;
- **the address**: `/assets/` is the part Vite hashes, as lesson 9's rules said.
