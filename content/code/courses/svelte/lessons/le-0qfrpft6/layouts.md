---
title: Layouts, the part of the page that stays
version: 1
---

**A `+layout.svelte` wraps every page in its folder and in the folders below it, and `{@render
children()}` is where the page goes.** The project has had one since lesson 1: `sv` wrote
`src/routes/+layout.svelte` to add the favicon, and it renders `children` and nothing else. Make it the
planner's frame, with a header that every page shares, the `<main>` that each page goes inside, and the
styles that belong to the whole document:

```schooling-example
{"language": "html", "file": "src/routes/+layout.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n\timport favicon from '#lib/assets/favicon.svg';\n\n\tlet { children } = $props();\n</script>\n\n<svelte:head>\n\t<link rel=\"icon\" href={favicon} />\n</svelte:head>", "note": "`page` from `$app/state` is the current page. The layout reads its address to mark the link to where you are."},
 {"code": "<header>\n\t<nav aria-label=\"Main\">\n\t\t<a href=\"/\" aria-current={page.url.pathname === '/' ? 'page' : undefined}>Study planner</a>\n\t\t<a href=\"/about\" aria-current={page.url.pathname === '/about' ? 'page' : undefined}>About</a>\n\t</nav>\n</header>", "note": "`aria-current=\"page\"` tells a screen reader which link is the page it is on. `undefined` leaves the attribute out."},
 {"code": "<main>\n\t{@render children()}\n</main>", "note": "The page goes here. The layout is created once and stays while the pages inside it change."},
 {"code": "<style>\n\t:global(body) {\n\t\tmargin: 0;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\theader {\n\t\tborder-bottom: 1px solid #767676;\n\t\tpadding: 0.5rem 1rem;\n\t}\n\n\tnav {\n\t\tdisplay: flex;\n\t\tgap: 1rem;\n\t\tmax-width: 40rem;\n\t\tmargin: 0 auto;\n\t}\n\n\t[aria-current='page'] {\n\t\tfont-weight: bold;\n\t}\n\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tpadding: 0 1rem;\n\t}\n</style>", "note": "`:global(body)` reaches outside the component, deliberately: the body belongs to the whole document, and this layout is the one place that should style it."}
]}
```

The home page had a `<main>` and its own style for it, which now belong to the layout. Take them out of
`src/routes/+page.svelte`, so the page is only its own content:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport { browser } from '$app/env';\n\timport Planner from '#lib/Planner.svelte';\n\n\tfunction load() {\n\t\treturn fetch('/planner.json').then((response) => {\n\t\t\tif (!response.ok) throw new Error(`${response.status} ${response.statusText}`);\n\t\t\treturn response.json();\n\t\t});\n\t}\n\n\t// In the browser, ask for the data. On the server, a promise that never\n\t// settles, so the server's HTML is the loading message.\n\tconst loading = browser ? load() : new Promise(() => {});\n</script>", "note": "The script is unchanged: the page still loads the data in the browser, as in lesson 8."},
 {"code": "<h1>Study planner</h1>\n{#await loading}\n\t<p>Loading the planner…</p>\n{:then data}\n\t<Planner {data} />\n{:catch error}\n\t<p role=\"alert\">The planner could not be loaded: {error.message}</p>\n{/await}", "note": "No `<main>` and no `<style>`: the layout provides both."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/about
at /about
title: About · Study planner
- main:
  - heading "About the planner" [level=1]
  - paragraph: The study planner lists your courses, the sessions you plan for each, and the minutes in your week. It keeps everything on this computer, in one small file, and asks nobody for anything.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

`look` prints the tree of `<main>`, which now belongs to the layout, so the page reads the same as
before. The header is outside `<main>` and so outside what `look` prints. To see it, read the HTML the
server sent:

```
ana@dev:~/planner$ curl -s http://localhost:5173/about | grep -o '<header.*</header>'
<header class="svelte-12qhfyh"><nav aria-label="Main" class="svelte-12qhfyh"><a href="/" class="svelte-12qhfyh">Study planner</a> <a href="/about" aria-current="page" class="svelte-12qhfyh">About</a></nav></header>
```

The server marked the About link as the current page, `aria-current="page"`, on the first response,
before any JavaScript ran.

## Layouts nest

Every folder may have a `+layout.svelte`, and a page is wrapped by every layout from its own folder up
to the root, the innermost closest to it. A layout is **not** recreated when you navigate between two
pages it wraps: it stays, with its state and its elements, and only the `children` it renders changes.
That is what makes a layout the right place for anything the pages under it share, and the next
section uses exactly that to share the planner.
