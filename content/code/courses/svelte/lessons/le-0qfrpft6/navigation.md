---
title: Links, preloading, and what a reload loses
version: 1
---

**A link inside the application is an `<a href>`, and SvelteKit makes it fast without any change to the
markup.** Two things happen that a plain website does not do: the click is handled without a reload, as
the first section of this lesson said, and the code for the page behind a link is fetched before the
click, while the pointer is on its way.

That second part comes from one attribute, which `sv` wrote into `src/app.html` in lesson 1:

```
ana@dev:~/planner$ grep -n sveltekit src/app.html
7:		%sveltekit.head%
9:	<body data-sveltekit-preload-data="hover">
10:		<div style="display: contents">%sveltekit.body%</div>
```

**`data-sveltekit-preload-data="hover"`** on the `<body>` tells SvelteKit to start loading a link's page
when the pointer rests on it, or when a finger touches it on a phone. By the time the click arrives,
most of the work is done. It applies to every link inside the element that carries it, so it can be
turned off for one link or one part of the page with `data-sveltekit-preload-data="false"`, or made
stricter with `tap`, which waits for the press itself, for pages where loading a link nobody follows
would cost too much.

## What survives a navigation

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"On the left, the planner&#x27;s routes as files: the root layout and error page; a (planner) group with its own layout, the week page at / and the course page at /courses/ followed by a slug; and an (info) group with the About page. On the right, the same routes as nested components. The root layout wraps everything. Inside it, the (planner) layout wraps the provider, which holds the planner, which wraps the page. Moving between the week and a course replaces only the page. Going to About replaces the (planner) layout and everything in it, the planner included.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">as files</text><text x=\"28\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/routes/</text><text x=\"46\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+layout.svelte</text><text x=\"46\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+error.svelte</text><text x=\"46\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">(planner)/</text><text x=\"64\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+layout.svelte</text><text x=\"64\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+page.svelte</text><text x=\"300\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">/</text><text x=\"64\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses/[id=slug]/</text><text x=\"82\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+page.svelte</text><text x=\"300\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">/courses/…</text><text x=\"46\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">(info)/</text><text x=\"64\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">about/</text><text x=\"82\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+page.svelte</text><text x=\"300\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">/about</text><text x=\"340\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">as components</text><rect x=\"340\" y=\"34\" width=\"360\" height=\"270\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+layout.svelte</text><text x=\"688\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">always stays</text><rect x=\"354\" y=\"66\" width=\"216\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">(planner)/+layout.svelte</text><rect x=\"366\" y=\"98\" width=\"192\" height=\"176\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlannerProvider</text><text x=\"378\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the planner, in context</text><rect x=\"378\" y=\"150\" width=\"168\" height=\"108\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"462\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the page</text><text x=\"462\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/</text><text x=\"462\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">or</text><text x=\"462\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/…</text><rect x=\"584\" y=\"66\" width=\"104\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"636\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">(info)</text><text x=\"636\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">about/</text><text x=\"636\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.svelte</text><text x=\"520\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dashed: replaced on navigation · solid: stays between the planner's pages</text></svg>", "caption": "Between two pages of the group only the page changes. About is outside the group, so going there replaces the group's layout, and the planner with it."}
```

The figure is the planner's routes as files and as nested components. **Following a link between two
pages of the `(planner)` group replaces only the page**: the root layout, the group's layout, the
provider and the planner inside it stay, which is why the week and any added session survived the trip
in "A route with a parameter". Going to About replaces the group's layout as well, because About is
outside the group; come back, and the group's layout is created again, loads the data again, and makes
a new planner from the file. The sessions added before are gone:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --fill 'Date=2026-10-21' --press Enter --click 'About' --click 'Study planner'
-- fill Date=2026-10-21
-- press Enter
-- click About
-- click Study planner
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 150 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 90 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
```

Guitar has its 45 minutes from the data file and not the 75 it had a moment before, on the course page.

**A reload loses everything in memory**, on any page, for the same reason: the browser starts from
nothing and the data file has not changed. That is the planner's real limit at this point in the
course. Its state lives in the browser, and the browser forgets. Lesson 13 moves the data to the server,
and lesson 14 writes changes back there, after which a reload shows what was added, on any computer.
