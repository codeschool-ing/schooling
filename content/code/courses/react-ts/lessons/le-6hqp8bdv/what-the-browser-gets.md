---
title: What the browser gets
version: 1
---

**A Server Component's result reaches the browser as HTML, and its code does not reach it at all.**
Ask for the page without a browser, so that nothing runs on your side:

```
ana@dev:~/planner-next$ curl -s 'http://localhost:3000/?week=2026-10-19' | grep -o '<p>80[^/]*</p>\|<h2>[^<]*</h2>'
<p>80<!-- --> of <!-- -->195<!-- --> minutes done</p>
<h2>Statistics</h2>
<h2>Spanish</h2>
<h2>Organic chemistry</h2>
```

The numbers and the course names are in the HTML the server sent. The `<!-- -->` between `80`, `of`
and `195` are comments React writes between pieces of text that came from different expressions, so
that it can tell them apart again in the browser.

Then the `console.log`. It ran on the server, so its line is in the Next.js terminal, once per page
asked for, the `look` and then the `curl`:

```
Planner: week of 2026-10-19, 6 sessions
 GET /?week=2026-10-19 200 in 83ms (next.js: 3ms, application-code: 80ms)
Planner: week of 2026-10-19, 6 sessions
 GET /?week=2026-10-19 200 in 50ms (next.js: 1.6ms, application-code: 48ms)
```

The browser's console had a copy of it too, in the `look` transcripts above, starting `%c%s%c` and
ending in `Server`. In development, React sends the server's console lines along with the page and
replays them in the browser with a grey **Server** badge in front, so that you can see them where you
are already looking. `look` prints the badge's styling as raw text; a browser draws the badge. In a
production build that copy is not sent.

```schooling-figure
{"svg": "<svg data-fig=\"server-client\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Where each part of the Next.js planner runs. On the server: page, Planner and getPlanner, which fetches from the API on port 3001. They send HTML and a description of the result to the browser. In the browser: WeekKeys, the one Client Component, which receives the string monday as a prop. The API's address never leaves the server.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">the server</text><rect x=\"40\" y=\"60\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">page.tsx</text><rect x=\"40\" y=\"110\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Planner.tsx</text><rect x=\"40\" y=\"160\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">getPlanner()</text><line x1=\"105\" y1=\"90\" x2=\"105\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><line x1=\"105\" y1=\"140\" x2=\"105\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"210\" y=\"160\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:3001 API</text><line x1=\"172\" y1=\"175\" x2=\"208\" y2=\"175\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,175.0 200.5,178.2 200.5,171.8\" fill=\"var(--amber)\"></polygon><rect x=\"390\" y=\"20\" width=\"310\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">the browser</text><rect x=\"410\" y=\"70\" width=\"270\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"87.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the page, as HTML</text><text x=\"545.0\" y=\"102.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">80 of 195 minutes done</text><rect x=\"410\" y=\"150\" width=\"270\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">WeekKeys  'use client'</text><line x1=\"352\" y1=\"95\" x2=\"408\" y2=\"95\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"408.0,95.0 400.5,98.2 400.5,91.8\" fill=\"var(--amber)\"></polygon><text x=\"380\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">HTML</text><line x1=\"172\" y1=\"125\" x2=\"408\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"408.0,168.0 400.0,169.8 401.2,163.5\" fill=\"var(--phosphor)\"></polygon><text x=\"270\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">monday=&quot;2026-10-19&quot;</text><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the fetch and the API's address stay on the server</text></svg>", "caption": "Server Components send results; only the Client Component's code travels."}
```

So two kinds of components now live in the same tree:

| | Server Component | Client Component |
|---|---|---|
| runs | on the server, once per request, or at build time | in the browser, and on the server for the first HTML |
| its code is sent to the browser | no | yes |
| can be `async` and `await` data | yes | no |
| can read files, a database, secrets | yes | no |
| can use state, effects, event handlers | no | yes |

The last row is the price. A Server Component has run and finished by the time the page reaches the
browser, so there is nothing left to hold state or to answer a click. The next section asks for a click
anyway, to see what happens.
