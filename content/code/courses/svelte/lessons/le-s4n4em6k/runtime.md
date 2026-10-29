---
title: What the types do not check
version: 1
---

**Types are checked when `svelte-check` runs, and then they are gone.** The build removes every
annotation, and what runs in Node and the browser is the same JavaScript as before. So a type says what
a value is supposed to be, and the checker holds the code to it; nothing holds the value to it when the
program runs.

Most of the time that distinction does not matter, because the values come from the program's own code,
which the checker has seen. It matters at the edges, where values come from outside:

- **A file.** `readPlanner` says it returns a `PlannerData`, and `JSON.parse` returns whatever the file
  holds. If somebody edits `data/planner.json` by hand and writes `"minutes": "30"`, the checker is
  none the wiser, and the planner adds a string to a number.
- **A request.** A form field is always a string; a JSON body is whatever the sender sent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two rows. At check time, svelte-check reads the TypeScript files and their types and reports mistakes in the code, before anything runs. At run time, the build has removed the types, and the JavaScript that runs receives values from outside, from a form or a JSON request. Those values have never been seen by the checker, so problemWith, a function that runs, checks them as they arrive.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">when svelte-check runs</text><rect x=\"20\" y=\"44\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">week.ts, +page.server.ts …</text><text x=\"120\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">code with its types</text><line x1=\"220\" y1=\"69\" x2=\"278\" y2=\"69\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,69.0 270.6,72.1 270.6,65.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"280\" y=\"44\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">svelte-check</text><text x=\"380\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mistakes in the code</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">when the planner runs</text><rect x=\"20\" y=\"154\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the build: no types left</text><text x=\"120\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">build/</text><rect x=\"520\" y=\"150\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a form</text><line x1=\"518\" y1=\"164\" x2=\"452\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"452.0,182.0 458.3,177.1 459.9,183.1\" fill=\"var(--paper-dim)\"></polygon><rect x=\"520\" y=\"190\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a JSON request</text><line x1=\"518\" y1=\"204\" x2=\"452\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"452.0,182.0 460.0,181.4 458.0,187.3\" fill=\"var(--paper-dim)\"></polygon><rect x=\"280\" y=\"154\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">problemWith()</text><text x=\"365\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bad values, as they arrive</text><line x1=\"220\" y1=\"179\" x2=\"278\" y2=\"179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,179.0 270.6,182.1 270.6,175.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the checker never sees what comes from outside; a check that runs does</text></svg>", "caption": "Types find mistakes in the code before it runs. Values from outside arrive after the types are gone."}
```

That is why **`problemWith` is still a function that runs**, and why its parameters are `unknown`.
Start the dev server and send the API a session whose minutes are a string:

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{"course":"spanish","date":"2026-10-24","minutes":"30"}' http://localhost:5173/api/sessions
{"status":400,"message":"Minutes must be a whole number from 5 to 600."} 400
```

Refused, by the check that runs, not by the types, which never saw the request. The two do different
jobs. The types find mistakes in the code before it runs; the check finds bad values while it runs.
A program that takes values from outside needs both, and a library such as Zod or Valibot can produce
the second from the first, a schema that checks a value and gives it a type in the same step. The
planner's one check is small enough to write by hand.

The planner works as it did:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish | sed -n 1,12p
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
```
