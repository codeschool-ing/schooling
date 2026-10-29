---
title: When a load function runs again
version: 1
---

**SvelteKit reruns a load function only when something it used has changed.** It tracks what each one
reads: a parameter, the URL, `parent()`. A load function that read none of them, like the planner's
layout, runs once for the first page and is never asked again while the visitor stays inside the
group. Make it say when it runs. Replace `src/routes/(planner)/+layout.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\tconsole.log('loading the planner');\n\treturn readPlanner();\n}", "note": "The `console.log` is the only new line. It prints in the terminal running `npm run dev`, since this function runs only on the server."}
]}
```

Restart the dev server so its terminal starts empty, and move around: the week, Spanish, the week again,
Guitar.

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click Spanish --click 'Study planner' --click Guitar | grep -v vite | head -6
-- click Spanish
console: loading the course spanish
-- click Study planner
-- click Guitar
console: loading the course guitar
at /courses/guitar
```

and in the terminal running `npm run dev`:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:24 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 583 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
loading the planner
200 GET /
```

**The planner was loaded once**, for the first page, by the server. The three clicks after it were
client-side navigations inside the `(planner)` group, and nothing the layout's load function reads had
changed, so its data was kept. The course page's load function ran for each course page, in the
browser, because `params.id` was different each time, and because each course page is a new page.

`page.data`, and the `data` prop of every layout and page, are the merged result of all of them. When a
load function reruns, **its component is not recreated**: SvelteKit hands the new `data` to the component
that is already on the screen, as a changed prop. A component that read `data` once, when it was
created, keeps what it read. The planner's `PlannerProvider` does exactly that, `new Planner(untrack(()
=> data))`, and lesson 14 is where that matters.

## Asking for a rerun

Sometimes the data changes for a reason SvelteKit cannot see: somebody else saved a session, or a
form just wrote to the file. Two functions from `$app/navigation` say so:

- **`refreshAll()`** reruns every load function of the current page, layouts included.
- **`invalidate(url)`** reruns only the ones that depend on `url`, which means the universal ones that
  fetched it, and any that called `depends(url)` to declare a dependency by name, such as
  `depends('planner:sessions')`.

Both return a promise that settles when the new data is in place. **`invalidateAll()`**, which older
code calls, is the name `refreshAll()` had before SvelteKit 3, and still works. Lesson 14 rarely needs
to call either: when a form is submitted to the server and succeeds, SvelteKit reruns the load functions
itself, which is the next thing to see.
