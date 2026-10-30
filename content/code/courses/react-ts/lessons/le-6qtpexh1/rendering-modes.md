---
title: When a page is rendered
version: 1
---

**A Next.js page can be rendered at three different moments**, and the build says which for each
route. Build the project as it is:

```
ana@dev:~/planner-next$ npm run build | sed -n "/^Route/,\$p"
Route (app)
┌ ◐ /
├ ○ /_not-found
└   /courses/[courseId]
  └ ◐ /courses/[courseId]


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

The marks mean:

| mark | name | when the HTML is made |
|---|---|---|
| ○ | static | once, at build time, and the same file is sent to everybody |
| ◐ | partial prerender | the shell at build time; the parts inside `Suspense` per request, streamed into it |
| ƒ | dynamic | entirely per request; this project has none, so the build left it out of the legend |

`/_not-found` is static: it never changes. `/` and `/courses/[courseId]` are partial prerenders, and
each for its own reason. The week reads **`searchParams`**, which only exists when a request arrives.
The course page reads **`params`** for a value the build was never told about, and calls an **uncached
`fetch`**, whose answer may differ on every request. Anything in that list makes the part of the page
that uses it wait for a request; the parts that use none of it, the headings and the fallbacks, are
built ahead.

**Which mode a page should have depends on how often its content changes and who it changes for.** A
page that says the same thing to everybody until somebody edits it, a course's description say, can be
built once and sent from a file, which is as fast as a server can answer. A page that depends on the
request, such as the week someone asked for, cannot. Most pages are in between, which is what the
partial prerender is for: the parts that can wait for a build do, and the rest streams.

The course page is the in-between case done badly. Its sessions change only when somebody plans or
ticks one, which is rare next to the number of times it is read, and yet every request asks the API
again. The next section caches it.

```schooling-figure
{"svg": "<svg data-fig=\"modes\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three rows, one per rendering mode, against two moments: build time and request time. Static: the whole page is made at build time and the same file is sent on every request. Partial prerender: the shell is made at build time, and the parts inside Suspense are rendered per request and streamed into it. Dynamic: nothing at build time; the whole page is made per request.\"><text x=\"285\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">at build time</text><text x=\"560\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">per request</text><line x1=\"420\" y1=\"30\" x2=\"420\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"24\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">○</text><text x=\"46\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">static</text><rect x=\"170\" y=\"44\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the whole page</text><text x=\"560\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same file, every time</text><text x=\"24\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">◐</text><text x=\"46\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">partial</text><rect x=\"170\" y=\"102\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the shell</text><rect x=\"440\" y=\"102\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what is inside Suspense</text><text x=\"24\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">ƒ</text><text x=\"46\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dynamic</text><rect x=\"440\" y=\"160\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the whole page</text></svg>", "caption": "The question is how much of the page can be known before anybody asks for it."}
```
