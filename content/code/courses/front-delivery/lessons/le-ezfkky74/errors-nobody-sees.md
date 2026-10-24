---
title: Errors nobody sees
version: 1
---

**An error in a front-end happens on somebody else's computer, and unless the page reports it, the only
person who knows is the one it happened to.** A server that fails writes to a log on a machine its team
runs. A page that fails writes to the console of a browser on a phone you will never hold, and the person
holding it sees a button that did nothing, closes the tab, and tells nobody.

The planner already has three places where that happens:

| where | what goes wrong | what the planner does today |
|---|---|---|
| `saveDone` in `main.ts` | the server refuses *Mark done*, or cannot be reached | `console.error("Could not save", …)` |
| `watch` in `main.ts` | the first load fails | `console.error("Could not load", …)` |
| `watchPlanner` in `apollo.ts` | a query answers with an error | `console.error("Could not load", …)` |

And one place it cannot see at all: **anything nobody wrote a `catch` for.** A `TypeError` in a click
handler, a promise rejected with nothing waiting for it, a bug in a library. Those stop the code that was
running, print a red line in the console, and leave the page as it was at that moment.

## What monitoring is

**Client-side error monitoring** is the page sending a short report of each error to a server you run, or
pay for, so that the team sees failures as they happen, with enough detail to find the line that caused
them. **Crash reporting** is the same thing, by the name native apps gave it.

The rest of this lesson builds the whole chain by hand, small enough to read in one sitting:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The chain this lesson builds. In the browser, the error and unhandledrejection listeners and the planner&#x27;s own catches call report, which sends a beacon to /errors. Vite&#x27;s proxy passes it to the collector, which writes one line of JSON per report to errors.jsonl. Later, symbolicate.mjs reads a report&#x27;s stack with the release&#x27;s source maps, kept in maps/, off the public host, and prints the original lines.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">somebody's browser</text><rect x=\"20\" y=\"32\" width=\"230\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"error\"</text><text x=\"36\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"unhandledrejection\"</text><text x=\"36\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">saveDone · load · Planner</text><rect x=\"36\" y=\"120\" width=\"198\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">report()</text><line x1=\"250\" y1=\"134\" x2=\"300\" y2=\"134\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,134.0 292.6,137.1 292.6,130.9\" fill=\"var(--phosphor)\"></polygon><text x=\"275\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/errors</text><text x=\"310\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the team's side</text><rect x=\"302\" y=\"110\" width=\"170\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"387\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">collector.mjs</text><line x1=\"472\" y1=\"134\" x2=\"520\" y2=\"134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,134.0 512.6,137.1 512.6,130.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"522\" y=\"110\" width=\"178\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"611\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">errors.jsonl</text><rect x=\"522\" y=\"34\" width=\"178\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"611\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">maps/&lt;release&gt;/</text><text x=\"611\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never on the host</text><rect x=\"302\" y=\"176\" width=\"398\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">symbolicate.mjs</text><text x=\"690\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src/main.ts:16:45</text><line x1=\"611\" y1=\"160\" x2=\"611\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"611.0,174.0 607.9,166.6 614.1,166.6\" fill=\"var(--paper-dim)\"></polygon><line x1=\"700\" y1=\"82\" x2=\"708\" y2=\"82\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><path d=\"M 708 82 L 708 196 L 702 196\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path></svg>", "caption": "Catch, send, keep, then read the stack with the maps of the same release."}
```

1. the page catches what escaped and what its own `catch`es saw;
2. it sends a report to a collector;
3. the collector keeps it;
4. a source map turns the report's minified stack back into the planner's own lines;
5. every report says which release it came from.

Hosted services such as Sentry do all five, and more, and the section on them shows how one is set up.
Building it first means knowing what they do with your data, which is the question the section on the
LGPD asks.
