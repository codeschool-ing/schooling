---
title: Hybrid rendering
version: 1
---

**Hybrid is the name for what the planner does now with JavaScript on: the server renders the
first page, and from then on the browser renders every page the person moves to.** The first view
gets what server rendering is good at, content in the first response. Every click after it gets
what client rendering is good at, no trip to the server for HTML.

Run `look.ts` with JavaScript against `server.ts` and watch the requests: the page, its script and
stylesheet, and `/courses.json`. Then click *Git* in your own browser with its developer tools open
on the Network tab: **no request for a page goes out.** The link handler in `mount` changed the
address with `history.pushState` and drew the course page from the plan it already had. Reload,
and the request goes to the server again, which draws the course page itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A hybrid session. The first page is requested from the server, which draws it. Then two clicks, to the Git course and back to the list, are drawn by the script in the browser, and no request for a page goes to the server. A reload sends the request to the server again.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">server</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">browser</text><line x1=\"100\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"100\" y1=\"140\" x2=\"700\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><rect x=\"120\" y=\"34\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">draws page</text><line x1=\"175\" y1=\"66\" x2=\"175\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"175.0,122.0 171.9,114.6 178.1,114.6\" fill=\"var(--amber)\"></polygon><rect x=\"120\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shows it</text><text x=\"175\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GET /</text><rect x=\"270\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">draws page</text><text x=\"325\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">click Git</text><rect x=\"420\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">draws page</text><text x=\"475\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">click All courses</text><rect x=\"580\" y=\"34\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">draws page</text><line x1=\"635\" y1=\"66\" x2=\"635\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"635.0,122.0 631.9,114.6 638.1,114.6\" fill=\"var(--amber)\"></polygon><rect x=\"580\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shows it</text><text x=\"635\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reload</text></svg>", "caption": "The server draws the first page and every reload; the browser draws everything in between."}
```

## Hybrid in three more senses

The word is used for more than one arrangement, and the frameworks of lesson 2 offer all of them,
so it is worth separating them now.

**Per navigation**, as above: server for the first page, browser for the rest. This is what every
one of the four meta-frameworks does by default.

**Per route**: some addresses are rendered on each request, some are rendered once at build time
and served as files, and some are left to the browser entirely. A course catalogue that changes
once a week, a dashboard that shows each person their own numbers, and a settings screen nobody
will ever find through a search engine want three different answers, and one site can give all
three. Lesson 2 shows how each framework spells the choice, and lesson 3 is the build-time answer.

**Per component**: most of a page is static HTML that never changes after it arrives, and only a
few parts of it respond to anything. An approach called **islands** sends the static part as
plain HTML with no script at all, and ships JavaScript only for the parts that need it, such as
the *Mark done* buttons and the form of the planner. Lesson 4 comes back to it, because it is a
way of making hydration cheaper.

## What hybrid costs

Hybrid keeps both costs of the previous two sections and adds one of its own. The server renders
every first page, as in server-side rendering. The browser downloads and runs the whole app, as
in client-side rendering, because it will draw the next page. **And the same page now has two
renderers that must agree**: the HTML the server drew and the HTML the script would draw have to
be the same, or the takeover changes what the person is looking at. In the planner they agree by
construction, because both call `page`. Lesson 4 breaks that on purpose, with a date.
