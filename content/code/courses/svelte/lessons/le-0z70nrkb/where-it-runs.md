---
title: Where each load function runs, and the difference that bites
version: 1
---

**A server load function runs on the server, always. A universal one runs on the server for the first
page and in the browser after that, and on the first page it runs in both.** The first part is easy to
remember. The second is where people get bitten, so watch it happen. Add a line to the course page's
load function, `src/routes/(planner)/courses/[id=slug]/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.js", "parts": [
 {"code": "// +page.js: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';\n\nexport async function load({ params, parent }) {"},
 {"code": "\tconsole.log('loading the course', params.id);\n\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n}", "note": "A line that says where it ran: in the dev server's terminal on the server, in the console in the browser."}
]}
```

Restart the dev server, so that its terminal starts empty. Then open a course page directly, the way a
bookmark or a typed address does, and print the browser's console with `--console`:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish --console | grep -v vite
console: loading the course spanish
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "22 Oct 2026, 30 min"
      - text: 22 Oct 2026, 30 min
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**The browser ran it**, and so did the server. Its terminal printed the same line a moment before,
when it rendered the page:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:15 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 671 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
loading the course spanish
200 GET /courses/spanish
```

The server ran it to render the HTML. The browser ran it again while **hydrating**, which is lesson 1's
word for the browser's code taking over the HTML the server sent: to bring a component to life,
SvelteKit needs the same `data` the server had, so it reruns the universal load functions to get it.
(It does not rerun a server load function. Its result came in the HTML, and running it in the browser
is impossible anyway.)

Now arrive at the same page by a link, from the week:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click Spanish | grep -v vite | head -3
-- click Spanish
console: loading the course spanish
at /courses/spanish
```

`loading the course spanish` was printed by the browser, after the click. The server's terminal has
one new line, for the week page that `look` opened first, and no new `loading the course`:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:15 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 671 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
loading the course spanish
200 GET /courses/spanish
200 GET /
```

**On a client-side navigation a universal load runs only in the browser.** It does not ask the server
anything, unless it calls `fetch`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two rows, each split between the server on the left and the browser on the right. First visit: on the server, the layout&#x27;s server load runs, then the page&#x27;s universal load, then the page is rendered to HTML; the HTML goes to the browser with the data written into it, and the browser runs the universal load again while hydrating. A click on a link: everything happens in the browser, where the universal load runs and the page renders; the server is asked for the server load&#x27;s data at __data.json only if that data is out of date.\"><text x=\"185\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">server</text><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">browser</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">first visit</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a click on a link</text><rect x=\"22\" y=\"60\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"79.5\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+layout.server.js</text><text x=\"79.5\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load</text><rect x=\"145\" y=\"60\" width=\"95\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"192.5\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.js</text><text x=\"192.5\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load</text><rect x=\"250\" y=\"60\" width=\"95\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"297.5\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">render</text><text x=\"297.5\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTML</text><line x1=\"137\" y1=\"83\" x2=\"143\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"143.0,83.0 135.6,86.1 135.6,79.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"240\" y1=\"83\" x2=\"248\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,83.0 240.6,86.1 240.6,79.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"345\" y1=\"83\" x2=\"398\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,83.0 390.6,86.1 390.6,79.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"372\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTML + data</text><rect x=\"400\" y=\"60\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.js</text><text x=\"465\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">load, again</text><line x1=\"530\" y1=\"83\" x2=\"568\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,83.0 560.6,86.1 560.6,79.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"570\" y=\"60\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">hydration</text><text x=\"635\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the page comes alive</text><rect x=\"400\" y=\"200\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.js</text><text x=\"465\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load</text><line x1=\"530\" y1=\"223\" x2=\"568\" y2=\"223\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,223.0 560.6,226.1 560.6,219.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"570\" y=\"200\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">render</text><text x=\"635\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the new page</text><rect x=\"40\" y=\"200\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+layout.server.js</text><text x=\"140\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only if its data is out of date</text><line x1=\"240\" y1=\"223\" x2=\"398\" y2=\"223\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"398.0,223.0 390.6,226.1 390.6,219.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"320\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">__data.json</text><text x=\"360\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the universal load runs on both sides; the server load only ever on the left</text></svg>", "caption": "A universal load runs on the server for the first page, again in the browser to hydrate it, and only in the browser after that. A server load never leaves the server."}
```

## The difference that bites

A universal load function is code that has to work in two different places. Everything in it runs on
the server for the first page and in the browser afterwards, so:

- **It cannot use what only one side has.** `localStorage`, `window` and `document` do not exist on
  the server; `node:fs`, private environment variables and a database connection must not exist in
  the browser, and SvelteKit refuses to ship the modules that hold them, as the second section saw.
- **Whatever it does, it may do twice.** A visit counter in a universal load counts every first visit
  twice, once in each place. Logging, counting and anything else with a side effect belongs in a server
  load function, which runs once per request.
- **Its result is never sent anywhere**, so it can return functions and class instances, which a
  server load function cannot.

A server load function is the opposite on every line. **It runs once, on the server**, can read files,
databases and secrets, and its result is data the browser can read. Choosing between the two is mostly
answering one question, whether the function needs the server, and the planner answers it twice: the
layout reads a file and needs it, the course page looks something up in data it already has and does
not.
