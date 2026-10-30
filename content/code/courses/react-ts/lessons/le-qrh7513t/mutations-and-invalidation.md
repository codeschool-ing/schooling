---
title: Mutations, and telling the cache it is stale
version: 1
---

**A mutation changes data on the server; invalidating a query tells the cache its copy is now
wrong.** The library then fetches again, every component reading that key gets the new data, and
nobody keeps two copies in step by hand. Tick a session and watch the requests:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep -E 'api|minutes done'
net  GET /api/planner  200
net  PATCH /api/sessions/s2  200
net  GET /api/planner  200
    - paragraph: 120 of 195 minutes done
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | grep 'minutes done'
    - paragraph: 120 of 195 minutes done
ana@dev:~/planner$ grep -A 4 '"s2"' data/planner.json
      "id": "s2",
      "course": "statistics",
      "date": "2026-10-21",
      "minutes": 40,
      "done": true
```

Three requests: the first load, **the `PATCH` that marked `s2` done**, and **the `GET` that
`refresh` caused**, after which the summary says 120. The second `look` is a new browser page with an
empty cache, and it still says 120, because the change is on the server now. The file on disk is
where the server keeps it.

Adding a session goes the same way, with a `POST`:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --do 'click button Back to courses' | grep -E 'api|minutes done'
net  GET /api/planner  200
net  POST /api/sessions  201
net  GET /api/planner  200
    - paragraph: 120 of 240 minutes done
```

**120 of 240**: the 45 minutes added on Saturday, with the 40 from the transcript before still ticked,
because the server remembers both. Lesson 10's form did not change; `addSession` now posts instead
of pushing into local state, and the server checks the session again before keeping it.

```schooling-figure
{"svg": "<svg data-fig=\"invalidate\" viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"A timeline of ticking a session. The checkbox calls toggleDone; the mutation sends PATCH to the server; when it answers, onSuccess invalidates the planner key; the query fetches GET /api/planner again; every component reading the key renders with the new data.\"><rect x=\"10\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">toggleDone(id)</text><line x1=\"141\" y1=\"42\" x2=\"151\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"151.0,42.0 143.5,45.2 143.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"152\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"217.0\" y=\"35.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">PATCH</text><text x=\"217.0\" y=\"48.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/sessions/s2</text><line x1=\"283\" y1=\"42\" x2=\"293\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"293.0,42.0 285.5,45.2 285.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"294\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">invalidateQueries</text><line x1=\"425\" y1=\"42\" x2=\"435\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"435.0,42.0 427.5,45.2 427.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"436\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"501.0\" y=\"35.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET</text><text x=\"501.0\" y=\"48.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/planner</text><line x1=\"567\" y1=\"42\" x2=\"577\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"577.0,42.0 569.5,45.2 569.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"578\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">readers render</text><text x=\"225\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the server changes</text><text x=\"507\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the copy is fetched again</text></svg>", "caption": "Change on the server, mark the copy stale, fetch it again."}
```

Invalidating and fetching again costs one request per change, and it is the simple, correct
default: the screen shows exactly what the server holds. There are two ways to save the request, and
both trade simplicity for speed. `setQueryData` writes the server's answer straight into the cache,
which works when the mutation returns everything the screen needs. And an **optimistic update**
changes the cache before the server answers, so the tick appears at once, and puts it back if the
request fails. That is lesson 16's subject, with React's own hook for it.
