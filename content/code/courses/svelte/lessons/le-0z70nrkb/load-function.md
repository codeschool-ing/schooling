---
title: A load function, and the data it returns
version: 1
---

**A `load` function is how a SvelteKit page gets its data before it renders.** It lives in a file beside
the page or layout, `+page.js` or `+layout.js`, and whatever it returns arrives in the component as a
prop called `data`. SvelteKit calls it, waits for it, and only then renders, so the component never
sees a moment without its data.

Since lesson 8 the planner has done the opposite: the `(planner)` layout renders first, starts a
`fetch` in the browser, and shows a loading message until the answer arrives. The server cannot run that
fetch, so what it sends is the loading message and nothing else. Ask it:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -c '<title>'
0
```

**No title at all.** The week page sets the title, and the week page is inside the `{#await}` that never
settles on the server, so it was never rendered there. A search engine, a link preview or a browser
with JavaScript switched off sees a page that says "Loading the planner…" for ever.

## Moving the request into `load`

The request moves out of the component into a load function. Save this as
`src/routes/(planner)/+layout.js`, beside the group's layout:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.js", "parts": [
 {"code": "// +layout.js: the data every page of the planner needs, loaded before any of them renders.\nimport { error } from '@sveltejs/kit';"},
 {"code": "export async function load({ fetch }) {\n\tconst response = await fetch('/planner.json');", "note": "`load` receives an object describing the request. `fetch` in it is SvelteKit's own, which can ask for a relative address even on the server."},
 {"code": "\tif (!response.ok) error(response.status, 'The planner could not be loaded.');", "note": "`error()` stops the load and shows the error page with that status, the one lesson 12 wrote."},
 {"code": "\treturn response.json();\n}", "note": "What it returns becomes the layout's `data`."}
]}
```

The layout loses its loading code. There is nothing to wait for any more, because by the time the
component runs, the data is there. Replace `src/routes/(planner)/+layout.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+layout.svelte", "parts": [
 {"code": "<script>\n\timport PlannerProvider from '#lib/PlannerProvider.svelte';"},
 {"code": "\tlet { data, children } = $props();\n</script>", "note": "`data` is what `load` returned. `children` is still the page."},
 {"code": "<PlannerProvider {data}>\n\t{@render children()}\n</PlannerProvider>"}
]}
```

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<title>.*</title>'
<title>225 min this week · Study planner</title>
```

**The server rendered the whole page this time**, title included: it ran `load`, waited for the file,
and rendered the week with the data in it. The `{#await}` and its three branches are gone, and so is
`browser` from `$app/env`, the guard lesson 8 needed because the component could not tell where
it was running. A load function does not have to know either.

## Run twice, fetched once

A load function in `+layout.js` or `+page.js` is **universal**: it runs on the server to render the
first page, and then again in the browser, when the page comes to life. The second run does not repeat
the request. During the server's run, SvelteKit's `fetch` kept the response and wrote it into the HTML;
in the browser, the same `fetch('/planner.json')` finds it there and answers at once:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<script type="application/json" data-sveltekit-fetched[^>]*>'
<script type="application/json" data-sveltekit-fetched data-url="/planner.json">
```

That is the reason to use the `fetch` that `load` receives rather than the global one. The global `fetch`
on the server cannot take a relative address, as lesson 8 found, and in the browser it would ask again
for what the page already has.
