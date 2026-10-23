---
title: Where the HTML is made
version: 1
---

**Every page a browser shows starts as HTML, and somebody has to write that HTML out of the data.**
This course calls that step **rendering**. The question this lesson is about is not *whether* it
happens but *where* and *when*: in the browser, after a script has run, or on a server, before
anything has been sent.

A common picture of the difference is that one kind of site "uses JavaScript" and the other does
not. That is not it. Both kinds of page in this lesson run the same JavaScript in the browser. What
differs is what the **first response** carries, and so what a person sees, and how soon, before
that JavaScript has arrived and run.

## Three answers to "where"

| | the HTML is made | the first response carries | named in this course |
|---|---|---|---|
| **client-side** | in the browser, by your script, after it has fetched the data | an empty container and a `<script>` tag | CSR, client-side rendering |
| **server-side** | on the server, for each request, out of the data it has then | the finished page | SSR, server-side rendering |
| **at build time** | on your computer or in CI, once, before deploying | a file that was finished before anybody asked | SSG, static generation (lesson 3) |

**Hybrid** is the fourth answer, and the one most real sites give: the server sends a finished
page, and then the script in the browser takes it over, so that every click after the first is
handled without asking the server for HTML again. Lesson 4 is about the moment of that takeover,
called hydration; this lesson only needs the idea.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three rows, one per way of rendering, each a timeline from left to right. Client-side: the browser receives an empty page, fetches the script, the script fetches the data, and only then is the page drawn. Server-side: the server reads the data and draws the page when the request arrives, and the browser shows it as soon as it is received. Build time: the page was drawn before anybody asked, and the server only hands out the file.\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">client-side</text><rect x=\"150\" y=\"44\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">empty HTML</text><rect x=\"280\" y=\"44\" width=\"102\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"331.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><rect x=\"400\" y=\"44\" width=\"102\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"451.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data</text><rect x=\"520\" y=\"44\" width=\"152\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"596.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">page drawn</text><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">server-side</text><rect x=\"150\" y=\"129\" width=\"222\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"261.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server reads data, draws page</text><rect x=\"390\" y=\"129\" width=\"152\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"466.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">page shown</text><rect x=\"560\" y=\"129\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"616.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build time</text><rect x=\"150\" y=\"214\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file</text><rect x=\"280\" y=\"214\" width=\"152\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"356.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">page shown</text><rect x=\"450\" y=\"214\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><text x=\"150\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">drawn earlier, on your computer or in CI</text><line x1=\"140\" y1=\"285\" x2=\"700\" y2=\"285\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,285.0 692.6,288.1 692.6,281.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "The same page, made in three places. What moves is the moment the person first sees it."}
```

## Why it decides so much

Where the HTML is made decides four things that the rest of this course measures:

- **when the first content appears.** A client-rendered page cannot show its content before three
  things have arrived one after the other: the HTML, the script it names, and the data the script
  asks for. A server-rendered page shows it with the first.
- **what a program that does not run scripts reads.** Some crawlers and every link preview read
  the first response and nothing else.
- **who does the work.** Rendering on the server costs the server time on every request; rendering
  in the browser costs the visitor's phone that time, on every visit.
- **what can be cached.** A finished page is a file a cache can keep. A page made per request for
  one person cannot be shared with the next.

None of these has one right answer for a whole site. The list of courses in the planner you are
about to build, and the form that adds a session, want different things, and the frameworks of
lesson 2 let you choose per page. **Choosing well means knowing what each answer costs**, which is
what the rest of this lesson measures, on your own computer, in an app you build yourself.
