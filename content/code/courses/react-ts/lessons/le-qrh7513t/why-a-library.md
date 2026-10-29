---
title: Why the effect from lesson 5 is not enough
version: 1
---

**Lesson 5's fetch was correct, and it handled one of the many things fetching data involves.** It
loaded once, dropped a late answer, and drew three states. Here is what it did not do, each of which
a real screen needs sooner or later:

| a real screen needs | lesson 5's effect |
|---|---|
| the same data shared by every component that asks, fetched once | each caller would fetch its own |
| two requests at once for the same thing merged into one | strict mode alone sent two |
| a retry when a request fails for a moment | one failure is final |
| fresh data after a change is saved | the change lives only in local state |
| fresh data when the user returns to the tab | never refetched |
| the old data kept on screen while new data loads | back to "loading" |

None of it is hard alone, and all of it together is a library. The deeper reason is that **data from a
server is not state in the sense lesson 4 meant**. `useState` owns its value: nothing else can change
it. The planner's sessions are a copy of something the server owns, which anybody with access may
change at any moment, and the copy is right only until it is not. Keeping a copy right is caching, and
caching is about knowing when a copy has gone stale.

```schooling-figure
{"svg": "<svg data-fig=\"server-state\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two kinds of state. Client state, such as the chosen week or the open course, lives in the browser and only this app changes it. Server state, the courses and sessions, lives on the server; the browser holds a cached copy, which other people and other tabs can make stale at any moment.\"><rect x=\"20\" y=\"30\" width=\"300\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">the browser</text><rect x=\"40\" y=\"70\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"84.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client state</text><text x=\"170.0\" y=\"99.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">monday · openId</text><rect x=\"40\" y=\"128\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"142.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a cached copy</text><text x=\"170.0\" y=\"157.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">['planner']</text><rect x=\"420\" y=\"90\" width=\"280\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the server</text><text x=\"560.0\" y=\"137.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data/planner.json</text><line x1=\"418\" y1=\"140\" x2=\"302\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"302.0,150.0 309.2,146.2 309.7,152.5\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GET</text><text x=\"560\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">anyone with access may change it</text></svg>", "caption": "Client state is owned; server state is a copy, and a copy can go stale."}
```

TanStack Query, still widely called React Query, is a cache for server data with a hook in front of
it. You tell it how to fetch something and give the data a key. It decides when to fetch, keeps the
answer under that key, shares it with every component that asks for the same key, and fetches again
when told the data has changed or when it judges the copy stale. Lesson 9 ended on this: global state
libraries hold client state, and this is the tool for the other kind.
